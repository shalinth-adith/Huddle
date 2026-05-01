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
    var adminId: String?
    var encryptedGroupKeys: [String: String] = [:]

    enum CodingKeys: String, CodingKey {
        case id, name, code, createdAt, members, adminId, encryptedGroupKeys
    }
}
