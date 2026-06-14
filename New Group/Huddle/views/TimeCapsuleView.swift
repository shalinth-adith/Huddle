//
//  TimeCapsuleView.swift
//  Huddle
//
//  Full-screen Time Capsule: sealed capsules (content hidden until their date)
//  and opened ones (revealed). Create a capsule to send a message to the future.
//

import SwiftUI

struct TimeCapsuleView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: CapsuleViewModel
    @State private var showCompose = false

    init(capsuleService: CapsuleService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: CapsuleViewModel(capsuleService: capsuleService, authService: authService))
    }

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.30)

            VStack(spacing: 0) {
                header

                if viewModel.isLoading {
                    Spacer(); ProgressView().tint(Color.huddleCoral); Spacer()
                } else if viewModel.capsules.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            if !viewModel.sealed.isEmpty {
                                sectionHeader("Sealed", icon: "lock.fill")
                                ForEach(viewModel.sealed) { sealedCard($0) }
                            }
                            if !viewModel.opened.isEmpty {
                                sectionHeader("Opened", icon: "lock.open.fill")
                                ForEach(viewModel.opened) { openedCard($0) }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeCapsuleSheet { message, deliverAt in
                viewModel.createCapsule(message: message, deliverAt: deliverAt)
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                LushEyebrow(text: "Send to the future")
                Text("Time Capsule").font(.system(size: 24, weight: .bold)).foregroundColor(Color.huddleTextPrimary).tracking(-0.6)
            }
            Spacer()
            Button(action: { showCompose = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom)))
            }
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Color.huddleTextPrimary.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.huddleGlassFill).overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1)))
            }
        }
        .padding(.horizontal, 20).padding(.top, 64).padding(.bottom, 14)
    }

    private func sectionHeader(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundColor(Color.huddleCoral)
            Text(text).font(.system(size: 13, weight: .bold)).foregroundColor(Color.huddleTextPrimary.opacity(0.6)).tracking(0.3)
        }
        .padding(.leading, 4)
    }

    private func sealedCard(_ capsule: TimeCapsule) -> some View {
        GlassCard(padding: 16) {
            HStack(spacing: 14) {
                Image(systemName: "hourglass")
                    .font(.system(size: 22))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(hex: "FF8A66").opacity(0.12)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Opens \(relativeDate(capsule.deliverAt))")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                    Text("From \(capsule.createdByName) · \(fullDate(capsule.deliverAt))")
                        .font(.system(size: 12)).foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                }
                Spacer(minLength: 0)
            }
        }
        .contextMenu {
            if viewModel.canDelete(capsule) {
                Button(role: .destructive) { viewModel.deleteCapsule(capsule) } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }

    private func openedCard(_ capsule: TimeCapsule) -> some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.open.fill").font(.system(size: 12)).foregroundColor(Color.huddleCoral)
                    Text("From \(capsule.createdByName)")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Color.huddleTextPrimary.opacity(0.6))
                    Spacer()
                    Text(fullDate(capsule.deliverAt)).font(.system(size: 11)).foregroundColor(Color.huddleTextPrimary.opacity(0.4))
                }
                Text(capsule.message)
                    .font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contextMenu {
            if viewModel.canDelete(capsule) {
                Button(role: .destructive) { viewModel.deleteCapsule(capsule) } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            ClayIcon(systemImage: "hourglass", lushColor: .coral, size: 70)
            Text("No capsules yet").font(.system(size: 19, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
            Text("Write a message your family will open on a future date — a birthday, a milestone, or just someday.")
                .font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Button(action: { showCompose = true }) {
                Text("Seal your first capsule").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 11)
                    .background(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom).cornerRadius(12))
            }
            .padding(.top, 4)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity).padding(.horizontal, 24)
    }

    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter(); f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: Date())
    }
    private func fullDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: date)
    }
}

private struct ComposeCapsuleSheet: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (_ message: String, _ deliverAt: Date) -> Void

    @State private var message = ""
    // Default: one year from now.
    @State private var deliverAt = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()

    private var canSave: Bool {
        !message.trimmingCharacters(in: .whitespaces).isEmpty && deliverAt > Date()
    }

    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }.foregroundColor(Color.huddleTextPrimary.opacity(0.6))
                    Spacer()
                    Text("New Capsule").font(.system(size: 16, weight: .bold)).foregroundColor(Color.huddleTextPrimary)
                    Spacer()
                    Button("Seal") { onSave(message, deliverAt); dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(canSave ? Color.huddleCoral : Color.huddleTextPrimary.opacity(0.3))
                        .disabled(!canSave)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("YOUR MESSAGE").font(.system(size: 11, weight: .bold)).tracking(0.6).foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                        TextField("Dear family, by the time you read this…", text: $message, axis: .vertical)
                            .font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary)
                            .lineLimit(6, reservesSpace: true)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.huddleGlassFill).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.huddleBorder, lineWidth: 1)))

                        Text("OPEN ON").font(.system(size: 11, weight: .bold)).tracking(0.6).foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                        DatePicker("Delivery date", selection: $deliverAt, in: Date()..., displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .tint(Color.huddleCoral)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.huddleGlassFill).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.huddleBorder, lineWidth: 1)))

                        Text("🔒 Sealed until the date — no one can read it before then.")
                            .font(.system(size: 12)).foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                    }
                    .padding(.horizontal, 20).padding(.top, 4)
                }
            }
        }
    }
}
