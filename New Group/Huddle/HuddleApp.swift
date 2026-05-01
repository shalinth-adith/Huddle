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
    @AppStorage("huddleColorScheme") private var colorSchemePreference: Int = 0

    init() {
        FirebaseApp.configure()
    }

    private var preferredScheme: ColorScheme? {
        switch colorSchemePreference {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

     var body: some Scene {
         WindowGroup {
             RootView(authService: authService, openToShopping: $openToShopping)
                 .environmentObject(authService)
                 .onOpenURL { url in
                     handleDeepLink(url)
                 }
                 .preferredColorScheme(preferredScheme)
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
