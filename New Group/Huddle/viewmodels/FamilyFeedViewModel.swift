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
      private var messageListener: ListenerRegistration?

      @Published var shoppingItems: [HuddleMessage] = []
      private var shoppingListener: ListenerRegistration?

      @Published var pinnedMessages: [HuddleMessage] = []

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

          messageService.deleteMessage(
              familyId: familyId,
              messageId: itemId
          ) { result in
              switch result {
              case .success:
                  self.loadShoppingItems()
              case .failure(_):
                  break
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
          guard let familyId = authService.currentUser?.currentFamilyId else {
              return
          }

          guard let messageId = message.id else {
              return
          }

          let newPinStatus = !message.isPinned

          messageService.togglePin(
              familyId: familyId,
              messageId: messageId,
              isPinned: newPinStatus
          ) { result in
              switch result {
              case .success:
                  self.loadMessages()
                  self.loadPinnedMessages()
              case .failure(_):
                  break
              }
          }
      }
      func deleteMessage(_ message: HuddleMessage) {
            guard let familyId = authService.currentUser?.currentFamilyId,
                  let messageId = message.id else { return }
                                                                                                             
            messageService.deleteMessage(
                familyId: familyId,
                messageId: messageId
            ) { result in
                switch result {
                case .success:
                    self.loadMessages()
                    self.loadPinnedMessages()
                case .failure(_):
                    break
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

          group.enter()
          authService.clearFamilyId {
              group.leave()
          }

          group.notify(queue: .main) {
              self.authService.signOut()
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
