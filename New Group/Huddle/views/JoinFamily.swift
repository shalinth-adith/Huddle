//
//  JoinFamily.swift
//  Huddle
//
//  Created by shalinth adithyan on 27/11/25.
//

import SwiftUI

struct JoinFamily: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: JoinFamilyViewModel

    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: JoinFamilyViewModel(
            familyService: FamilyService(),
            authService: authService
        ))
    }

    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()
            if viewModel.showSuccess {
                successView
            } else {
                inputView
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(spacing: 0) {
            // Header
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
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.huddleSecondaryFixed)
                            .frame(width: 80, height: 80)
                        Image(systemName: "key.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color.huddleTextSecondary)
                    }
                    .padding(.top, 32)

                    // Heading
                    VStack(spacing: 8) {
                        Text("Join Your Family")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(Color.huddleTextPrimary)
                            .multilineTextAlignment(.center)
                            .tracking(-0.3)
                        Text("Enter the family code shared by your household.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.huddleTextTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }

                    // Code input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Family Code")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.huddleTextSecondary)
                            .padding(.leading, 4)

                        TextField("H-000000", text: $viewModel.familyCode)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color.huddleTextPrimary)
                            .multilineTextAlignment(.center)
                            .tracking(4)
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled(true)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.huddleSurface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        viewModel.familyCode.isEmpty ? Color.clear : Color.huddleCoral,
                                        lineWidth: 2
                                    )
                            )
                            .onChange(of: viewModel.familyCode) { newValue in
                                viewModel.formatFamilyCode(newValue)
                            }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "BA1A1A"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                    }

                    // Info box
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.huddleCoral)
                        Text("Ask the family admin for the 7-character code that looks like H-216962.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.huddleTextSecondary)
                            .lineSpacing(2)
                    }
                    .padding(14)
                    .background(Color.huddleCoral.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.huddleCoral.opacity(0.1), lineWidth: 1)
                    )

                    // Join button
                    Button(action: viewModel.joinFamily) {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Join Family")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.isValidCode
                                ? Color.huddleCoral
                                : Color.huddleTextTertiary.opacity(0.4)
                        )
                        .cornerRadius(8)
                        .shadow(
                            color: viewModel.isValidCode ? Color.huddleCoral.opacity(0.3) : .clear,
                            radius: 8, x: 0, y: 4
                        )
                    }
                    .disabled(!viewModel.isValidCode || viewModel.isLoading)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.huddleCoral.opacity(0.1))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color.huddleCoral)
            }

            VStack(spacing: 12) {
                Text("Joined Successfully!")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)

                Text(viewModel.joinedFamilyName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color.huddleCoral)
                    .multilineTextAlignment(.center)

                Text("You're now part of the \(viewModel.joinedFamilyName) family. Say hello!")
                    .font(.system(size: 16))
                    .foregroundColor(Color.huddleTextTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 16)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.huddleCoral)
                    .cornerRadius(8)
                    .shadow(color: Color.huddleCoral.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    JoinFamily(authService: AuthService())
}
