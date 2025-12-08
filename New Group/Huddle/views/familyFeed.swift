import SwiftUI

  struct FamilyFeedView: View {
      @EnvironmentObject var authService: AuthService
      @State private var family: Family?
      @State private var isLoading = true
      @State private var showShareSheet = false
      @State private var showShoppingList = false

      private var familyService = FamilyService()

      var body: some View {
          ZStack {
              Color.huddleBackground.ignoresSafeArea()

              if isLoading {
                  ProgressView()
              } else if let family = family {
                  feedContent(family: family)
              } else {
                  Text("Error loading family")
              }

              floatingButton
          }
          .onAppear {
              loadFamily()
          }
          .sheet(isPresented: $showShareSheet) {
              shareSheet
          }
      }

      private func feedContent(family: Family) -> some View {
          VStack(spacing: 0) {
              headerSection(family: family)
              membersSection(family: family)
              pinnedSection()
              messagesSection()
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
                  showShareSheet = true
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
          VStack(alignment: .leading, spacing: 12) {
              Text("Family Members")
                  .font(.system(size: 16, weight: .semibold, design: .rounded))
                  .foregroundColor(.gray)
                  .padding(.horizontal, 20)

              ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 16) {
                      ForEach(family.members) { member in
                          VStack(spacing: 8) {
                              Circle()
                                  .fill(Color.huddleCoral.opacity(0.2))
                                  .frame(width: 60, height: 60)
                                  .overlay(
                                      Text(getInitials(from: member.displayName))
                                          .font(.system(size: 20, weight: .bold, design:
  .rounded))
                                          .foregroundColor(.huddleCoral)
                                  )

                              Text(member.displayName)
                                  .font(.system(size: 12, weight: .medium, design: .rounded))
                                  .foregroundColor(.primary)
                                  .lineLimit(1)
                          }
                      }
                  }
                  .padding(.horizontal, 20)
              }
          }
          .padding(.bottom, 16)
      }

      private func getInitials(from name: String) -> String {
          let components = name.split(separator: " ")
          let initials = components.prefix(2).compactMap { $0.first }
          return String(initials).uppercased()
      }

      private func pinnedSection() -> some View {
          VStack(alignment: .leading, spacing: 12) {
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
                  pinnedItemCard(text: "Don't forget to pick up milk!")
                  pinnedItemCard(text: "Family dinner on Sunday at 6 PM")
              }
              .padding(.horizontal, 20)
          }
          .padding(.bottom, 16)
      }

      private func pinnedItemCard(text: String) -> some View {
          HStack {
              Text(text)
                  .font(.system(size: 14, weight: .medium, design: .rounded))
                  .foregroundColor(.primary)
              Spacer()
          }
          .padding(12)
          .background(Color.huddlePeach.opacity(0.3))
          .cornerRadius(12)
      }

      private func messagesSection() -> some View {
          VStack(alignment: .leading, spacing: 12) {
              HStack {
                  Image(systemName: "message.fill")
                      .font(.system(size: 14))
                      .foregroundColor(.huddleCoral)

                  Text("Messages")
                      .font(.system(size: 16, weight: .semibold, design: .rounded))
                      .foregroundColor(.gray)

                  Spacer()
              }
              .padding(.horizontal, 20)

              ScrollView {
                  VStack(spacing: 12) {
                      messageCard(sender: "John", message: "On my way home!", time: "2m ago")
                      messageCard(sender: "Jane", message: "Picked up groceries", time: "15m ago")
                      messageCard(sender: "Mike", message: "Don't forget the meeting tomorrow",
  time: "1h ago")

                      ForEach(0..<10, id: \.self) { i in
                          messageCard(sender: "User \(i)", message: "Test message \(i)", time:
  "\(i+4)h ago")
                      }
                  }
                  .padding(.horizontal, 20)
                  .padding(.bottom, 80)
              }
          }
      }

      private func messageCard(sender: String, message: String, time: String) -> some View {
          VStack(alignment: .leading, spacing: 6) {
              HStack {
                  Text(sender)
                      .font(.system(size: 14, weight: .semibold, design: .rounded))
                      .foregroundColor(.huddleCoral)

                  Spacer()

                  Text(time)
                      .font(.system(size: 12, design: .rounded))
                      .foregroundColor(.gray)
              }

              Text(message)
                  .font(.system(size: 14, design: .rounded))
                  .foregroundColor(.primary)
          }
          .padding(12)
          .background(Color.white)
          .cornerRadius(12)
      }

      private var floatingButton: some View {
          VStack {
              Spacer()
              HStack {
                  Spacer()
                  Button(action: {
                      showShoppingList = true
                  }) {
                      Image(systemName: "cart.fill")
                          .font(.system(size: 24))
                          .foregroundColor(.white)
                          .frame(width: 60, height: 60)
                          .background(Color.huddleCoral)
                          .clipShape(Circle())
                          .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                  }
                  .padding(.trailing, 20)
                  .padding(.bottom, 20)
              }
          }
          .sheet(isPresented: $showShoppingList) {
              if let family = family {
                  ShoppingList(family: family)
                      .environmentObject(authService)
              }
          }
      }

      private func loadFamily() {
          print("🔍 Loading family...")

          guard let familyId = authService.currentUser?.currentFamilyId else {
              print("❌ No familyId found!")
              isLoading = false
              return
          }

          print("✅ FamilyId found: \(familyId)")

          familyService.fetchFamily(familyId: familyId) { result in
              print("📦 Fetch completed")
              isLoading = false

              switch result {
              case .success(let fetchedFamily):
                  print("✅ Family loaded: \(fetchedFamily.name)")
                  family = fetchedFamily
              case .failure(let error):
                  print("❌ Error loading family: \(error.localizedDescription)")
              }
          }
      }

      private var shareSheet: some View {
          if let family = family {
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
                          showShareSheet = false
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
      FamilyFeedView()
          .environmentObject(AuthService())
  }

