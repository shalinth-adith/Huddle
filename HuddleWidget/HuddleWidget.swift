//
//  HuddleWidget.swift
//  HuddleWidget
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HuddleEntry {
        HuddleEntry(
            date: Date(),
            pinnedMessages: [
                SharedDataManager.WidgetPinnedMessage(text: "Remember to call grandma!", senderName: "Mom")
            ],
            shoppingItems: [
                SharedDataManager.WidgetShoppingItem(text: "Milk"),
                SharedDataManager.WidgetShoppingItem(text: "Bread")
            ],
            pings: [
                SharedDataManager.WidgetPing(content: "🏠 I'm home", senderName: "Jake", sentAt: Date())
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HuddleEntry) -> ()) {
        let entry = HuddleEntry(
            date: Date(),
            pinnedMessages: SharedDataManager.loadPinnedMessages(),
            shoppingItems: SharedDataManager.loadShoppingItems(),
            pings: SharedDataManager.loadPings()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let pings = SharedDataManager.loadPings()
        let entry = HuddleEntry(
            date: Date(),
            pinnedMessages: SharedDataManager.loadPinnedMessages(),
            shoppingItems: SharedDataManager.loadShoppingItems(),
            pings: pings
        )
        let refreshDate: Date
        if let ping = pings.first {
            let expiry = ping.sentAt.addingTimeInterval(86400)
            let fifteenMin = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            refreshDate = min(expiry, fifteenMin)
        } else {
            refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        }
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct HuddleEntry: TimelineEntry {
    let date: Date
    let pinnedMessages: [SharedDataManager.WidgetPinnedMessage]
    let shoppingItems: [SharedDataManager.WidgetShoppingItem]
    let pings: [SharedDataManager.WidgetPing]
}

// MARK: - Widget View

struct HuddleWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Ambient coral glow
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
        .widgetURL(URL(string: "huddle://open"))
    }

    // MARK: - Brand

    private var brandRow: some View {
        HStack(spacing: 5) {
            Image(systemName: "heart.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FF8A66"), Color(hex: "D8512B")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            Text("Huddle")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .tracking(-0.3)
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
                            Circle()
                                .fill(Color(hex: "FF8A66").opacity(0.5))
                                .frame(width: 4, height: 4)
                            Text(item.text)
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "F5E9E2"))
                                .lineLimit(1)
                        }
                    }
                }
            } else {
                Text("Your family is quiet…")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "F5E9E2").opacity(0.35))
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Medium

    private var mediumContent: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left: ping or pinned
            Link(destination: URL(string: "huddle://open")!) {
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

            // Divider
            Rectangle()
                .fill(Color(hex: "FFC8AA").opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 2)

            // Right: shopping
            Link(destination: URL(string: "huddle://shopping")!) {
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
                                    Circle()
                                        .fill(Color(hex: "FF8A66").opacity(0.5))
                                        .frame(width: 4, height: 4)
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "FFC8AA").opacity(0.10), lineWidth: 1)
                    )
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "FFC8AA").opacity(0.10), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Widget Configuration

struct HuddleWidget: Widget {
    let kind: String = "HuddleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                HuddleWidgetEntryView(entry: entry)
                    .containerBackground(Color(hex: "0E0809"), for: .widget)
            } else {
                HuddleWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(hex: "0E0809"))
            }
        }
        .configurationDisplayName("Huddle")
        .description("See pinned messages and shopping list")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    HuddleWidget()
} timeline: {
    HuddleEntry(
        date: .now,
        pinnedMessages: [
            SharedDataManager.WidgetPinnedMessage(text: "Pick up kids at 3pm", senderName: "Mom")
        ],
        shoppingItems: [
            SharedDataManager.WidgetShoppingItem(text: "Milk"),
            SharedDataManager.WidgetShoppingItem(text: "Bread")
        ],
        pings: [
            SharedDataManager.WidgetPing(content: "🏠 I'm home", senderName: "Jake", sentAt: Date().addingTimeInterval(-300))
        ]
    )
}

#Preview(as: .systemMedium) {
    HuddleWidget()
} timeline: {
    HuddleEntry(
        date: .now,
        pinnedMessages: [
            SharedDataManager.WidgetPinnedMessage(text: "Pick up kids at 3pm", senderName: "Mom"),
            SharedDataManager.WidgetPinnedMessage(text: "Dentist Monday 10am", senderName: "Mom")
        ],
        shoppingItems: [
            SharedDataManager.WidgetShoppingItem(text: "Milk"),
            SharedDataManager.WidgetShoppingItem(text: "Bread"),
            SharedDataManager.WidgetShoppingItem(text: "Eggs")
        ],
        pings: [
            SharedDataManager.WidgetPing(content: "📍 At the gym", senderName: "Mom", sentAt: Date().addingTimeInterval(-240))
        ]
    )
}
