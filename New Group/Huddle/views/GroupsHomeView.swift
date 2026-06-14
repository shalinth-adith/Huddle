//
//  GroupsHomeView.swift
//  Huddle
//
//  The hub: lists every group the user belongs to. Tap a group to open its
//  feed; create or join more from the top-right menu. Replaces the old model
//  where the app dropped you straight into a single group.
//

import SwiftUI

struct GroupsHomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var serviceContainer: ServiceContainer
    let onSelect: (String) -> Void

    @StateObject private var vm: GroupsViewModel
    @State private var showCreate = false
    @State private var showJoin = false
    @State private var showSignOutAlert = false
    @State private var float = false

    init(authService: AuthService, serviceContainer: ServiceContainer, onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
        _vm = StateObject(wrappedValue: GroupsViewModel(
            familyService: serviceContainer.familyService,
            authService: authService
        ))
    }

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.38)

            VStack(spacing: 0) {
                header

                if vm.isLoading {
                    Spacer()
                    ProgressView().tint(Color.huddleCoral)
                    Spacer()
                } else if vm.groups.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(vm.groups) { group in
                                groupCard(group)
                            }
                            addCard
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { vm.start(); float = true }
        .onDisappear { vm.stop() }
        .sheet(isPresented: $showCreate, onDismiss: { vm.start() }) {
            CreateFamily(familyService: serviceContainer.familyService, authService: authService)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showJoin, onDismiss: { vm.start() }) {
            JoinFamily(familyService: serviceContainer.familyService, authService: authService)
                .environmentObject(authService)
        }
        .alert("Sign Out?", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) { authService.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll be signed out and returned to the welcome screen.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                LushEyebrow(text: "Your spaces")
                Text("Groups")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color.huddleTextPrimary)
                    .tracking(-0.8)
            }
            Spacer()
            Menu {
                Button { showCreate = true } label: { Label("Create a new group", systemImage: "plus.circle") }
                Button { showJoin = true } label: { Label("Join with a code", systemImage: "key.fill") }
                Divider()
                Button(role: .destructive) { showSignOutAlert = true } label: { Label("Sign Out", systemImage: "arrow.right.square") }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle().fill(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
                            .shadow(color: Color(hex: "D8512B").opacity(0.4), radius: 6, x: 0, y: 3)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 64)
        .padding(.bottom, 14)
    }

    // MARK: - Group card

    private func groupCard(_ group: Family) -> some View {
        let members = uniqueMembers(group)
        let isUnread = group.id.map { vm.unreadGroupIds.contains($0) } ?? false

        return Button { if let id = group.id { onSelect(id) } } label: {
            GlassCard(padding: 18) {
                HStack(spacing: 14) {
                    ClayIcon(systemImage: "house.fill", lushColor: .coral, size: 50)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Text(group.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.huddleTextPrimary)
                                .lineLimit(1)
                            if isUnread {
                                Circle().fill(Color(hex: "FF8A66")).frame(width: 8, height: 8)
                                    .shadow(color: Color(hex: "FF8A66").opacity(0.7), radius: 3)
                            }
                        }
                        HStack(spacing: -7) {
                            ForEach(members.prefix(4)) { m in
                                MemberAvatarView(name: m.displayName, photoBase64: m.photoBase64, size: 24)
                            }
                            Text("\(members.count) member\(members.count == 1 ? "" : "s")")
                                .font(.system(size: 12.5))
                                .foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                                .padding(.leading, 12)
                        }
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.4))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var addCard: some View {
        Menu {
            Button { showCreate = true } label: { Label("Create a new group", systemImage: "plus.circle") }
            Button { showJoin = true } label: { Label("Join with a code", systemImage: "key.fill") }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "FF8A66"))
                Text("Create or join a group")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.75))
                Spacer()
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.huddleGlassFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                            .foregroundColor(Color.huddleBorder)
                    )
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ClayIcon(systemImage: "person.2.fill", lushColor: .coral, size: 70)
            Text("No groups yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.huddleTextPrimary)
            Text("Create a family space or join one with a code.")
                .font(.system(size: 14))
                .foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                EmberButton(label: "Create a new group", action: { showCreate = true })
                Button(action: { showJoin = true }) {
                    Text("I have a code")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "FF8A66"))
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func uniqueMembers(_ group: Family) -> [Member] {
        group.members.reduce(into: [Member]()) { acc, m in
            if !acc.contains(where: { $0.id == m.id }) { acc.append(m) }
        }
    }
}
