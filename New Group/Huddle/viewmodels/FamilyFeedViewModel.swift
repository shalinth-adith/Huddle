//
  //  FamilyFeedViewModel.swift
  //  Huddle
  //
  //  Created by shalinth adithyan on 22/12/25.
  //
  import Foundation
  import SwiftUI
  import Combine
  import FirebaseFirestore

  class FamilyFeedViewModel: ObservableObject {
      @Published var family: Family?
      @Published var isLoading = true
      @Published var showShareSheet = false
      @Published var showShoppingList = false

      @Published var messages: [HuddleMessage] = []
      @Published var unreadCount: Int = 0
      private var messageListener: ListenerRegistration?

      @Published var shoppingItems: [HuddleMessage] = []
      private var shoppingListener: ListenerRegistration?

      @Published var pinnedMessages: [HuddleMessage] = []
      @Published var availableFamilies: [Family] = []

      private let familyService: FamilyService
      private let authService: AuthService
      private let messageService: MessageService
      private let db = Firestore.firestore()

      init(familyService: FamilyService, authService: AuthService, messageService: MessageService) {
          self.familyService = familyService
          self.authService = authService
          self.messageService = messageService
      }

      func loadFamily() {
          guard let familyId = authService.currentUser?.currentFamilyId else {
              self.isLoading = false
              return
          }

          familyService.fetchFamily(familyId: familyId) { [weak self] result in
              guard let self else { return }
              switch result {
              case .success(var fetchedFamily):
                  // Patch current user's member instantly from in-memory authService (no network call)
                  if let uid = self.authService.currentUser?.id,
                     let photo = self.authService.currentUser?.photoBase64 {
                      fetchedFamily.members = fetchedFamily.members.map { member in
                          guard member.id == uid else { return member }
                          var m = member; m.photoBase64 = photo; return m
                      }
                  }
                  self.family = fetchedFamily
                  self.isLoading = false
                  self.setupEncryption(family: fetchedFamily)
              case .failure:
                  self.isLoading = false
              }
          }
      }

      func loadMessages() {
          guard let familyId = authService.currentUser?.currentFamilyId else {
              return
          }

          self.messageListener = messageService.listenToMessages(familyId: familyId) { result in
              switch result {
              case .success(let fetchedMessages):
                  self.messages = fetchedMessages
                  self.updateUnreadCount()
                  let widgetPings = fetchedMessages
                      .filter { $0.type == .ping }
                      .suffix(1)
                      .map { SharedDataManager.WidgetPing(content: $0.content, senderName: $0.senderName ?? "Unknown", sentAt: $0.createdAt) }
                  SharedDataManager.savePings(Array(widgetPings))
              case .failure(_):
                  break
              }
          }
      }

      func loadShoppingItems() {
          guard let familyId = authService.currentUser?.currentFamilyId else {
              return
          }

          messageService.fetchShoppingItems(familyId: familyId) { result in
              switch result {
              case .success(let items):
                    self.shoppingItems = items
                    self.saveWidgetShoppingItems(items)
              case .failure(_):
                  break
              }
          }
      }

      func toggleShoppingItem(_ item: HuddleMessage) {
          guard let familyId = authService.currentUser?.currentFamilyId,
                let itemId = item.id else { return }

          // Optimistic update — no Firestore re-fetch needed
          shoppingItems.removeAll { $0.id == itemId }

          messageService.deleteMessage(familyId: familyId, messageId: itemId) { [weak self] result in
              if case .failure = result {
                  self?.loadShoppingItems()
              }
          }
      }

      func sendMessage(content: String) {
          guard let familyId = authService.currentUser?.currentFamilyId,
                let userId = authService.currentUser?.id,
                let userName = authService.currentUser?.displayName else {
              return
          }

          messageService.sendChatMessage(
              familyId: familyId,
              content: content,
              senderId: userId,
              senderName: userName
          ) { result in
              switch result {
              case .success:
                  break
              case .failure(_):
                  break
              }
          }
      }

      func sendPing(content: String) {
          guard let familyId = authService.currentUser?.currentFamilyId,
                let userId = authService.currentUser?.id,
                let userName = authService.currentUser?.displayName else { return }
          messageService.sendPingMessage(familyId: familyId, content: content, senderId: userId, senderName: userName) { _ in }
      }

      func loadPinnedMessages() {
          guard let familyId = authService.currentUser?.currentFamilyId else {
              return
          }

          messageService.fetchPinnedMessages(familyId: familyId) { result in
              switch result {
              case .success(let messages):
                    self.pinnedMessages = messages
                    self.saveWidgetPinnedMessages(messages)
              case .failure(_):
                  break
              }
          }
      }

      func togglePinMessage(_ message: HuddleMessage) {
          guard let familyId = authService.currentUser?.currentFamilyId,
                let messageId = message.id else { return }

          let newPinStatus = !message.isPinned

          // Optimistic update — no Firestore re-fetch needed
          if let idx = messages.firstIndex(where: { $0.id == messageId }) {
              messages[idx].isPinned = newPinStatus
          }
          if newPinStatus {
              if !pinnedMessages.contains(where: { $0.id == messageId }) {
                  var pinned = message; pinned.isPinned = true
                  pinnedMessages.append(pinned)
              }
          } else {
              pinnedMessages.removeAll { $0.id == messageId }
          }

          messageService.togglePin(familyId: familyId, messageId: messageId, isPinned: newPinStatus) { [weak self] result in
              if case .failure = result {
                  // Revert on failure
                  if let idx = self?.messages.firstIndex(where: { $0.id == messageId }) {
                      self?.messages[idx].isPinned = !newPinStatus
                  }
                  if newPinStatus {
                      self?.pinnedMessages.removeAll { $0.id == messageId }
                  } else if !(self?.pinnedMessages.contains(where: { $0.id == messageId }) ?? false) {
                      var reverted = message; reverted.isPinned = true
                      self?.pinnedMessages.append(reverted)
                  }
              }
          }
      }
      var isCurrentUserAdmin: Bool {
          guard let uid = authService.currentUser?.id, let family else { return false }
          if let adminId = family.adminId { return adminId == uid }
          return family.members.min(by: { $0.joinedAt < $1.joinedAt })?.id == uid
      }

      func removeMember(_ member: Member) {
          guard isCurrentUserAdmin,
                let familyId = authService.currentUser?.currentFamilyId else { return }
          familyService.removeMember(userId: member.id, familyId: familyId) { [weak self] _ in
              self?.loadFamily()
          }
      }

      func renameFamily(_ newName: String) {
          let trimmed = newName.trimmingCharacters(in: .whitespaces)
          guard isCurrentUserAdmin, !trimmed.isEmpty,
                let familyId = authService.currentUser?.currentFamilyId else { return }
          familyService.renameFamily(familyId: familyId, newName: trimmed) { [weak self] _ in
              self?.loadFamily()
          }
      }

      func transferAdmin(to member: Member) {
          guard isCurrentUserAdmin,
                let familyId = authService.currentUser?.currentFamilyId else { return }
          familyService.transferAdmin(familyId: familyId, newAdminId: member.id) { [weak self] _ in
              self?.loadFamily()
          }
      }

      func deleteMessage(_ message: HuddleMessage) {
          guard (isCurrentUserAdmin || message.senderID == authService.currentUser?.id),
                let familyId = authService.currentUser?.currentFamilyId,
                let messageId = message.id else { return }

          // Optimistic update — no Firestore re-fetch needed
          messages.removeAll { $0.id == messageId }
          pinnedMessages.removeAll { $0.id == messageId }

          messageService.deleteMessage(familyId: familyId, messageId: messageId) { [weak self] result in
              if case .failure = result {
                  // Revert on failure by reloading
                  self?.loadMessages()
                  self?.loadPinnedMessages()
              }
          }
      }               

      func leaveGroup() {
          guard let userId = authService.currentUser?.id,
                let familyId = authService.currentUser?.currentFamilyId,
                let displayName = authService.currentUser?.displayName else { return }

          let group = DispatchGroup()

          group.enter()
          messageService.sendSystemMessage(familyId: familyId, content: "\(displayName) left the group") { _ in
              group.leave()
          }

          group.enter()
          familyService.leaveFamily(userId: userId, familyId: familyId) { _ in
              group.leave()
          }

          group.notify(queue: .main) {
              // Keeps identity — no signOut(). removeFamily switches currentFamilyId or clears it.
              self.authService.removeFamily(familyId: familyId) { }
          }
      }

      func switchGroup(to familyId: String) {
          guard familyId != authService.currentUser?.currentFamilyId else { return }
          isLoading = true
          cleanup()
          authService.switchFamily(to: familyId) { [weak self] in
              self?.loadFamily()
              self?.loadMessages()
              self?.loadShoppingItems()
              self?.loadPinnedMessages()
          }
      }

      func loadAvailableFamilies() {
          let ids = authService.currentUser?.familyIds ?? []
          guard ids.count > 1 else { availableFamilies = []; return }
          availableFamilies = []
          var loaded: [Family] = []
          let group = DispatchGroup()
          for id in ids {
              group.enter()
              familyService.fetchFamily(familyId: id) { result in
                  if case .success(let f) = result { loaded.append(f) }
                  group.leave()
              }
          }
          group.notify(queue: .main) { self.availableFamilies = loaded }
      }

      func markMessagesAsRead() {
          UserDefaults.standard.set(Date(), forKey: "lastMessagesViewDate")
          unreadCount = 0
      }

      private func updateUnreadCount() {
          let lastRead = UserDefaults.standard.object(forKey: "lastMessagesViewDate") as? Date ?? .distantPast
          guard let uid = authService.currentUser?.id else { return }
          unreadCount = messages.filter {
              $0.senderID != uid && $0.type != .system && $0.createdAt > lastRead
          }.count
      }

      func setupEncryption(family: Family) {
          guard let uid = authService.currentUser?.id,
                let familyId = family.id else { return }

          // Decrypt group key from Firestore if not already in Keychain
          if EncryptionService.loadGroupKey(familyId: familyId) == nil,
             let encryptedForMe = family.encryptedGroupKeys[uid],
             let privateKey = try? EncryptionService.loadPrivateKey() {
              let candidateKeys = family.members.compactMap { $0.publicKey }
              if let groupKey = EncryptionService.decryptGroupKey(encryptedForMe, candidateSenderPublicKeys: candidateKeys, recipientPrivateKey: privateKey) {
                  try? EncryptionService.saveGroupKey(groupKey, familyId: familyId)
              }
          }

          // Distribute group key to any members who don't have it yet
          guard let groupKey = EncryptionService.loadGroupKey(familyId: familyId),
                let privateKey = try? EncryptionService.loadPrivateKey() else { return }

          for member in family.members {
              guard family.encryptedGroupKeys[member.id] == nil,
                    let memberPublicKey = member.publicKey,
                    let encrypted = try? EncryptionService.encryptGroupKey(groupKey, for: memberPublicKey, senderPrivateKey: privateKey) else { continue }
              db.collection("families").document(familyId)
                .updateData(["encryptedGroupKeys.\(member.id)": encrypted])
          }
      }

      func cleanup() {
          messageListener?.remove()
          shoppingListener?.remove()
      }
      private func saveWidgetPinnedMessages(_ messages: [HuddleMessage]) {
            let widgetMessages = messages.map { message in
                SharedDataManager.WidgetPinnedMessage(
                    text: message.content,
                    senderName: message.senderName ?? "Unknown"
                )
            }
            SharedDataManager.savePinnedMessages(widgetMessages)
        }
                                                                                                             
        private func saveWidgetShoppingItems(_ items: [HuddleMessage]) {
            let widgetItems = items.map { item in
                SharedDataManager.WidgetShoppingItem(text: item.content)
            }
            SharedDataManager.saveShoppingItems(widgetItems)
        }                             
  }
