//
//  JoinFamily.swift
//  Huddle
//

import SwiftUI

struct JoinFamily: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: JoinFamilyViewModel
    @FocusState private var isCodeFocused: Bool
    @State private var showHelp = false
    @State private var shakeOffset: CGFloat = 0

    init(familyService: FamilyService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: JoinFamilyViewModel(
            familyService: familyService,
            authService: authService
        ))
    }

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.5)

            if viewModel.showSuccess {
                successView
            } else {
                inputView
            }
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .onTapGesture { isCodeFocused = false }
        .onChange(of: viewModel.errorMessage) { error in
            guard error != nil else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.easeInOut(duration: 0.07).repeatCount(4, autoreverses: true)) { shakeOffset = 9 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { shakeOffset = 0 }
        }
        .alert("How to join", isPresented: $showHelp) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Ask the family admin for the 7-character code that looks like H-216962. Enter just the 6 numbers after the H- prefix.")
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
                Button(action: { showHelp = true }) {
                    Text("Help")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "FF8A66"))
                }
            }
            .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    LushEyebrow(text: "Got the code?")
                    Spacer().frame(height: 8)
                    Text("Enter your\ninvite code.")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color.huddleTextPrimary).tracking(-0.8)
                    Spacer().frame(height: 8)
                    Text("Six characters from a family member.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.6))

                    Spacer().frame(height: 32)

                    // Code input field (H- prefix)
                    HStack(spacing: 0) {
                        Text("H-")
                            .font(.system(size: 22, weight: .semibold)).tracking(4)
                            .foregroundColor(Color(hex: "FF8A66"))
                            .padding(.leading, 16)
                        TextField("000000", text: Binding(
                            get: { String(viewModel.familyCode.dropFirst(2)) },
                            set: { input in
                                let digits = input.filter { $0.isNumber }
                                viewModel.familyCode = "H-\(String(digits.prefix(6)))"
                                if digits.count >= 6 { isCodeFocused = false }
                            }
                        ))
                        .font(.system(size: 22, weight: .semibold)).tracking(4)
                        .keyboardType(.numberPad)
                        .focused($isCodeFocused)
                        .foregroundColor(Color.huddleTextPrimary)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.huddleGlassFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(viewModel.familyCode == "H-" ? Color.huddleBorder : Color(hex: "FF8A66").opacity(0.5), lineWidth: 1)
                            )
                    )
                    .shadow(color: viewModel.familyCode != "H-" ? Color(hex: "FF8A66").opacity(0.2) : .clear, radius: 10, x: 0, y: 0)
                    .offset(x: shakeOffset)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 13)).foregroundColor(Color(hex: "FF6B6B"))
                            .padding(.top, 8)
                    }

                    Spacer().frame(height: 20)

                    // Info hint
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16)).foregroundColor(Color(hex: "FF8A66"))
                        Text("Ask the family admin for the 7-character code that looks like H-216962.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.huddleTextPrimary.opacity(0.65)).lineSpacing(2)
                    }
                    .padding(14)
                    .background(Color(hex: "FF8A66").opacity(0.08))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "FF8A66").opacity(0.15), lineWidth: 1))

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 24)
            }
        }
        .overlay(
            VStack {
                Spacer()
                EmberButton(
                    label: "Join family",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isValidCode
                ) { isCodeFocused = false; viewModel.joinFamily() }
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
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle().fill(Color(hex: "FF8A66").opacity(0.12)).frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
            }
            VStack(spacing: 10) {
                Text("Joined Successfully!")
                    .font(.system(size: 26, weight: .bold)).foregroundColor(Color.huddleTextPrimary).tracking(-0.5)
                Text(viewModel.joinedFamilyName)
                    .font(.system(size: 20, weight: .semibold)).foregroundColor(Color(hex: "FF8A66"))
                Text("You're now part of the \(viewModel.joinedFamilyName) family. Say hello!")
                    .font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary.opacity(0.65))
                    .multilineTextAlignment(.center).lineSpacing(3).padding(.horizontal, 16)
            }
            Spacer()
            EmberButton(label: "Continue", action: { dismiss() })
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
    }
}

#Preview {
    JoinFamily(familyService: FamilyService(), authService: AuthService())
}
