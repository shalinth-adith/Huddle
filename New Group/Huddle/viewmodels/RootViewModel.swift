//
//  RootViewModel.swift
//  Huddle
//
//  Created by shalinth adithyan on 08/12/25.
//

import Foundation
import Combine
import UIKit

class RootViewModel: ObservableObject {
    @Published var showNameInput: Bool = false
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func signIn(name: String, image: UIImage? = nil) {
        authService.signInAnonymously(displayName: name, profileImage: image) { result in
            switch result {
            case .success(let user):
                debugLog("✅ Signed in: \(user.displayName)")
                self.showNameInput = false
            case .failure(let error):
                debugLog("❌ Error: \(error.localizedDescription)")
            }
        }
    }
}


    
    
    

