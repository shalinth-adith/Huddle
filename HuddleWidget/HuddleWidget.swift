//
//  HuddleWidget.swift
//  HuddleWidget
//
//  Configurable per-group widget: each instance shows one group the user picks.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Configuration intent (group picker)

struct GroupEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Group"
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    static var defaultQuery = GroupQuery()
}

struct GroupQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [GroupEntity] {
        SharedDataManager.loadGroups()
            .filter { identifiers.contains($0.id) }
            .map { GroupEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [GroupEntity] {
        SharedDataManager.loadGroups().map { GroupEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> GroupEntity? {
        SharedDataManager.loadGroups().first.map { GroupEntity(id: $0.id, name: $0.name) }
    }
}

struct SelectGroupIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose Group"
    static var description = IntentDescription("Pick which group this widget shows.")

    @Parameter(title: "Group")
    var group: GroupEntity?

    init() {}
    init(group: GroupEntity?) { self.group = group }
}

// MARK: - Timeline

struct HuddleEntry: TimelineEntry {
    let date: Date
    let groupId: String?
    let groupName: String
    let pinnedMessages: [SharedDataManager.WidgetPinnedMessage]
    let shoppingItems: [SharedDataManager.WidgetShoppingItem]
    let pings: [SharedDataManager.WidgetPing]
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HuddleEntry {
        HuddleEntry(
            date: Date(),
            groupId: nil,
            groupName: "Family",
            pinnedMessages: [SharedDataManager.WidgetPinnedMessage(text: "Remember to call grandma!", senderName: "Mom")],
            shoppingItems: [SharedDataManager.WidgetShoppingItem(text: "Milk"), SharedDataManager.WidgetShoppingItem(text: "Bread")],
            pings: [SharedDataManager.WidgetPing(content: "🏠 I'm home", senderName: "Jake", sentAt: Date())]
        )
    }

    func snapshot(for configuration: SelectGroupIntent, in context: Context) async -> HuddleEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: SelectGroupIntent, in context: Context) async -> Timeline<HuddleEntry> {
        let current = entry(for: configuration)
        let refreshDate: Date
        if let ping = current.pings.first {
            let expiry = ping.sentAt.addingTimeInterval(86400)
            let fifteenMin = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            refreshDate = min(expiry, fifteenMin)
        } else {
            refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        }
        return Timeline(entries: [current], policy: .after(refreshDate))
    }

    /// Resolves the picked group (or the first available), then loads its data.
    private func entry(for configuration: SelectGroupIntent) -> HuddleEntry {
        let groups = SharedDataManager.loadGroups()
        let selected = configuration.group ?? groups.first.map { GroupEntity(id: $0.id, name: $0.name) }

        guard let selected else {
            return HuddleEntry(date: Date(), groupId: nil, groupName: "Huddle",
                               pinnedMessages: [], shoppingItems: [], pings: [])
        }
        // Prefer the live name from the index in case the group was renamed.
        let name = SharedDataManager.groupName(selected.id) ?? selected.name
        return HuddleEntry(
            date: Date(),
            groupId: selected.id,
            groupName: name,
            pinnedMessages: SharedDataManager.loadPinnedMessages(familyId: selected.id),
            shoppingItems: SharedDataManager.loadShoppingItems(familyId: selected.id),
            pings: SharedDataManager.loadPings(familyId: selected.id)
        )
    }
}

// MARK: - Widget View

struct HuddleWidgetEntryView: View {
    var entry: HuddleEntry
    @Environment(\.widgetFamily) var widgetFamily

    private var openURL: URL {
        if let id = entry.groupId { return URL(string: "huddle://group/\(id)")! }
        return URL(string: "huddle://open")!
    }

    private var shoppingURL: URL {
        if let id = entry.groupId { return URL(string: "huddle://group/\(id)/shopping")! }
        return URL(string: "huddle://shopping")!
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: "FF8A66").opacity(0.18))
                .frame(width: 90, height: 90)
                .blur(radius: 35)
                .offset(x: 10, y: -20)

            Circle()
                .fill(Color(hex: "E85A7A").opacity(0.10))
                .frame(width: 60, height: 60)
                .blur(radius: 25)
                .offset(x: -10, y: 60)

