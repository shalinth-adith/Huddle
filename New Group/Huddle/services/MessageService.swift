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
    
    func fetchShoppingItems(familyId: String, completion: @escaping (Result<[HuddleMessage], Error>) -> Void) {
        let query = db.collection("families")
            .document(familyId)
            .collection("messages")
            .whereField("type", isEqualTo: MessageType.Shopping.rawValue)
            .order(by: "createdAt", descending: false)

        let decode: (QuerySnapshot) throws -> [HuddleMessage] = { snapshot in
            try snapshot.documents.compactMap { try $0.data(as: HuddleMessage.self) }
        }

        query.getDocuments(source: .cache) { snapshot, _ in
            if let snapshot, let messages = try? decode(snapshot) {
                completion(.success(messages))
            }
        }
        query.getDocuments(source: .server) { snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let snapshot else { return }
            do { completion(.success(try decode(snapshot))) } catch { completion(.failure(error)) }
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

              let message = HuddleMessage(
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
                      .setData(from: message) { error in
                          if let error = error {
                              completion(.failure(error))
                          } else {
                              completion(.success(message))
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

        let decode: (QuerySnapshot) throws -> [HuddleMessage] = { snapshot in
            try snapshot.documents.compactMap { try $0.data(as: HuddleMessage.self) }
        }

        query.getDocuments(source: .cache) { snapshot, _ in
            if let snapshot, let messages = try? decode(snapshot) {
                completion(.success(messages))
            }
        }
        query.getDocuments(source: .server) { snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let snapshot else { return }
            do { completion(.success(try decode(snapshot))) } catch { completion(.failure(error)) }
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

         let message = HuddleMessage(
             id: messageId,
             familyID: familyId,
             senderID: senderId,
             senderName: senderName,
             type: .text,
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
                 .setData(from: message) { error in
                     if let error = error {
                         completion(.failure(error))
                     } else {
                         completion(.success(message))
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
        let message = HuddleMessage(
            id: messageId,
            familyID: familyId,
            senderID: senderId,
            senderName: senderName,
            type: .ping,
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
                .setData(from: message) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(message))
                    }
                }
        } catch {
            completion(.failure(error))
        }
    }

    func sendSystemMessage(familyId: String, content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let message = HuddleMessage(
            familyID: familyId,
            senderID: "system",
            senderName: "system",
            type: .system,
            content: content,
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
                    completion(.success(messages))
                } catch {
                    completion(.failure(error))
                }
            }
    }
}




    
    
