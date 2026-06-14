//
//  GroupReadTracker.swift
//  Huddle
//
//  Per-family "last read" tracking for unread badges. Stored locally (per
//  device) keyed by family id. A group is unread when its newest message
//  (Family.lastMessageAt) is newer than the last time this device opened it.
//

import Foundation

enum GroupReadTracker {
    private static func key(_ familyId: String) -> String { "huddle_lastRead_\(familyId)" }

    static func lastRead(_ familyId: String) -> Date {
        UserDefaults.standard.object(forKey: key(familyId)) as? Date ?? .distantPast
    }

    static func markRead(_ familyId: String) {
        UserDefaults.standard.set(Date(), forKey: key(familyId))
    }

    static func isUnread(_ family: Family) -> Bool {
        guard let fid = family.id, let last = family.lastMessageAt else { return false }
        return last > lastRead(fid)
    }
}
