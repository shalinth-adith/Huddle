//
//  CreateFamily.swift
//  Huddle
//
//  Created by shalinth adithyan on 27/11/25.
//

import SwiftUI

struct CreateFamily: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: CreateFamilyViewModel
    @Environment(\.dismiss) var dismiss
    
    
    
    init() {
        _viewModel = StateObject(wrappedValue: CreateFamilyViewModel(
            familyService: FamilyService(),
            authService: AuthService()
        ))
    }

    
    
    
    
    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()
            
            if viewModel.showSuccess{
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
                .buttonStyle(.plain) 

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
            
            TextField("Family Name : ", text: $viewModel.familyName)
                .font(.system(size: 18,design: .rounded))
                .foregroundColor(.black)

                .autocorrectionDisabled(true)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.huddleCoral.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal,40)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 14,design: .rounded))
                    .foregroundColor(.red)
                    .padding(.horizontal,40)
            }
            
            Spacer()
            
            Button(action: viewModel.createFamily){
                if viewModel.isLoading{
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
            .background(viewModel.isCreateButtonDisabled ? Color.gray : Color.huddleCoral)
            .cornerRadius(16)
            .padding(.horizontal,40)
            .padding(.bottom,50)
            .buttonStyle(.plain)  

            .disabled(viewModel.isCreateButtonDisabled)

            
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

             Text(viewModel.generatedCode)
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
}

 #Preview {
     CreateFamily()
         .environmentObject(AuthService())
 }


#Preview {
    CreateFamily()
}
