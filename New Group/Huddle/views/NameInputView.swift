//
//  NameInputView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI
import PhotosUI

struct NameInputView: View {
    @State private var name: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil

    let onSubmit: (String, UIImage?) -> Void
    var onBack: (() -> Void)? = nil

    var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()

            // Background accents — isolated so they never rebuild on keystroke
            ZStack {
                Circle()
                    .fill(Color.huddlePrimaryFixed.opacity(0.25))
                    .frame(width: 260, height: 260)
                    .offset(x: 140, y: -100)
                Circle()
                    .fill(Color.huddleSecondaryFixed.opacity(0.30))
                    .frame(width: 200, height: 200)
                    .offset(x: -120, y: 380)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Back button + progress dots
                    HStack {
                        Button(action: { onBack?() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.huddleTextSecondary)
                                .padding(10)
                                .background(Color.huddleCard)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                        .opacity(isLoading ? 0.4 : 1)
                        .disabled(isLoading)

                        Spacer()

                        HStack(spacing: 8) {
                            Capsule().fill(Color.huddleCoral).frame(width: 40, height: 6)
                            Capsule().fill(Color.huddleSecondaryFixed).frame(width: 40, height: 6)
                            Capsule().fill(Color.huddleSecondaryFixed).frame(width: 40, height: 6)
                        }

                        Spacer()

                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.top, 24)

                    // Main card
                    VStack(spacing: 24) {
                        // Avatar — tap to pick a photo
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(Color.huddleSurface)
                                    .frame(width: 96, height: 96)
                                    .overlay(
                                        Group {
                                            if let img = profileImage {
                                                Image(uiImage: img)
                                                    .resizable()
                                                    .scaledToFill()
                                            } else {
                                                Image(systemName: "person.circle")
                                                    .font(.system(size: 54))
                                                    .foregroundColor(Color.huddleOutlineVariant)
                                            }
                                        }
                                    )
                                    .clipShape(Circle())

                                if profileImage != nil {
                                    // Checkmark badge — replaces camera icon after photo selected
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 30, weight: .semibold))
                                        .foregroundStyle(.white, .green)
                                        .background(Color.huddleCard.clipShape(Circle()))
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Circle()
                                        .fill(Color.huddleCoral)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        )
                                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedItem) { newItem in
                            Task.detached(priority: .userInitiated) {
                                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                                      let raw = UIImage(data: data) else { return }
                                let thumb = await Task.detached(priority: .userInitiated) {
                                    let maxDim: CGFloat = 300
                                    let scale = min(maxDim / raw.size.width, maxDim / raw.size.height)
                                    let newSize = CGSize(width: raw.size.width * scale, height: raw.size.height * scale)
                                    return UIGraphicsImageRenderer(size: newSize).image { _ in
                                        raw.draw(in: CGRect(origin: .zero, size: newSize))
                                    }
                                }.value
                                await MainActor.run {
                                    withAnimation(.spring(response: 0.3)) {
                                        profileImage = thumb
                                    }
                                }
                            }
                        }

                        // Title
                        VStack(spacing: 12) {
                            Text("What is Your name?")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(Color.huddleTextPrimary)
                                .multilineTextAlignment(.center)
                                .tracking(-0.3)
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
                            onSubmit(trimmedName, profileImage)
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
                    .background(Color.huddleCard)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 4)

                    // Decorative shapes — extracted struct, never rebuilds on parent state changes
                    NameInputDecorativeShapes()
                        .drawingGroup()
                        .allowsHitTesting(false)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct NameInputDecorativeShapes: View {
    var body: some View {
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
    }
}

#Preview {
    NameInputView(onSubmit: { name, _ in print("Name submitted: \(name)") })
}