            VStack(alignment: .leading, spacing: 7) {
                brandRow

                if widgetFamily == .systemSmall {
                    smallContent
                } else {
                    mediumContent
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .widgetURL(openURL)
    }

    // MARK: - Brand

    private var brandRow: some View {
        HStack(spacing: 5) {
            Image(systemName: "heart.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom)
                )
            Text(entry.groupName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .tracking(-0.3)
                .lineLimit(1)
        }
    }

    // MARK: - Small

    private var smallContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let ping = entry.pings.first, Date().timeIntervalSince(ping.sentAt) < 86400 {
                sectionLabel("PING", icon: "mappin.circle.fill")
                glassRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ping.content)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        HStack(spacing: 3) {
                            Text(ping.senderName)
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "F5E9E2").opacity(0.45))
                            Text("·")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "F5E9E2").opacity(0.25))
                            Text(ping.sentAt, style: .relative)
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "F5E9E2").opacity(0.45))
                                .lineLimit(1)
                        }
                    }
                }
            } else if !entry.pinnedMessages.isEmpty {
                sectionLabel("PINNED", icon: "pin.fill")
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.pinnedMessages.prefix(2), id: \.text) { msg in
                        glassRow {
                            Text(msg.text)
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "F5E9E2"))
                                .lineLimit(1)
                        }
                    }
                }
            } else if !entry.shoppingItems.isEmpty {
                sectionLabel("SHOPPING", icon: "cart.fill")
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.shoppingItems.prefix(3), id: \.text) { item in
                        HStack(spacing: 6) {
                            Circle().fill(Color(hex: "FF8A66").opacity(0.5)).frame(width: 4, height: 4)
                            Text(item.text)
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "F5E9E2"))
                                .lineLimit(1)
                        }
                    }
                }
            } else {
                Text("All quiet here…")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "F5E9E2").opacity(0.35))
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Medium

    private var mediumContent: some View {
        HStack(alignment: .top, spacing: 10) {
            Link(destination: openURL) {
                VStack(alignment: .leading, spacing: 6) {
                    if let ping = entry.pings.first, Date().timeIntervalSince(ping.sentAt) < 86400 {
                        sectionLabel("PING", icon: "mappin.circle.fill")
                        glassCard {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ping.content)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                HStack(spacing: 3) {
                                    Text(ping.senderName)
                                        .font(.system(size: 9))
                                        .foregroundColor(Color(hex: "F5E9E2").opacity(0.45))
                                    Text("·")
                                        .font(.system(size: 9))
                                        .foregroundColor(Color(hex: "F5E9E2").opacity(0.25))
                                    Text(ping.sentAt, style: .relative)
                                        .font(.system(size: 9))
                                        .foregroundColor(Color(hex: "F5E9E2").opacity(0.45))
                                        .lineLimit(1)
                                }
                            }
                        }
                    } else {
                        sectionLabel("PINNED", icon: "pin.fill")
                        if entry.pinnedMessages.isEmpty {
                            glassCard {
                                Text("Nothing pinned yet")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "F5E9E2").opacity(0.3))
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(entry.pinnedMessages.prefix(3), id: \.text) { msg in
                                    glassRow {
                                        Text(msg.text)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "F5E9E2"))
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Rectangle()
                .fill(Color(hex: "FFC8AA").opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 2)

            Link(destination: shoppingURL) {
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("SHOPPING", icon: "cart.fill")
                    if entry.shoppingItems.isEmpty {
                        glassCard {
                            Text("List is clear")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "F5E9E2").opacity(0.3))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(entry.shoppingItems.prefix(4), id: \.text) { item in
                                HStack(spacing: 6) {
                                    Circle().fill(Color(hex: "FF8A66").opacity(0.5)).frame(width: 4, height: 4)
                                    Text(item.text)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: "F5E9E2"))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color(hex: "FF8A66"))
            Text(text)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundColor(Color(hex: "FF8A66"))
        }
    }

    @ViewBuilder
    private func glassRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "281A16").opacity(0.65))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "FFC8AA").opacity(0.10), lineWidth: 1))
            )
    }

    @ViewBuilder
    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "281A16").opacity(0.65))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "FFC8AA").opacity(0.10), lineWidth: 1))
            )
    }
}

// MARK: - Widget Configuration

struct HuddleWidget: Widget {
    let kind: String = "HuddleWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectGroupIntent.self, provider: Provider()) { entry in
            HuddleWidgetEntryView(entry: entry)
                .containerBackground(Color(hex: "0E0809"), for: .widget)
        }
        .configurationDisplayName("Huddle")
        .description("See a group's pins and shopping list. Long-press to pick the group.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    HuddleWidget()
} timeline: {
    HuddleEntry(
        date: .now, groupId: "preview", groupName: "Cousins",
        pinnedMessages: [SharedDataManager.WidgetPinnedMessage(text: "Pick up kids at 3pm", senderName: "Mom")],
        shoppingItems: [SharedDataManager.WidgetShoppingItem(text: "Milk"), SharedDataManager.WidgetShoppingItem(text: "Bread")],
        pings: [SharedDataManager.WidgetPing(content: "🏠 I'm home", senderName: "Jake", sentAt: Date().addingTimeInterval(-300))]
    )
}

#Preview(as: .systemMedium) {
    HuddleWidget()
} timeline: {
    HuddleEntry(
        date: .now, groupId: "preview", groupName: "Home",
        pinnedMessages: [
            SharedDataManager.WidgetPinnedMessage(text: "Pick up kids at 3pm", senderName: "Mom"),
            SharedDataManager.WidgetPinnedMessage(text: "Dentist Monday 10am", senderName: "Mom")
        ],
        shoppingItems: [
            SharedDataManager.WidgetShoppingItem(text: "Milk"),
            SharedDataManager.WidgetShoppingItem(text: "Bread"),
            SharedDataManager.WidgetShoppingItem(text: "Eggs")
        ],
        pings: [SharedDataManager.WidgetPing(content: "📍 At the gym", senderName: "Mom", sentAt: Date().addingTimeInterval(-240))]
    )
}
