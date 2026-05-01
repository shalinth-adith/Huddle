//
//  CreateFamily.swift
//  Huddle
//
//  Created by shalinth adithyan on 27/11/25.
//

import SwiftUI

struct CreateFamily: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: CreateFamilyViewModel
    @Environment(\.dismiss) var dismiss

    init() {
        _viewModel = StateObject(wrappedValue: CreateFamilyViewModel(
            familyService: FamilyService(),
            authService: AuthService()
        ))
    }

    @State private var showCopiedToast = false

    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
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
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Huddle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color.huddleCoral)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.huddleTextTertiary)
                        .padding(8)
                        .background(Color.huddleSecondaryFixed)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.huddleBackground)
            .overlay(
                Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder),
                alignment: .bottom
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Heading
                    VStack(spacing: 8) {
                        Text("Create your Family")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(Color.huddleTextPrimary)
                            .multilineTextAlignment(.center)
                            .tracking(-0.5)
                        Text("Start your private digital huddle today.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.huddleTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)

                    // Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Family Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.huddleTextSecondary)
                            .padding(.leading, 4)

                        TextField("e.g. The Anderson Family", text: $viewModel.familyName)
                            .font(.system(size: 16))
                            .foregroundColor(Color.huddleTextPrimary)
                            .autocorrectionDisabled(true)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.huddleSurface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        viewModel.familyName.isEmpty ? Color.clear : Color.huddleCoral,
                                        lineWidth: 2
                                    )
                            )
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "BA1A1A"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                    }

                    // Privacy info box
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.huddleCoral)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privacy is our priority")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.huddleTextPrimary)
                            Text("Your family data is end-to-end encrypted. Only members you explicitly invite can see your content.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color.huddleTextTertiary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(16)
                    .background(Color.huddleCoral.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.huddleCoral.opacity(0.1), lineWidth: 1)
                    )

                    // Create button
                    Button(action: viewModel.createFamily) {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Family")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.isCreateButtonDisabled
                                ? Color.huddleTextTertiary.opacity(0.4)
                                : Color.huddleCoral
                        )
                        .cornerRadius(8)
                        .shadow(
                            color: viewModel.isCreateButtonDisabled ? .clear : Color.huddleCoral.opacity(0.3),
                            radius: 8, x: 0, y: 4
                        )
                    }
                    .disabled(viewModel.isCreateButtonDisabled)

                    Text("By creating a family, you agree to our Terms of Service and Privacy Policy.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.huddleTextTertiary)
                        .multilineTextAlignment(.center)

                    // Trust icons
                    HStack(spacing: 0) {
                        Label("Secure", systemImage: "lock.fill")
                            .frame(maxWidth: .infinity)
                        Label("Unlimited Members", systemImage: "person.2.fill")
                            .frame(maxWidth: .infinity)
                        Label("Cloud Sync", systemImage: "checkmark.icloud.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.huddleTextSecondary.opacity(0.6))
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Check icon
                ZStack {
                    Circle()
                        .fill(Color.huddleCoral.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.huddleCoral)
                }
                .padding(.top, 48)

                VStack(spacing: 12) {
                    Text("Success!")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary)
                    Text("Your Huddle family group has been created. Use the code below to invite your loved ones.")
                        .font(.system(size: 16))
                        .foregroundColor(Color.huddleTextTertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                // Family code card
                VStack(spacing: 8) {
                    Text("UNIQUE FAMILY CODE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.huddleTextTertiary)
                        .kerning(0.6)

                    HStack(spacing: 12) {
                        Text(viewModel.generatedCode)
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(Color.huddleCoral)
                            .tracking(4)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            UIPasteboard.general.string = viewModel.generatedCode
                            withAnimation { showCopiedToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { showCopiedToast = false }
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 18))
                                .foregroundColor(Color.huddleTextTertiary)
                                .padding(8)
                                .background(Color.huddleCoral.opacity(0.06))
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(Color.huddleBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.huddleOutlineVariant, lineWidth: 1)
                )

                // Action buttons
                VStack(spacing: 12) {
                    ShareLink(item: viewModel.generatedCode) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Share with Family")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.huddleCoral)
                        .cornerRadius(8)
                    }

                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.huddleTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.huddleCard)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.huddleBorder, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    CreateFamily().environmentObject(AuthService())
}
