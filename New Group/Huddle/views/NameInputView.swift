//
//  NameInputView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI

struct NameInputView: View {
    @State private var name: String = ""
    @State private var isLoading: Bool = false

    let onSubmit: (String) -> Void

    var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()

            // Background blurred accents
            GeometryReader { geo in
                Circle()
                    .fill(Color.huddlePrimaryFixed.opacity(0.35))
                    .frame(width: 220, height: 220)
                    .blur(radius: 60)
                    .offset(x: geo.size.width - 80, y: -60)
                Circle()
                    .fill(Color.huddleSecondaryFixed.opacity(0.45))
                    .frame(width: 160, height: 160)
                    .blur(radius: 60)
                    .offset(x: -40, y: geo.size.height - 80)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Progress dots
                    HStack(spacing: 8) {
                        Capsule()
                            .fill(Color.huddleCoral)
                            .frame(width: 48, height: 6)
                        Capsule()
                            .fill(Color.huddleSecondaryFixed)
                            .frame(width: 48, height: 6)
                        Capsule()
                            .fill(Color.huddleSecondaryFixed)
                            .frame(width: 48, height: 6)
                    }
                    .padding(.top, 24)

                    // Main card
                    VStack(spacing: 24) {
                        // Avatar
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.huddleSurface)
                                .frame(width: 96, height: 96)
                                .overlay(
                                    Image(systemName: "person.circle")
                                        .font(.system(size: 54))
                                        .foregroundColor(Color.huddleOutlineVariant)
                                )
                            Circle()
                                .fill(Color.huddleCoral)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }

                        // Title + subtitle
                        VStack(spacing: 12) {
                            Text("What is Your name?")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(Color.huddleTextPrimary)
                                .multilineTextAlignment(.center)
                                .tracking(-0.3)

                            Text("This is how you will appear to your household and family members.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color.huddleTextTertiary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .frame(maxWidth: 270)
                        }

                        // Input field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.huddleTextSecondary)
                                .padding(.leading, 4)

                            HStack {
                                TextField("e.g. Alex Henderson", text: $name)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.huddleTextPrimary)
                                    .autocorrectionDisabled(true)
                                Image(systemName: "person")
                                    .foregroundColor(Color.huddleTextSecondary.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.huddleSurface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        trimmedName.isEmpty ? Color.clear : Color.huddleCoral,
                                        lineWidth: 2
                                    )
                            )
                        }

                        // Continue button
                        Button(action: {
                            guard !trimmedName.isEmpty else { return }
                            isLoading = true
                            onSubmit(trimmedName)
                        }) {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(trimmedName.isEmpty ? Color.huddleTextTertiary.opacity(0.4) : Color.huddleCoral)
                            .cornerRadius(8)
                        }
                        .disabled(trimmedName.isEmpty || isLoading)
                    }
                    .padding(28)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 4)

                    // Decorative shapes
                    HStack(spacing: 36) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.huddlePrimaryFixed)
                            .frame(width: 52, height: 52)
                            .rotationEffect(.degrees(12))
                        Circle()
                            .fill(Color.huddleSecondaryFixed)
                            .frame(width: 38, height: 38)
                            .offset(y: 10)
                        ZStack {
                            Circle()
                                .strokeBorder(
                                    Color.huddleOutlineVariant,
                                    style: StrokeStyle(lineWidth: 2, dash: [4])
                                )
                                .frame(width: 60, height: 60)
                            Circle()
                                .fill(Color.huddlePrimaryFixed.opacity(0.6))
                                .frame(width: 14, height: 14)
                        }
                    }
                    .opacity(0.2)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NameInputView(onSubmit: { name in print("Name submitted: \(name)") })
}
