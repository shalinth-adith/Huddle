//
//  AskHuddleView.swift
//  Huddle
//
//  On-device AI assistant. Summarizes recent chat, drafts ideas, answers
//  questions — all locally via Apple Intelligence, so E2E content stays private.
//

import SwiftUI

struct AskHuddleView: View {
    @Environment(\.dismiss) var dismiss

    let familyName: String
    let recentMessages: [String]

    private let ai = AIService()
    private let instructions = "You are Huddle, a warm and concise assistant inside a private family app. Keep answers short, friendly, and practical. Never invent family details you weren't given."

    @State private var turns: [Turn] = []
    @State private var input = ""
    @State private var isThinking = false
    @FocusState private var inputFocused: Bool

    struct Turn: Identifiable {
        let id = UUID()
        let isUser: Bool
        let text: String
    }

    private let quickActions = [
        ("Summarize what I missed", "text.append"),
        ("Suggest a family activity", "sparkles"),
        ("Draft a dinner plan", "fork.knife")
    ]

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.30)

            VStack(spacing: 0) {
                header

                if !ai.isAvailable {
                    unavailableState
                } else {
                    conversation
                    inputBar
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
            VStack(alignment: .leading, spacing: 1) {
                Text("Ask Huddle").font(.system(size: 18, weight: .bold)).foregroundColor(Color.huddleTextPrimary).tracking(-0.3)
                Text("On-device · private").font(.system(size: 11)).foregroundColor(Color.huddleTextPrimary.opacity(0.45))
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Color.huddleTextPrimary.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.huddleGlassFill).overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1)))
            }
        }
        .padding(.horizontal, 20).padding(.top, 64).padding(.bottom, 14)
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if turns.isEmpty {
                        intro
                    }
                    ForEach(turns) { turn in
                        bubble(turn)
                    }
                    if isThinking {
                        HStack(spacing: 6) {
                            ProgressView().tint(Color.huddleCoral)
                            Text("Thinking…").font(.system(size: 13)).foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                        }
                        .padding(.leading, 4)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 10)
            }
            .onChange(of: turns.count) { _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
            .onChange(of: isThinking) { _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hi! I can help with \(familyName).")
                .font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary.opacity(0.7))
                .padding(.top, 4)
            ForEach(quickActions, id: \.0) { label, icon in
                Button { runQuickAction(label) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color.huddleCoral)
                        Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(Color.huddleTextPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.system(size: 11)).foregroundColor(Color.huddleTextPrimary.opacity(0.3))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.huddleGlassFill).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.huddleBorder, lineWidth: 1)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func bubble(_ turn: Turn) -> some View {
        HStack {
            if turn.isUser { Spacer(minLength: 50) }
            Text(turn.text)
                .font(.system(size: 15))
                .foregroundColor(turn.isUser ? .white : Color.huddleTextPrimary)
                .padding(.horizontal, 13).padding(.vertical, 10)
                .background(
                    Group {
                        if turn.isUser {
                            RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        } else {
                            RoundedRectangle(cornerRadius: 18).fill(Color.huddleGlassFill).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.huddleBorder, lineWidth: 1))
                        }
                    }
                )
                .fixedSize(horizontal: false, vertical: true)
            if !turn.isUser { Spacer(minLength: 50) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask anything…", text: $input, axis: .vertical)
                .font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary)
                .focused($inputFocused)
                .lineLimit(1...4)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Capsule().fill(Color.huddleGlassFill).overlay(Capsule().stroke(Color.huddleBorder, lineWidth: 1)))

            Button(action: { send(input) }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(canSend ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Color.huddleTextPrimary.opacity(0.12))))
            }
            .disabled(!canSend || isThinking)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.huddleBackground.overlay(Rectangle().fill(Color.huddleBorder).frame(height: 1), alignment: .top))
    }

    private var unavailableState: some View {
        VStack(spacing: 14) {
            Spacer()
            ClayIcon(systemImage: "sparkles", lushColor: .coral, size: 64)
            Text("Not available here").font(.system(size: 18, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
            Text(ai.unavailableMessage)
                .font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var canSend: Bool { !input.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Actions

    private func runQuickAction(_ label: String) {
        switch label {
        case "Summarize what I missed":
            guard !recentMessages.isEmpty else {
                turns.append(Turn(isUser: true, text: label))
                turns.append(Turn(isUser: false, text: "There's nothing new in the chat to summarize yet."))
                return
            }
            let context = recentMessages.suffix(30).joined(separator: "\n")
            ask(display: label, prompt: "Summarize this family chat in 2–3 short bullet points, focusing on plans, decisions, and anything that needs a reply:\n\n\(context)")
        case "Suggest a family activity":
            ask(display: label, prompt: "Suggest 3 simple activity ideas a family could do together this week. One short line each.")
        case "Draft a dinner plan":
            ask(display: label, prompt: "Draft a simple 3-day family dinner plan. One line per day with a meal name.")
        default:
            send(label)
        }
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        input = ""
        inputFocused = false
        // Give the model light context from recent chat for grounded answers.
        let context = recentMessages.isEmpty ? "" : "\n\nRecent family chat for context:\n\(recentMessages.suffix(20).joined(separator: "\n"))"
        ask(display: trimmed, prompt: trimmed + context)
    }

    private func ask(display: String, prompt: String) {
        turns.append(Turn(isUser: true, text: display))
        isThinking = true
        Task {
            do {
                let answer = try await ai.respond(to: prompt, instructions: instructions)
                await MainActor.run {
                    isThinking = false
                    turns.append(Turn(isUser: false, text: answer.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            } catch {
                await MainActor.run {
                    isThinking = false
                    turns.append(Turn(isUser: false, text: "Sorry — I couldn't answer that just now. \(error.localizedDescription)"))
                }
            }
        }
    }
}
