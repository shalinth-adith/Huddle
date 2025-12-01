import Foundation
import FirebaseFirestore
import FirebaseAuth

class FamilyService  {
    private let db = Firestore.firestore()

  
    private func generateFamilyCode() -> String {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        return "H-\(code)"
    }

 
    func createFamily(familyName: String, creatorId: String, creatorName: String, completion:
@escaping (Result<Family, Error>) -> Void) {
        let familyCode = generateFamilyCode()

     
        checkCodeExists(code: familyCode) { [weak self] exists in
            if exists {
                
                self?.createFamily(familyName: familyName, creatorId: creatorId, creatorName:
creatorName, completion: completion)
                return
            }

           
            let familyId = UUID().uuidString
            let member = Member(id: creatorId, displayName: creatorName, joinedAt: Date())

            let family = Family(
                id: familyId,
                name: familyName,
                code: familyCode,
                members: [member],

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

    

    func joinFamily(code: String, userId: String, displayName: String, completion:
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

               
                let newMember = Member(id: userId, displayName: displayName, joinedAt: Date())

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

   
    func fetchFamily(familyId: String, completion: @escaping (Result<Family, Error>) -> Void) {
        db.collection("families").document(familyId).getDocument(source: .default) { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                let error = NSError(domain: "FamilyService", code: 404, userInfo:
[NSLocalizedDescriptionKey: "Family not found"])
                completion(.failure(error))
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
        return [
            "id": id,
            "displayName": displayName,
            "joinedAt": Timestamp(date: joinedAt)
        ]
    }
}
