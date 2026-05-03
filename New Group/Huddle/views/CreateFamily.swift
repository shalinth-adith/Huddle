//
//  CreateFamily.swift
//  Huddle
//

import SwiftUI

struct CreateFamily: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: CreateFamilyViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedVibe = 0
    @State private var showCopiedToast = false
    @State private var cursorVisible = true
    @FocusState private var isFamilyNameFocused: Bool

    private let vibes: [(emoji: String, label: String)] = [
        ("🏡", "Cozy nest"), ("🏔️", "Adventure crew"), ("🌿", "Calm garden"), ("🎨", "Creative chaos")
    ]

    init(familyService: FamilyService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: CreateFamilyViewModel(
            familyService: familyService,
            authService: authService
        ))
    }

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.6)

            if viewModel.showSuccess {
                successView
            } else {
                inputView
            }

            if showCopiedToast {
                VStack {
                    Spacer()
                    Text("Code copied!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(24)
                        .padding(.bottom, 60)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                .zIndex(1)
                .animation(.easeInOut(duration: 0.2), value: showCopiedToast)
            }
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .onTapGesture { isFamilyNameFocused = false }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { cursorVisible = false }
        }
    }

    // MARK: - Input

    private var inputView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.7))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.huddleGlassFill))
                        .overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1))
                }
                Spacer()
                Text("Step 2 of 3")
                    .font(.system(size: 12))
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.5))
            }
            .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    LushEyebrow(text: "Your Huddle")
                    Spacer().frame(height: 8)
                    Text("Name your\nfamily.")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.huddleTextPrimary).tracking(-1.0)
                    Spacer().frame(height: 8)
                    Text("You can rename it later.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.6))

                    Spacer().frame(height: 24)

                    // Live preview card
                    GlassCard(padding: 18, isHero: true) {
                        HStack(spacing: 14) {
                            ClayIcon(systemImage: "heart.fill", lushColor: .rose, size: 52, glow: true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FAMILY NAME")
                                    .font(.system(size: 10, weight: .bold)).tracking(1.2)
                                    .foregroundColor(Color(hex: "FFB68A").opacity(0.85))
                                HStack(spacing: 0) {
                                    Text(viewModel.familyName.isEmpty ? "Your family name" : viewModel.familyName)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(viewModel.familyName.isEmpty ? Color.huddleTextPrimary.opacity(0.35) : Color.huddleTextPrimary)
                                        .tracking(-0.5)
                                    if !viewModel.familyName.isEmpty {
                                        Rectangle()
                                            .fill(Color(hex: "FF8A66"))
                                            .frame(width: 2, height: 20)
                                            .opacity(cursorVisible ? 1 : 0)
                                    }
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 20)

                    // Name input
                    HStack {
                        TextField("e.g. The Sharma's", text: $viewModel.familyName)
                            .font(.system(size: 16))
                            .foregroundColor(Color.huddleTextPrimary)
                            .autocorrectionDisabled(true)
                            .focused($isFamilyNameFocused)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.huddleGlassFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(viewModel.familyName.isEmpty ? Color.huddleBorder : Color(hex: "FF8A66").opacity(0.5), lineWidth: 1)
                            )
                    )

                    Spacer().frame(height: 24)

                    // Vibe selector
                    LushEyebrow(text: "Family Vibe")
                    Spacer().frame(height: 12)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(vibes.indices, id: \.self) { i in
                            let v = vibes[i]
                            Button(action: { withAnimation(.spring(response: 0.25)) { selectedVibe = i } }) {
                                HStack(spacing: 10) {
                                    Text(v.emoji).font(.system(size: 20))
                                    Text(v.label)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedVibe == i ? .white : Color.huddleTextPrimary.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14).padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedVibe == i
                                              ? LinearGradient(colors: [Color(hex: "FF8A66").opacity(0.22), Color(hex: "E85A7A").opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                              : LinearGradient(colors: [Color.huddleGlassFill], startPoint: .top, endPoint: .bottom))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedVibe == i ? Color(hex: "FF8A66").opacity(0.5) : Color.huddleBorder, lineWidth: 1)
                                        )
                                )
                                .shadow(color: selectedVibe == i ? Color(hex: "FF8A66").opacity(0.2) : .clear, radius: 10, x: 0, y: 4)
                            }
                        }
                    }

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 24)
            }
        }
        .overlay(
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    if let err = viewModel.errorMessage {
                        Text(err).font(.system(size: 13)).foregroundColor(Color(hex: "FF6B6B"))
                            .padding(.bottom, 8)
                    }
                    EmberButton(
                        label: "Create my family",
                        systemImage: "star.fill",
                        isLoading: viewModel.isLoading,
                        isDisabled: viewModel.familyName.trimmingCharacters(in: .whitespaces).isEmpty
                    ) { isFamilyNameFocused = false; viewModel.createFamily() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 38)
                .background(
                    LinearGradient(colors: [.clear, Color.huddleBackground.opacity(0.9), Color.huddleBackground], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                )
            }
        )
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(hex: "FF8A66").opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
            }
            VStack(spacing: 10) {
                Text("Your Huddle is ready!")
                    .font(.system(size: 26, weight: .bold)).foregroundColor(Color.huddleTextPrimary).tracking(-0.5)
                Text(viewModel.familyName)
                    .font(.system(size: 20, weight: .semibold)).foregroundColor(Color(hex: "FF8A66"))
                Text("Share your invite code with family members so they can join.")
                    .font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.65))
                    .multilineTextAlignment(.center).lineSpacing(3).padding(.horizontal, 16)
            }

            GlassCard(padding: 20) {
                VStack(spacing: 6) {
                    Text(viewModel.generatedCode)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "FF8A66")).tracking(6)
                    Text("family invite code")
                        .font(.system(size: 12)).foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 12) {
                Button(action: {
                    UIPasteboard.general.string = viewModel.generatedCode
                    withAnimation { showCopiedToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { showCopiedToast = false } }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc").font(.system(size: 13))
                        Text("Copy Code").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "FF8A66"))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.huddleGlassFill)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "FF8A66").opacity(0.3), lineWidth: 1)))
                }
                Button(action: { dismiss() }) {
                    Text("Continue")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom).cornerRadius(14))
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}

#Preview {
    let auth = AuthService()
    CreateFamily(familyService: FamilyService(), authService: auth)
        .environmentObject(auth)
}
