import SwiftUI
import Combine
import PhotosUI

struct FamilyFeedView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: FamilyFeedViewModel
    @Binding var openToShopping: Bool

    @AppStorage("huddleColorScheme") private var colorSchemePreference: Int = 0

    @State private var selectedTab: FeedTab = .home
    @State private var showLeaveAlert = false
    @State private var showRenameAlert = false
    @State private var newFamilyName = ""
    @State private var showPingTray = false
    @State private var messageToDelete: HuddleMessage?
    @State private var memberToRemove: Member?
    @State private var showCopiedToast = false
    @State private var showExpandedChat = false
    @State private var showTimeCapsule = false
    @State private var showAskHuddle = false
    @State private var showMediaGallery = false

    // Lush animation states
    @State private var floatPhase = false

    private let pingOptions: [String] = [
        "I'm home", "On my way", "Leaving school", "Running late", "At the store", "Be there soon"
    ]

    enum FeedTab: CaseIterable {
        case home, messages, calendar, shopping, family

        var icon: String {
            switch self {
            case .home:     return "house"
            case .messages: return "message"
            case .calendar: return "calendar"
            case .shopping: return "cart"
            case .family:   return "person.2"
            }
        }
        var activeIcon: String {
            switch self {
            case .home:     return "house.fill"
            case .messages: return "message.fill"
            case .calendar: return "calendar"
            case .shopping: return "cart.fill"
            case .family:   return "person.2.fill"
            }
        }
        var label: String {
            switch self {
            case .home:     return "Home"
            case .messages: return "Messages"
            case .calendar: return "Calendar"
            case .shopping: return "Shopping"
            case .family:   return "Family"
            }
        }
    }

    private let messageService: MessageService
    private let capsuleService: CapsuleService
    private let onBack: () -> Void

    @StateObject private var eventsViewModel: EventsViewModel

    init(familyService: FamilyService, messageService: MessageService,
         eventService: EventService, capsuleService: CapsuleService,
         authService: AuthService,
         openToShopping: Binding<Bool>, onBack: @escaping () -> Void) {
        self.messageService = messageService
        self.capsuleService = capsuleService
        self.onBack = onBack
        _viewModel = StateObject(wrappedValue: FamilyFeedViewModel(
            familyService: familyService,
            authService: authService,
            messageService: messageService
        ))
        _eventsViewModel = StateObject(wrappedValue: EventsViewModel(
            eventService: eventService,
            authService: authService
        ))
        _openToShopping = openToShopping
    }

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.38)

            if showCopiedToast {
                VStack {
                    Spacer()
                    Text("Code copied!")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(Color.black.opacity(0.75)).cornerRadius(24)
                        .padding(.bottom, 100)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                .zIndex(2)
                .animation(.easeInOut(duration: 0.2), value: showCopiedToast)
            }

            if viewModel.isLoading {
                ProgressView().tint(Color(hex: "FF8A66"))
            } else if let family = viewModel.family {
                VStack(spacing: 0) {
                    headerBar(family: family)
                    tabContent(family: family)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        if selectedTab == .messages {
                            MessageInputBar(
                                onSend: { viewModel.sendMessage(content: $0) },
                                onSendPhoto: { image, caption in viewModel.sendPhoto(image: image, caption: caption) },
                                onPingTap: { showPingTray = true }
                            )
                        }
                        lushTabBar
                    }
                }
            } else {
                Text("Error loading family")
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.5))
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showPingTray) {
            pingTrayView.presentationDetents([.medium]).presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showExpandedChat) {
            ExpandedChat(viewModel: viewModel).environmentObject(authService)
        }
        .buttonStyle(.plain)
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .onAppear {
            viewModel.loadFamily()
            viewModel.loadMessages()
            viewModel.loadShoppingItems()
            viewModel.loadPinnedMessages()
            if selectedTab == .messages { viewModel.markMessagesAsRead() }
            // Widget "shopping" deep link may have set this before the feed appeared.
            if openToShopping { selectedTab = .shopping; openToShopping = false }
            floatPhase = true
        }
        .onChange(of: selectedTab) { tab in
            if tab == .messages { viewModel.markMessagesAsRead() }
        }
        .onDisappear { viewModel.cleanup() }
        .alert("Leave Huddle?", isPresented: $showLeaveAlert) {
            Button("Leave", role: .destructive) { viewModel.leaveGroup { onBack() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.family.map { $0.members.count <= 1 } == true
                 ? "You're the last member — leaving will permanently delete this group and all its messages."
                 : "You will be removed from this group.")
        }
        .alert("Rename Group", isPresented: $showRenameAlert) {
            TextField("Group name", text: $newFamilyName)
            Button("Save") { viewModel.renameFamily(newFamilyName) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Message?", isPresented: Binding(get: { messageToDelete != nil }, set: { if !$0 { messageToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let msg = messageToDelete { viewModel.deleteMessage(msg) }
                messageToDelete = nil
            }
            Button("Cancel", role: .cancel) { messageToDelete = nil }
        } message: { Text("This message will be permanently deleted.") }
        .alert("Remove Member?", isPresented: Binding(get: { memberToRemove != nil }, set: { if !$0 { memberToRemove = nil } })) {
            Button("Remove", role: .destructive) {
                if let m = memberToRemove { viewModel.removeMember(m) }
                memberToRemove = nil
            }
            Button("Cancel", role: .cancel) { memberToRemove = nil }
        } message: {
            if let m = memberToRemove { Text("\(m.displayName) will be removed from the group.") }
        }
        .onChange(of: openToShopping) { newValue in
            if newValue { selectedTab = .shopping; openToShopping = false }
        }
        .sheet(isPresented: $viewModel.showShareSheet) { shareSheet }
        .sheet(isPresented: $viewModel.showShoppingList, onDismiss: { viewModel.loadShoppingItems() }) {
            if let family = viewModel.family {
                ShoppingList(family: family, messageService: messageService)
                    .environmentObject(authService)
            }
        }
        .fullScreenCover(isPresented: $showTimeCapsule) {
            TimeCapsuleView(capsuleService: capsuleService, authService: authService)
                .environmentObject(authService)
        }
        .fullScreenCover(isPresented: $showMediaGallery) {
            MediaGalleryView(messageService: messageService, authService: authService)
                .environmentObject(authService)
        }
        .fullScreenCover(isPresented: $showAskHuddle) {
            AskHuddleView(
                familyName: viewModel.family?.name ?? "your family",
                recentMessages: viewModel.messages.suffix(40).compactMap { msg in
                    switch msg.type {
                    case .system: return nil
                    case .photo:  return "\(msg.senderName): [photo]"
                    default:      return "\(msg.senderName): \(msg.content)"
                    }
                }
            )
        }
    }

    // MARK: - Lush Tab Bar

    private var lushTabBar: some View {
        HStack(spacing: 0) {
            ForEach(FeedTab.allCases, id: \.self) { tab in
                Button(action: {
                    if selectedTab != tab { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tab }
                    if tab == .messages { viewModel.markMessagesAsRead() }
                }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: selectedTab == tab ? tab.activeIcon : tab.icon)
                                .font(.system(size: 21))
                                .foregroundColor(selectedTab == tab ? Color(hex: "FF8A66") : Color.huddleTextPrimary.opacity(0.50))
                            if tab == .messages && viewModel.unreadCount > 0 && selectedTab != .messages {
                                Circle().fill(Color(hex: "FF8A66")).frame(width: 8, height: 8)
                                    .shadow(color: Color(hex: "FF8A66").opacity(0.8), radius: 4)
                                    .offset(x: 4, y: -2)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        Text(tab.label)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? Color(hex: "FF8A66") : Color.huddleTextPrimary.opacity(0.50))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab
                            ? RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: [Color(hex: "FF8A66").opacity(0.14), Color(hex: "FF8A66").opacity(0.04)], startPoint: .top, endPoint: .bottom))
                                .padding(.horizontal, 4)
                            : nil
                    )
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.huddleGlassFill)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.huddleOutlineVariant, lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 0)
                .overlay(
                    VStack {
                        LinearGradient(colors: [Color(hex: "FFE6D2").opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(height: 1).padding(.horizontal, 20)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                )
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 30)
        .background(
            LinearGradient(colors: [.clear, Color.huddleBackground.opacity(0.9), Color.huddleBackground], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Tab Router

    @ViewBuilder
    private func tabContent(family: Family) -> some View {
        switch selectedTab {
        case .home:     homeTab(family: family)
        case .messages: messagesTab()
        case .calendar: CalendarView(viewModel: eventsViewModel, members: family.members)
        case .shopping: shoppingTab()
        case .family:   familyTab(family: family)
        }
    }

    // MARK: - Header

    private func headerBar(family: Family) -> some View {
        HStack(spacing: 10) {
            Button(action: { UIImpactFeedbackGenerator(style: .light).impactOccurred(); onBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(Color.huddleGlassFill)
                            .overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1))
                    )
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(family.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.huddleTextPrimary)
                    .tracking(-0.3)
                    .lineLimit(1)
                Text("\(family.members.count) member\(family.members.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.45))
            }
            Spacer()
            HStack(spacing: 10) {
                GlassCircleButton(systemImage: "photo.on.rectangle.angled", action: { showMediaGallery = true })
                ZStack(alignment: .topTrailing) {
                    GlassCircleButton(systemImage: "bell", action: { viewModel.showShareSheet = true })
                    Circle().fill(Color(hex: "FF8A66")).frame(width: 8, height: 8)
                        .shadow(color: Color(hex: "FF8A66").opacity(0.8), radius: 4)
                        .offset(x: 2, y: 0)
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
        .padding(.top, 44)
        .background(
            LinearGradient(colors: [Color.huddleBackground, Color.huddleBackground.opacity(0)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Home Tab

    private func homeTab(family: Family) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                heroCard(family: family)
                quickActionsRow
                membersCard(family: family)
                shoppingPreviewCard()
                if !viewModel.pinnedMessages.isEmpty { pinnedCard() }
                chatPreviewCard()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Quick Actions (Time Capsule + Ask Huddle)

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            quickActionCard(title: "Time Capsule", subtitle: "Send to the future", icon: "hourglass", action: { showTimeCapsule = true })
            quickActionCard(title: "Ask Huddle", subtitle: "Your AI helper", icon: "sparkles", action: { showAskHuddle = true })
        }
    }

    private func quickActionCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color(hex: "FF8A66").opacity(0.12)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                    Text(subtitle).font(.system(size: 11)).foregroundColor(Color.huddleTextPrimary.opacity(0.5)).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.huddleGlassFill)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.huddleBorder, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Orbital Hero Card

    private func heroCard(family: Family) -> some View {
        // Dedup by id while preserving Firestore array order (join order).
        // Dictionary(grouping:) had non-deterministic iteration order, so members
        // visibly reshuffled on every re-render (e.g. toggling light/dark mode).
        let unique = Array(family.members.reduce(into: [Member]()) { acc, m in
            if !acc.contains(where: { $0.id == m.id }) { acc.append(m) }
        }.prefix(3))
        let lushColors: [LushColor] = [.rose, .amber, .plum]
        let angles: [Double] = [0, 120, 240]
        let floatAmounts: [CGFloat] = [4, 5, 3]
        let durations: [Double] = [2.0, 2.3, 2.6]

        // Ticker items
        let recentMessages = viewModel.messages.filter { $0.type == .text }.suffix(3)
        let tickerItems: [(String, String)] = recentMessages.isEmpty
            ? [("All together", "right now"), ("Huddle with family", "today"), ("Connected", "always")]
            : recentMessages.map { ($0.senderName, "sent a message") }

        return ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FF8A66"), Color(hex: "E85A7A"), Color(hex: "4A1020")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            // Glow orb
            Circle()
                .fill(Color.white.opacity(0.15)).frame(width: 200, height: 200)
                .blur(radius: 40).offset(x: 60, y: -60)

            VStack(spacing: 14) {
                // Orbital system
                ZStack {
                    // Dashed orbit ring
                    Circle()
                        .stroke(Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: 134, height: 134)

                    // Center monogram
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 64, height: 64)
                            .shadow(color: Color(hex: "FF8A66").opacity(0.7), radius: 14)
                        Text(String(family.name.prefix(1)).uppercased())
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // Orbital avatars
                    ForEach(Array(unique.enumerated()), id: \.element.id) { idx, member in
                        let angle = angles[idx % 3]
                        let x = CGFloat(cos((angle - 90) * .pi / 180)) * 67
                        let y = CGFloat(sin((angle - 90) * .pi / 180)) * 67

                        ZStack(alignment: .bottomTrailing) {
                            LushAvatar(
                                letter: String(member.displayName.prefix(1)),
                                lushColor: lushColors[idx % 3],
                                size: 36,
                                photoBase64: member.photoBase64
                            )
                            Circle()
                                .fill(Color(hex: "7CFFA8"))
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(.black.opacity(0.3), lineWidth: 1.5))
                                .offset(x: 2, y: 2)
                        }
                        .offset(x: x, y: y + (floatPhase ? -floatAmounts[idx % 3] : 0))
                        .animation(
                            .easeInOut(duration: durations[idx % 3]).repeatForever(autoreverses: true).delay(Double(idx) * 0.25),
                            value: floatPhase
                        )
                    }
                }
                .frame(width: 180, height: 180)

                // Family name + subhead
                VStack(spacing: 4) {
                    Text(family.name.uppercased())
                        .font(.system(size: 10, weight: .bold)).tracking(1.5)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(family.members.count) hearts, all glowing")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white).tracking(-0.5)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }

                // Live ticker
                LiveTickerView(items: tickerItems)
            }
            .padding(20)
        }
        .cornerRadius(26)
        .shadow(color: Color(hex: "D8512B").opacity(0.4), radius: 22, x: 0, y: 10)
    }

    // MARK: - Members Card

    private func membersCard(family: Family) -> some View {
        // Dedup by id preserving join order — see note at the avatar stack.
        let unique = family.members.reduce(into: [Member]()) { acc, m in
            if !acc.contains(where: { $0.id == m.id }) { acc.append(m) }
        }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                LushEyebrow(text: "Members")
                Spacer()
                Button(action: { withAnimation(.easeInOut(duration: 0.18)) { selectedTab = .family } }) {
                    Text("See All")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "FF8A66"))
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(unique) { member in
                        VStack(spacing: 6) {
                            let photo = member.id == authService.currentUser?.id
                                ? (authService.currentUser?.photoBase64 ?? member.photoBase64)
                                : member.photoBase64
                            MemberAvatarView(name: member.displayName, photoBase64: photo, size: 48)
                            Text(member.displayName.components(separatedBy: " ").first ?? member.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.huddleTextPrimary.opacity(0.72))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.huddleGlassFill)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.huddleBorder, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    // MARK: - Shopping Preview

    private func shoppingPreviewCard() -> some View {
        let items = viewModel.shoppingItems
        let preview = Array(items.prefix(3))
        let remaining = max(0, items.count - 3)
        let done = items.filter { $0.isCompleted }.count
        let progress: CGFloat = items.isEmpty ? 0 : CGFloat(done) / CGFloat(items.count)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    ClayIcon(systemImage: "cart.fill", lushColor: .amber, size: 32)
                    Text("Shopping List")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                }
                Spacer()
                Button(action: { withAnimation(.easeInOut(duration: 0.18)) { selectedTab = .shopping } }) {
                    Text("View All")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "FF8A66"))
                }
            }

            if !items.isEmpty {
                // Progress arc
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 4)
                            .frame(width: 46, height: 46)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(colors: [Color(hex: "FFB68A"), Color(hex: "E85A7A")], startPoint: .leading, endPoint: .trailing),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 46, height: 46)
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(Color.huddleTextPrimary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(items.count - done) items to grab")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                        Text("\(done) of \(items.count) done")
                            .font(.system(size: 11)).foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                    }
                    Spacer()
                }
            }

            if items.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "cart").font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.4))
                    Text("No items yet").font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(preview) { item in
                        HStack(spacing: 10) {
                            Button(action: { viewModel.toggleShoppingItem(item) }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(item.isCompleted ? Color(hex: "FF8A66") : Color.huddleTextPrimary.opacity(0.35))
                            }
                            Text(item.content)
                                .font(.system(size: 14)).foregroundColor(item.isCompleted ? Color.huddleTextPrimary.opacity(0.45) : .white)
                                .strikethrough(item.isCompleted, color: Color.huddleTextPrimary.opacity(0.45))
                            Spacer()
                        }
                    }
                    if remaining > 0 {
                        Text("+\(remaining) more items")
                            .font(.system(size: 12)).foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.huddleGlassFill)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.huddleBorder, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    // MARK: - Pinned Card

    private func pinnedCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ClayIcon(systemImage: "pin.fill", lushColor: .amber, size: 28)
                Text("Pinned").font(.system(size: 15, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                Spacer()
            }
            ForEach(viewModel.pinnedMessages) { message in
                HStack {
                    Text(message.content).font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.9))
                    Spacer()
                }
                .padding(12)
                .background(Color(hex: "FF8A66").opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "FF8A66").opacity(0.2), lineWidth: 1))
                .contextMenu {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.togglePinMessage(message)
                    }) { Label("Unpin Message", systemImage: "pin.slash") }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.huddleGlassFill)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.huddleBorder, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    // MARK: - Chat Preview Card

    private func chatPreviewCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    ClayIcon(systemImage: "message.fill", lushColor: .rose, size: 28)
                    Text("Huddle Chat").font(.system(size: 15, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                }
                Spacer()
                Button(action: { withAnimation(.easeInOut(duration: 0.18)) { selectedTab = .messages } }) {
                    Text("Open Chat").font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "FF8A66"))
                }
            }
            if viewModel.messages.isEmpty {
                Text("No messages yet. Start chatting!")
                    .font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.45)).padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.messages.filter { $0.type != .system }.suffix(3))) { msg in
                        messageBubble(message: msg)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.huddleGlassFill)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.huddleBorder, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    // MARK: - Messages Tab

    private func messagesTab() -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    LushEyebrow(text: "Family chat")
                    Text(viewModel.family?.name ?? "Chat")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(Color.huddleTextPrimary).tracking(-0.5)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.huddleBackground.opacity(0.6))

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if viewModel.messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "message").font(.system(size: 48)).foregroundColor(Color.huddleTextPrimary.opacity(0.2)).padding(.top, 60)
                                Text("No messages yet").font(.system(size: 18, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                                Text("Be the first to say something!").font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                            }.frame(maxWidth: .infinity)
                        } else {
                            // Date pill
                            HStack {
                                Spacer()
                                Text("Today")
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                                    .padding(.horizontal, 12).padding(.vertical, 4)
                                    .background(Color.huddleGlassFill)
                                    .cornerRadius(999)
                                    .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.huddleBorder, lineWidth: 1))
                                Spacer()
                            }
                            ForEach(viewModel.messages) { message in
                                if message.type == .system { systemMessageView(message: message) }
                                else if message.type == .ping { pingCard(message: message) }
                                else { messageBubble(message: message) }
                            }
                        }
                        Color.clear.frame(height: 1).id("msgBottom")
                    }
                    .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 10)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { proxy.scrollTo("msgBottom", anchor: .bottom) }
                }
                .onChange(of: viewModel.messages.count) { _ in
                    proxy.scrollTo("msgBottom", anchor: .bottom)
                }
            }
        }
    }

    private func systemMessageView(message: HuddleMessage) -> some View {
        Text(message.content)
            .font(.system(size: 11)).foregroundColor(Color.huddleTextPrimary.opacity(0.4))
            .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.vertical, 2)
    }

    private func pingCard(message: HuddleMessage) -> some View {
        let label = message.content.replacingOccurrences(of: "📍", with: "").trimmingCharacters(in: .whitespaces)
        return HStack(spacing: 12) {
            Text("📍").font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(label.isEmpty ? "Ping" : label).font(.system(size: 14, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                Text("\(message.senderName) · \(formatTime(message.createdAt))").font(.caption).foregroundColor(Color.huddleTextPrimary.opacity(0.5))
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "FF8A66").opacity(0.10)).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "FF8A66").opacity(0.25), lineWidth: 1))
        .padding(.vertical, 2)
    }

    private func messageBubble(message: HuddleMessage) -> some View {
        let isMe = message.senderID == authService.currentUser?.id
        let senderPhoto = viewModel.family?.members.first(where: { $0.id == message.senderID })?.photoBase64
        return HStack(alignment: .top, spacing: 8) {
            if isMe { Spacer(minLength: 48) }
            if !isMe {
                MemberAvatarView(name: message.senderName, photoBase64: senderPhoto, size: 30)
            }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                if !isMe {
                    Text(message.senderName)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                        .padding(.leading, 6)
                }
                Group {
                    if message.type == .photo {
                        PhotoMessageView(message: message, isMe: isMe, viewModel: viewModel)
                    } else {
                        Text(message.content)
                            .font(.system(size: 14))
                            .foregroundColor(isMe ? .white : Color.huddleTextPrimary)
                            .padding(.horizontal, 12).padding(.vertical, 9)
                            .background(
                                isMe
                                    ? AnyView(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "F26A45"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom)
                                        .cornerRadius(16).shadow(color: Color(hex: "D8512B").opacity(0.35), radius: 6, x: 0, y: 3))
                                    : AnyView(Color.huddleGlassFill
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.huddleBorder, lineWidth: 1)))
                            )
                    }
                }
                .contextMenu {
                    Menu("React") {
                        ForEach(["❤️","😂","👍","😮","😢","🎉"], id: \.self) { emoji in
                            Button(action: { UIImpactFeedbackGenerator(style: .light).impactOccurred(); viewModel.toggleReaction(message: message, emoji: emoji) }) { Text(emoji) }
                        }
                    }
                    Button(action: { UIImpactFeedbackGenerator(style: .light).impactOccurred(); viewModel.togglePinMessage(message) }) {
                        Label(message.isPinned ? "Unpin" : "Pin", systemImage: message.isPinned ? "pin.slash" : "pin.fill")
                    }
                    if viewModel.isCurrentUserAdmin || message.senderID == authService.currentUser?.id {
                        Button(role: .destructive, action: { messageToDelete = message }) { Label("Delete", systemImage: "trash") }
                    }
                }
                if let reactions = message.reactions, !reactions.isEmpty { reactionRow(reactions: reactions, message: message) }
                Text(formatTime(message.createdAt))
                    .font(.system(size: 10)).foregroundColor(Color.huddleTextPrimary.opacity(0.35))
            }
            if !isMe { Spacer(minLength: 48) }
        }
    }

    private func reactionRow(reactions: [String: [String]], message: HuddleMessage) -> some View {
        let sorted = reactions.sorted { $0.value.count > $1.value.count }
        return HStack(spacing: 5) {
            ForEach(sorted, id: \.key) { emoji, users in
                let isMine = users.contains(authService.currentUser?.id ?? "")
                Button(action: { UIImpactFeedbackGenerator(style: .light).impactOccurred(); viewModel.toggleReaction(message: message, emoji: emoji) }) {
                    HStack(spacing: 3) {
                        Text(emoji).font(.system(size: 12))
                        if users.count > 1 {
                            Text("\(users.count)").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isMine ? Color(hex: "FF8A66") : Color.huddleTextPrimary.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(isMine ? Color(hex: "FF8A66").opacity(0.14) : Color.huddleGlassFill)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isMine ? Color(hex: "FF8A66").opacity(0.4) : Color.clear, lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Shopping Tab

    private func shoppingTab() -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    LushEyebrow(text: "Shared list")
                    Text("Groceries").font(.system(size: 20, weight: .bold)).foregroundColor(Color.huddleTextPrimary).tracking(-0.5)
                }
                Spacer()
                Button(action: { viewModel.showShoppingList = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                        Text("Add Items").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom).cornerRadius(10))
                    .shadow(color: Color(hex: "D8512B").opacity(0.35), radius: 6, x: 0, y: 3)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            ScrollView(showsIndicators: false) {
                if viewModel.shoppingItems.isEmpty {
                    VStack(spacing: 14) {
                        ClayIcon(systemImage: "cart", lushColor: .slate, size: 60).padding(.top, 60)
                        Text("Your list is empty").font(.system(size: 18, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                        Text("Tap \"Add Items\" to get started").font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                    }.frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.shoppingItems) { item in
                            HStack(spacing: 12) {
                                Button(action: { viewModel.toggleShoppingItem(item) }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(item.isCompleted
                                                  ? LinearGradient(colors: [Color(hex: "FFB68A"), Color(hex: "F26A45")], startPoint: .top, endPoint: .bottom)
                                                  : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                                            .frame(width: 24, height: 24)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(item.isCompleted ? Color.clear : Color(hex: "FFC8AA").opacity(0.35), lineWidth: 1.5))
                                        if item.isCompleted {
                                            Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                                        }
                                    }
                                }
                                Text(item.content)
                                    .font(.system(size: 15)).foregroundColor(item.isCompleted ? Color.huddleTextPrimary.opacity(0.4) : Color.huddleTextPrimary)
                                    .strikethrough(item.isCompleted, color: Color.huddleTextPrimary.opacity(0.4))
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.huddleGlassFill)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.huddleBorder, lineWidth: 1))
                            )
                            .opacity(item.isCompleted ? 0.7 : 1)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Family Tab

    private func familyTab(family: Family) -> some View {
        // Dedup by id preserving join order — see note at the avatar stack.
        let unique = family.members.reduce(into: [Member]()) { acc, m in
            if !acc.contains(where: { $0.id == m.id }) { acc.append(m) }
        }
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // Family code card
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        ClayIcon(systemImage: "house.fill", lushColor: .coral, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(family.name).font(.system(size: 17, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                                if viewModel.isCurrentUserAdmin {
                                    Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                                }
                            }
                            .onTapGesture {
                                if viewModel.isCurrentUserAdmin { newFamilyName = family.name; showRenameAlert = true }
                            }
                            Text("\(unique.count) members").font(.system(size: 13)).foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                        }
                        Spacer()
                    }

                    VStack(spacing: 6) {
                        Text(family.code)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(Color(hex: "FF8A66")).tracking(6)
                        Text("family invite code").font(.system(size: 12)).foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color(hex: "FF8A66").opacity(0.06)).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "FF8A66").opacity(0.2), lineWidth: 1))

                    HStack(spacing: 10) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            UIPasteboard.general.string = family.code
                            withAnimation { showCopiedToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { showCopiedToast = false } }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc").font(.system(size: 13))
                                Text("Copy Code").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "FF8A66")).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.huddleGlassFill).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "FF8A66").opacity(0.3), lineWidth: 1))
                        }
                        ShareLink(item: family.code) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up").font(.system(size: 13))
                                Text("Share").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom).cornerRadius(12))
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.huddleGlassFill).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.huddleBorder, lineWidth: 1)))
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)

                // Members list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Members (\(unique.count))").font(.system(size: 15, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                    VStack(spacing: 0) {
                        ForEach(Array(unique.enumerated()), id: \.element.id) { idx, member in
                            HStack(spacing: 12) {
                                let photo = member.id == authService.currentUser?.id
                                    ? (authService.currentUser?.photoBase64 ?? member.photoBase64)
                                    : member.photoBase64
                                MemberAvatarView(name: member.displayName, photoBase64: photo, size: 40)
                                Text(member.displayName).font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary)
                                if family.adminId == member.id {
                                    Text("Admin").font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: "FF8A66"))
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color(hex: "FF8A66").opacity(0.12)).cornerRadius(4)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 11)
                            .contextMenu {
                                if viewModel.isCurrentUserAdmin && member.id != authService.currentUser?.id {
                                    Button(role: .destructive) { memberToRemove = member } label: { Label("Remove", systemImage: "person.crop.circle.badge.minus") }
                                    Button { viewModel.transferAdmin(to: member) } label: { Label("Make Admin", systemImage: "star.fill") }
                                }
                            }
                            if idx < unique.count - 1 { Divider().padding(.leading, 52).overlay(Color.huddleBorder) }
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.huddleGlassFill).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.huddleBorder, lineWidth: 1)))
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)

                // Leave button
                Button(action: { showLeaveAlert = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 15))
                        Text("Leave Huddle").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(hex: "FF6B6B").opacity(0.08)).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "FF6B6B").opacity(0.2), lineWidth: 1))
                }

                // Appearance picker
                HStack {
                    Label("Appearance", systemImage: "moon.fill")
                        .font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary)
                    Spacer()
                    Picker("", selection: $colorSchemePreference) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented).frame(width: 185)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.huddleGlassFill).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.huddleBorder, lineWidth: 1)))
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 16)
        }
    }

    // MARK: - Ping Tray

    private var pingTrayView: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text("Send a ping").font(.system(size: 17, weight: .semibold)).foregroundColor(Color.huddleTextPrimary).padding(.horizontal)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(pingOptions, id: \.self) { label in
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.sendPing(content: "📍 \(label)")
                            showPingTray = false
                        } label: {
                            HStack(spacing: 10) {
                                Text("📍").font(.title3)
                                Text(label).font(.subheadline).fontWeight(.medium)
                                Spacer()
                            }
                            .foregroundColor(Color.huddleTextPrimary)
                            .padding(12)
                            .background(Color.huddleGlassFill).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.huddleBorder, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 20).padding(.bottom, 8)
        }
    }

    // MARK: - Share Sheet

    private var shareSheet: some View {
        if let family = viewModel.family {
            return AnyView(
                ZStack {
                    Color.huddleBackground.ignoresSafeArea()
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 3).fill(Color(hex: "FFC8AA").opacity(0.3))
                            .frame(width: 40, height: 5).padding(.top, 12).padding(.bottom, 20)
                        VStack(spacing: 20) {
                            ClayIcon(systemImage: "person.badge.plus", lushColor: .coral, size: 64, glow: true)
                            VStack(spacing: 6) {
                                Text("Invite to \(family.name)").font(.system(size: 22, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
                                Text("Share this code with family members").font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.6))
                            }
                            VStack(spacing: 6) {
                                Text(family.code).font(.system(size: 32, weight: .bold)).foregroundColor(Color(hex: "FF8A66")).tracking(6)
                                Text("family code").font(.system(size: 12)).foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(Color(hex: "FF8A66").opacity(0.07)).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "FF8A66").opacity(0.2), lineWidth: 1))
                            HStack(spacing: 12) {
                                Button(action: { UIPasteboard.general.string = family.code; viewModel.showShareSheet = false }) {
                                    HStack(spacing: 6) { Image(systemName: "doc.on.doc"); Text("Copy Code") }
                                        .font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "FF8A66"))
                                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                                        .background(Color.huddleGlassFill).cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "FF8A66").opacity(0.3), lineWidth: 1))
                                }
                                ShareLink(item: family.code) {
                                    HStack(spacing: 6) { Image(systemName: "square.and.arrow.up"); Text("Share") }
                                        .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                                        .background(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom).cornerRadius(12))
                                }
                            }
                            Button("Done") { viewModel.showShareSheet = false }
                                .font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.5)).padding(.bottom, 8)
                        }
                        .padding(.horizontal, 24).padding(.bottom, 24)
                    }
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

