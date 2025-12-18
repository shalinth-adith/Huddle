//
//  CreateFamilyViewModel.swift
//  Huddle
//
//  Created by shalinth adithyan on 08/12/25.
//

import Foundation
import SwiftUI
import Combine

  class CreateFamilyViewModel: ObservableObject {
      @Published var familyName: String = ""
      @Published var isLoading: Bool = false
      @Published var showSuccess: Bool = false
      @Published var generatedCode: String = ""
      @Published var errorMessage: String?
      
      var isCreateButtonDisabled: Bool {
            familyName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
        }

      private let familyService: FamilyService
      private let authService: AuthService

      init(familyService: FamilyService, authService: AuthService) {
          self.familyService = familyService
          self.authService = authService
      }
      func createFamily() {
          guard let userId = authService.currentUser?.id,
                  let userName = authService.currentUser?.displayName else {
              errorMessage  = "User not found "
              return
          }
          let trimmedName = familyName.trimmingCharacters(in: .whitespaces)
          guard !trimmedName.isEmpty else {
              return
          }
          isLoading = true
          errorMessage = nil
          familyService.createFamily(familyName: trimmedName, creatorId: userId, creatorName: userName) {  result in
              self.isLoading = false
              switch result {
                case .success(let family):
                  if let familyId = family.id {
                       self.authService.updateUserFamily(familyId: familyId) { result in
                           switch result {
                           case .success:
                               self.generatedCode = family.code
                               self.showSuccess = true
                               
                           case .failure(let error):
                               self.errorMessage = "Error: \(error.localizedDescription)"
                           }
                       }
                   }


                case .failure(let error):
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }

          }
          
      }

  }
