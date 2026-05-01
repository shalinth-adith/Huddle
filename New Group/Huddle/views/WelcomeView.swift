//
//  WelcomeView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    @AppStorage("huddleColorScheme") private var colorSchemePreference: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.huddleBackground.ignoresSafeArea()

            // Dark mode toggle — top trailing
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        colorSchemePreference = colorSchemePreference == 2 ? 1 : 2
                    }) {
                        Image(systemName: colorSchemePreference == 2 ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.huddleTextTertiary)
                            .padding(8)
                            .background(Color.huddleSecondaryFixed)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 60)
                Spacer()
            }

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    // ── Top content (centred in available space) ──
                    VStack(spacing: 70) {
                        // Tag pill
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                            Text("All-in-one family organizer")
                                .font(.system(size: 12, weight: .semibold))
                                .kerning(0.4)
                                .textCase(.uppercase)
                        }
                        .foregroundColor(Color.huddleCoral)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.huddleCoral.opacity(0.1))
                        .clipShape(Capsule())

                        // Headline
                        VStack(spacing: 2) {
                            Text("Your family in")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(Color.huddleTextPrimary)
                            Text("one place")
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundColor(Color.huddleCoral)
                        }
                        .multilineTextAlignment(.center)

                        // App brand mark
                        HStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color.huddleCoral)
                            Text("Huddle")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color.huddleCoral)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                    Spacer()

                    // ── Bottom: Sign In ──
                    VStack(spacing: 20) {
                        Button(action: onGetStarted) {
                            Text("Sign In")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.huddleCoral)
                                .cornerRadius(12)
                                .shadow(color: Color.huddleCoral.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WelcomeView(onGetStarted: { print("Get started tapped!") })
}
