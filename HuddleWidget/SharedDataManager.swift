//
//  SharedDataManager.swift
//  Huddle
//
//  Bridges the app and the widget via the shared App Group. Data is stored
//  PER GROUP (keyed by familyId) so a configurable widget can show whichever
//  group the user picked. A separate "groups index" lists every group the
//  user belongs to, which powers the widget's group picker.
//

import Foundation
import WidgetKit

struct SharedDataManager {
    static let appGroupID = "group.huddle.shared"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Models

    struct WidgetGroup: Codable, Identifiable, Hashable {
        let id: String
        let name: String
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

    // MARK: - Groups index (powers the widget's group picker + titles)

    private static let groupsKey = "widgetGroups"

    static func saveGroups(_ groups: [WidgetGroup]) {
        guard let data = try? JSONEncoder().encode(groups) else { return }
        sharedDefaults?.set(data, forKey: groupsKey)
        reloadWidget()
    }

    static func loadGroups() -> [WidgetGroup] {
        guard let data = sharedDefaults?.data(forKey: groupsKey) else { return [] }
        return (try? JSONDecoder().decode([WidgetGroup].self, from: data)) ?? []
    }

    static func groupName(_ familyId: String) -> String? {
        loadGroups().first { $0.id == familyId }?.name
    }

    // MARK: - Per-group payloads

    private static func pinnedKey(_ fid: String) -> String { "pinned_\(fid)" }
    private static func shoppingKey(_ fid: String) -> String { "shopping_\(fid)" }
    private static func pingsKey(_ fid: String) -> String { "pings_\(fid)" }

    static func savePinnedMessages(_ messages: [WidgetPinnedMessage], familyId: String) {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        sharedDefaults?.set(data, forKey: pinnedKey(familyId))
        reloadWidget()
    }

    static func loadPinnedMessages(familyId: String) -> [WidgetPinnedMessage] {
        guard let data = sharedDefaults?.data(forKey: pinnedKey(familyId)) else { return [] }
        return (try? JSONDecoder().decode([WidgetPinnedMessage].self, from: data)) ?? []
    }

    static func saveShoppingItems(_ items: [WidgetShoppingItem], familyId: String) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        sharedDefaults?.set(data, forKey: shoppingKey(familyId))
        reloadWidget()
    }

    static func loadShoppingItems(familyId: String) -> [WidgetShoppingItem] {
        guard let data = sharedDefaults?.data(forKey: shoppingKey(familyId)) else { return [] }
        return (try? JSONDecoder().decode([WidgetShoppingItem].self, from: data)) ?? []
    }

    static func savePings(_ pings: [WidgetPing], familyId: String) {
        guard let data = try? JSONEncoder().encode(pings) else { return }
        sharedDefaults?.set(data, forKey: pingsKey(familyId))
        reloadWidget()
    }

    static func loadPings(familyId: String) -> [WidgetPing] {
        guard let data = sharedDefaults?.data(forKey: pingsKey(familyId)) else { return [] }
        return (try? JSONDecoder().decode([WidgetPing].self, from: data)) ?? []
    }

    static func latestActivePing(familyId: String) -> WidgetPing? {
        guard let ping = loadPings(familyId: familyId).first else { return nil }
        return Date().timeIntervalSince(ping.sentAt) < 86400 ? ping : nil
    }

    /// Removes a group's widget payload when the user leaves/it's deleted.
    static func clearGroup(_ familyId: String) {
        sharedDefaults?.removeObject(forKey: pinnedKey(familyId))
        sharedDefaults?.removeObject(forKey: shoppingKey(familyId))
        sharedDefaults?.removeObject(forKey: pingsKey(familyId))
        reloadWidget()
    }
}
