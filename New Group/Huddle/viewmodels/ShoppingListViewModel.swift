//
//  ShoppingList.swift
//  Huddle
//
//  Created by shalinth adithyan on 01/12/25.
//

import Foundation
  import Combine

  class ShoppingListViewModel: ObservableObject {
      @Published var shoppingItems: [HuddleMessage] = []
      @Published var isLoading = true
      @Published var errorMessage: String?

      private let messageService = MessageService()
      private let familyId: String

      init(familyId: String) {
          self.familyId = familyId
      }


      func loadItems() {
          isLoading = true
          errorMessage = nil

          messageService.fetchShoppingItems(familyId: familyId) { [weak self] result in
              DispatchQueue.main.async {
                  self?.isLoading = false

                  switch result {
                  case .success(let items):
                      self?.shoppingItems = items
                  case .failure(let error):
                      self?.errorMessage = error.localizedDescription
                  }
              }
          }
      }

      func addItem(content: String, senderId: String, senderName: String) {
          let trimmedContent = content.trimmingCharacters(in: .whitespaces)
          guard !trimmedContent.isEmpty else { return }

          messageService.addShoppingItem(
              familyId: familyId,
              content: trimmedContent,
              senderId: senderId,
              senderName: senderName
          ) { [weak self] result in
              DispatchQueue.main.async {
                  switch result {
                  case .success(let newItem):
                      self?.shoppingItems.append(newItem)
                  case .failure(let error):
                      self?.errorMessage = error.localizedDescription
                  }
              }
          }
      }

      func toggleComplete(item: HuddleMessage) {
          guard let itemId = item.id else { return }

          let newCompletionState = !item.isCompleted

          if let index = shoppingItems.firstIndex(where: { $0.id == itemId }) {
              shoppingItems[index].isCompleted = newCompletionState
          }

          messageService.toggleCompletion(
              familyId: familyId,
              messageId: itemId,
              isCompleted: newCompletionState
          ) { [weak self] result in
              DispatchQueue.main.async {
                  switch result {
                  case .success:
                      break
                  case .failure(let error):
                      if let index = self?.shoppingItems.firstIndex(where: { $0.id == itemId }) {
                          self?.shoppingItems[index].isCompleted = !newCompletionState
                      }
                      self?.errorMessage = error.localizedDescription
                  }
              }
          }
      }

      func deleteItem(item: HuddleMessage) {
          guard let itemId = item.id else { return }

          shoppingItems.removeAll { $0.id == itemId }

          messageService.deleteMessage(
              familyId: familyId,
              messageId: itemId
          ) { [weak self] result in
              DispatchQueue.main.async {
                  if case .failure(let error) = result {
                      self?.errorMessage = error.localizedDescription
                  }
              }
          }
      }
  }
