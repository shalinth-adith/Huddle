//
//  RootView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authService : AuthService
    @State private var showNameInput = false
    
    var body: some View {
        ZStack {
            if !authService.isAuthenticated {
                WelcomeView(onGetStarted:{
                    showNameInput = true
                    
                })
            }  else if authService.currentUser?.currentFamilyId == nil {
               
                CreateJoinFamily()
                    .environmentObject(authService)
            } else {
                FamilyFeedView()
                     .environmentObject(authService)
             }


            if showNameInput && !authService.isAuthenticated {
                             NameInputView(onSubmit: { name in
                                 handleSignIn(name: name)
                             })
                             .transition(.move(edge: .bottom))
                         }
                     }
                     .animation(.easeInOut, value: showNameInput)
                     .animation(.easeInOut, value: authService.isAuthenticated)
                 }

                 private func handleSignIn(name: String) {
                     authService.signInAnonymously(displayName: name) { result in
                         switch result {
                         case .success(let user):
                             print("✅ Signed in: \(user.displayName)")
                             showNameInput = false
                         case .failure(let error):
                             print("❌ Error: \(error.localizedDescription)")
                         }
                     }
                 }
             }


#Preview {
    RootView()
        .environmentObject(AuthService())

}
