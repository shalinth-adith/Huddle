//
//  CreateFamily.swift
//  Huddle
//
//  Created by shalinth adithyan on 27/11/25.
//

import SwiftUI

struct CreateFamily: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var familyName: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var generateCode: String = ""
    @State private var errorMessage: String?
    
    private var familyService = FamilyService()
    
    
    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()
            
            if showSuccess{
                successView
            } else {
                inputView
            }
        }
    }
    
    private var inputView: some View {
        VStack(spacing: 30) {
            HStack{
                Button(action: {dismiss() }){
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(.gray))
                }
                Spacer()
            }
            .padding(.horizontal,20)
            .padding(.top,20)
            
            Spacer()
            
            Image(systemName: "house.fill")
                .font(.system(size: 70))
                .foregroundColor(.huddleCoral)
            
            Text("Create your Family")
                .font(.system(size: 32,weight: .bold,design: .rounded))
                .foregroundColor(.huddleCoral)
            
            Text("Choose a name for your Family")
                .font(.system(size: 16,weight: .medium,design: .rounded))
                .foregroundColor(.gray)
            
            TextField("Family Name : ", text: $familyName)
                .font(.system(size: 18,design: .rounded))
                .autocorrectionDisabled(true)  
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.huddleCoral.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal,40)
            
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14,design: .rounded))
                    .foregroundColor(.red)
                    .padding(.horizontal,40)
            }
            
            Spacer()
            
            Button(action: createFamily){
                if isLoading{
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }else{
                    Text("Create Family")
                        .font(.system(size: 18,weight: .semibold,design: .rounded))
                        .foregroundColor(.white)
                    
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(familyName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.huddleCoral)
            .cornerRadius(16)
            .padding(.horizontal,40)
            .padding(.bottom,50)
            .disabled(familyName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            
            
        }
    }
    private var successView: some View {
         VStack(spacing: 30){
             Spacer()

             Image(systemName: "checkmark.circle.fill")
                 .font(.system(size: 80))
                 .foregroundColor(.green)

             Text("Family Created")
                 .font(.system(size: 14,weight: .medium,design: .rounded))
                 .foregroundColor(.gray)

             Text(generateCode)
                 .font(.system(size: 48, weight: .bold, design: .rounded))
                 .foregroundColor(.huddleCoral)
                 .tracking(4)
                 .minimumScaleFactor(0.5)      
                 .lineLimit(1)
                 .padding()
                 .background(Color.white)
                 .cornerRadius(16)
                 .overlay(
                     RoundedRectangle(cornerRadius: 16)
                         .stroke(Color.huddleCoral, lineWidth: 2)
                 )
                 .padding(.horizontal, 40)

             Text("Share this code with family members so they can join")
                 .font(.system(size: 14, weight: .medium, design: .rounded))
                 .foregroundColor(.gray)
                 .multilineTextAlignment(.center)
                 .padding(.horizontal, 40)

             Spacer()

             Button(action: {
                 dismiss()
             }){
                 Text("Continue")
                     .font(.system(size: 18,weight: .semibold,design: .rounded))
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

    
    private func createFamily() {
        guard let userId = authService.currentUser?.id,
              let userName = authService.currentUser?.displayName else {
            errorMessage = "User not found"
            return
        }
        
        let trimmedName = familyName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        familyService.createFamily(
            familyName: trimmedName,
            creatorId: userId,
            creatorName: userName
        ) { [self] result in
            isLoading = false
            
            switch result {
            case .success(let family):
                
                if let familyId = family.id {
                    authService.updateUserFamily(familyId: familyId) { result in
                        switch result {
                        case .success:
                            generateCode = family.code
                            withAnimation {
                                showSuccess = true
                            }
                        case .failure(let error):
                            errorMessage = "Error: \(error.localizedDescription)"
                        }
                    }
                }
                
            case .failure(let error):
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
}

 #Preview {
     CreateFamily()
         .environmentObject(AuthService())
 }


#Preview {
    CreateFamily()
}
