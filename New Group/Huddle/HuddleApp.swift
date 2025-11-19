//
//  HuddleApp.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI
 import FirebaseCore
 import FirebaseAuth

 @main
 struct HuddleApp: App {

     @StateObject private var authService = AuthService()

     init() {
         FirebaseApp.configure()
     }

     var body: some Scene {
         WindowGroup {
             ContentView()
                 .environmentObject(authService)
         }
     }
 }

