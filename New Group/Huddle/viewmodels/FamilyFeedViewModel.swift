//
//  FamilyFeedViewModel.swift
//  Huddle
//
//  Created by shalinth adithyan on 22/12/25.
//
import Foundation
import SwiftUI
import Combine

class FamilyFeedViewModel: ObservableObject {
    @Published var family: Family?
    @Published var isLoading = true
    @Published var showShareSheet = false
    @Published var showShoppingList = false

    private let familyService: FamilyService
    private let authService: AuthService
    
    init(familyService: FamilyService, authService: AuthService) {
        self.familyService = familyService
        self.authService = authService
    }
    func loadFamily() {
        print("🔍 Loading family...")

        guard let familyId = authService.currentUser?.currentFamilyId else {
            print("❌ No familyId found!")
            self.isLoading = false
            return
        }

        print("✅ FamilyId found: \(familyId)")

        familyService.fetchFamily(familyId: familyId) { result in
            print("📦 Fetch completed")
            self.isLoading = false

            switch result {
            case .success(let fetchedFamily):
                print("✅ Family loaded: \(fetchedFamily.name)")
                self.family = fetchedFamily
            case .failure(let error):
                print("❌ Error loading family: \(error.localizedDescription)")
            }
        }
    }

    
}

