//
//  RootView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI
                                                                                                       
  struct RootView: View {
      @EnvironmentObject var authService: AuthService
      @StateObject private var viewModel: RootViewModel
      @Binding var openToShopping: Bool
                                                                                                       
      init(authService: AuthService, openToShopping: Binding<Bool>) {
          _viewModel = StateObject(wrappedValue: RootViewModel(authService: authService))
          _openToShopping = openToShopping
      }
                                                                                                       
      var body: some View {
          ZStack {
              if !authService.isAuthenticated {
                  WelcomeView(onGetStarted: {
                      viewModel.showNameInput = true
                  })
              } else if authService.currentUser?.currentFamilyId == nil {
                  CreateJoinFamily()
                      .environmentObject(authService)
              } else {
                  FamilyFeedView(authService: authService, openToShopping: $openToShopping)
              }
                                                                                                       
              if viewModel.showNameInput && !authService.isAuthenticated {
                  NameInputView(onSubmit: { name in
                      viewModel.signIn(name: name)
                  })
                  .transition(.move(edge: .bottom))
              }
          }
          .animation(.easeInOut, value: viewModel.showNameInput)
          .animation(.easeInOut, value: authService.isAuthenticated)
      }
  }
                                                                                                       
  #Preview {
      let authService = AuthService()
      return RootView(authService: authService, openToShopping: .constant(false))
          .environmentObject(authService)
  }                    

