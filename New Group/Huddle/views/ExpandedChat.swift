import SwiftUI

struct ExpandedChat: View {
    @ObservedObject var viewModel: FamilyFeedViewModel
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var messageText = ""
    @State private var reactingTo: HuddleMessage?
    @State private var showPingTray = false
    @FocusState private var isInputFocused: Bool

    private let pingOptions = ["I'm home", "On my way", "Leaving school", "Running late", "At the store", "Be there soon"]
    private let reactionEmojis = ["❤️", "😂", "👍", "😮", "😢", "🎉"]

    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                messageList
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                inputBar
            }

            if let msg = reactingTo {
                reactionOverlay(for: msg)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .sheet(isPresented: $showPingTray) {
            pingTrayView
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .buttonStyle(.plain)
        .onTapGesture {
            isInputFocused = false
            withAnimation { reactingTo = nil }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.family?.name ?? "Chat")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                Text("\(viewModel.family?.members.count ?? 0) members · end-to-end encrypted")
                    .font(.system(size: 11))
                    .foregroundColor(Color.huddleTextTertiary)
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
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.huddleBackground)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder), alignment: .bottom)
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        Group {
                            if shouldShowDateSeparator(at: index) {
                                dateSeparator(for: message.createdAt).padding(.vertical, 10)
                            }
                            if message.type == .system {
                                systemRow(message).padding(.vertical, 2)
                            } else if message.type == .ping {
                                pingRow(message).padding(.vertical, 5)
                            } else {
                                chatRow(message, firstInGroup: isFirstInGroup(at: index)).padding(.vertical, 2)
                            }
                        }
                    }
                    Color.clear.frame(height: 1).id("chatBottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    proxy.scrollTo("chatBottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("chatBottom", anchor: .bottom) }
            }
        }
    }

    // MARK: - Grouping helpers

    private func shouldShowDateSeparator(at index: Int) -> Bool {
        guard index > 0 else { return true }
        return !Calendar.current.isDate(viewModel.messages[index - 1].createdAt, inSameDayAs: viewModel.messages[index].createdAt)
    }

    private func isFirstInGroup(at index: Int) -> Bool {
        guard index > 0 else { return true }
        let prev = viewModel.messages[index - 1], curr = viewModel.messages[index]
        guard prev.senderID == curr.senderID, prev.type == curr.type else { return true }
        return (Calendar.current.dateComponents([.minute], from: prev.createdAt, to: curr.createdAt).minute ?? 0) > 5
    }

    private func dateSeparator(for date: Date) -> some View {
        let label: String
        if Calendar.current.isDateInToday(date) { label = "Today" }
        else if Calendar.current.isDateInYesterday(date) { label = "Yesterday" }
        else { let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; label = f.string(from: date) }
        return HStack(spacing: 10) {
            Rectangle().fill(Color.huddleBorder).frame(height: 1)
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundColor(Color.huddleTextTertiary).fixedSize()
            Rectangle().fill(Color.huddleBorder).frame(height: 1)
        }
    }

    // MARK: - Row types

    private func systemRow(_ message: HuddleMessage) -> some View {
        Text(message.content)
            .font(.system(size: 12))
            .foregroundColor(Color.huddleTextTertiary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }

    private func pingRow(_ message: HuddleMessage) -> some View {
        let label = message.content.replacingOccurrences(of: "📍", with: "").trimmingCharacters(in: .whitespaces)
        return HStack(spacing: 12) {
            Text("📍").font(.system(size: 26))
            VStack(alignment: .leading, spacing: 2) {
                Text(label.isEmpty ? "Ping" : label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                Text("\(message.senderName) · \(formatTime(message.createdAt))")
                    .font(.caption).foregroundColor(Color.huddleTextTertiary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.huddleCoral.opacity(0.10))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.huddleCoral.opacity(0.25), lineWidth: 1))
    }

    private func chatRow(_ message: HuddleMessage, firstInGroup: Bool) -> some View {
        let isMe = message.senderID == authService.currentUser?.id
        let senderPhoto = viewModel.family?.members.first(where: { $0.id == message.senderID })?.photoBase64

        return HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 60) }

            if !isMe {
                if firstInGroup { MemberAvatarView(name: message.senderName, photoBase64: senderPhoto, size: 28) }
                else { Color.clear.frame(width: 28) }
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe && firstInGroup {
                    Text(message.senderName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.huddleTextSecondary)
                        .padding(.leading, 2)
                }
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isMe ? .white : Color.huddleTextPrimary)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(isMe ? Color.huddleCoral : Color.huddleSurface)
                    .cornerRadius(18)
                    .onLongPressGesture(minimumDuration: 0.4) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { reactingTo = message }
                    }

                if let reactions = message.reactions, !reactions.isEmpty {
                    reactionRow(reactions: reactions, message: message)
                }

                Text(formatTime(message.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(Color.huddleTextTertiary)
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }

    // MARK: - Reaction row

    private func reactionRow(reactions: [String: [String]], message: HuddleMessage) -> some View {
        let sorted = reactions.sorted { $0.value.count > $1.value.count }
        return HStack(spacing: 5) {
            ForEach(sorted, id: \.key) { emoji, users in
                let isMine = users.contains(authService.currentUser?.id ?? "")
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.toggleReaction(message: message, emoji: emoji)
                }) {
                    HStack(spacing: 3) {
                        Text(emoji).font(.system(size: 13))
                        if users.count > 1 {
                            Text("\(users.count)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isMine ? Color.huddleCoral : Color.huddleTextTertiary)
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(isMine ? Color.huddleCoral.opacity(0.12) : Color.huddleSecondaryFixed)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isMine ? Color.huddleCoral.opacity(0.4) : Color.clear, lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Reaction overlay

    private func reactionOverlay(for message: HuddleMessage) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.25).ignoresSafeArea()
                .onTapGesture { withAnimation { reactingTo = nil } }

            HStack(spacing: 4) {
                ForEach(reactionEmojis, id: \.self) { emoji in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.toggleReaction(message: message, emoji: emoji)
                        withAnimation { reactingTo = nil }
                    }) {
                        Text(emoji)
                            .font(.system(size: 30))
                            .padding(10)
                            .background(Color.huddleCard)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.huddleCard)
                    .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: -4)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 90)
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPingTray = true
            } label: {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.huddleCoral)
            }

            HStack(spacing: 8) {
                TextField("Message your family...", text: $messageText)
                    .font(.system(size: 15))
                    .foregroundColor(Color.huddleTextPrimary)
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }
                if !messageText.isEmpty {
                    Button(action: { messageText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.huddleTextTertiary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(Color.huddleBackground)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(isInputFocused ? Color.huddleCoral : Color.huddleBorder, lineWidth: 1.5))

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16)).foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.huddleTextTertiary.opacity(0.3) : Color.huddleCoral)
                    .clipShape(Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.huddleCard)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder), alignment: .top)
    }

    // MARK: - Ping tray

    private var pingTrayView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Send a ping").font(.headline).padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(pingOptions, id: \.self) { label in
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.sendPing(content: "📍 \(label)")
                        showPingTray = false
                    } label: {
                        HStack(spacing: 10) {
                            Text("📍").font(.title2)
                            Text(label).font(.subheadline).fontWeight(.medium)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.huddleSurface)
                        .cornerRadius(12)
                    }
                    .foregroundColor(Color.huddleTextPrimary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 20).padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.sendMessage(content: text)
        messageText = ""
    }

    private func formatTime(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return "just now" }
        if s < 3600 { return "\(s / 60)m ago" }
        if s < 86400 { return "\(s / 3600)h ago" }
        return "\(s / 86400)d ago"
    }
}
