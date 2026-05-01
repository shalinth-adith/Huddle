//
//  MessageService.swift
//  Huddle
//
//  Created by shalinth adithyan on 01/12/25.
//

import Foundation
import FirebaseFirestore

class MessageService {
    private let db = Firestore.firestore()

    private func decrypted(_ messages: [HuddleMessage], familyId: String) -> [HuddleMessage] {
        guard let groupKey = EncryptionService.loadGroupKey(familyId: familyId) else { return messages }
        return messages.map { msg in
            var m = msg
            if let plain = EncryptionService.decrypt(m.content, groupKey: groupKey) {
                m.content = plain
            }
            return m
        }
    }

    private func encryptedContent(_ content: String, familyId: String) -> String {
        guard let groupKey = EncryptionService.loadGroupKey(familyId: familyId),
              let cipher = try? EncryptionService.encrypt(content, groupKey: groupKey) else {
            return content
        }
        return cipher
    }

    func fetchShoppingItems(familyId: String, completion: @escaping (Result<[HuddleMessage], Error>) -> Void) {
        let query = db.collection("families")
            .document(familyId)
            .collection("messages")
            .whereField("type", isEqualTo: MessageType.Shopping.rawValue)
            .order(by: "createdAt", descending: false)

        let decode: (QuerySnapshot) -> [HuddleMessage] = { snapshot in
            (try? snapshot.documents.compactMap { try $0.data(as: HuddleMessage.self) }) ?? []
        }

        query.getDocuments(source: .cache) { [weak self] snapshot, _ in
            guard let snapshot else { return }
            let msgs = decode(snapshot)
            DispatchQueue.global(qos: .utility).async {
                let result = self?.decrypted(msgs, familyId: familyId) ?? msgs
                DispatchQueue.main.async { completion(.success(result)) }
            }
        }
        query.getDocuments(source: .server) { [weak self] snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let snapshot else { return }
            let msgs = decode(snapshot)
            DispatchQueue.global(qos: .utility).async {
                let result = self?.decrypted(msgs, familyId: familyId) ?? msgs
                DispatchQueue.main.async { completion(.success(result)) }
            }
        }
    }
    func addShoppingItem(
              familyId: String,
              content: String,
              senderId: String,
              senderName: String,
              completion: @escaping (Result<HuddleMessage, Error>) -> Void
          ) {
              let messageId = UUID().uuidString
              let storedContent = encryptedContent(content, familyId: familyId)

              let firestoreMessage = HuddleMessage(
                  id: messageId,
                  familyID: familyId,
                  senderID: senderId,
                  senderName: senderName,
                  type: .Shopping,
                  content: storedContent,
                  photoURL: nil,
                  isPinned: false,
                  isCompleted: false,
                  createdAt: Date()
              )
              let returnMessage = HuddleMessage(
                  id: messageId,
                  familyID: familyId,
                  senderID: senderId,
                  senderName: senderName,
                  type: .Shopping,
                  content: content,
                  photoURL: nil,
                  isPinned: false,
                  isCompleted: false,
                  createdAt: Date()
              )

              do {
                  try db.collection("families")
                      .document(familyId)
                      .collection("messages")
                      .document(messageId)
                      .setData(from: firestoreMessage) { error in
                          if let error = error {
                              completion(.failure(error))
                          } else {
                              completion(.success(returnMessage))
                          }
                      }
              } catch {
                  completion(.failure(error))
              }
          }
    func toggleCompletion(
             familyId: String,
             messageId: String,
             isCompleted: Bool,
             completion: @escaping (Result<Void, Error>) -> Void
         ) {
             db.collection("families")
                 .document(familyId)
                 .collection("messages")
                 .document(messageId)
                 .updateData(["isCompleted": isCompleted]) { error in
                     if let error = error {
                         completion(.failure(error))
                     } else {
                         completion(.success(()))
                     }
                 }
         }

         func deleteMessage(
             familyId: String,
             messageId: String,
             completion: @escaping (Result<Void, Error>) -> Void
         ) {
             db.collection("families")
                 .document(familyId)
                 .collection("messages")
                 .document(messageId)
                 .delete { error in
                     if let error = error {
                         completion(.failure(error))
                     } else {
                         completion(.success(()))
                     }
                 }
         }
    func togglePin(
          familyId: String,
          messageId: String,
          isPinned: Bool,
          completion: @escaping (Result<Void, Error>) -> Void
      ) {
          db.collection("families")
              .document(familyId)
              .collection("messages")
              .document(messageId)
              .updateData(["isPinned": isPinned]) { error in
                  if let error = error {
                      completion(.failure(error))
                  } else {
                      completion(.success(()))
                  }
              }
      }
    func fetchPinnedMessages(
        familyId: String,
        completion: @escaping (Result<[HuddleMessage], Error>) -> Void
    ) {
        let query = db.collection("families")
            .document(familyId)
            .collection("messages")
            .whereField("isPinned", isEqualTo: true)
            .whereField("type", isEqualTo: MessageType.text.rawValue)
            .order(by: "createdAt", descending: false)

        let decode: (QuerySnapshot) -> [HuddleMessage] = { snapshot in
            (try? snapshot.documents.compactMap { try $0.data(as: HuddleMessage.self) }) ?? []
        }

        query.getDocuments(source: .cache) { [weak self] snapshot, _ in
            guard let snapshot else { return }
            let msgs = decode(snapshot)
            DispatchQueue.global(qos: .utility).async {
                let result = self?.decrypted(msgs, familyId: familyId) ?? msgs
                DispatchQueue.main.async { completion(.success(result)) }
            }
        }
        query.getDocuments(source: .server) { [weak self] snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let snapshot else { return }
            let msgs = decode(snapshot)
            DispatchQueue.global(qos: .utility).async {
                let result = self?.decrypted(msgs, familyId: familyId) ?? msgs
                DispatchQueue.main.async { completion(.success(result)) }
            }
        }
    }


