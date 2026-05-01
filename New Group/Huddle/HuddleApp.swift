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

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService()
    @State private var openToShopping = false

    init() {
        FirebaseApp.configure()
    }
                                                                                                      
     var body: some Scene {
         WindowGroup {
             RootView(authService: authService, openToShopping: $openToShopping)
                 .environmentObject(authService)
                 .onOpenURL { url in
                     handleDeepLink(url)
                 }
         }
     }
                                                                                                      
     private func handleDeepLink(_ url: URL) {
         guard url.scheme == "huddle" else { return }
                                                                                                      
         switch url.host {
         case "shopping":
             openToShopping = true
         default:
             // Just open app (huddle://open)
             break
         }
     }
 }
