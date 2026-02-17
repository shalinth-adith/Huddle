//
//  CreateJoinFamily.swift
//  Huddle
//
//  Created by shalinth adithyan on 26/11/25.
//

import SwiftUI

struct CreateJoinFamily: View {
    @EnvironmentObject var authService: AuthService
    @State private var showCreateFamily = false
    @State private var showJoinFamily = false
    
    var body: some View {
        ZStack{
            Color.huddleBackground
                .ignoresSafeArea()
            VStack(spacing: 30 ){
                
                     Spacer()

                     Button(action: {
                         authService.signOut()
                     }) {
                         Text("Sign Out (Testing)")
                             .font(.system(size: 14, design: .rounded))
                             .foregroundColor(.red)
                     }
                     .padding(.top, 20)

                    
                     Image(systemName: "house.circle.fill")
                    .font(.system(size:80))
                    .foregroundStyle(Color.huddleCoral)
                
                Text("Join Your Family")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.huddleCoral)
                    .multilineTextAlignment(.center)
                
                Text("Create a new family or join an existing one")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
                VStack(spacing: 16) {
                                      
                                      Button(action: {
                                          showCreateFamily = true
                                      }) {
                                          HStack {
                                              Image(systemName: "plus.circle.fill")
                                              Text("Create Family")
                                          }
                                          .font(.system(size: 18, weight: .semibold, design: .rounded))
                                          .foregroundColor(.white)
                                          .frame(maxWidth: .infinity)
                                          .padding()
                                          .background(Color.huddleCoral)
                                          .cornerRadius(16)
                                      }

                                 
                                      Button(action: {
                                          showJoinFamily = true
                                      }) {
                                          HStack {
                                              Image(systemName: "person.2.fill")
                                              Text("Join Family")
                                          }
                                          .font(.system(size: 18, weight: .semibold, design: .rounded))
                                          .foregroundColor(.huddleCoral)
                                          .frame(maxWidth: .infinity)
                                          .padding()
                                          .background(Color.white)
                                          .cornerRadius(16)
                                          .overlay(
                                              RoundedRectangle(cornerRadius: 16)
                                                  .stroke(Color.huddleCoral, lineWidth: 2)
                                          )
                                      }
                                  }
                                  .padding(.horizontal, 40)
                                  .padding(.bottom, 50)
                              }
                                .buttonStyle(.plain)

                          }
                            .sheet(isPresented: $showCreateFamily) {
                                    CreateFamily()
                                    .environmentObject(authService)
                                }
                            .sheet(isPresented: $showJoinFamily) {
                                JoinFamily(authService: authService)
                                      .environmentObject(authService)
                              }
                      }
                  }


#Preview {
    CreateJoinFamily()
}
