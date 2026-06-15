import Foundation
import FirebaseFirestore
import FirebaseAuth

class FamilyService  {
    private let db = Firestore.firestore()

  
    private func generateFamilyCode() -> String {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        return "H-\(code)"
    }

 
    func createFamily(familyName: String, creatorId: String, creatorName: String, creatorPhotoBase64: String? = nil, creatorPublicKey: String? = nil, completion:
@escaping (Result<Family, Error>) -> Void) {
        let familyCode = generateFamilyCode()

        checkCodeExists(code: familyCode) { [weak self] exists in
            if exists {
                self?.createFamily(familyName: familyName, creatorId: creatorId, creatorName:
creatorName, creatorPhotoBase64: creatorPhotoBase64, creatorPublicKey: creatorPublicKey, completion: completion)
                return
            }

            let familyId = UUID().uuidString
            let member = Member(id: creatorId, displayName: creatorName, photoBase64: creatorPhotoBase64, joinedAt: Date(), publicKey: creatorPublicKey)

            let groupKey = EncryptionService.generateGroupKey()
            try? EncryptionService.saveGroupKey(groupKey, familyId: familyId)

            let family = Family(
                id: familyId,
                name: familyName,
                code: familyCode,
                members: [member],
                memberIds: [creatorId],
                adminId: creatorId,
                encryptedGroupKeys: nil
            )

            do {
                try self?.db.collection("families").document(familyId).setData(from: family) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    // Store the ONE shared family key in a members-only location so
                    // every member reads the same key (no per-device divergence).
                    self?.db.collection("families").document(familyId)
                        .collection("secrets").document("groupKey")
                        .setData(["key": EncryptionService.exportKey(groupKey)]) { _ in
                            completion(.success(family))
                        }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func checkCodeExists(code: String, completion: @escaping (Bool) -> Void) {
          db.collection("families")
              .whereField("code", isEqualTo: code)
              .getDocuments(source: .default) { (snapshot, error) in
                  if let error = error {
                      debugLog("Error checking code: \(error)")
                      completion(false)
                      return
                  }
                  completion(snapshot?.documents.isEmpty == false)
              }
      }

    

    func joinFamily(code: String, userId: String, displayName: String, photoBase64: String? = nil, publicKey: String? = nil, completion:
                    @escaping(Result < Family, Error>) -> Void) {
        db.collection("families")
             .whereField("code", isEqualTo: code)
             .getDocuments(source: .default) { [weak self] (snapshot, error) in
                 if let error = error {
                     completion(.failure(error))
                     return
                 }


                guard let document = snapshot?.documents.first else {
                    let error = NSError(domain: "FamilyService", code: 404, userInfo:
[NSLocalizedDescriptionKey: "Family not found with code: \(code)"])
                    completion(.failure(error))
                    return
                }

                let familyId = document.documentID

                guard let currentFamily = try? document.data(as: Family.self) else {
                    completion(.failure(NSError(domain: "FamilyService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not read family data"])))
                    return
                }

                let uniqueMembers = Dictionary(grouping: currentFamily.members, by: { $0.id }).compactMap { $0.value.first }
                guard uniqueMembers.count < 6 else {
                    completion(.failure(NSError(domain: "FamilyService", code: 403, userInfo: [NSLocalizedDescriptionKey: "This group is full. Maximum 6 members allowed."])))
                    return
                }

                let newMember = Member(id: userId, displayName: displayName, photoBase64: photoBase64, joinedAt: Date(), publicKey: publicKey)

                self?.db.collection("families").document(familyId).updateData([
                    "members": FieldValue.arrayUnion([newMember.toDictionary()]),
                    "memberIds": FieldValue.arrayUnion([userId])
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                  
                    do {
                        var family = try document.data(as: Family.self)
                        family.members.append(newMember)
                        completion(.success(family))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
    }

   
    func leaveFamily(userId: String, familyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = db.collection("families").document(familyId)
        ref.getDocument { snapshot, error in
            if let error = error { completion(.failure(error)); return }
            guard let family = try? snapshot?.data(as: Family.self) else {
                completion(.failure(NSError(domain: "FamilyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Family not found"])))
                return
            }
            let remaining = family.members.filter { $0.id != userId }
            var updateData: [String: Any] = [
                "members": remaining.map { $0.toDictionary() },
                "memberIds": remaining.map { $0.id }
            ]
            // Auto-transfer admin to oldest remaining member if admin is leaving
            if family.adminId == userId, let newAdmin = remaining.sorted(by: { $0.joinedAt < $1.joinedAt }).first {
                updateData["adminId"] = newAdmin.id
            }
            ref.updateData(updateData) { error in
                if let error = error { completion(.failure(error)); return }
                completion(.success(()))
            }
        }
    }

    func removeMember(userId: String, familyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = db.collection("families").document(familyId)
        ref.getDocument { snapshot, error in
            if let error = error { completion(.failure(error)); return }
            guard let family = try? snapshot?.data(as: Family.self) else {
                completion(.failure(NSError(domain: "FamilyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Family not found"])))
                return
            }
            let remaining = family.members.filter { $0.id != userId }
            ref.updateData([
                "members": remaining.map { $0.toDictionary() },
                "memberIds": remaining.map { $0.id }
            ]) { error in
                if let error = error { completion(.failure(error)); return }
                completion(.success(()))
            }
        }
    }

    func renameFamily(familyId: String, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("families").document(familyId).updateData(["name": newName]) { error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }
    }

    func transferAdmin(familyId: String, newAdminId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("families").document(familyId).updateData(["adminId": newAdminId]) { error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }
    }

    func fetchFamily(familyId: String, completion: @escaping (Result<Family, Error>) -> Void) {
        let ref = db.collection("families").document(familyId)

        // Serve from cache immediately so the feed appears without a spinner on re-open
        ref.getDocument(source: .cache) { snapshot, _ in
            if let snapshot, snapshot.exists, let family = try? snapshot.data(as: Family.self) {
                completion(.success(family))
            }
        }

        // Then refresh from server in the background
        ref.getDocument(source: .server) { snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "FamilyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Family not found"])))
                return
            }
            do {
                let family = try snapshot.data(as: Family.self)
                completion(.success(family))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updateEncryptedGroupKey(familyId: String, userId: String, encryptedKey: String) {
        db.collection("families").document(familyId)
            .updateData(["encryptedGroupKeys.\(userId)": encryptedKey])
    }

    /// Syncs this device's cached group key to the family's single canonical key
    /// (stored members-only at families/{id}/secrets/groupKey). Guarantees every
    /// member encrypts/decrypts with the SAME key. If the secret doesn't exist
    /// yet (legacy family), the local key is promoted to canonical.
    func ensureGroupKey(familyId: String, completion: @escaping () -> Void) {
        let secretRef = db.collection("families").document(familyId)
            .collection("secrets").document("groupKey")

        secretRef.getDocument(source: .default) { snapshot, _ in
            if let b64 = snapshot?.data()?["key"] as? String,
               let key = EncryptionService.importKey(b64) {
                // Canonical key exists — adopt it (overwrites any divergent local key).
                try? EncryptionService.saveGroupKey(key, familyId: familyId)
                completion()
            } else {
                // No canonical key yet: establish one from the local key or a new key.
                let key = EncryptionService.loadGroupKey(familyId: familyId) ?? EncryptionService.generateGroupKey()
                try? EncryptionService.saveGroupKey(key, familyId: familyId)
                secretRef.setData(["key": EncryptionService.exportKey(key)]) { _ in completion() }
            }
        }
    }

    /// Fully deletes an abandoned group: first the messages subcollection (must
    /// happen while the family doc still lists us as a member, so the message
    /// rules pass), then the family document itself.
    func deleteFamily(familyId: String, completion: @escaping (Error?) -> Void) {
        let famRef = db.collection("families").document(familyId)
        deleteCollection(famRef.collection("messages"), batchSize: 300) { [weak self] error in
            if let error { completion(error); return }
            _ = self
            famRef.delete { deleteError in completion(deleteError) }
        }
    }

    private func deleteCollection(_ ref: CollectionReference, batchSize: Int, completion: @escaping (Error?) -> Void) {
        ref.limit(to: batchSize).getDocuments { [weak self] snapshot, error in
            guard let self else { completion(nil); return }
            if let error { completion(error); return }
            guard let docs = snapshot?.documents, !docs.isEmpty else { completion(nil); return }
            let batch = self.db.batch()
            docs.forEach { batch.deleteDocument($0.reference) }
            batch.commit { commitError in
                if let commitError { completion(commitError); return }
                // Recurse until the collection is empty.
                self.deleteCollection(ref, batchSize: batchSize, completion: completion)
            }
        }
    }

    /// Real-time listener on the family document. Unlike `fetchFamily` (a
    /// one-time read), this keeps the local family in sync so the E2E group-key
    /// handshake converges live: the moment a new member joins, an existing
    /// member sees it and distributes the key; the moment `encryptedGroupKeys`
    /// gains the local user's entry, that user derives the key — no app reopen.
    func listenToFamily(familyId: String, completion: @escaping (Result<Family, Error>) -> Void) -> ListenerRegistration {
        return db.collection("families").document(familyId)
            .addSnapshotListener { snapshot, error in
                if let error { completion(.failure(error)); return }
                guard let snapshot, snapshot.exists,
                      let family = try? snapshot.data(as: Family.self) else {
                    completion(.failure(NSError(domain: "FamilyService", code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Family not found"])))
                    return
                }
                completion(.success(family))
            }
    }
}


extension Member {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "displayName": displayName,
            "joinedAt": Timestamp(date: joinedAt)
        ]
        if let photoBase64 { dict["photoBase64"] = photoBase64 }
        if let publicKey { dict["publicKey"] = publicKey }
        return dict
    }
}
