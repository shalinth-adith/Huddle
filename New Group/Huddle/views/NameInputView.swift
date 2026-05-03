//
//  NameInputView.swift
//  Huddle
//

import SwiftUI
import PhotosUI

struct NameInputView: View {
    @State private var name: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var selectedColorIndex: Int = 0
    @State private var avatarFloat: CGFloat = 0
    @FocusState private var isNameFocused: Bool

    let onSubmit: (String, UIImage?) -> Void
    var onBack: (() -> Void)? = nil

    private let avatarColors: [LushColor] = [.coral, .rose, .amber, .plum]
    var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.6)
                .onTapGesture { isNameFocused = false }

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.huddleTextPrimary.opacity(0.8))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.huddleGlassFill))
                            .overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1))
                    }
                    .opacity(isLoading ? 0.4 : 1)
                    .disabled(isLoading)

                    Spacer()

                    Text("Step 1 of 3")
                        .font(.system(size: 12))
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Eyebrow + headline
                        VStack(alignment: .leading, spacing: 8) {
                            LushEyebrow(text: "Hello there")
                            Text("What should\nwe call you?")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color.huddleTextPrimary)
                                .tracking(-1.0)
                            Text("This is how your family will see you.")
                                .font(.system(size: 14))
                                .foregroundColor(Color.huddleTextPrimary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                        // Avatar with float animation
                        VStack(spacing: 14) {
                            ZStack {
                                // Breathing ring
                                Circle()
                                    .stroke(Color(hex: "FF8A66").opacity(0.20), lineWidth: 1)
                                    .frame(width: 132, height: 132)

                                if let img = profileImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 108, height: 108)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color(hex: "FFC8AA").opacity(0.3), lineWidth: 2))
                                } else {
                                    LushAvatar(
                                        letter: trimmedName.isEmpty ? "?" : String(trimmedName.prefix(1)),
                                        lushColor: avatarColors[selectedColorIndex],
                                        size: 108,
                                        glow: true
                                    )
                                }
                            }
                            .offset(y: avatarFloat)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { avatarFloat = -6 }
                            }

                            // Photo picker + color swatches
                            if profileImage == nil {
                                HStack(spacing: 10) {
                                    ForEach(0..<4) { i in
                                        Button(action: { withAnimation(.spring(response: 0.3)) { selectedColorIndex = i } }) {
                                            Circle()
                                                .fill(LinearGradient(colors: avatarColors[i].gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Circle().stroke(Color.white.opacity(selectedColorIndex == i ? 0.9 : 0), lineWidth: 2)
                                                )
                                                .scaleEffect(selectedColorIndex == i ? 1.15 : 1.0)
                                        }
                                    }
                                }
                            } else {
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Label("Change photo", systemImage: "camera.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "FF8A66"))
                                }
                            }
                        }
                        .padding(.bottom, 32)

                        // Name input + inline next button
                        HStack(spacing: 0) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "FF8A66").opacity(0.7))
                                    .padding(.leading, 16)
                            }

                            TextField("Your name…", text: $name)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.huddleTextPrimary)
                                .autocorrectionDisabled(true)
                                .focused($isNameFocused)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)

                            Button(action: {
                                guard !trimmedName.isEmpty else { return }
                                isNameFocused = false
                                isLoading = true
                                onSubmit(trimmedName, profileImage)
                            }) {
                                HStack(spacing: 5) {
                                    if isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8)
                                    } else {
                                        Text("Next")
                                            .font(.system(size: 14, weight: .semibold))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                }
                                .foregroundColor(trimmedName.isEmpty ? Color.huddleTextPrimary : .white)
                                .padding(.horizontal, 16)
                                .frame(height: 48)
                                .background {
                                    if trimmedName.isEmpty {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.huddleTextPrimary.opacity(0.1))
                                    } else {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "FFA078"), Color(hex: "D8512B")],
                                                startPoint: .top, endPoint: .bottom
                                            ))
                                    }
                                }
                            }
                            .disabled(trimmedName.isEmpty || isLoading)
                            .padding(.trailing, 4)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.huddleGlassFill)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.huddleOutlineVariant, lineWidth: 1))
                        )
                        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                        .padding(.horizontal, 24)

                        Text("Tip — short names work best.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                            .padding(.top, 10)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer().frame(height: 100)
                    }
                }
            }

            // Progress dots
            VStack {
                Spacer()
                HStack(spacing: 6) {
                    Capsule().fill(Color(hex: "FF8A66")).frame(width: 28, height: 4)
                    Capsule().fill(Color(hex: "FF8A66").opacity(0.25)).frame(width: 14, height: 4)
                    Capsule().fill(Color(hex: "FF8A66").opacity(0.25)).frame(width: 14, height: 4)
                }
                .padding(.bottom, 38)
            }
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .onChange(of: selectedItem) { newItem in
            Task.detached(priority: .userInitiated) {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let raw = UIImage(data: data) else { return }
                let thumb = await Task.detached(priority: .userInitiated) {
                    let maxDim: CGFloat = 300
                    let scale = min(maxDim / raw.size.width, maxDim / raw.size.height)
                    let newSize = CGSize(width: raw.size.width * scale, height: raw.size.height * scale)
                    return UIGraphicsImageRenderer(size: newSize).image { _ in raw.draw(in: CGRect(origin: .zero, size: newSize)) }
                }.value
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) { profileImage = thumb }
                }
            }
        }
    }
}

#Preview {
    NameInputView(onSubmit: { _, _ in })
}
