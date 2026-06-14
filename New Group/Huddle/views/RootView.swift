//
//  RootView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: RootViewModel
    @Binding var openToShopping: Bool

    // nil = showing the Groups hub; non-nil = inside that group's feed.
    @State private var selectedGroupId: String?

    init(authService: AuthService, openToShopping: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: RootViewModel(authService: authService))
        _openToShopping = openToShopping
    }

    private var hasGroups: Bool {
        !(authService.currentUser?.familyIds.isEmpty ?? true)
    }

    var body: some View {
        ZStack {
            if authService.isCheckingAuth {
                loadingScreen
            } else if !authService.isAuthenticated {
                WelcomeView(onGetStarted: { viewModel.showNameInput = true })
            } else if authService.currentUser == nil {
                loadingScreen   // authenticated, profile still loading
            } else if !hasGroups {
                CreateJoinFamily()
                    .environmentObject(authService)
            } else if let groupId = selectedGroupId {
                FamilyFeedView(
                    familyService: serviceContainer.familyService,
                    messageService: serviceContainer.messageService,
                    eventService: serviceContainer.eventService,
                    capsuleService: serviceContainer.capsuleService,
                    authService: authService,
                    openToShopping: $openToShopping,
                    onBack: { selectedGroupId = nil }
                )
                .id(groupId)   // rebuild the feed when the active group changes
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                GroupsHomeView(
                    authService: authService,
                    serviceContainer: serviceContainer,
                    onSelect: { id in selectGroup(id) }
                )
                .transition(.opacity)
            }

            if viewModel.showNameInput && !authService.isAuthenticated {
                NameInputView(
                    onSubmit: { name, image in viewModel.signIn(name: name, image: image) },
                    onBack: { viewModel.showNameInput = false }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: viewModel.showNameInput)
        .animation(.easeInOut, value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: selectedGroupId)
        .onReceive(NotificationCenter.default.publisher(for: .openFamilyRequested)) { note in
            routeToGroup(note.object as? String)
        }
        .onAppear {
            // Cold start from a notification / widget tap.
            routeToGroup(AppDelegate.pendingFamilyId)
        }
        .onChange(of: authService.currentUser?.id) { _ in
            // Profile loaded after a cold-start deep link — apply the pending route.
            routeToGroup(AppDelegate.pendingFamilyId)
        }
    }

    private var loadingScreen: some View {
        Color.huddleBackground.ignoresSafeArea()
            .overlay(ProgressView().tint(Color.huddleCoral))
    }

    private func selectGroup(_ id: String) {
        authService.switchFamily(to: id) {
            selectedGroupId = id
        }
    }

    private func routeToGroup(_ familyId: String?) {
        AppDelegate.pendingFamilyId = nil
        guard let familyId,
              authService.currentUser?.familyIds.contains(familyId) == true else { return }
        selectGroup(familyId)
    }
}

#Preview {
    let authService = AuthService()
    return RootView(authService: authService, openToShopping: .constant(false))
        .environmentObject(authService)
        .environmentObject(ServiceContainer())
}
