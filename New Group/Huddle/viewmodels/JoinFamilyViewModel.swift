//
//  JoinFamilyViewModel.swift
//  Huddle
//
//  Created by shalinth adithyan on 22/12/25.
//

import SwiftUI
import Foundation
import Combine

class JoinFamilyViewModel: ObservableObject {
    @Published var familyCode: String = "H-"
    @Published var isLoading: Bool = false
    @Published var showSuccess: Bool = false
    @Published var joinedFamilyName: String = ""
    @Published var errorMessage: String?
    
    private let familyService: FamilyService
    private let authService: AuthService
    
    init(familyService: FamilyService, authService: AuthService) {
        self.familyService = familyService
        self.authService = authService
    }
    
     func joinFamily() {
        guard let userId = authService.currentUser?.id,
              let userName = authService.currentUser?.displayName else {
            self.errorMessage = "User Not Found"
            return
            
        }
        self.isLoading = true
        self.errorMessage = nil
        
        familyService.joinFamily(code: familyCode, userId: userId, displayName: userName, photoBase64: authService.photoThumbnailBase64) { result in
            self.isLoading = false
            switch result {
            case .success(let family):
                if let familyId = family.id{
                    self.authService.updateUserFamily(familyId: familyId) { updatedResult in
                        switch updatedResult{
                        case.success:
                            self.joinedFamilyName = family.name
                            withAnimation{
                                self.showSuccess = true
                            }
                        case .failure(let error):
                            self.errorMessage = "Error : \(error.localizedDescription)"
                            
                            
                        }
                        
                    }
                }
                
            case .failure(let error):
                if error.localizedDescription.contains("Family not found") {
                    self.errorMessage = "Invalid code. Please check and try again."
                } else {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
                
            }
            
        }
    }
     var isValidCode: Bool {
          familyCode.count == 8 &&
          familyCode.hasPrefix("H-") &&
          familyCode.dropFirst(2).allSatisfy { $0.isNumber }
      }
    func formatFamilyCode(_ newValue: String) {
        if !newValue.hasPrefix("H-") {
            familyCode = "H-"
            return
        }

        let digitsOnly = newValue.dropFirst(2).filter { $0.isNumber }

        if digitsOnly.count <= 6 {
            familyCode = "H-\(digitsOnly)"
        } else {
            familyCode = "H-\(digitsOnly.prefix(6))"
        }
      }
}
