//
//  WelcomeView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.huddleBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                ScrollView(showsIndicators: false) {
                    heroSection
                }
            }
        }
        .preferredColorScheme(.light)
        .buttonStyle(.plain)
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
            Button(action: onGetStarted) {
                Text("Join Free")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.huddleCoral)
                    .cornerRadius(8)
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
        VStack(spacing: 24) {
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
            VStack(spacing: 0) {
                Text("Your family in")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                Text("one place")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(Color.huddleCoral)
            }
            .multilineTextAlignment(.center)

            // Body
            Text(" Huddle brings everyone together, effortlessly.")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color.huddleTextTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // CTA buttons
            VStack(spacing: 12) {
                Button(action: onGetStarted) {
                    HStack(spacing: 8) {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.huddleCoral)
                    .cornerRadius(12)
                    .shadow(color: Color.huddleCoral.opacity(0.3), radius: 8, x: 0, y: 4)
                }

                Button(action: onGetStarted) {
                    Text("Sign In")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.huddleBorder, lineWidth: 2)
                        )
                }
            }

            // Social proof
            HStack(spacing: 12) {
                HStack(spacing: -10) {
                    Circle()
                        .fill(Color.huddleCoral.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    Circle()
                        .fill(Color.huddleSecondaryFixed)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    Circle()
                        .fill(Color.huddlePrimaryFixed)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                (Text(" ")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.huddleTextPrimary)
                + Text("Families Huddling together")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.huddleTextTertiary))
            }
            .padding(.top, 4)

        }
        .padding(.horizontal, 24)
        .padding(.top, 36)
        .padding(.bottom, 48)
    }
}

#Preview {
    WelcomeView(onGetStarted: { print("Get started tapped!") })
}
