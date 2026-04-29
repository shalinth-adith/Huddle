//
//  HuddleMessage.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import Foundation
import FirebaseFirestore

enum MessageType: String, Codable {
    case text
    case photo
    case Shopping
    case system
}

struct HuddleMessage: Codable, Identifiable {
    @DocumentID var id: String?
    var familyID: String
    var senderID: String
    var senderName: String
    var type: MessageType
    var content : String
    var photoURL: String?
    var isPinned: Bool
    var isCompleted: Bool
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, familyID, senderID, senderName, type, content, photoURL, isPinned, isCompleted, createdAt
    }
}