// MARK: - Message Input Bar

private struct MessageInputBar: View {
    let onSend: (String) -> Void
    let onSendPhoto: (UIImage, String) -> Void
    let onPingTap: () -> Void

    @State private var messageText = ""
    @State private var sendPulse = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingImage: UIImage?
    @State private var isPreparingPhoto = false
    @FocusState private var isFocused: Bool

    private var canSend: Bool {
        pendingImage != nil || !messageText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if pendingImage != nil { pendingPhotoPreview }
            inputControls
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            LinearGradient(colors: [Color.huddleBackground.opacity(0.0), Color.huddleBackground.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onChange(of: selectedPhotoItem) { _ in loadPickedPhoto() }
    }

    private var pendingPhotoPreview: some View {
        HStack(spacing: 12) {
            if let pendingImage {
                Image(uiImage: pendingImage)
                    .resizable().scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.huddleBorder, lineWidth: 1))
            }
            Text("Photo ready · add a caption or send")
                .font(.system(size: 12.5))
                .foregroundColor(Color.huddleTextPrimary.opacity(0.55))
            Spacer()
            Button { pendingImage = nil; selectedPhotoItem = nil } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 19))
                    .foregroundColor(Color.huddleTextPrimary.opacity(0.4))
            }
        }
        .padding(.bottom, 10)
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
                            .foregroundStyle(LinearGradient(colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
                            .shadow(color: Color(hex: "FF8A66").opacity(0.5), radius: 4)
                    }
                }
                .frame(width: 26, height: 26)
            }
            .disabled(isPreparingPhoto)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onPingTap()
            } label: {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Color(hex: "FF8A66").opacity(0.5), radius: 4)
            }

            HStack(spacing: 8) {
                TextField(pendingImage == nil ? "Send some love…" : "Add a caption…", text: $messageText)
                    .font(.system(size: 14))
                    .foregroundColor(Color.huddleTextPrimary)
                    .focused($isFocused)
                    .onSubmit { send() }
                    .tint(Color(hex: "FF8A66"))
                if !messageText.isEmpty {
                    Button(action: { messageText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.huddleTextPrimary.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(Color.huddleGlassFill)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isFocused ? Color(hex: "FF8A66").opacity(0.5) : Color.huddleBorder, lineWidth: 1)
            )

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15))
                    .foregroundColor(canSend ? .white : Color.huddleTextPrimary)
                    .frame(width: 42, height: 42)
                    .background(
                        canSend
                            ? AnyView(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
                            : AnyView(Color.huddleTextPrimary.opacity(0.08))
                    )
                    .clipShape(Circle())
                    .shadow(color: canSend ? Color(hex: "D8512B").opacity(0.4) : .clear, radius: 6, x: 0, y: 3)
                    .scaleEffect(sendPulse ? 1.18 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: sendPulse)
            }
            .disabled(!canSend)
            .onChange(of: messageText) { newValue in
                let wasEmpty = messageText.trimmingCharacters(in: .whitespaces).isEmpty
                let isNowNonEmpty = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
                if wasEmpty && isNowNonEmpty {
                    sendPulse = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { sendPulse = false }
                }
            }
        }
    }

    private func send() {
        if let image = pendingImage {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSendPhoto(image, messageText.trimmingCharacters(in: .whitespaces))
            pendingImage = nil
            selectedPhotoItem = nil
            messageText = ""
            return
        }
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSend(text)
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
}

// MARK: - Live Ticker (isolated so only this re-renders every 3s, not heroCard)

private struct LiveTickerView: View {
    let items: [(String, String)]
    @State private var index = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.30))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.14), lineWidth: 1))
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "7CFFA8"))
                    .frame(width: 6, height: 6)
                    .shadow(color: Color(hex: "7CFFA8"), radius: 4)
                let item = items[index % items.count]
                Text(item.0).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                Text(item.1).font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("live").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 36)
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
            guard items.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.35)) { index = (index + 1) % items.count }
        }
    }
}

#Preview {
    let auth = AuthService()
    let container = ServiceContainer()
    FamilyFeedView(
        familyService: container.familyService,
        messageService: container.messageService,
        eventService: container.eventService,
        capsuleService: container.capsuleService,
        authService: auth,
        openToShopping: .constant(false),
        onBack: {}
    )
    .environmentObject(auth)
}
