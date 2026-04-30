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
    private static let pingsKey = "pings"
      
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

struct WidgetPing: Codable {
    let content: String
    let senderName: String
    let sentAt: Date
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
  
static func savePings(_ pings: [WidgetPing]) {
    do {
        let data = try JSONEncoder().encode(pings)
        sharedDefaults?.set(data, forKey: pingsKey)
        reloadWidget()
    } catch {}
}

static func loadPings() -> [WidgetPing] {
    guard let data = sharedDefaults?.data(forKey: pingsKey) else { return [] }
    return (try? JSONDecoder().decode([WidgetPing].self, from: data)) ?? []
}

static func latestActivePing() -> WidgetPing? {
    guard let ping = loadPings().first else { return nil }
    return Date().timeIntervalSince(ping.sentAt) < 86400 ? ping : nil
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

