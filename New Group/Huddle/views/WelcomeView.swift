//
//  WelcomeView.swift
//  Huddle
//

import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    @AppStorage("huddleColorScheme") private var colorSchemePreference: Int = 0

    @State private var heartScale: CGFloat = 1.0
    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring2Scale: CGFloat = 1.0
    @State private var card1Float: CGFloat = 0
    @State private var card2Float: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                AuroraBackground()

                // Floating chip — left
                GlassCard(padding: 10) {
                    HStack(spacing: 8) {
                        LushAvatar(letter: "M", lushColor: .rose, size: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Maya").font(.system(size: 10, weight: .semibold)).foregroundColor(.white)
                            Text("just home ✨").font(.system(size: 9)).foregroundColor(Color(hex: "F5E9E2").opacity(0.6))
                        }
                    }
                }
                .frame(width: 130)
                .rotationEffect(.degrees(-8))
                .position(x: 78, y: geo.size.height * 0.27 + card1Float)

                // Floating chip — right
                GlassCard(padding: 10) {
                    HStack(spacing: 8) {
                        ClayIcon(systemImage: "waveform.path.ecg", lushColor: .amber, size: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Heartbeats").font(.system(size: 10, weight: .semibold)).foregroundColor(.white)
                            Text("4 family").font(.system(size: 9)).foregroundColor(Color(hex: "F5E9E2").opacity(0.6))
                        }
                    }
                }
                .frame(width: 148)
                .rotationEffect(.degrees(6))
                .position(x: geo.size.width - 84, y: geo.size.height * 0.35 + card2Float)

                // Animated heart
                ZStack {
                    Circle()
                        .stroke(Color(hex: "FF8A66").opacity(0.22), lineWidth: 1)
                        .frame(width: 152, height: 152)
                        .scaleEffect(ring1Scale)
                    Circle()
                        .stroke(Color(hex: "FF8A66").opacity(0.15), lineWidth: 1)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ring2Scale)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFD2BD"), Color(hex: "FF8A66"), Color(hex: "D8512B")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "FF8A66").opacity(0.7), radius: 20)
                        .shadow(color: Color(hex: "FF8A66").opacity(0.35), radius: 40)
                        .scaleEffect(heartScale)
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.31)

                // Bottom gradient sheet
                VStack(spacing: 0) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 0) {
                        LushEyebrow(text: "The Family OS")
                        Spacer().frame(height: 10)
                        Text("Stay close,\neven when apart.")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(-1.2)
                            .lineSpacing(2)
                        Spacer().frame(height: 12)
                        Text("Live presence, plans and tiny moments — all in one warm, private place.")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "F5E9E2").opacity(0.65))
                            .lineSpacing(3)
                        Spacer().frame(height: 26)
                        EmberButton(label: "Sign In", action: onGetStarted)
                        Spacer().frame(height: 20)
                        Text("By continuing you agree to our Terms & Privacy Policy")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "F5E9E2").opacity(0.4))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 52)
                    .padding(.bottom, 48)
                    .background(
                        LinearGradient(
                            colors: [.clear, Color(hex: "0E0809").opacity(0.85), Color(hex: "0E0809")],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                }

                // Dark mode toggle (cosmetic — keeps user preference)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { colorSchemePreference = colorSchemePreference == 2 ? 1 : 2 }) {
                            Image(systemName: colorSchemePreference == 2 ? "sun.max.fill" : "moon.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "F5E9E2").opacity(0.5))
                                .padding(8)
                                .background(Color(hex: "281A16").opacity(0.6))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(hex: "FFC8AA").opacity(0.14), lineWidth: 1))
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 60)
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { heartScale = 1.12 }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { ring1Scale = 1.07 }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.5)) { ring2Scale = 1.07 }
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) { card1Float = -10 }
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) { card2Float = 8 }
        }
    }
}

#Preview {
    WelcomeView(onGetStarted: {})
}