    func sendChatMessage(
         familyId: String,
         content: String,
         senderId: String,
         senderName: String,
         completion: @escaping (Result<HuddleMessage, Error>) -> Void
     ) {
         let messageId = UUID().uuidString
         let storedContent = encryptedContent(content, familyId: familyId)

         let firestoreMessage = HuddleMessage(
             id: messageId, familyID: familyId, senderID: senderId, senderName: senderName,
             type: .text, content: storedContent, photoURL: nil, isPinned: false, isCompleted: false, createdAt: Date()
         )
         let returnMessage = HuddleMessage(
             id: messageId, familyID: familyId, senderID: senderId, senderName: senderName,
             type: .text, content: content, photoURL: nil, isPinned: false, isCompleted: false, createdAt: Date()
         )

         do {
             try db.collection("families")
                 .document(familyId)
                 .collection("messages")
                 .document(messageId)
                 .setData(from: firestoreMessage) { error in
                     if let error = error {
                         completion(.failure(error))
                     } else {
                         completion(.success(returnMessage))
                     }
                 }
         } catch {
             completion(.failure(error))
         }
     }
    func sendPingMessage(
        familyId: String,
        content: String,
        senderId: String,
        senderName: String,
        completion: @escaping (Result<HuddleMessage, Error>) -> Void
    ) {
        let messageId = UUID().uuidString
        let storedContent = encryptedContent(content, familyId: familyId)

        let firestoreMessage = HuddleMessage(
            id: messageId, familyID: familyId, senderID: senderId, senderName: senderName,
            type: .ping, content: storedContent, photoURL: nil, isPinned: false, isCompleted: false, createdAt: Date()
        )
        let returnMessage = HuddleMessage(
            id: messageId, familyID: familyId, senderID: senderId, senderName: senderName,
            type: .ping, content: content, photoURL: nil, isPinned: false, isCompleted: false, createdAt: Date()
        )
        do {
            try db.collection("families")
                .document(familyId)
                .collection("messages")
                .document(messageId)
                .setData(from: firestoreMessage) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(returnMessage))
                    }
                }
        } catch {
            completion(.failure(error))
        }
    }

    func sendSystemMessage(familyId: String, content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storedContent = encryptedContent(content, familyId: familyId)
        let message = HuddleMessage(
            familyID: familyId,
            senderID: "system",
            senderName: "system",
            type: .system,
            content: storedContent,
            isPinned: false,
            isCompleted: false,
            createdAt: Date()
        )
        do {
            try db.collection("families").document(familyId)
                .collection("messages").addDocument(from: message) { error in
                    if let error { completion(.failure(error)); return }
                    completion(.success(()))
                }
        } catch {
            completion(.failure(error))
        }
    }

    func toggleReaction(familyId: String, messageId: String, emoji: String, userId: String, add: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let field = "reactions.\(emoji)"
        let value: Any = add ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId])
        db.collection("families").document(familyId)
          .collection("messages").document(messageId)
          .updateData([field: value]) { error in
              if let error { completion(.failure(error)); return }
              completion(.success(()))
          }
    }

    func listenToMessages(
          familyId: String,
          completion: @escaping (Result<[HuddleMessage], Error>) -> Void
    ) -> ListenerRegistration {
        
        return db.collection("families")
              .document(familyId)
              .collection("messages")
              .whereField("type", in: [MessageType.text.rawValue, MessageType.system.rawValue, MessageType.ping.rawValue])
              .order(by: "createdAt", descending: false)
              .limit(to: 50) 
              .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                do {
                    let messages = try documents.compactMap { doc in
                        try doc.data(as: HuddleMessage.self)
                    }
                    DispatchQueue.global(qos: .userInitiated).async {
                        let result = self.decrypted(messages, familyId: familyId)
                        DispatchQueue.main.async { completion(.success(result)) }
                    }
                } catch {
                    completion(.failure(error))
                }
            }
    }
}




    
    
