//
//  Family.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import Foundation
import FirebaseFirestore

struct Family: Codable , Identifiable {
    @DocumentID var id: String?
    var name : String
    var code : String
    var createdAt : Date?
    var members : [Member]
    // Flat copy of members[].id — Firestore security rules can't search an
    // array of maps, so membership checks key off this list instead
    var memberIds: [String]? = nil
    var adminId: String?
    var encryptedGroupKeys: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, name, code, createdAt, members, memberIds, adminId, encryptedGroupKeys
    }
}
