//
//  WelcomeView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    var body: some View {
        ZStack{
            Color.huddleBackground.ignoresSafeArea(edges: .all)
            
            VStack(alignment: .center, spacing: 20){
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.huddleCoral)
                
                Text("Huddle")
                    .font(.system(size: 48,weight: .bold,design: .rounded))
                    .foregroundStyle(Color.huddleCoral)
                
                Text("Your Family in one Place ")
                    .font(.system(size: 20,weight: .medium,design:.rounded))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.system(size: 18,weight: .semibold,design:.rounded))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.huddleCoral)
                        .cornerRadius(16)
                }
                .padding(.horizontal,40)
                .padding(.bottom,50)
            }
            .buttonStyle(.plain)  

        }
    }
}

#Preview {
    WelcomeView(onGetStarted: {
        print("Get started Tapped!")
    })
}
