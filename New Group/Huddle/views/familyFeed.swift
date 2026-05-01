import SwiftUI

struct FamilyFeedView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: FamilyFeedViewModel
    @Binding var openToShopping: Bool

    @AppStorage("huddleColorScheme") private var colorSchemePreference: Int = 0

    @State private var selectedTab: FeedTab = .home
    @State private var showLeaveAlert = false
    @State private var showRenameAlert = false
    @State private var newFamilyName = ""
    @State private var showGroupSwitcher = false
    @State private var showPingTray = false
    @State private var messageToDelete: HuddleMessage?
    @State private var memberToRemove: Member?
    @State private var showCopiedToast = false
    @State private var showExpandedChat = false

    private let pingOptions: [String] = [
        "I'm home",
        "On my way",
        "Leaving school",
        "Running late",
        "At the store",
        "Be there soon"
    ]

    enum FeedTab: CaseIterable {
        case home, messages, shopping, family

        var icon: String {
            switch self {
            case .home:     return "house"
            case .messages: return "message"
            case .shopping: return "cart"
            case .family:   return "person.2"
            }
        }
        var activeIcon: String {
            switch self {
            case .home:     return "house.fill"
            case .messages: return "message.fill"
            case .shopping: return "cart.fill"
            case .family:   return "person.2.fill"
            }
        }
        var label: String {
            switch self {
            case .home:     return "Home"
            case .messages: return "Messages"
            case .shopping: return "Shopping"
            case .family:   return "Family"
            }
        }
    }

    init(authService: AuthService, openToShopping: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: FamilyFeedViewModel(
            familyService: FamilyService(),
            authService: authService,
            messageService: MessageService()
        ))
        _openToShopping = openToShopping
    }

    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()

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
                        .padding(.bottom, 100)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                .zIndex(1)
                .animation(.easeInOut(duration: 0.2), value: showCopiedToast)
            }

            if viewModel.isLoading {
                ProgressView()
            } else if let family = viewModel.family {
                VStack(spacing: 0) {
                    headerBar(family: family)
                    tabContent(family: family)
                }
                // safeAreaInset pins the bar to the real bottom (incl. home indicator)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        if selectedTab == .messages {
                            MessageInputBar(
                                onSend: { viewModel.sendMessage(content: $0) },
                                onPingTap: { showPingTray = true }
                            )
                        }
                        tabBar
                    }
                }
            } else {
                Text("Error loading family")
                    .foregroundColor(Color.huddleTextTertiary)
            }
        }
        .sheet(isPresented: $showPingTray) {
            pingTrayView
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showExpandedChat) {
            ExpandedChat(viewModel: viewModel).environmentObject(authService)
        }
        .buttonStyle(.plain)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            viewModel.loadFamily()
            viewModel.loadMessages()
            viewModel.loadShoppingItems()
            viewModel.loadPinnedMessages()
            if selectedTab == .messages { viewModel.markMessagesAsRead() }
        }
        .onChange(of: selectedTab) { tab in
            if tab == .messages { viewModel.markMessagesAsRead() }
        }
        .onDisappear { viewModel.cleanup() }
        .alert("Leave Huddle?", isPresented: $showLeaveAlert) {
            Button("Leave", role: .destructive) { viewModel.leaveGroup() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be removed from this group. Your profile is kept — you can join or create another group.")
        }
        .alert("Rename Group", isPresented: $showRenameAlert) {
            TextField("Group name", text: $newFamilyName)
            Button("Save") { viewModel.renameFamily(newFamilyName) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Message?", isPresented: Binding(
            get: { messageToDelete != nil },
            set: { if !$0 { messageToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let msg = messageToDelete { viewModel.deleteMessage(msg) }
                messageToDelete = nil
            }
            Button("Cancel", role: .cancel) { messageToDelete = nil }
        } message: {
            Text("This message will be permanently deleted.")
        }
        .alert("Remove Member?", isPresented: Binding(
            get: { memberToRemove != nil },
            set: { if !$0 { memberToRemove = nil } }
        )) {
            Button("Remove", role: .destructive) {
                if let member = memberToRemove { viewModel.removeMember(member) }
                memberToRemove = nil
            }
            Button("Cancel", role: .cancel) { memberToRemove = nil }
        } message: {
            if let member = memberToRemove {
                Text("\(member.displayName) will be removed from the group.")
            }
        }
        .sheet(isPresented: $showGroupSwitcher) {
            NavigationView {
                List {
                    ForEach(viewModel.availableFamilies) { family in
                        Button {
                            if let id = family.id {
                                showGroupSwitcher = false
                                viewModel.switchGroup(to: id)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(family.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.huddleTextPrimary)
                                    Text("\(family.members.count) member\(family.members.count == 1 ? "" : "s")")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.huddleTextTertiary)
                                }
                                Spacer()
                                if family.id == authService.currentUser?.currentFamilyId {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.huddleCoral)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Your Groups")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showGroupSwitcher = false }
                            .foregroundColor(Color.huddleCoral)
                    }
                }
            }
        }
        .onChange(of: openToShopping) { newValue in
            if newValue {
                selectedTab = .shopping
                openToShopping = false
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) { shareSheet }
        .sheet(isPresented: $viewModel.showShoppingList, onDismiss: {
            viewModel.loadShoppingItems()
        }) {
            if let family = viewModel.family {
                ShoppingList(family: family).environmentObject(authService)
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(FeedTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tab }
                    if tab == .messages { viewModel.markMessagesAsRead() }
                }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: selectedTab == tab ? tab.activeIcon : tab.icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == tab ? Color.huddleCoral : Color.huddleTextTertiary.opacity(0.5))
                            if tab == .messages && viewModel.unreadCount > 0 && selectedTab != .messages {
                                Circle()
                                    .fill(Color.huddleCoral)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -2)
                            }
                        }
                        Text(tab.label)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? Color.huddleCoral : Color.huddleTextTertiary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(
            Color.huddleCard
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -2)
        )
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder), alignment: .top)
    }

    // MARK: - Tab Router

    @ViewBuilder
    private func tabContent(family: Family) -> some View {
        switch selectedTab {
        case .home:     homeTab(family: family)
        case .messages: messagesTab()
        case .shopping: shoppingTab()
        case .family:   familyTab(family: family)
        }
    }

    // MARK: - Shared Header

    private func headerBar(family: Family) -> some View {
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
            HStack(spacing: 10) {
                Button(action: { viewModel.showShareSheet = true }) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundColor(Color.huddleCoral)
                        .padding(8)
                        .background(Color.huddleSecondaryFixed)
                        .clipShape(Circle())
                }
                if (authService.currentUser?.familyIds.count ?? 0) > 1 {
                    Button(action: {
                        viewModel.loadAvailableFamilies()
                        showGroupSwitcher = true
                    }) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color.huddleCoral)
                            .padding(8)
                            .background(Color.huddleSecondaryFixed)
                            .clipShape(Circle())
                    }
                }
                Button(action: { withAnimation(.easeInOut(duration: 0.18)) { selectedTab = .family } }) {
                    MemberAvatarView(
                        name: authService.currentUser?.displayName ?? "",
                        photoBase64: authService.currentUser?.photoBase64,
                        size: 36
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.huddleBackground)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder), alignment: .bottom)
    }

    // MARK: - Home Tab

    private func homeTab(family: Family) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                heroCard(family: family)
                membersCard(family: family)
                shoppingPreviewCard()
                if !viewModel.pinnedMessages.isEmpty { pinnedCard() }
                chatPreviewCard()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
    }

    private func heroCard(family: Family) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.huddleCoral.opacity(0.8), Color.huddlePrimaryFixed],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 148)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.4)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(family.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("\(family.members.count) members")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(16)
        }
        .overlay(
            Button(action: { viewModel.showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .padding(12),
            alignment: .topTrailing
        )
    }

    private func membersCard(family: Family) -> some View {
        let unique = Array(Dictionary(grouping: family.members, by: { $0.id }).compactMap { $0.value.first })

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Members")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                Spacer()
                Button(action: { withAnimation(.easeInOut(duration: 0.18)) { selectedTab = .family } }) {
                    Text("See All")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.huddleCoral)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(unique) { member in
                        VStack(spacing: 6) {
                            let memberPhoto = member.id == authService.currentUser?.id
                                ? (authService.currentUser?.photoBase64 ?? member.photoBase64)
                                : member.photoBase64
                            MemberAvatarView(name: member.displayName, photoBase64: memberPhoto, size: 48)
                            Text(member.displayName.components(separatedBy: " ").first ?? member.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.huddleTextSecondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.huddleCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func shoppingPreviewCard() -> some View {
        let items = viewModel.shoppingItems
        let preview = Array(items.prefix(3))
        let remaining = max(0, items.count - 3)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color.huddleCoral)
                    Text("Shopping List")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary)
                }
                Spacer()
                Button(action: { withAnimation(.easeInOut(duration: 0.18)) { selectedTab = .shopping } }) {
                    Text("View All")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.huddleCoral)
                }
            }

            if items.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "cart")
                        .font(.system(size: 15))
                        .foregroundColor(Color.huddleTextTertiary.opacity(0.5))
                    Text("No items yet")
                        .font(.system(size: 14))
                        .foregroundColor(Color.huddleTextTertiary)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(preview) { item in
                        HStack(spacing: 10) {
                            Button(action: { viewModel.toggleShoppingItem(item) }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(item.isCompleted ? Color.huddleCoral : Color.huddleTextTertiary.opacity(0.4))
                            }
                            Text(item.content)
                                .font(.system(size: 14))
                                .foregroundColor(item.isCompleted ? Color.huddleTextTertiary : Color.huddleTextPrimary)
                                .strikethrough(item.isCompleted, color: Color.huddleTextTertiary)
                            Spacer()
                        }
                    }
                    if remaining > 0 {
                        Text("+\(remaining) more items")
                            .font(.system(size: 12))
                            .foregroundColor(Color.huddleTextTertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.huddleCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func pinnedCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color.huddleCoral)
                Text("Pinned")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                Spacer()
            }
            ForEach(viewModel.pinnedMessages) { message in
                HStack {
                    Text(message.content)
                        .font(.system(size: 14))
                        .foregroundColor(Color.huddleTextPrimary)
                    Spacer()
                }
                .padding(12)
                .background(Color.huddlePeach.opacity(0.3))
                .cornerRadius(10)
                .contextMenu {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.togglePinMessage(message)
                    }) {
                        Label("Unpin Message", systemImage: "pin.slash")
                    }
                }
            }
        }
        .padding(16)
        .background(Color.huddleCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func chatPreviewCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color.huddleCoral)
                    Text("Huddle Chat")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary)
                }
                Spacer()
                Button(action: { withAnimation(.easeInOut(duration: 0.18)) { selectedTab = .messages } }) {
                    Text("Open Chat")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.huddleCoral)
                }
            }

            if viewModel.messages.isEmpty {
                Text("No messages yet. Start chatting!")
                    .font(.system(size: 14))
                    .foregroundColor(Color.huddleTextTertiary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.messages.filter { $0.type != .system }.suffix(3))) { message in
                        messageBubble(message: message)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.huddleCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Messages Tab

    private func messagesTab() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Messages")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                Spacer()
                Button(action: { showExpandedChat = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Full Chat")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color.huddleCoral)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.huddleBackground)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder), alignment: .bottom)

        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    if viewModel.messages.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "message")
                                .font(.system(size: 48))
                                .foregroundColor(Color.huddleTextTertiary.opacity(0.35))
                                .padding(.top, 60)
                            Text("No messages yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.huddleTextPrimary)
                            Text("Be the first to say something!")
                                .font(.system(size: 14))
                                .foregroundColor(Color.huddleTextTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(viewModel.messages) { message in
                            if message.type == .system {
                                systemMessageView(message: message)
                            } else if message.type == .ping {
                                pingCard(message: message)
                            } else {
                                messageBubble(message: message)
                            }
                        }
                    }
                    Color.clear.frame(height: 1).id("msgBottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 14)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    proxy.scrollTo("msgBottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("msgBottom", anchor: .bottom)
                }
            }
        }
        } // end VStack for messagesTab
    }

    private func systemMessageView(message: HuddleMessage) -> some View {
        Text(message.content)
            .font(.system(size: 12))
            .foregroundColor(Color.huddleTextTertiary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.vertical, 2)
    }

    private func pingCard(message: HuddleMessage) -> some View {
        let label = message.content.replacingOccurrences(of: "📍", with: "").trimmingCharacters(in: .whitespaces)
        return HStack(spacing: 12) {
            Text("📍")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(label.isEmpty ? "Ping" : label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                Text("\(message.senderName) · \(formatTime(message.createdAt))")
                    .font(.caption)
                    .foregroundColor(Color.huddleTextTertiary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.huddleCoral.opacity(0.10))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.huddleCoral.opacity(0.25), lineWidth: 1))
        .padding(.vertical, 4)
    }

    private func messageBubble(message: HuddleMessage) -> some View {
        let isMe = message.senderID == authService.currentUser?.id
        let senderPhotoBase64 = viewModel.family?.members.first(where: { $0.id == message.senderID })?.photoBase64

        return HStack(alignment: .top, spacing: 8) {
            if isMe { Spacer(minLength: 48) }

            if !isMe {
                MemberAvatarView(name: message.senderName, photoBase64: senderPhotoBase64, size: 30)
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                if !isMe {
                    Text(message.senderName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.huddleTextSecondary)
                }
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(isMe ? .white : Color.huddleTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMe ? Color.huddleCoral : Color.huddleSurface)
                    .cornerRadius(14)
                    .contextMenu {
                        Menu("React") {
                            ForEach(["❤️", "😂", "👍", "😮", "😢", "🎉"], id: \.self) { emoji in
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.toggleReaction(message: message, emoji: emoji)
                                }) { Text(emoji) }
                            }
                        }
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.togglePinMessage(message)
                        }) {
                            Label(
                                message.isPinned ? "Unpin Message" : "Pin Message",
                                systemImage: message.isPinned ? "pin.slash" : "pin.fill"
                            )
                        }
                        if viewModel.isCurrentUserAdmin || message.senderID == authService.currentUser?.id {
                            Button(role: .destructive, action: { messageToDelete = message }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                if let reactions = message.reactions, !reactions.isEmpty {
                    reactionRow(reactions: reactions, message: message)
                }

                Text(formatTime(message.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(Color.huddleTextTertiary)
            }

            if !isMe { Spacer(minLength: 48) }
        }
    }

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
                        Text(emoji).font(.system(size: 12))
                        if users.count > 1 {
                            Text("\(users.count)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isMine ? Color.huddleCoral : Color.huddleTextTertiary)
                        }
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(isMine ? Color.huddleCoral.opacity(0.12) : Color.huddleSecondaryFixed)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isMine ? Color.huddleCoral.opacity(0.4) : Color.clear, lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Shopping Tab

    private func shoppingTab() -> some View {
        VStack(spacing: 0) {
            // Sub-header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shopping List")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary)
                    if !viewModel.shoppingItems.isEmpty {
                        let done = viewModel.shoppingItems.filter { $0.isCompleted }.count
                        Text("\(viewModel.shoppingItems.count) items · \(done) done")
                            .font(.system(size: 12))
                            .foregroundColor(Color.huddleTextTertiary)
                    }
                }
                Spacer()
                Button(action: { viewModel.showShoppingList = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add Items")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.huddleCoral)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.huddleBackground)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder), alignment: .bottom)

            ScrollView(showsIndicators: false) {
                if viewModel.shoppingItems.isEmpty {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.huddleSecondaryFixed)
                                .frame(width: 72, height: 72)
                            Image(systemName: "cart")
                                .font(.system(size: 30))
                                .foregroundColor(Color.huddleTextTertiary)
                        }
                        .padding(.top, 60)
                        Text("Your list is empty")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.huddleTextPrimary)
                        Text("Tap \"Add Items\" to get started")
                            .font(.system(size: 14))
                            .foregroundColor(Color.huddleTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.shoppingItems) { item in
                            HStack(spacing: 12) {
                                Button(action: { viewModel.toggleShoppingItem(item) }) {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 22))
                                        .foregroundColor(item.isCompleted ? Color.huddleCoral : Color.huddleTextTertiary.opacity(0.4))
                                }
                                Text(item.content)
                                    .font(.system(size: 15))
                                    .foregroundColor(item.isCompleted ? Color.huddleTextTertiary : Color.huddleTextPrimary)
                                    .strikethrough(item.isCompleted, color: Color.huddleTextTertiary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(Color.huddleCard)
                            .cornerRadius(12)
                            .opacity(item.isCompleted ? 0.65 : 1)
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Family Tab

    private func familyTab(family: Family) -> some View {
        let unique = Array(Dictionary(grouping: family.members, by: { $0.id }).compactMap { $0.value.first })

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                // Family code card
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.huddlePrimaryFixed)
                                .frame(width: 40, height: 40)
                            Image(systemName: "house.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.huddleCoral)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(family.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color.huddleTextPrimary)
                                if viewModel.isCurrentUserAdmin {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.huddleTextTertiary)
                                }
                            }
                            .onTapGesture {
                                if viewModel.isCurrentUserAdmin {
                                    newFamilyName = family.name
                                    showRenameAlert = true
                                }
                            }
                            Text("\(unique.count) members")
                                .font(.system(size: 13))
                                .foregroundColor(Color.huddleTextTertiary)
                        }
                        Spacer()
                    }

                    VStack(spacing: 6) {
                        Text(family.code)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(Color.huddleCoral)
                            .tracking(6)
                        Text("family invite code")
                            .font(.system(size: 12))
                            .foregroundColor(Color.huddleTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.huddleCoral.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.huddleCoral.opacity(0.15), lineWidth: 1))

                    HStack(spacing: 10) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            UIPasteboard.general.string = family.code
                            withAnimation { showCopiedToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { showCopiedToast = false }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc").font(.system(size: 13))
                                Text("Copy Code").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(Color.huddleCoral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.huddleCard)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.huddleBorder, lineWidth: 1.5))
                        }
                        ShareLink(item: family.code) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up").font(.system(size: 13))
                                Text("Share").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.huddleCoral)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(16)
                .background(Color.huddleCard)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

                // Members list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Members (\(unique.count))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary)

                    VStack(spacing: 0) {
                        ForEach(Array(unique.enumerated()), id: \.element.id) { index, member in
                            HStack(spacing: 12) {
                                let memberPhoto = member.id == authService.currentUser?.id
                                    ? (authService.currentUser?.photoBase64 ?? member.photoBase64)
                                    : member.photoBase64
                                MemberAvatarView(name: member.displayName, photoBase64: memberPhoto, size: 40)
                                Text(member.displayName)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.huddleTextPrimary)
                                if family.adminId == member.id {
                                    Text("Admin")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color.huddleCoral)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.huddleCoral.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 11)
                            .contextMenu {
                                if viewModel.isCurrentUserAdmin && member.id != authService.currentUser?.id {
                                    Button(role: .destructive) {
                                        memberToRemove = member
                                    } label: {
                                        Label("Remove from Group", systemImage: "person.crop.circle.badge.minus")
                                    }
                                    Button {
                                        viewModel.transferAdmin(to: member)
                                    } label: {
                                        Label("Make Admin", systemImage: "star.fill")
                                    }
                                }
                            }
                            if index < unique.count - 1 {
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.huddleCard)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

                Button(action: { showLeaveAlert = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 15))
                        Text("Leave Huddle")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "BA1A1A"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "BA1A1A").opacity(0.07))
                    .cornerRadius(12)
                }

                // Appearance toggle
                HStack {
                    Label("Appearance", systemImage: "moon.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color.huddleTextPrimary)
                    Spacer()
                    Picker("", selection: $colorSchemePreference) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 185)
                }
                .padding(16)
                .background(Color.huddleCard)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Ping Tray

    private var pingTrayView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Send a ping")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(pingOptions, id: \.self) { label in
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.sendPing(content: "📍 \(label)")
                        showPingTray = false
                    } label: {
                        HStack(spacing: 10) {
                            Text("📍").font(.title2)
                            Text(label)
                                .font(.subheadline)
                                .fontWeight(.medium)
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
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Share Sheet

    private var shareSheet: some View {
        if let family = viewModel.family {
            return AnyView(
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.huddleBorder)
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 20)

                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.huddleCoral.opacity(0.1))
                                .frame(width: 64, height: 64)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 28))
                                .foregroundColor(Color.huddleCoral)
                        }
                        VStack(spacing: 6) {
                            Text("Invite to \(family.name)")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color.huddleTextPrimary)
                            Text("Share this code with family members")
                                .font(.system(size: 14))
                                .foregroundColor(Color.huddleTextTertiary)
                        }
                        VStack(spacing: 6) {
                            Text(family.code)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color.huddleCoral)
                                .tracking(6)
                            Text("family code")
                                .font(.system(size: 12))
                                .foregroundColor(Color.huddleTextTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.huddleCoral.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.huddleCoral.opacity(0.15), lineWidth: 1))

                        HStack(spacing: 12) {
                            Button(action: {
                                UIPasteboard.general.string = family.code
                                viewModel.showShareSheet = false
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Code")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.huddleCoral)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.huddleCard)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.huddleBorder, lineWidth: 1.5))
                            }
                            ShareLink(item: family.code) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.huddleCoral)
                                .cornerRadius(10)
                            }
                        }
                        Button("Done") { viewModel.showShareSheet = false }
                            .font(.system(size: 14))
                            .foregroundColor(Color.huddleTextTertiary)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .presentationDetents([.medium])
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return "just now" }
        if s < 3600 { return "\(s / 60)m ago" }
        if s < 86400 { return "\(s / 3600)h ago" }
        return "\(s / 86400)d ago"
    }
}

// MARK: - Isolated input bar — owns its own state so typing never rebuilds the message list

private struct MessageInputBar: View {
    let onSend: (String) -> Void
    let onPingTap: () -> Void

    @State private var messageText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onPingTap()
            } label: {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.huddleCoral)
            }

            HStack(spacing: 8) {
                TextField("Message your family...", text: $messageText)
                    .font(.system(size: 15))
                    .foregroundColor(Color.huddleTextPrimary)
                    .focused($isFocused)
                    .onSubmit { send() }
                if !messageText.isEmpty {
                    Button(action: { messageText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.huddleTextTertiary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.huddleBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isFocused ? Color.huddleCoral : Color.huddleBorder, lineWidth: 1.5)
            )

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        messageText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.huddleTextTertiary.opacity(0.3)
                            : Color.huddleCoral
                    )
                    .clipShape(Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.huddleCard)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder), alignment: .top)
    }

    private func send() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSend(text)
        messageText = ""
    }
}

#Preview {
    FamilyFeedView(authService: AuthService(), openToShopping: .constant(false))
        .environmentObject(AuthService())
}
