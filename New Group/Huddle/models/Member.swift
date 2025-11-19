//
//  Member.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import Foundation
import FirebaseFirestore

struct Member: Identifiable , Codable {
    @DocumentID var id: String?
    var userID: String
    var DisplayName: String
    var familyID: String
    var joinedDate: Date
    var avatarColor: String
    
    enum CodingKeys: String, CodingKey {
        case id, userID, DisplayName, familyID, joinedDate, avatarColor
    }
}
