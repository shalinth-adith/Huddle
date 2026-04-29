//
//  AppUser.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    var id: String?
    var PhoneNumber: String?
    var email: String?
    var displayName: String
    var photoBase64: String?
    var currentFamilyId: String?
    var familyIds: [String] = []
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, PhoneNumber, email, displayName, photoBase64, currentFamilyId, familyIds, createdAt
    }
}
 


