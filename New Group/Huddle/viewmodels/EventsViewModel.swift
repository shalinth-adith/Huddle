//
//  EventsViewModel.swift
//  Huddle
//
//  Drives the family calendar tab: live list of events, create, RSVP, delete.
//

import Foundation
import Combine
import FirebaseFirestore

class EventsViewModel: ObservableObject {
    @Published var events: [FamilyEvent] = []
    @Published var isLoading = true

    private let eventService: EventService
    private let authService: AuthService
    private var listener: ListenerRegistration?

    init(eventService: EventService, authService: AuthService) {
        self.eventService = eventService
        self.authService = authService
    }

    deinit { listener?.remove() }

    /// Upcoming + today's events (hides events whose end is before today).
    var upcomingEvents: [FamilyEvent] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return events.filter { ($0.endAt ?? $0.startAt) >= startOfToday }
    }

    /// Upcoming events grouped by calendar day, in chronological order.
    var groupedByDay: [(day: Date, events: [FamilyEvent])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: upcomingEvents) { cal.startOfDay(for: $0.startAt) }
        return groups.keys.sorted().map { day in (day, groups[day]!.sorted { $0.startAt < $1.startAt }) }
    }

    func start() {
        guard let familyId = authService.currentUser?.currentFamilyId else { isLoading = false; return }
        listener?.remove()
        listener = eventService.listenToEvents(familyId: familyId) { [weak self] result in
            self?.isLoading = false
            if case .success(let events) = result { self?.events = events }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func createEvent(title: String, notes: String?, startAt: Date, endAt: Date?, isAllDay: Bool) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let familyId = authService.currentUser?.currentFamilyId,
              let userId = authService.currentUser?.id,
              let userName = authService.currentUser?.displayName else { return }
        eventService.createEvent(
            familyId: familyId, title: trimmed, notes: notes,
            startAt: startAt, endAt: endAt, isAllDay: isAllDay,
            creatorId: userId, creatorName: userName
        ) { _ in }
    }

    func setRSVP(_ event: FamilyEvent, status: RSVPStatus) {
        guard let familyId = authService.currentUser?.currentFamilyId,
              let eventId = event.id,
              let userId = authService.currentUser?.id else { return }

        // Optimistic update.
        if let idx = events.firstIndex(where: { $0.id == eventId }) {
            var rsvps = events[idx].rsvps ?? [:]
            rsvps[userId] = status.rawValue
            events[idx].rsvps = rsvps
        }
        eventService.setRSVP(familyId: familyId, eventId: eventId, userId: userId, status: status) { _ in }
    }

    func deleteEvent(_ event: FamilyEvent) {
        guard let familyId = authService.currentUser?.currentFamilyId,
              let eventId = event.id,
              canDelete(event) else { return }
        events.removeAll { $0.id == eventId }
        eventService.deleteEvent(familyId: familyId, eventId: eventId) { _ in }
    }

    func canDelete(_ event: FamilyEvent) -> Bool {
        event.createdBy == authService.currentUser?.id
    }

    func myRSVP(_ event: FamilyEvent) -> RSVPStatus? {
        guard let userId = authService.currentUser?.id else { return nil }
        return event.rsvp(for: userId)
    }
}
