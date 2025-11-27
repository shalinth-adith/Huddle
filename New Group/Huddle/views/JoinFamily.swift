//
//  JoinFamily.swift
//  Huddle
//
//  Created by shalinth adithyan on 27/11/25.
//

import SwiftUI

struct JoinFamily: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var familyCode: String = "H-"
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var joinedFamilyName: String = ""
    @State private var errorMessage: String?
    
    private var familyService = FamilyService()
        
    
    
    var body: some View {
        ZStack{
            Color.huddleBackground.ignoresSafeArea()
            
            if showSuccess{
                successView
            }else{
                inputView
            }
        }
    
    }
    private var inputView: some View {
        VStack(spacing: 30){
            HStack{
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.gray)
                }
                Spacer()
            }
            .padding(.horizontal,20)
            .padding(.top,20)
            Spacer()
            
            Image(systemName: "person.2.fill")
                .font(.system(size:70))
                .foregroundColor(Color.huddleCoral)
            
            Text("Join Your Family")
                .font(.system(size: 32,weight: .bold,design: .rounded))
                .foregroundColor(Color.huddleCoral)
            
            Text("Enter the family Code")
                .font(.system(size: 16,weight: .medium,design: .rounded))
                .foregroundColor(.gray)
            
            TextField("H-000000", text: $familyCode)
                .font(.system(size: 18,design: .rounded))
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.huddleCoral, lineWidth: 1)
                )
                .padding(.horizontal,40)
                .autocapitalization(.allCharacters)
                .onChange(of: familyCode) { newValue in
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

            if let error = errorMessage {
                 Text(error)
                     .font(.system(size: 14, design: .rounded))
                     .foregroundColor(.red)
                     .padding(.horizontal, 40)
             }
        
            
            Spacer()
            
            
            Button(action: joinFamily) {
                  if isLoading {
                      ProgressView()
                          .progressViewStyle(CircularProgressViewStyle(tint: .white))
                  } else {
                      Text("Join Family")
                          .font(.system(size: 18, weight: .semibold, design: .rounded))
                          .foregroundColor(.white)
                  }
              }
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(isValidCode ? Color.huddleCoral : Color.gray)
              .cornerRadius(16)
              .padding(.horizontal, 40)
              .padding(.bottom, 50)
              .disabled(!isValidCode || isLoading)
        }
    }
    
    private var successView: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Joined Successfully!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.gray)

            Text(joinedFamilyName)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.huddleCoral)
                .padding(.horizontal, 40)
                .multilineTextAlignment(.center)

            Text("You're now part of \(joinedFamilyName)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: {
                dismiss()
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.huddleCoral)
            .cornerRadius(16)
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    
    
    private func joinFamily() {
        guard let userId = authService.currentUser?.id,
              let userName = authService.currentUser?.displayName else {
            errorMessage = "User Not Found"
            return
            
        }
        isLoading = true
        errorMessage = nil
        
        familyService.joinFamily(code:familyCode,userId: userId , displayName: userName){ result in
            isLoading = false
            switch result {
            case .success(let family):
                if let familyId = family.id{
                    authService.updateUserFamily(familyId: familyId) { updatedResult in
                        switch updatedResult{
                        case.success:
                            joinedFamilyName = family.name
                            withAnimation{
                                showSuccess = true
                            }
                        case .failure(let error):
                            errorMessage = "Error : \(error.localizedDescription)"
                            
                            
                        }
                        
                    }
                }
               
            case .failure(let error):
                if error.localizedDescription.contains("Family not found") {
                                 errorMessage = "Invalid code. Please check and try again."
                             } else {
                                 errorMessage = "Error: \(error.localizedDescription)"
                             }

            }
            
        }
      }
    private var isValidCode: Bool {
          familyCode.count == 8 &&
          familyCode.hasPrefix("H-") &&
          familyCode.dropFirst(2).allSatisfy { $0.isNumber }
      }
}

#Preview {
    JoinFamily()
              .environmentObject(AuthService())
}




