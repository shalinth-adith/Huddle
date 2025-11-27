//
//  NameInputView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI

struct NameInputView: View {
    @State private var name: String = ""
    @State private var isLoading: Bool = false
    
    let onSubmit : (String) -> Void
    
    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()
            
            VStack(spacing: 30){
                Spacer()
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Color.huddleCoral)
                
                Text("What is Your name ?")
                    .font(.system(size: 32,weight: .bold,design: .rounded))
                    .foregroundStyle(Color.huddleCoral)
                
                Text("This how your family will see you ?")
                    .font(.system(size: 16,weight: .regular,design: .rounded))
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal,40)
                
                TextField("Enter Your Name", text: $name)
                    .font(Font.system(size: 18,design: .rounded))
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.huddleCoral.opacity(0.3),lineWidth: 1)
                    )
                    .padding(.horizontal,40)
                
                Spacer()
                
                Button(action: {
                    isLoading = true
                    onSubmit(name.trimmingCharacters(in: .whitespaces))
                }) {
                    if isLoading{
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray: Color.huddleCoral)
                .cornerRadius(16)
                .padding(.horizontal,40)
                .padding(.bottom,50)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    
                
            }
        }
    }
}

#Preview {
    NameInputView(onSubmit: {name in
    print("Name Submitted : \(name)")})
}
