//
//  CreateJoinFamily.swift
//  Huddle
//
//  Created by shalinth adithyan on 26/11/25.
//

import SwiftUI

struct CreateJoinFamily: View {
    @EnvironmentObject var authService: AuthService
    @State private var showCreateFamily = false
    @State private var showJoinFamily = false
    @State private var showSignOutAlert = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.huddleBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroSection
                        cardsSection
                        privacyCard
                        trustRow
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 48)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showCreateFamily) {
            CreateFamily().environmentObject(authService)
        }
        .sheet(isPresented: $showJoinFamily) {
            JoinFamily(authService: authService).environmentObject(authService)
        }
        .alert("Sign Out?", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) { authService.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll be signed out and returned to the welcome screen.")
        }
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.huddleCoral)
                Text("Huddle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color.huddleCoral)
            }
            Spacer()
            Button(action: { showSignOutAlert = true }) {
                Text("Sign Out")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.huddleTextTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.huddleSecondaryFixed)
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.huddleBackground)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder),
            alignment: .bottom
        )
    }

    private var heroSection: some View {
        VStack(spacing: 10) {
            Text("Welcome to Your Huddle")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(Color.huddleTextPrimary)
                .multilineTextAlignment(.center)
                .tracking(-0.3)
            Text("The heart of your family's daily life.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color.huddleTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.top, 4)
    }

    private var cardsSection: some View {
        VStack(spacing: 14) {
            // Create Family
            Button(action: { showCreateFamily = true }) {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.huddlePrimaryFixed)
                            .frame(width: 56, height: 56)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(Color.huddleCoral)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create Family")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.huddleTextPrimary)
                        Text("Start a new private space for your household. Invite members .")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.huddleTextSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 4) {
                            Text("Get Started")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color.huddleCoral)
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(20)
                .background(Color.huddleCard)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            }

            // Join Family
            Button(action: { showJoinFamily = true }) {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.huddleSecondaryFixed)
                            .frame(width: 56, height: 56)
                        Image(systemName: "key.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.huddleTextSecondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Join Family")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.huddleTextPrimary)
                        Text("Enter your unique invitation code to jump right into the conversation.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.huddleTextSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 4) {
                            Text("Enter Code")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color.huddleCoral)
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(20)
                .background(Color.huddleCard)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            }
        }
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.huddlePrimaryFixed.opacity(0.6))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.huddleCoral)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("SECURE & PRIVATE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.huddleCoral)
                    .kerning(0.5)
                Text("Your safe space for sharing")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                Text("Huddle uses end-to-end encryption for your chats and documents.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.huddleTextSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.huddleCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private var trustRow: some View {
        HStack(spacing: 40) {
            Label("Encrypted", systemImage: "lock.fill")
                .frame(maxWidth: .infinity)
            Label("No Ads", systemImage: "hand.raised.slash")
                .frame(maxWidth: .infinity)
            Label("Auto-Sync", systemImage: "checkmark.icloud.fill")
                .frame(maxWidth: .infinity)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(Color.huddleTextSecondary.opacity(0.6))
    }
}

#Preview {
    CreateJoinFamily().environmentObject(AuthService())
}
