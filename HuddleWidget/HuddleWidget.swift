//
//  HuddleWidget.swift
//  HuddleWidget
//
//  Created by shalinth adithyan on 10/02/26.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
      func placeholder(in context: Context) -> HuddleEntry {
          HuddleEntry(
              date: Date(),
              pinnedMessages: [
                  SharedDataManager.WidgetPinnedMessage(text: "Remember to call grandma!", senderName:
  "Mom")
              ],
              shoppingItems: [
                  SharedDataManager.WidgetShoppingItem(text: "Milk"),
                  SharedDataManager.WidgetShoppingItem(text: "Bread")
              ]
          )
      }
                                                                                                       
      func getSnapshot(in context: Context, completion: @escaping (HuddleEntry) -> ()) {
          let entry = HuddleEntry(
              date: Date(),
              pinnedMessages: SharedDataManager.loadPinnedMessages(),
              shoppingItems: SharedDataManager.loadShoppingItems()
          )
          completion(entry)
      }
                                                                                                       
      func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
          let entry = HuddleEntry(
              date: Date(),
              pinnedMessages: SharedDataManager.loadPinnedMessages(),
              shoppingItems: SharedDataManager.loadShoppingItems()
          )
                                                                                                       
          // Refresh every 15 minutes
          let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
          let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
          completion(timeline)
      }
  }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }


struct HuddleEntry: TimelineEntry {
      let date: Date
      let pinnedMessages: [SharedDataManager.WidgetPinnedMessage]
      let shoppingItems: [SharedDataManager.WidgetShoppingItem]
  }

struct HuddleWidgetEntryView: View {
      var entry: Provider.Entry
      @Environment(\.widgetFamily) var widgetFamily
                                                                                                       
      var body: some View {
          VStack(alignment: .leading, spacing: 6) {
              Text("Huddle")
                  .font(.system(size: 16, weight: .bold, design: .rounded))
                  .foregroundColor(Color.huddleCoral)
                                                                                                       
              if widgetFamily == .systemSmall {
                  smallWidgetContent
              } else {
                  mediumWidgetContent
              }
                                                                                                       
              Spacer(minLength: 0)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
      }
                                                                                                       
      var smallWidgetContent: some View {
          VStack(alignment: .leading, spacing: 4) {
              if !entry.pinnedMessages.isEmpty {
                  Text("📌 Pinned")
                      .font(.system(size: 10, weight: .semibold))
                      .foregroundColor(.gray)
                                                                                                       
                  ForEach(entry.pinnedMessages.prefix(2), id: \.text) { message in
                      Text(message.text)
                          .font(.system(size: 12, design: .rounded))
                          .foregroundColor(.black)
                          .lineLimit(1)
                  }
              } else if !entry.shoppingItems.isEmpty {
                  Text("🛒 Shopping")
                      .font(.system(size: 10, weight: .semibold))
                      .foregroundColor(.gray)
                                                                                                       
                  ForEach(entry.shoppingItems.prefix(3), id: \.text) { item in
                      HStack(spacing: 4) {
                          Image(systemName: "circle")
                              .font(.system(size: 8))
                              .foregroundColor(.gray)
                          Text(item.text)
                              .font(.system(size: 12, design: .rounded))
                              .foregroundColor(.black)
                              .lineLimit(1)
                      }
                  }
              } else {
                  Text("No items yet")
                      .font(.system(size: 12))
                      .foregroundColor(.gray)
              }
          }
      }
                                                                                                       
      var mediumWidgetContent: some View {
          HStack(alignment: .top, spacing: 16) {
              // Pinned Messages
              VStack(alignment: .leading, spacing: 4) {
                  Text("📌 Pinned")
                      .font(.system(size: 11, weight: .semibold))
                      .foregroundColor(Color.huddleCoral)
                                                                                                       
                  if entry.pinnedMessages.isEmpty {
                      Text("No pins")
                          .font(.system(size: 11))
                          .foregroundColor(.gray)
                  } else {
                      ForEach(entry.pinnedMessages.prefix(3), id: \.text) { message in
                          Text("• \(message.text)")
                              .font(.system(size: 11, design: .rounded))
                              .foregroundColor(.black)
                              .lineLimit(1)
                      }
                  }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
                                                                                                       
              // Shopping List
              VStack(alignment: .leading, spacing: 4) {
                  Text("🛒 Shopping")
                      .font(.system(size: 11, weight: .semibold))
                      .foregroundColor(Color.huddleCoral)
                                                                                                       
                  if entry.shoppingItems.isEmpty {
                      Text("No items")
                          .font(.system(size: 11))
                          .foregroundColor(.gray)
                  } else {
                      ForEach(entry.shoppingItems.prefix(3), id: \.text) { item in
                          HStack(spacing: 4) {
                              Image(systemName: "circle")
                                  .font(.system(size: 8))
                                  .foregroundColor(.gray)
                              Text(item.text)
                                  .font(.system(size: 11, design: .rounded))
                                  .foregroundColor(.black)
                                  .lineLimit(1)
                          }
                      }
                  }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
          }
      }
  }
struct HuddleWidget: Widget {
      let kind: String = "HuddleWidget"
                                                                                                       
      var body: some WidgetConfiguration {
          StaticConfiguration(kind: kind, provider: Provider()) { entry in
              if #available(iOS 17.0, *) {
                  HuddleWidgetEntryView(entry: entry)
                      .containerBackground(Color.huddleBackground, for: .widget)
              } else {
                  HuddleWidgetEntryView(entry: entry)
                      .padding()
                      .background(Color.huddleBackground)
              }
          }
          .configurationDisplayName("Huddle")
          .description("See pinned messages and shopping list")
          .supportedFamilies([.systemSmall, .systemMedium])
      }
  }                        

#Preview(as: .systemSmall) {
     HuddleWidget()
 } timeline: {
     HuddleEntry(
         date: .now,
         pinnedMessages: [
             SharedDataManager.WidgetPinnedMessage(text: "Pick up kids at 3pm", senderName: "Mom"),
             SharedDataManager.WidgetPinnedMessage(text: "Call grandma Sunday", senderName: "Dad")
         ],
         shoppingItems: [
             SharedDataManager.WidgetShoppingItem(text: "Milk"),
             SharedDataManager.WidgetShoppingItem(text: "Bread"),
             SharedDataManager.WidgetShoppingItem(text: "Eggs")
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
             SharedDataManager.WidgetPinnedMessage(text: "Call grandma Sunday", senderName: "Dad"),
             SharedDataManager.WidgetPinnedMessage(text: "Dentist Monday 10am", senderName: "Mom")
         ],
         shoppingItems: [
             SharedDataManager.WidgetShoppingItem(text: "Milk"),
             SharedDataManager.WidgetShoppingItem(text: "Bread"),
             SharedDataManager.WidgetShoppingItem(text: "Eggs")
         ]
     )
 }
