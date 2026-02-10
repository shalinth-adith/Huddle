import SwiftUI

 struct FamilyFeedView: View {
     @EnvironmentObject var authService: AuthService
     @StateObject private var viewModel: FamilyFeedViewModel
     @State private var messageText: String = ""

     
     @FocusState private var isMessageFieldFocused: Bool
     @State private var isChatExpanded = false


     init(authService: AuthService) {
         _viewModel = StateObject(wrappedValue: FamilyFeedViewModel(
             familyService: FamilyService(),
             authService: authService,
             messageService: MessageService()
         ))
     }

     var body: some View {
         ZStack {
               Color.huddleBackground.ignoresSafeArea()

               if viewModel.isLoading {
                   ProgressView()
               } else if let family = viewModel.family {
                   if isChatExpanded {
                       expandedChatView(family: family)
                   } else {
                       feedContent(family: family)  
                   }
               } else {
                   Text("Error loading family")
               }

               VStack {
                   Spacer()
                   messageInputField()
               }
           }

           .onTapGesture {
               isMessageFieldFocused = false
           }
           .onAppear {
               viewModel.loadFamily()
               viewModel.loadMessages()
               viewModel.loadShoppingItems()
               viewModel.loadPinnedMessages()

           }
           .onDisappear {
               viewModel.cleanup()
           }
           .sheet(isPresented: $viewModel.showShareSheet) {
               shareSheet
           }
           .sheet(isPresented: $viewModel.showShoppingList, onDismiss: {
                viewModel.loadShoppingItems()
            }) {
                if let family = viewModel.family {
                    ShoppingList(family: family)
                        .environmentObject(authService)
                }
            }                           
       }




     private func feedContent(family: Family) -> some View {
         VStack(spacing: 0) {
             headerSection(family: family)
             membersSection(family: family)
             shoppingListPreview()
             pinnedSection()
             messagesSection()
         }
     }
     private func expandedChatView(family: Family) -> some View {
               VStack(spacing: 0) {
                   VStack(spacing: 8) {
                       RoundedRectangle(cornerRadius: 3)
                           .fill(Color.gray.opacity(0.5))
                           .frame(width: 40, height: 5)
                           .padding(.top, 12)

                       HStack {
                           Image(systemName: "message.fill")
                               .font(.system(size: 18))
                               .foregroundColor(.huddleCoral)

                           Text("Messages")
                               .font(.system(size: 20, weight: .semibold, design: .rounded))
                               .foregroundColor(.black)

                           Spacer()

                           Button(action: {
                               withAnimation(.spring()) {
                                   isChatExpanded = false
                               }
                           }) {
                               Image(systemName: "xmark.circle.fill")
                                   .font(.system(size: 24))
                                   .foregroundColor(.gray)
                           }
                       }
                       .padding(.horizontal, 20)
                       .padding(.vertical, 12)
                   }
                   .background(Color.huddleBackground)

                   ScrollView {
                       VStack(spacing: 12) {
                           if viewModel.messages.isEmpty {
                               Text("No messages yet. Start chatting!")
                                   .font(.system(size: 14, design: .rounded))
                                   .foregroundColor(.gray)
                                   .padding()
                           } else {
                               ForEach(viewModel.messages) { message in
                                   messageCard(message: message)

                               }
                           }
                       }
                       .padding(.horizontal, 20)
                       .padding(.bottom, 80)
                   }
               }
           }


     private func headerSection(family: Family) -> some View {
         HStack {
             VStack(alignment: .leading, spacing: 4) {
                 Text(family.name)
                     .font(.system(size: 28, weight: .bold, design: .rounded))
                     .foregroundColor(.huddleCoral)

                 Text("\(family.members.count) members")
                     .font(.system(size: 14, weight: .medium, design: .rounded))
                     .foregroundColor(.gray)
             }

             Spacer()

             Button(action: {
                 viewModel.showShareSheet = true
             }) {
                 HStack(spacing: 6) {
                     Image(systemName: "square.and.arrow.up")
                     Text("Share")
                 }
                 .font(.system(size: 14, weight: .semibold, design: .rounded))
                 .foregroundColor(.huddleCoral)
                 .padding(.horizontal, 12)
                 .padding(.vertical, 8)
                 .background(Color.white)
                 .cornerRadius(20)
             }

             Button(action: {
                 authService.signOut()
             }) {
                 Image(systemName: "rectangle.portrait.and.arrow.right")
                     .font(.system(size: 16))
                     .foregroundColor(.red)
             }
         }
         .padding(.horizontal, 20)
         .padding(.top, 20)
         .padding(.bottom, 16)
     }

     private func membersSection(family: Family) -> some View {
          // Get unique members by ID
          let uniqueMembers = Array(Dictionary(grouping: family.members, by: { $0.id })
              .compactMap { $0.value.first })

          return HStack(spacing: 12) {
              // Member avatars (first 3 unique members)
              HStack(spacing: -8) {
                  ForEach(uniqueMembers.prefix(3)) { member in
                      Circle()
                          .fill(Color.huddleCoral.opacity(0.2))
                          .frame(width: 36, height: 36)
                          .overlay(
                              Text(getInitials(from: member.displayName))
                                  .font(.system(size: 12, weight: .bold, design: .rounded))
                                  .foregroundColor(.huddleCoral)
                          )
                          .overlay(
                              Circle()
                                  .stroke(Color.white, lineWidth: 2)
                          )
                  }
              }

              Text("\(uniqueMembers.count) members")
                  .font(.system(size: 14, weight: .medium, design: .rounded))
                  .foregroundColor(.gray)

              Spacer()

              Image(systemName: "chevron.right")
                  .font(.system(size: 12))
                  .foregroundColor(.gray)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 12)
          .background(Color.white)
          .cornerRadius(12)
          .padding(.horizontal, 20)
          .padding(.bottom, 16)
      }

         

     private func shoppingListPreview() -> some View {
           let items = viewModel.shoppingItems
           let firstThree = Array(items.prefix(3))
           let remainingCount = max(0, items.count - 3)

           return VStack(alignment: .leading, spacing: 12) {
               HStack {
                   Image(systemName: "cart.fill")
                       .font(.system(size: 14))
                       .foregroundColor(.huddleCoral)

                   Text("Shopping List")
                       .font(.system(size: 16, weight: .semibold, design: .rounded))
                       .foregroundColor(.gray)

                   Spacer()

                   if remainingCount > 0 {
                       Text("+\(remainingCount) more")
                           .font(.system(size: 12, design: .rounded))
                           .foregroundColor(.gray)
                   }
               }
               .padding(.horizontal, 20)

               if items.isEmpty {
                   Text("No items yet")
                       .font(.system(size: 14, design: .rounded))
                       .foregroundColor(.gray)
                       .padding(.horizontal, 20)
               } else {
                   VStack(spacing: 8) {
                       ForEach(firstThree) { item in
                           shoppingItemRow(item: item)
                       }
                   }
                   .padding(.horizontal, 20)
               }
           }
           .padding(.bottom, 16)
       }


     private func shoppingItemRow(item: HuddleMessage) -> some View {
          let isCompleted = item.isCompleted
          let content = item.content

          return HStack(spacing: 12) {
              Button(action: {
                  viewModel.toggleShoppingItem(item)
              }) {
                  Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                      .font(.system(size: 20))
                      .foregroundColor(isCompleted ? .green : .gray)
              }

              Text(content)
                  .font(.system(size: 14, design: .rounded))
                  .foregroundColor(isCompleted ? .gray : .black)
                  .strikethrough(isCompleted)

              Spacer()
          }
          .padding(12)
          .background(Color.white)
          .cornerRadius(12)
      }


     private func getInitials(from name: String) -> String {
         let components = name.split(separator: " ")
         let initials = components.prefix(2).compactMap { $0.first }
         return String(initials).uppercased()
     }

     private func pinnedSection() -> some View {
          VStack(alignment: .leading, spacing: 12) {
              // Only show if there are pinned messages
              if !viewModel.pinnedMessages.isEmpty {
                  HStack {
                      Image(systemName: "pin.fill")
                          .font(.system(size: 14))
                          .foregroundColor(.huddleCoral)

                      Text("Pinned")
                          .font(.system(size: 16, weight: .semibold, design: .rounded))
                          .foregroundColor(.gray)

                      Spacer()
                  }
                  .padding(.horizontal, 20)

                  VStack(spacing: 8) {
                      ForEach(viewModel.pinnedMessages) { message in
                          pinnedItemCard(message: message)
                      }
                  }
                  .padding(.horizontal, 20)
                  .padding(.bottom, 16)
              }
          }
      }


     private func pinnedItemCard(message: HuddleMessage) -> some View {
           HStack {
               Text(message.content)
                   .font(.system(size: 14, weight: .medium, design: .rounded))
                   .foregroundColor(.black)
               Spacer()
           }
           .padding(12)
           .background(Color.huddlePeach.opacity(0.3))
           .cornerRadius(12)
           .contextMenu {
               Button(action: {
                   viewModel.togglePinMessage(message)
               }) {
                   Label("Unpin Message", systemImage: "pin.slash")
               }
           }
       }


     
     private func messagesSection() -> some View {
         VStack(alignment: .leading, spacing: 0) {
             HStack {
                 Image(systemName: "message.fill")
                     .font(.system(size: 14))
                     .foregroundColor(.huddleCoral)

                 Text("Messages")
                     .font(.system(size: 16, weight: .semibold, design: .rounded))
                     .foregroundColor(.gray)

                 Spacer()

                 Button(action: {
                     viewModel.showShoppingList = true
                 }) {
                     HStack(spacing: 6) {
                         Image(systemName: "cart.fill")
                             .font(.system(size: 14))
                         Text("Shopping")
                             .font(.system(size: 13, weight: .semibold, design: .rounded))
                     }
                     .foregroundColor(.huddleCoral)
                     .padding(.horizontal, 12)
                     .padding(.vertical, 6)
                     .background(Color.white)
                     .cornerRadius(16)
                 }
             }
             .padding(.horizontal, 20)
             .padding(.vertical, 12)

             ScrollView {
                 VStack(spacing: 12) {
                     if viewModel.messages.isEmpty {
                         Text("No messages yet. Start chatting!")
                             .font(.system(size: 14, design: .rounded))
                             .foregroundColor(.gray)
                             .padding()
                     } else {
                         ForEach(viewModel.messages) { message in
                             messageCard(message: message)  // ← Changed this line
                         }
                     }
                 }
             }
             .padding(.horizontal, 20)
             .padding(.bottom, 80)
         }
         .onTapGesture {
             withAnimation(.spring()) {
                 isChatExpanded = true
             }
         }
     }



     private func messageInputField() -> some View {
           HStack(spacing: 12) {
               ZStack(alignment: .leading) {
                   if messageText.isEmpty {
                       Text("Type a message...")
                           .foregroundColor(.gray)
                           .font(.system(size: 16, design: .rounded))
                           .padding(.leading, 12)
                   }
                   TextField("", text: $messageText)
                       .font(.system(size: 16, design: .rounded))
                       .foregroundColor(.black)
                       .padding(12)
                       .focused($isMessageFieldFocused)
               }
               .background(Color.white)
               .cornerRadius(20)

               Button(action: {
                   guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                   viewModel.sendMessage(content: messageText)
                   messageText = ""
                   isMessageFieldFocused = false
               }) {
                   Image(systemName: "paperplane.fill")
                       .font(.system(size: 16))
                       .foregroundColor(.white)
                       .frame(width: 40, height: 40)
                       .background(Color.huddleCoral)
                       .clipShape(Circle())
               }
           }
           .padding(.horizontal, 20)
           .padding(.vertical, 12)
           .background(Color.huddleBackground)
       }



     private func formatTime(_ date: Date) -> String {
         let now = Date()
         let seconds = Int(now.timeIntervalSince(date))

         if seconds < 60 {
             return "just now"
         } else if seconds < 3600 {
             let minutes = seconds / 60
             return "\(minutes)m ago"
         } else if seconds < 86400 {
             let hours = seconds / 3600
             return "\(hours)h ago"
         } else {
             let days = seconds / 86400
             return "\(days)d ago"
         }
     }

     private func messageCard(message: HuddleMessage) -> some View {
          VStack(alignment: .leading, spacing: 6) {
              HStack {
                  Text(message.senderName)
                      .font(.system(size: 14, weight: .semibold, design: .rounded))
                      .foregroundColor(.huddleCoral)

                  Spacer()

                  Text(formatTime(message.createdAt))
                      .font(.system(size: 12, design: .rounded))
                      .foregroundColor(.gray)
              }

              Text(message.content)
                  .font(.system(size: 15, design: .rounded))
                  .foregroundColor(.black)
                  .fixedSize(horizontal: false, vertical: true)
          }
          .padding(12)
          .background(Color.white)
          .cornerRadius(12)
          .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
          .contextMenu {
              Button(action: {
                  viewModel.togglePinMessage(message)
              }) {
                  Label(
                      message.isPinned ? "Unpin Message" : "Pin Message",
                      systemImage: message.isPinned ? "pin.slash" : "pin.fill"
                  )
              }
          }
      }


     

     private var shareSheet: some View {
         if let family = viewModel.family {
             return AnyView(
                 VStack(spacing: 20) {
                     Text("Share Family Code")
                         .font(.system(size: 24, weight: .bold, design: .rounded))

                     Text(family.code)
                         .font(.system(size: 48, weight: .bold, design: .rounded))
                         .foregroundColor(.huddleCoral)
                         .tracking(4)
                         .padding()
                         .background(Color.white)
                         .cornerRadius(16)
                         .overlay(
                             RoundedRectangle(cornerRadius: 16)
                                 .stroke(Color.huddleCoral, lineWidth: 2)
                         )

                     Text("Share this code with family members")
                         .font(.system(size: 14, design: .rounded))
                         .foregroundColor(.gray)

                     Button("Done") {
                         viewModel.showShareSheet = false
                     }
                     .font(.system(size: 18, weight: .semibold, design: .rounded))
                     .foregroundColor(.white)
                     .frame(maxWidth: .infinity)
                     .padding()
                     .background(Color.huddleCoral)
                     .cornerRadius(16)
                     .padding(.horizontal)
                 }
                 .padding()
                 .presentationDetents([.medium])
             )
         } else {
             return AnyView(EmptyView())
         }
     }
 }

 #Preview {
     FamilyFeedView(authService: AuthService())
 }
