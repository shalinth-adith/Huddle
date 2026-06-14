import SwiftUI
import PhotosUI

struct ExpandedChat: View {
    @ObservedObject var viewModel: FamilyFeedViewModel
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var messageText = ""
    @State private var reactingTo: HuddleMessage?
    @State private var showPingTray = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingImage: UIImage?
    @State private var isPreparingPhoto = false
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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.family?.name ?? "Chat")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.huddleTextPrimary)
                    .tracking(-0.3)
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "FF8A66").opacity(0.7))
                    Text("\(viewModel.family?.members.count ?? 0) members · end-to-end encrypted")
                        .font(.system(size: 11))
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                }
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.huddleGlassFill))
                    .overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(Color.huddleBackground)
        .overlay(
            Rectangle()
                .fill(Color.huddleBorder)
                .frame(height: 1),
            alignment: .bottom
        )
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
                            } else if message.type == .photo {
                                photoRow(message, firstInGroup: isFirstInGroup(at: index)).padding(.vertical, 2)
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
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.huddleTextPrimary.opacity(0.4))
                .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.huddleGlassFill)
                        .overlay(Capsule().stroke(Color.huddleBorder, lineWidth: 1))
                )
            Rectangle().fill(Color.huddleBorder).frame(height: 1)
        }
    }

    // MARK: - Row types

    private func systemRow(_ message: HuddleMessage) -> some View {
        Text(message.content)
            .font(.system(size: 12))
            .foregroundColor(Color.huddleTextPrimary.opacity(0.35))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }

    private func pingRow(_ message: HuddleMessage) -> some View {
        let label = message.content.replacingOccurrences(of: "📍", with: "").trimmingCharacters(in: .whitespaces)
        return HStack(spacing: 12) {
            Text("📍").font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(label.isEmpty ? "Ping" : label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                Text("\(message.senderName) · \(formatTime(message.createdAt))")
                    .font(.caption)
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.45))
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "FF8A66").opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "FF8A66").opacity(0.22), lineWidth: 1))
        )
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
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                        .padding(.leading, 4)
                }

                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isMe ? .white : Color.huddleTextPrimary)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(
                        Group {
                            if isMe {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FFA078"), Color(hex: "D8512B")],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.huddleGlassFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.huddleBorder, lineWidth: 1)
                                    )
                            }
                        }
                    )
                    .shadow(
                        color: isMe ? Color(hex: "D8512B").opacity(0.25) : Color.black.opacity(0.15),
                        radius: isMe ? 6 : 4, x: 0, y: 2
                    )
                    .onLongPressGesture(minimumDuration: 0.4) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { reactingTo = message }
                    }

                if let reactions = message.reactions, !reactions.isEmpty {
                    reactionRow(reactions: reactions, message: message)
                }

                Text(formatTime(message.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.3))
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }

    private func photoRow(_ message: HuddleMessage, firstInGroup: Bool) -> some View {
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
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                        .padding(.leading, 4)
                }

                PhotoMessageView(message: message, isMe: isMe, viewModel: viewModel)
                    .onLongPressGesture(minimumDuration: 0.4) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { reactingTo = message }
                    }

                if let reactions = message.reactions, !reactions.isEmpty {
                    reactionRow(reactions: reactions, message: message)
                }

                Text(formatTime(message.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.3))
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
                                .foregroundColor(isMine ? Color(hex: "FF8A66") : Color.huddleTextPrimary.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(isMine ? Color(hex: "FF8A66").opacity(0.12) : Color.huddleGlassFill)
                            .overlay(
                                Capsule().stroke(
                                    isMine ? Color(hex: "FF8A66").opacity(0.35) : Color.huddleBorder,
                                    lineWidth: 1
                                )
                            )
                    )
                }
            }
        }
    }

    // MARK: - Reaction overlay

    private func reactionOverlay(for message: HuddleMessage) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { withAnimation { reactingTo = nil } }

            HStack(spacing: 6) {
                ForEach(reactionEmojis, id: \.self) { emoji in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.toggleReaction(message: message, emoji: emoji)
                        withAnimation { reactingTo = nil }
                    }) {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(Color.huddleCard.opacity(0.9))
                                    .overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1))
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.huddleCard)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.huddleBorder, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: -4)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 90)
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            if pendingImage != nil { pendingPhotoPreview }
            inputControls
        }
        .background(
            Color.huddleBackground
                .overlay(
                    Rectangle()
                        .fill(Color.huddleBorder)
                        .frame(height: 1),
                    alignment: .top
                )
        )
        .onChange(of: selectedPhotoItem) { _ in loadPickedPhoto() }
    }

    private var pendingPhotoPreview: some View {
        HStack(spacing: 12) {
            if let pendingImage {
                Image(uiImage: pendingImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.huddleBorder, lineWidth: 1))
            }
            Text("Photo ready · add a caption or send")
                .font(.system(size: 13))
                .foregroundColor(Color.huddleTextPrimary.opacity(0.55))
            Spacer()
            Button {
                pendingImage = nil
                selectedPhotoItem = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var inputControls: some View {
        HStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                Group {
                    if isPreparingPhoto {
                        ProgressView().tint(Color(hex: "FF8A66"))
                    } else {
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    }
                }
                .frame(width: 26, height: 26)
            }
            .disabled(isPreparingPhoto)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPingTray = true
            } label: {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            HStack(spacing: 8) {
                TextField(pendingImage == nil ? "Message your family..." : "Add a caption...", text: $messageText)
                    .font(.system(size: 15))
                    .foregroundColor(Color.huddleTextPrimary)
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }
                if !messageText.isEmpty {
                    Button(action: { messageText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color.huddleTextPrimary.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(Color.huddleGlassFill)
                    .overlay(
                        Capsule().stroke(
                            isInputFocused ? Color(hex: "FF8A66").opacity(0.5) : Color.huddleBorder,
                            lineWidth: 1
                        )
                    )
            )

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14))
                    .foregroundColor(canSend ? .white : Color.huddleTextPrimary)
                    .frame(width: 42, height: 42)
                    .background(
                        canSend
                            ? AnyView(
                                Circle().fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFA078"), Color(hex: "D8512B")],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color(hex: "D8512B").opacity(0.4), radius: 6, x: 0, y: 2)
                            )
                            : AnyView(Circle().fill(Color.huddleGlassFill))
                    )
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var canSend: Bool {
        pendingImage != nil || !messageText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Ping tray

    private var pingTrayView: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Send a ping")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.huddleTextPrimary)
                            .tracking(-0.4)
                        Text("Quick status update for your family")
                            .font(.system(size: 13))
                            .foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(pingOptions, id: \.self) { label in
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.sendPing(content: "📍 \(label)")
                            showPingTray = false
                        } label: {
                            HStack(spacing: 10) {
                                Text("📍").font(.system(size: 18))
                                Text(label)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.huddleTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.huddleGlassFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.huddleBorder, lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 28)
        }
    }

    // MARK: - Helpers

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)

        if let image = pendingImage {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.sendPhoto(image: image, caption: text)
            pendingImage = nil
            selectedPhotoItem = nil
            messageText = ""
            return
        }

        guard !text.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.sendMessage(content: text)
        messageText = ""
    }

    private func loadPickedPhoto() {
        guard let item = selectedPhotoItem else { return }
        isPreparingPhoto = true
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            let image = data.flatMap { UIImage(data: $0) }
            await MainActor.run {
                isPreparingPhoto = false
                if let image {
                    pendingImage = image
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else {
                    selectedPhotoItem = nil
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return "just now" }
        if s < 3600 { return "\(s / 60)m ago" }
        if s < 86400 { return "\(s / 3600)h ago" }
        return "\(s / 86400)d ago"
    }
}
