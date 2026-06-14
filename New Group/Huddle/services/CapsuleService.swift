//
//  CapsuleService.swift
//  Huddle
//
//  Firestore CRUD + listener for time capsules. Sealed capsules are NOT
//  decrypted (their content stays ciphertext in memory until the deliver date),
//  so the reveal is genuine on the client side.
//

import Foundation
import FirebaseFirestore

class CapsuleService {
    private let db = Firestore.firestore()

    private func encrypted(_ text: String, familyId: String) -> String {
        guard let key = EncryptionService.loadGroupKey(familyId: familyId),
              let cipher = try? EncryptionService.encrypt(text, groupKey: key) else { return text }
        return cipher
    }

    /// Decrypts only already-delivered capsules; sealed ones keep their cipher.
    private func decryptedOpened(_ capsules: [TimeCapsule], familyId: String) -> [TimeCapsule] {
        guard let key = EncryptionService.loadGroupKey(familyId: familyId) else { return capsules }
        return capsules.map { capsule in
            guard !capsule.isSealed else { return capsule }
            var c = capsule
            if let plain = EncryptionService.decrypt(c.message, groupKey: key) { c.message = plain }
            return c
        }
    }

    func createCapsule(
        familyId: String,
        message: String,
        deliverAt: Date,
        creatorId: String,
        creatorName: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let id = UUID().uuidString
        let capsule = TimeCapsule(
            id: id,
            familyID: familyId,
            message: encrypted(message, familyId: familyId),
            deliverAt: deliverAt,
            createdBy: creatorId,
            createdByName: creatorName,
            createdAt: Date()
        )
        do {
            try db.collection("families").document(familyId)
                .collection("capsules").document(id)
                .setData(from: capsule) { error in
                    if let error { completion(.failure(error)) } else { completion(.success(())) }
                }
        } catch {
            completion(.failure(error))
        }
    }

    func listenToCapsules(
        familyId: String,
        completion: @escaping (Result<[TimeCapsule], Error>) -> Void
    ) -> ListenerRegistration {
        return db.collection("families").document(familyId)
            .collection("capsules")
            .order(by: "deliverAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error { completion(.failure(error)); return }
                guard let documents = snapshot?.documents else { completion(.success([])); return }
                let capsules = (try? documents.compactMap { try $0.data(as: TimeCapsule.self) }) ?? []
                DispatchQueue.global(qos: .userInitiated).async {
                    let result = self?.decryptedOpened(capsules, familyId: familyId) ?? capsules
                    DispatchQueue.main.async { completion(.success(result)) }
                }
            }
    }

    func deleteCapsule(familyId: String, capsuleId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("families").document(familyId)
            .collection("capsules").document(capsuleId)
            .delete { error in
                if let error { completion(.failure(error)) } else { completion(.success(())) }
            }
    }
}
