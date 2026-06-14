//
//  FamilyEvent.swift
//  Huddle
//
//  A shared family calendar event. `title`/`notes` are E2E-encrypted at rest
//  with the family group key (like message content); `startAt`/`endAt` stay
//  plaintext so Firestore can sort and query by time.
//

import Foundation
import FirebaseFirestore

enum RSVPStatus: String, Codable, CaseIterable {
    case going, maybe, no

    var label: String {
        switch self {
        case .going: return "Going"
        case .maybe: return "Maybe"
        case .no:    return "Can't"
        }
    }
    var emoji: String {
        switch self {
        case .going: return "✅"
        case .maybe: return "🤔"
        case .no:    return "❌"
        }
    }
}

struct FamilyEvent: Codable, Identifiable {
    @DocumentID var id: String?
    var familyID: String
    var title: String          // E2E encrypted at rest
    var notes: String?         // E2E encrypted at rest
    var startAt: Date
    var endAt: Date?
    var isAllDay: Bool
    var createdBy: String
    var createdByName: String
    var createdAt: Date
    var rsvps: [String: String]?   // userId -> RSVPStatus.rawValue

    enum CodingKeys: String, CodingKey {
        case id, familyID, title, notes, startAt, endAt, isAllDay, createdBy, createdByName, createdAt, rsvps
    }

    func rsvp(for userId: String) -> RSVPStatus? {
        rsvps?[userId].flatMap { RSVPStatus(rawValue: $0) }
    }

    func attendeeIds(status: RSVPStatus) -> [String] {
        (rsvps ?? [:]).compactMap { $0.value == status.rawValue ? $0.key : nil }
    }
}
