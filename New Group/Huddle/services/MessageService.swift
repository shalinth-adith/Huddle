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
    
    func fetchShoppingItems(familyId : String ,completion : @escaping(Result <[HuddleMessage],Error>) -> Void){
        db.collection("families")
            .document(familyId)
            .collection("messages")
            .whereField("type", isEqualTo: MessageType.Shopping.rawValue)
            .order(by: "createdAt",descending: false)
            .getDocuments { Snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = Snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                do {
                    let messages = try documents.compactMap{ doc in
                        try doc.data(as:HuddleMessage.self)
                    }
                    completion(.success(messages))
                } catch {
                    completion(.failure(error))
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
     }




    
    
