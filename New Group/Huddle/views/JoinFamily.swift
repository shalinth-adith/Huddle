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
    @StateObject private var viewModel: JoinFamilyViewModel

    
    init(authService: AuthService) {
          _viewModel = StateObject(wrappedValue: JoinFamilyViewModel(
              familyService: FamilyService(),
              authService: authService
          ))
      }

        
    
    
    var body: some View {
        ZStack{
            Color.huddleBackground.ignoresSafeArea()
            
            if viewModel.showSuccess{
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
            
            TextField("H-000000", text: $viewModel.familyCode)
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
                .onChange(of: viewModel.familyCode) { newValue in
                      viewModel.formatFamilyCode(newValue)
                  }
            if let error = viewModel.errorMessage {
                 Text(error)
                     .font(.system(size: 14, design: .rounded))
                     .foregroundColor(.red)
                     .padding(.horizontal, 40)
             }
        
            
            Spacer()
            
            
            Button(action: viewModel.joinFamily) {
                if viewModel.isLoading {
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
              .background(viewModel.isValidCode ? Color.huddleCoral : Color.gray)
              .cornerRadius(16)
              .padding(.horizontal, 40)
              .padding(.bottom, 50)
              .disabled(!viewModel.isValidCode || viewModel.isLoading)
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

            Text(viewModel.joinedFamilyName)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.huddleCoral)
                .padding(.horizontal, 40)
                .multilineTextAlignment(.center)

            Text("You're now part of \(viewModel.joinedFamilyName)")
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

    
    
   
}

#Preview {
     JoinFamily(authService: AuthService())
 }





