//
//  EventService.swift
//  Huddle
//
//  Firestore CRUD + real-time listener for the family calendar. Mirrors
//  MessageService: title/notes are encrypted with the family group key before
//  write and decrypted on read; time fields stay plaintext for ordering.
//

import Foundation
import FirebaseFirestore

class EventService {
    private let db = Firestore.firestore()

    private func encrypted(_ text: String, familyId: String) -> String {
        guard let key = EncryptionService.loadGroupKey(familyId: familyId),
              let cipher = try? EncryptionService.encrypt(text, groupKey: key) else { return text }
        return cipher
    }

    private func decrypted(_ events: [FamilyEvent], familyId: String) -> [FamilyEvent] {
        guard let key = EncryptionService.loadGroupKey(familyId: familyId) else { return events }
        return events.map { event in
            var e = event
            if let title = EncryptionService.decrypt(e.title, groupKey: key) { e.title = title }
            if let notes = e.notes, let plain = EncryptionService.decrypt(notes, groupKey: key) { e.notes = plain }
            return e
        }
    }

    func createEvent(
        familyId: String,
        title: String,
        notes: String?,
        startAt: Date,
        endAt: Date?,
        isAllDay: Bool,
        creatorId: String,
        creatorName: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let eventId = UUID().uuidString
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let event = FamilyEvent(
            id: eventId,
            familyID: familyId,
            title: encrypted(title, familyId: familyId),
            notes: (trimmedNotes?.isEmpty == false) ? encrypted(trimmedNotes!, familyId: familyId) : nil,
            startAt: startAt,
            endAt: endAt,
            isAllDay: isAllDay,
            createdBy: creatorId,
            createdByName: creatorName,
            createdAt: Date(),
            rsvps: [creatorId: RSVPStatus.going.rawValue]   // creator is going by default
        )
        do {
            try db.collection("families").document(familyId)
                .collection("events").document(eventId)
                .setData(from: event) { error in
                    if let error { completion(.failure(error)) } else { completion(.success(())) }
                }
        } catch {
            completion(.failure(error))
        }
    }

    func listenToEvents(
        familyId: String,
        completion: @escaping (Result<[FamilyEvent], Error>) -> Void
    ) -> ListenerRegistration {
        return db.collection("families").document(familyId)
            .collection("events")
            .order(by: "startAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error { completion(.failure(error)); return }
                guard let documents = snapshot?.documents else { completion(.success([])); return }
                let events = (try? documents.compactMap { try $0.data(as: FamilyEvent.self) }) ?? []
                DispatchQueue.global(qos: .userInitiated).async {
                    let result = self?.decrypted(events, familyId: familyId) ?? events
                    DispatchQueue.main.async { completion(.success(result)) }
                }
            }
    }

    func setRSVP(
        familyId: String,
        eventId: String,
        userId: String,
        status: RSVPStatus,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("families").document(familyId)
            .collection("events").document(eventId)
            .updateData(["rsvps.\(userId)": status.rawValue]) { error in
                if let error { completion(.failure(error)) } else { completion(.success(())) }
            }
    }

    func deleteEvent(familyId: String, eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("families").document(familyId)
            .collection("events").document(eventId)
            .delete { error in
                if let error { completion(.failure(error)) } else { completion(.success(())) }
            }
    }
}
