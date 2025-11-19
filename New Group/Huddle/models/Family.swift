//
//  Family.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import Foundation
import FirebaseFirestore

struct family: Codable , Identifiable {
    @DocumentID var id: String?
    var name : String
    var code : String
    var createdAt : Date?
    var memberId : [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, code, createdAt, memberId
    }
}
