//
//  CalendarView.swift
//  Huddle
//
//  Family calendar tab: upcoming events grouped by day, with RSVP and an
//  add-event sheet. Embedded inside FamilyFeedView as the .calendar tab.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: EventsViewModel
    let members: [Member]

    @State private var showAddEvent = false

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.isLoading {
                Spacer(); ProgressView().tint(Color.huddleCoral); Spacer()
            } else if viewModel.groupedByDay.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(viewModel.groupedByDay, id: \.day) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(dayLabel(group.day))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.huddleTextPrimary.opacity(0.6))
                                    .tracking(0.3)
                                    .padding(.leading, 4)
                                ForEach(group.events) { event in
                                    eventCard(event)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventSheet { title, notes, startAt, endAt, isAllDay in
                viewModel.createEvent(title: title, notes: notes, startAt: startAt, endAt: endAt, isAllDay: isAllDay)
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                LushEyebrow(text: "Shared calendar")
                Text("Events").font(.system(size: 20, weight: .bold)).foregroundColor(Color.huddleTextPrimary).tracking(-0.5)
            }
            Spacer()
            Button(action: { showAddEvent = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                    Text("Add Event").font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom).cornerRadius(10))
                .shadow(color: Color(hex: "D8512B").opacity(0.35), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Event card

    private func eventCard(_ event: FamilyEvent) -> some View {
        let going = event.attendeeIds(status: .going).compactMap { id in members.first { $0.id == id } }

        return GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    // Time block
                    VStack(spacing: 1) {
                        if event.isAllDay {
                            Text("All").font(.system(size: 13, weight: .bold)).foregroundColor(Color.huddleCoral)
                            Text("day").font(.system(size: 10)).foregroundColor(Color.huddleCoral.opacity(0.7))
                        } else {
                            Text(timeString(event.startAt)).font(.system(size: 14, weight: .bold)).foregroundColor(Color.huddleCoral)
                            if let end = event.endAt {
                                Text(timeString(end)).font(.system(size: 10)).foregroundColor(Color.huddleTextPrimary.opacity(0.4))
                            }
                        }
                    }
                    .frame(width: 52)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(event.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.huddleTextPrimary)
                        if let notes = event.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.system(size: 13))
                                .foregroundColor(Color.huddleTextPrimary.opacity(0.55))
                                .lineLimit(2)
                        }
                        if !going.isEmpty {
                            HStack(spacing: -6) {
                                ForEach(going.prefix(5)) { m in
                                    MemberAvatarView(name: m.displayName, photoBase64: m.photoBase64, size: 22)
                                }
                                Text("\(going.count) going")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.huddleTextPrimary.opacity(0.45))
                                    .padding(.leading, 10)
                            }
                            .padding(.top, 2)
                        }
                    }
                    Spacer(minLength: 0)
                }

                rsvpControl(event)
            }
        }
        .contextMenu {
            if viewModel.canDelete(event) {
                Button(role: .destructive) { viewModel.deleteEvent(event) } label: { Label("Delete Event", systemImage: "trash") }
            }
        }
    }

    private func rsvpControl(_ event: FamilyEvent) -> some View {
        let mine = viewModel.myRSVP(event)
        return HStack(spacing: 6) {
            ForEach(RSVPStatus.allCases, id: \.self) { status in
                let selected = mine == status
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.setRSVP(event, status: status)
                } label: {
                    HStack(spacing: 4) {
                        Text(status.emoji).font(.system(size: 11))
                        Text(status.label).font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(selected ? .white : Color.huddleTextPrimary.opacity(0.6))
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(
                        Group {
                            if selected {
                                Capsule().fill(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom))
                            } else {
                                Capsule().fill(Color.huddleGlassFill).overlay(Capsule().stroke(Color.huddleBorder, lineWidth: 1))
                            }
                        }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ClayIcon(systemImage: "calendar", lushColor: .coral, size: 60).padding(.top, 60)
            Text("No upcoming events")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.huddleTextPrimary)
            Text("Add a birthday, trip, or dinner so everyone's in the loop.")
                .font(.system(size: 14))
                .foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: { showAddEvent = true }) {
                Text("Add your first event")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom).cornerRadius(12))
            }
            .padding(.top, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Formatting

    private func dayLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none
        return f.string(from: date)
    }
}

// MARK: - Add Event Sheet

private struct AddEventSheet: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (_ title: String, _ notes: String?, _ startAt: Date, _ endAt: Date?, _ isAllDay: Bool) -> Void

    @State private var title = ""
    @State private var notes = ""
    @State private var startAt = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endAt = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var isAllDay = false

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }.foregroundColor(Color.huddleTextPrimary.opacity(0.6))
                    Spacer()
                    Text("New Event").font(.system(size: 16, weight: .bold)).foregroundColor(Color.huddleTextPrimary)
                    Spacer()
                    Button("Add") {
                        onSave(title, notes, startAt, isAllDay ? nil : endAt, isAllDay)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(canSave ? Color.huddleCoral : Color.huddleTextPrimary.opacity(0.3))
                    .disabled(!canSave)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        field("Title") {
                            TextField("Birthday, trip, dinner…", text: $title)
                                .font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary)
                        }

                        VStack(spacing: 0) {
                            Toggle(isOn: $isAllDay) {
                                Text("All day").font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary)
                            }
                            .tint(Color.huddleCoral)
                            .padding(.horizontal, 14).padding(.vertical, 12)

                            Divider().overlay(Color.huddleBorder)

                            DatePicker("Starts", selection: $startAt, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                                .font(.system(size: 15))
                                .foregroundColor(Color.huddleTextPrimary)
                                .tint(Color.huddleCoral)
                                .padding(.horizontal, 14).padding(.vertical, 8)

                            if !isAllDay {
                                Divider().overlay(Color.huddleBorder)
                                DatePicker("Ends", selection: $endAt, in: startAt..., displayedComponents: [.date, .hourAndMinute])
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.huddleTextPrimary)
                                    .tint(Color.huddleCoral)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.huddleGlassFill).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.huddleBorder, lineWidth: 1)))

                        field("Notes (optional)") {
                            TextField("Add details…", text: $notes, axis: .vertical)
                                .font(.system(size: 15)).foregroundColor(Color.huddleTextPrimary)
                                .lineLimit(3, reservesSpace: true)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold)).tracking(0.6)
                .foregroundColor(Color.huddleTextPrimary.opacity(0.45))
            content()
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.huddleGlassFill).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.huddleBorder, lineWidth: 1)))
        }
    }
}
