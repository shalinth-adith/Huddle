//
//  AuthService.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

  class AuthService: ObservableObject {
      @Published var currentUser: AppUser?
      @Published var isAuthenticated = false

      private let db = Firestore.firestore()

      init() {
          checkAuthStatus()
      }

      // Check if user is already signed in
      func checkAuthStatus() {
          if let firebaseUser = Auth.auth().currentUser {
              // User is signed in, fetch their profile
              fetchUserProfile(userId: firebaseUser.uid)
          }
      }

      // Sign in anonymously
      func signInAnonymously(displayName: String, completion: @escaping (Result<AppUser, Error>)
  -> Void) {
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
                  currentFamilyId: nil,
                  createdAt: Date()
              )

              self?.createUserProfile(user: newUser) { result in
                  switch result {
                  case .success:
                      self?.currentUser = newUser
                      self?.isAuthenticated = true
                      completion(.success(newUser))
                  case .failure(let error):
                      completion(.failure(error))
                  }
              }
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
          db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
              if let error = error {
                  print("Error fetching user profile: \(error.localizedDescription)")
                  return
              }

              guard let data = snapshot?.data() else {
                  print("User profile not found")
                  return
              }

              do {
                  let user = try Firestore.Decoder().decode(AppUser.self, from: data)
                  self?.currentUser = user
                  self?.isAuthenticated = true
              } catch {
                  print("Error decoding user: \(error.localizedDescription)")
              }
          }
      }

      // Update user's family ID
      func updateUserFamily(familyId: String, completion: @escaping (Result<Void, Error>) -> Void)
   {
          guard let userId = currentUser?.id else {
              completion(.failure(NSError(domain: "AuthService", code: -1, userInfo:
  [NSLocalizedDescriptionKey: "No user logged in"])))
              return
          }

          db.collection("users").document(userId).updateData([
              "currentFamilyId": familyId
          ]) { [weak self] error in
              if let error = error {
                  completion(.failure(error))
              } else {
                  self?.currentUser?.currentFamilyId = familyId
                  completion(.success(()))
              }
          }
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
