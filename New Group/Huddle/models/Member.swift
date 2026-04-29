//
//  Member.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import Foundation
  import FirebaseFirestore

  struct Member: Codable, Identifiable {
      var id: String
      var displayName: String
      var photoBase64: String?
      var joinedAt: Date

      enum CodingKeys: String, CodingKey {
          case id, displayName, photoBase64, joinedAt
      }
  }

