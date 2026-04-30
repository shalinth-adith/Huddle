import SwiftUI

struct FamilyFeedView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: FamilyFeedViewModel
    @State private var messageText: String = ""
    @Binding var openToShopping: Bool

    @FocusState private var isMessageFieldFocused: Bool
    @State private var selectedTab: FeedTab = .home
    @State private var showLeaveAlert = false
    @State private var showRenameAlert = false
    @State private var newFamilyName = ""
    @State private var showGroupSwitcher = false
    @State private var showPingTray = false
    @State private var customPingText = ""

    private let pingOptions: [(emoji: String, label: String)] = [
        ("🏠", "I'm home"),
        ("🚗", "On my way"),
        ("🏫", "Leaving school"),
        ("⏰", "Running late"),
        ("🛒", "At the store"),
        ("📍", "Be there soon")
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
                            messageInputBar
                        }
                        tabBar
                    }
                }
                .sheet(isPresented: $showPingTray) {
                    pingTrayView
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            } else {
                Text("Error loading family")
                    .foregroundColor(Color.huddleTextTertiary)
            }
        }
        .preferredColorScheme(.light)
        .buttonStyle(.plain)
        .onTapGesture { isMessageFieldFocused = false }
        .onAppear {
            viewModel.loadFamily()
            viewModel.loadMessages()
            viewModel.loadShoppingItems()
            viewModel.loadPinnedMessages()
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
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.activeIcon : tab.icon)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == tab ? Color.huddleCoral : Color.huddleTextTertiary.opacity(0.5))
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
            Color.white
                .ignoresSafeArea(edges: .bottom)    // fills the home-indicator gap
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
                            MemberAvatarView(name: member.displayName, photoBase64: member.photoBase64, size: 48)
                            Text(member.displayName.components(separatedBy: " ").first ?? member.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.huddleTextSecondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
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
        .background(Color.white)
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
                    Button(action: { viewModel.togglePinMessage(message) }) {
                        Label("Unpin Message", systemImage: "pin.slash")
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Messages Tab

    private func messagesTab() -> some View {
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)
        }
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
        HStack(spacing: 12) {
            Text(String(message.content.prefix(2)))
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(message.content.dropFirst(2).trimmingCharacters(in: .whitespaces))
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
        let isMe = message.senderName == authService.currentUser?.displayName
        let senderPhotoBase64 = viewModel.family?.members.first(where: { $0.displayName == message.senderName })?.photoBase64

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
                        Button(action: { viewModel.togglePinMessage(message) }) {
                            Label(
                                message.isPinned ? "Unpin Message" : "Pin Message",
                                systemImage: message.isPinned ? "pin.slash" : "pin.fill"
                            )
                        }
                        if viewModel.isCurrentUserAdmin || message.senderID == authService.currentUser?.id {
                            Button(role: .destructive, action: { viewModel.deleteMessage(message) }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                Text(formatTime(message.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(Color.huddleTextTertiary)
            }

            if !isMe { Spacer(minLength: 48) }
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
                            .background(Color.white)
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
                        Button(action: { UIPasteboard.general.string = family.code }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc").font(.system(size: 13))
                                Text("Copy Code").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(Color.huddleCoral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.white)
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
                .background(Color.white)
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
                                MemberAvatarView(name: member.displayName, photoBase64: member.photoBase64, size: 40)
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
                                        viewModel.removeMember(member)
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
                .background(Color.white)
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Message Input

    private var pingTrayView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Send a ping")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(pingOptions, id: \.label) { option in
                    Button {
                        viewModel.sendPing(content: "\(option.emoji) \(option.label)")
                        showPingTray = false
                    } label: {
                        HStack(spacing: 10) {
                            Text(option.emoji).font(.title2)
                            Text(option.label)
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

            Divider().padding(.horizontal)

            VStack(alignment: .leading, spacing: 6) {
                Text("Custom location")
                    .font(.caption)
                    .foregroundColor(Color.huddleTextTertiary)
                    .padding(.horizontal)

                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Text("📍")
                            .font(.system(size: 20))
                        TextField("Where are you going?", text: $customPingText)
                            .font(.subheadline)
                            .autocorrectionDisabled(true)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.huddleSurface)
                    .cornerRadius(12)

                    Button {
                        let trimmed = customPingText.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        viewModel.sendPing(content: "📍 \(trimmed)")
                        customPingText = ""
                        showPingTray = false
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                customPingText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.huddleTextTertiary.opacity(0.3)
                                    : Color.huddleCoral
                            )
                            .clipShape(Circle())
                    }
                    .disabled(customPingText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var messageInputBar: some View {
        HStack(spacing: 10) {
            Button { showPingTray = true } label: {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.huddleCoral)
            }

            HStack(spacing: 8) {
                TextField("Message your family...", text: $messageText)
                    .font(.system(size: 15))
                    .foregroundColor(Color.huddleTextPrimary)
                    .focused($isMessageFieldFocused)
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
                    .stroke(isMessageFieldFocused ? Color.huddleCoral : Color.huddleBorder, lineWidth: 1.5)
            )

            Button(action: {
                guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                viewModel.sendMessage(content: messageText)
                messageText = ""
                isMessageFieldFocused = false
            }) {
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
        .background(Color.white)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder), alignment: .top)
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
                                .background(Color.white)
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
                .preferredColorScheme(.light)
                .presentationDetents([.medium])
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    // MARK: - Helpers

    private func getInitials(from name: String) -> String {
        String(name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }

    private func formatTime(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return "just now" }
        if s < 3600 { return "\(s / 60)m ago" }
        if s < 86400 { return "\(s / 3600)h ago" }
        return "\(s / 86400)d ago"
    }
}

#Preview {
    FamilyFeedView(authService: AuthService(), openToShopping: .constant(false))
        .environmentObject(AuthService())
}
