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
      private var familyListener: ListenerRegistration?

      @Published var shoppingItems: [HuddleMessage] = []
      private var shoppingListener: ListenerRegistration?

      @Published var pinnedMessages: [HuddleMessage] = []
      @Published var availableFamilies: [Family] = []
      // Ids of the user's OTHER groups (not the active one) that have unread messages.
      @Published var unreadGroupIds: Set<String> = []
      private var groupListeners: [ListenerRegistration] = []
      private var groupCache: [String: Family] = [:]

      private let familyService: FamilyService
      private let authService: AuthService
      private let messageService: MessageService

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

          // Live listener (not a one-time fetch) so the E2E key handshake
          // converges automatically: a new joiner is seen instantly and gets
          // the key distributed, and the joiner derives it the moment it lands.
          familyListener?.remove()
          familyListener = familyService.listenToFamily(familyId: familyId) { [weak self] result in
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
                  self.setupEncryption(family: fetchedFamily) { [weak self] in
                      // Key just arrived — re-decrypt anything already on screen.
                      self?.redecryptLoadedContent()
                  }
              case .failure:
                  self.isLoading = false
              }
          }
      }

      /// Re-runs decryption over already-loaded content. Called when the group
      /// key arrives after messages were first rendered as ciphertext.
      private func redecryptLoadedContent() {
          guard let familyId = authService.currentUser?.currentFamilyId else { return }
          let decryptedMessages = messageService.redecrypt(messages, familyId: familyId)
          let decryptedShopping = messageService.redecrypt(shoppingItems, familyId: familyId)
          let decryptedPinned = messageService.redecrypt(pinnedMessages, familyId: familyId)
          messages = decryptedMessages
          shoppingItems = decryptedShopping
          pinnedMessages = decryptedPinned
          saveWidgetShoppingItems(decryptedShopping)
          saveWidgetPinnedMessages(decryptedPinned)
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
                  SharedDataManager.savePings(Array(widgetPings), familyId: familyId)
              case .failure(_):
                  break
              }
          }
      }

      func loadShoppingItems() {
          guard let familyId = authService.currentUser?.currentFamilyId else {
              return
          }

          // Live listener so shopping changes on another device sync here.
          shoppingListener?.remove()
          shoppingListener = messageService.listenToShoppingItems(familyId: familyId) { [weak self] result in
              switch result {
              case .success(let items):
                    self?.shoppingItems = items
                    self?.saveWidgetShoppingItems(items)
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

      func sendPhoto(image: UIImage, caption: String) {
          guard let familyId = authService.currentUser?.currentFamilyId,
                let userId = authService.currentUser?.id,
                let userName = authService.currentUser?.displayName else { return }

          messageService.sendPhotoMessage(
              familyId: familyId,
              image: image,
              caption: caption,
              senderId: userId,
              senderName: userName
          ) { _ in
              // The Firestore listener delivers the authoritative message; the
              // sender's plaintext image is already warm in PhotoCache from upload.
          }
      }

      func loadPhoto(for message: HuddleMessage, completion: @escaping (UIImage?) -> Void) {
          guard let familyId = authService.currentUser?.currentFamilyId,
                let path = message.photoURL else { completion(nil); return }
          messageService.loadPhoto(familyId: familyId, path: path) { result in
              completion(try? result.get())
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

          messageService.togglePin(
              familyId: familyId,
              messageId: messageId,
              isPinned: newPinStatus,
              pinnedBy: authService.currentUser?.id,
              pinnedByName: authService.currentUser?.displayName
          ) { [weak self] result in
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

          // Photo messages also own a Storage blob — clean it up.
          if message.type == .photo, let path = message.photoURL {
              messageService.deletePhotoBlob(path: path)
          }

          messageService.deleteMessage(familyId: familyId, messageId: messageId) { [weak self] result in
              if case .failure = result {
                  // Revert on failure by reloading
                  self?.loadMessages()
                  self?.loadPinnedMessages()
              }
          }
      }               

      func leaveGroup(onComplete: (() -> Void)? = nil) {
          guard let userId = authService.currentUser?.id,
                let familyId = authService.currentUser?.currentFamilyId,
                let displayName = authService.currentUser?.displayName else { onComplete?(); return }

          let isLastMember = (family?.members.count ?? 0) <= 1

          // Drop this group's cached widget payload from the App Group.
          SharedDataManager.clearGroup(familyId)

          if isLastMember {
              // Last one out — delete the whole group from the backend so it
              // can't be re-joined by code: photos, messages, then the doc.
              messageService.deleteAllPhotos(familyId: familyId)
              familyService.deleteFamily(familyId: familyId) { [weak self] _ in
                  self?.authService.removeFamily(familyId: familyId) { onComplete?() }
              }
              return
          }

          // Otherwise just remove myself and announce it.
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
              self.authService.removeFamily(familyId: familyId) { onComplete?() }
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
              self?.listenToAllGroups()
          }
      }

      func loadAvailableFamilies() {
          // Kept for call sites; the live listener is the real source of truth.
          listenToAllGroups()
      }

      /// Attaches a live listener to every group the user belongs to, so the
      /// switcher list and per-group unread badges stay current in real time.
      func listenToAllGroups() {
          groupListeners.forEach { $0.remove() }
          groupListeners = []
          let ids = authService.currentUser?.familyIds ?? []
          for id in ids {
              let listener = familyService.listenToFamily(familyId: id) { [weak self] result in
                  guard let self, case .success(let fam) = result, let fid = fam.id else { return }
                  self.groupCache[fid] = fam
                  self.recomputeGroups()
              }
              groupListeners.append(listener)
          }
      }

      private func recomputeGroups() {
          let ids = authService.currentUser?.familyIds ?? []
          availableFamilies = ids.compactMap { groupCache[$0] }
          let current = authService.currentUser?.currentFamilyId
          unreadGroupIds = Set(
              availableFamilies
                  .filter { $0.id != current && isGroupUnread($0) }
                  .compactMap { $0.id }
          )
      }

      /// A group is unread if its newest message is newer than the last time
      /// this device opened that group's chat.
      func isGroupUnread(_ family: Family) -> Bool {
          GroupReadTracker.isUnread(family)
      }

      /// Re-attaches all per-group state after the active group changes
      /// (e.g. after creating or joining a new group from the switcher).
      func reloadActiveGroup() {
          isLoading = true
          messageListener?.remove()
          shoppingListener?.remove()
          familyListener?.remove()
          messages = []
          shoppingItems = []
          pinnedMessages = []
          loadFamily()
          loadMessages()
          loadShoppingItems()
          loadPinnedMessages()
          listenToAllGroups()
      }

      func markMessagesAsRead() {
          unreadCount = 0
          guard let fid = authService.currentUser?.currentFamilyId else { return }
          GroupReadTracker.markRead(fid)
          // Active group can't be "unread"; refresh other groups' badges.
          recomputeGroups()
      }

      private func updateUnreadCount() {
          guard let uid = authService.currentUser?.id,
                let fid = authService.currentUser?.currentFamilyId else { return }
          let lastRead = GroupReadTracker.lastRead(fid)
          unreadCount = messages.filter {
              $0.senderID != uid && $0.type != .system && $0.createdAt > lastRead
          }.count
      }

      func toggleReaction(message: HuddleMessage, emoji: String) {
          guard let familyId = authService.currentUser?.currentFamilyId,
                let messageId = message.id,
                let userId = authService.currentUser?.id else { return }

          let alreadyReacted = message.reactions?[emoji]?.contains(userId) ?? false

          // Optimistic update
          if let idx = messages.firstIndex(where: { $0.id == messageId }) {
              var reactions = messages[idx].reactions ?? [:]
              var users = reactions[emoji] ?? []
              if alreadyReacted { users.removeAll { $0 == userId } } else { users.append(userId) }
              reactions[emoji] = users.isEmpty ? nil : users
              messages[idx].reactions = reactions.isEmpty ? nil : reactions
          }

          messageService.toggleReaction(familyId: familyId, messageId: messageId, emoji: emoji, userId: userId, add: !alreadyReacted) { _ in }
      }

      func setupEncryption(family: Family, onKeyReady: (() -> Void)? = nil) {
          guard let familyId = family.id else { return }
          // Sync this device to the family's single canonical key (members-only in
          // Firestore). This is what guarantees every member reads every message —
          // no per-device key divergence. Replaces the old ECDH handshake.
          familyService.ensureGroupKey(familyId: familyId) { [weak self] in
              DispatchQueue.main.async {
                  self?.redecryptLoadedContent()
                  onKeyReady?()
              }
          }
      }

      func cleanup() {
          messageListener?.remove()
          shoppingListener?.remove()
          familyListener?.remove()
          groupListeners.forEach { $0.remove() }
          groupListeners = []
      }
      private func saveWidgetPinnedMessages(_ messages: [HuddleMessage]) {
            guard let familyId = authService.currentUser?.currentFamilyId else { return }
            let widgetMessages = messages.map { message -> SharedDataManager.WidgetPinnedMessage in
                let text = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                let display = text.isEmpty && message.type == .photo ? "📷 Photo" : message.content
                return SharedDataManager.WidgetPinnedMessage(
                    text: display,
                    senderName: message.senderName ?? "Unknown"
                )
            }
            SharedDataManager.savePinnedMessages(widgetMessages, familyId: familyId)
        }

        private func saveWidgetShoppingItems(_ items: [HuddleMessage]) {
            guard let familyId = authService.currentUser?.currentFamilyId else { return }
            let widgetItems = items.map { item in
                SharedDataManager.WidgetShoppingItem(text: item.content)
            }
            SharedDataManager.saveShoppingItems(widgetItems, familyId: familyId)
        }
  }
