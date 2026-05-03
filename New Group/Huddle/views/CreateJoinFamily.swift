//
//  CreateJoinFamily.swift
//  Huddle
//

import SwiftUI

struct CreateJoinFamily: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var showCreateFamily = false
    @State private var showJoinFamily = false
    @State private var showSignOutAlert = false
    @State private var floatAvatars = false

    private let floatColors: [LushColor] = [.rose, .amber, .coral]

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Sign out
                    HStack {
                        Spacer()
                        Button(action: { showSignOutAlert = true }) {
                            Text("Sign Out")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(Color.huddleGlassFill)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.huddleBorder, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 60)

                    // Avatar with pulse ring
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "FF8A66").opacity(0.18), lineWidth: 1)
                            .frame(width: 92, height: 92)
                            .scaleEffect(floatAvatars ? 1.06 : 1.0)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatAvatars)
                        LushAvatar(
                            letter: String(authService.currentUser?.displayName.prefix(1) ?? "Y"),
                            lushColor: .coral,
                            size: 72,
                            glow: true,
                            photoBase64: authService.currentUser?.photoBase64
                        )
                    }
                    .padding(.top, 28).padding(.bottom, 18)

                    let firstName = authService.currentUser?.displayName.components(separatedBy: " ").first ?? "there"
                    Text("Welcome, \(firstName)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color.huddleTextPrimary)
                        .tracking(-0.8)
                    Spacer().frame(height: 8)
                    Text("Let's gather your people.")
                        .font(.system(size: 15))
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.62))
                    Spacer().frame(height: 34)

                    // Create family hero card
                    Button(action: { showCreateFamily = true }) {
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: 26)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF8A66"), Color(hex: "E85A7A"), Color(hex: "6B2B3D")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                            Circle()
                                .fill(Color.white.opacity(0.28))
                                .frame(width: 140, height: 140)
                                .blur(radius: 30)
                                .offset(x: 50, y: -50)

                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Spacer()
                                    HStack(spacing: -8) {
                                        ForEach(Array(floatColors.enumerated()), id: \.offset) { i, c in
                                            LushAvatar(letter: ["A","J","M"][i], lushColor: c, size: 30)
                                                .offset(y: floatAvatars ? CGFloat([-3,2,-4][i]) : 0)
                                                .animation(.easeInOut(duration: 2.0 + Double(i) * 0.3).repeatForever(autoreverses: true).delay(Double(i) * 0.2), value: floatAvatars)
                                        }
                                    }
                                }
                                .padding(.bottom, 14)
                                ClayIcon(systemImage: "star.fill", lushColor: .amber, size: 48)
                                Spacer().frame(height: 12)
                                Text("RECOMMENDED")
                                    .font(.system(size: 10, weight: .bold)).tracking(1.4)
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer().frame(height: 4)
                                Text("Start a new family")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white).tracking(-0.5)
                                Spacer().frame(height: 4)
                                Text("You'll get an invite code to share.")
                                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.78))
                            }
                            .padding(22)

                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 36, height: 36)
                                .overlay(Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.white))
                                .padding(16)
                        }
                        .frame(height: 192)
                        .shadow(color: Color(hex: "D8512B").opacity(0.4), radius: 20, x: 0, y: 10)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 14)

                    Button(action: { showJoinFamily = true }) {
                        GlassCard(padding: 20) {
                            HStack(spacing: 14) {
                                ClayIcon(systemImage: "key.fill", lushColor: .plum, size: 48)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("I have a code")
                                        .font(.system(size: 17, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                                    Text("Join an existing family")
                                        .font(.system(size: 13)).foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 30)
                    Text("🔒  End-to-end encrypted · Private to your family")
                        .font(.system(size: 11))
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.40))
                    Spacer().frame(height: 48)
                }
            }
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .onAppear { floatAvatars = true }
        .sheet(isPresented: $showCreateFamily) {
            CreateFamily(familyService: serviceContainer.familyService, authService: authService)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showJoinFamily) {
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
}

#Preview {
    CreateJoinFamily()
        .environmentObject(AuthService())
        .environmentObject(ServiceContainer())
}
