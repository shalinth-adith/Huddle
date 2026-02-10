//
//  SharedDataManager.swift
//  Huddle
//
//  Created by shalinth adithyan on 10/02/26.
//


import Foundation
import WidgetKit

  
struct SharedDataManager {
    static let appGroupID = "group.huddle.shared"
  
    private static let pinnedMessagesKey = "pinnedMessages"
    private static let shoppingItemsKey = "shoppingItems"
      
    static var sharedDefaults: UserDefaults? {
    return UserDefaults(suiteName: appGroupID)
}
  
  
struct WidgetPinnedMessage: Codable {
    let text: String
    let senderName: String
}
  
struct WidgetShoppingItem: Codable {
    let text: String
}
static func reloadWidget() {
          WidgetCenter.shared.reloadAllTimelines()
      }
  
  
static func savePinnedMessages(_ messages: [WidgetPinnedMessage]) {
          do {
              let data = try JSONEncoder().encode(messages)
              sharedDefaults?.set(data, forKey: pinnedMessagesKey)
              reloadWidget()
          } catch {
              // Silently fail
          }
      }
  
static func saveShoppingItems(_ items: [WidgetShoppingItem]) {
          do {
              let data = try JSONEncoder().encode(items)
              sharedDefaults?.set(data, forKey: shoppingItemsKey)
              reloadWidget()
          } catch {
              // Silently fail
          }
      }
  
  
static func loadPinnedMessages() -> [WidgetPinnedMessage] {
        guard let data = sharedDefaults?.data(forKey: pinnedMessagesKey) else {
                return []
        }
  
        do {
            return try JSONDecoder().decode([WidgetPinnedMessage].self, from: data)
            } catch {
                return []
                }
            }
  
static func loadShoppingItems() -> [WidgetShoppingItem] {
        guard let data = sharedDefaults?.data(forKey: shoppingItemsKey) else {
                return []
        }
  
        do {
                return try JSONDecoder().decode([WidgetShoppingItem].self, from: data)
            } catch {
                    return []
                }
            }
    }

