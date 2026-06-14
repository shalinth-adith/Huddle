//
//  TimeCapsule.swift
//  Huddle
//
//  A message sealed until a future date. `message` is E2E-encrypted with the
//  family group key; `deliverAt` is plaintext so the app knows when to reveal.
//  Client-side reveal: the app simply hides the content until deliverAt passes.
//

import Foundation
import FirebaseFirestore

struct TimeCapsule: Codable, Identifiable {
    @DocumentID var id: String?
    var familyID: String
    var message: String        // E2E encrypted at rest (decrypted only once opened)
    var deliverAt: Date        // plaintext
    var createdBy: String
    var createdByName: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, familyID, message, deliverAt, createdBy, createdByName, createdAt
    }

    var isSealed: Bool { Date() < deliverAt }
}
