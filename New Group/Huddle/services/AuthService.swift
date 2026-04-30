//
//  AuthService.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import Combine

  class AuthService: ObservableObject {
      @Published var currentUser: AppUser?
      @Published var isAuthenticated = false
      @Published var isCheckingAuth: Bool
      private(set) var photoThumbnailBase64: String?

      private let db = Firestore.firestore()

      init() {
          // Synchronous — reads local device storage, no network
          isCheckingAuth = Auth.auth().currentUser != nil
          checkAuthStatus()
      }

      // Check if user is already signed in
      func checkAuthStatus() {
          guard let firebaseUser = Auth.auth().currentUser else {
              return  // isCheckingAuth already false (set in init)
          }
          fetchUserProfile(userId: firebaseUser.uid)
      }

      // Sign in anonymously
      func signInAnonymously(displayName: String, profileImage: UIImage? = nil, completion: @escaping (Result<AppUser, Error>) -> Void) {
          DispatchQueue.global(qos: .userInitiated).async { [weak self] in
              var photoBase64: String? = nil
              var thumbnailBase64: String? = nil
              if let image = profileImage, let self {
                  // Full quality stored in user doc — shown only for current user (in-memory)
                  let full = self.resizeImage(image, maxDimension: 500)
                  if let data = full.jpegData(compressionQuality: 0.92) {
                      photoBase64 = data.base64EncodedString()
                  }
                  // Small thumbnail stored in family members array — keeps family doc small
                  let thumb = self.resizeImage(image, maxDimension: 120)
                  if let data = thumb.jpegData(compressionQuality: 0.75) {
                      thumbnailBase64 = data.base64EncodedString()
                  }
              }
              DispatchQueue.main.async {
                  self?.photoThumbnailBase64 = thumbnailBase64
                  self?._signInAnonymously(displayName: displayName, photoBase64: photoBase64, completion: completion)
              }
          }
      }

      private func _signInAnonymously(displayName: String, photoBase64: String?, completion: @escaping (Result<AppUser, Error>) -> Void) {
          Auth.auth().signInAnonymously { [weak self] authResult, error in
              if let error = error {
                  completion(.failure(error))
                  return
              }

              guard let userId = authResult?.user.uid else {
                  completion(.failure(NSError(domain: "AuthService", code: -1, userInfo:
  [NSLocalizedDescriptionKey: "Failed to get user ID"])))
                  return
              }

              let newUser = AppUser(
                  id: userId,
                  PhoneNumber: nil,
                  email: nil,
                  displayName: displayName,
                  photoBase64: photoBase64,
                  currentFamilyId: nil,
                  createdAt: Date()
              )

              self?.createUserProfile(user: newUser) { result in
                  switch result {
                  case .failure(let error):
                      completion(.failure(error))
                  case .success:
                      self?.currentUser = newUser
                      self?.isAuthenticated = true
                      completion(.success(newUser))
                  }
              }
          }
      }

private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
          let size = image.size
          guard size.width > maxDimension || size.height > maxDimension else { return image }
          let ratio = min(maxDimension / size.width, maxDimension / size.height)
          let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
          return UIGraphicsImageRenderer(size: newSize).image { _ in
              image.draw(in: CGRect(origin: .zero, size: newSize))
          }
      }

      // Create user profile in Firestore
      private func createUserProfile(user: AppUser, completion: @escaping (Result<Void, Error>) ->
   Void) {
          guard let userId = user.id else {
              completion(.failure(NSError(domain: "AuthService", code: -1, userInfo:
  [NSLocalizedDescriptionKey: "User ID is nil"])))
              return
          }

          do {
              try db.collection("users").document(userId).setData(from: user) { error in
                  if let error = error {
                      completion(.failure(error))
                  } else {
                      completion(.success(()))
                  }
              }
          } catch {
              completion(.failure(error))
          }
      }

      // Fetch user profile from Firestore
      func fetchUserProfile(userId: String) {
          let ref = db.collection("users").document(userId)

          // Serve from cache first so the app appears instantly on re-launch
          ref.getDocument(source: .cache) { [weak self] snapshot, _ in
              guard let snapshot, snapshot.exists, let data = snapshot.data(),
                    let user = try? Firestore.Decoder().decode(AppUser.self, from: data) else { return }
              DispatchQueue.main.async {
                  self?.currentUser = user
                  self?.isAuthenticated = true
                  self?.isCheckingAuth = false
              }
          }

          // Refresh from server in background (keeps data fresh without blocking UI)
          ref.getDocument(source: .server) { [weak self] snapshot, error in
              if let error {
                  print("Error fetching user profile: \(error.localizedDescription)")
                  DispatchQueue.main.async { self?.isCheckingAuth = false }
                  return
              }
              guard let data = snapshot?.data() else {
                  DispatchQueue.main.async { self?.isCheckingAuth = false }
                  return
              }
              do {
                  let user = try Firestore.Decoder().decode(AppUser.self, from: data)
                  DispatchQueue.main.async {
                      self?.currentUser = user
                      self?.isAuthenticated = true
                      self?.isCheckingAuth = false
                  }
              } catch {
                  print("Error decoding user: \(error.localizedDescription)")
                  DispatchQueue.main.async { self?.isCheckingAuth = false }
              }
          }
      }

      // Update user's active family — also adds to familyIds array
      func updateUserFamily(familyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
          guard let userId = currentUser?.id else {
              completion(.failure(NSError(domain: "AuthService", code: -1, userInfo:
  [NSLocalizedDescriptionKey: "No user logged in"])))
              return
          }
          db.collection("users").document(userId).updateData([
              "currentFamilyId": familyId,
              "familyIds": FieldValue.arrayUnion([familyId])
          ]) { [weak self] error in
              if let error { completion(.failure(error)); return }
              self?.currentUser?.currentFamilyId = familyId
              if self?.currentUser?.familyIds.contains(familyId) == false {
                  self?.currentUser?.familyIds.append(familyId)
              }
              completion(.success(()))
          }
      }

      // Switch active group without touching membership
      func switchFamily(to familyId: String, completion: @escaping () -> Void) {
          guard let userId = currentUser?.id else { completion(); return }
          db.collection("users").document(userId).updateData(["currentFamilyId": familyId]) { [weak self] _ in
              self?.currentUser?.currentFamilyId = familyId
              completion()
          }
      }

      // Remove from a group — switches active group or clears it; keeps identity
      func removeFamily(familyId: String, completion: @escaping () -> Void) {
          guard let userId = currentUser?.id else { completion(); return }
          currentUser?.familyIds.removeAll { $0 == familyId }
          let next = currentUser?.familyIds.first
          currentUser?.currentFamilyId = next
          var update: [String: Any] = ["familyIds": FieldValue.arrayRemove([familyId])]
          if let next { update["currentFamilyId"] = next } else { update["currentFamilyId"] = FieldValue.delete() }
          db.collection("users").document(userId).updateData(update) { _ in completion() }
      }

      func signOut() {
          do {
              try Auth.auth().signOut()
              currentUser = nil
              isAuthenticated = false
          } catch {
              print("Error signing out: \(error.localizedDescription)")
          }
      }
  }
