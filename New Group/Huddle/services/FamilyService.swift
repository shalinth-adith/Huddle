import Foundation
import FirebaseFirestore
import FirebaseAuth

class FamilyService  {
    private let db = Firestore.firestore()

  
    private func generateFamilyCode() -> String {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        return "H-\(code)"
    }

 
    func createFamily(familyName: String, creatorId: String, creatorName: String, creatorPhotoBase64: String? = nil, completion:
@escaping (Result<Family, Error>) -> Void) {
        let familyCode = generateFamilyCode()


        checkCodeExists(code: familyCode) { [weak self] exists in
            if exists {

                self?.createFamily(familyName: familyName, creatorId: creatorId, creatorName:
creatorName, creatorPhotoBase64: creatorPhotoBase64, completion: completion)
                return
            }


            let familyId = UUID().uuidString
            let member = Member(id: creatorId, displayName: creatorName, photoBase64: creatorPhotoBase64, joinedAt: Date())

            let family = Family(
                id: familyId,
                name: familyName,
                code: familyCode,
                members: [member],
                adminId: creatorId
            )

     
            do {
                try self?.db.collection("families").document(familyId).setData(from: family) {
error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
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
                      print("Error checking code: \(error)")
                      completion(false)
                      return
                  }
                  completion(snapshot?.documents.isEmpty == false)
              }
      }

    

    func joinFamily(code: String, userId: String, displayName: String, photoBase64: String? = nil, completion:
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

                let newMember = Member(id: userId, displayName: displayName, photoBase64: photoBase64, joinedAt: Date())

                self?.db.collection("families").document(familyId).updateData([
                    "members": FieldValue.arrayUnion([newMember.toDictionary()])
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
            var updateData: [String: Any] = ["members": remaining.map { $0.toDictionary() }]
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
            let remaining = family.members.filter { $0.id != userId }.map { $0.toDictionary() }
            ref.updateData(["members": remaining]) { error in
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

}


extension Member {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "displayName": displayName,
            "joinedAt": Timestamp(date: joinedAt)
        ]
        if let photoBase64 { dict["photoBase64"] = photoBase64 }
        return dict
    }
}
