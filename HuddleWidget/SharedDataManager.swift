//
//  SharedDataManager.swift
//  Huddle
//
//  Created by shalinth adithyan on 10/02/26.
//

import Foundation
                                                                                                       
struct SharedDataManager {
      // The App Group identifier
      static let appGroupID = "group.huddle.shared"
                                                                                                       
      // Get the shared UserDefaults
      static var sharedDefaults: UserDefaults? {
          // How would you get UserDefaults for an App Group?
          // Hint: UserDefaults has an initializer that takes a suiteName
      }
  }
