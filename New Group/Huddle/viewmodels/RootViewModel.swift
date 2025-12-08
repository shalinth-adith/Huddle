//
//  RootViewModel.swift
//  Huddle
//
//  Created by shalinth adithyan on 08/12/25.
//

import Foundation
import Combine


class RootViewModel: ObservableObject {
    @Published var showNameInput: Bool = false
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    func signIn(name: String) {
        authService.signInAnonymously(displayName: name) { result in
            switch result {
            case .success(let user):
                  print("✅ Signed in: \(user.displayName)")
                  self.showNameInput = false
            
                
            case .failure(let error):
                  print("❌ Error: \(error.localizedDescription)")
              
            }
        }
    }
}


    
    
    

