import SwiftUI

struct ShoppingList: View {
     @EnvironmentObject var authService: AuthService
     @Environment(\.dismiss) var dismiss

     @StateObject private var viewModel: ShoppingListViewModel
     @State private var newItem: String = ""

     let family: Family

     init(family: Family) {
         self.family = family
         let familyId = family.id ?? ""
           print("🏠 ShoppingList initialized with familyId: \(familyId)")
           _viewModel = StateObject(wrappedValue: ShoppingListViewModel(familyId: familyId))
     }

     var body: some View {
         ZStack {
             Color.huddleBackground.ignoresSafeArea()

             VStack(spacing: 0) {
                 headerSection
                 addItemSection

                 if viewModel.isLoading {
                     ProgressView()
                         .padding()
                 } else {
                     shoppingListSection
                 }
             }
         }
         .onAppear {
             viewModel.loadItems()
         }
     }

     private var headerSection: some View {
         HStack {
             Text("Shopping List")
                 .font(.system(size: 28, weight: .bold, design: .rounded))
                 .foregroundColor(.huddleCoral)

             Spacer()

             Button(action: {
                 dismiss()
             }) {
                 Image(systemName: "xmark.circle.fill")
                     .font(.system(size: 28))
                     .foregroundColor(.gray)
             }
             .buttonStyle(.plain) 

         }
         .padding(.horizontal, 20)
         .padding(.top, 20)
         .padding(.bottom, 16)
     }

     private var addItemSection: some View {
         HStack(spacing: 12) {
             TextField("Add item...", text: $newItem)
                 .font(.system(size: 16, design: .rounded))
                 .foregroundColor(.black)
                 .padding(12)
                 .background(Color.white)  // CHANGED from Color.primary
                 .cornerRadius(12)
                 .autocorrectionDisabled(true)

             
                Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(newItem.trimmingCharacters(in: .whitespaces).isEmpty ?
                .gray : .huddleCoral)
                }
                .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
                }
         .padding(.horizontal, 20)
         .padding(.bottom, 16)
     }

     private var shoppingListSection: some View {
         ScrollView {
             VStack(spacing: 12) {
                 if viewModel.shoppingItems.isEmpty {
                     VStack(spacing: 12) {
                         Image(systemName: "cart")
                             .font(.system(size: 60))
                             .foregroundColor(.gray.opacity(0.5))
                             .padding(.top, 60)

                         Text("No items yet")
                             .font(.system(size: 16, design: .rounded))
                             .foregroundColor(.gray)
                     }
                 } else {
                     ForEach(Array(viewModel.shoppingItems.prefix(3))) { item in
                           shoppingItemRow(item: item)
                       }
                     }
                 }
             }
             .padding(.horizontal, 20)
             .padding(.bottom, 20)
         }
     

     private func shoppingItemRow(item: HuddleMessage) -> some View {
         HStack(spacing: 12) {
             Button(action: {
                 viewModel.toggleComplete(item: item)
             }) {
                 Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                     .font(.system(size: 24))
                     .foregroundColor(item.isCompleted ? .green : .gray)
             }

             VStack(alignment: .leading, spacing: 4) {
                 Text(item.content)
                     .font(.system(size: 16, design: .rounded))
                     .foregroundColor(item.isCompleted ? .gray : .black)
                     .strikethrough(item.isCompleted)

                 Text("Added by \(item.senderName)")
                     .font(.system(size: 12, design: .rounded))
                     .foregroundColor(.gray)
             }

             Spacer()

             Button(action: {
                 viewModel.deleteItem(item: item)
             }) {
                 Image(systemName: "trash")
                     .font(.system(size: 16))
                     .foregroundColor(.red)
             }
         }
         .padding(12)
         .background(Color.white)
         .cornerRadius(12)
     }


     private func addItem() {
         guard let userId = authService.currentUser?.id,
               let userName = authService.currentUser?.displayName else {
             return
         }

         viewModel.addItem(
             content: newItem,
             senderId: userId,
             senderName: userName
         )

         newItem = ""
     }
 }

 #Preview {
     ShoppingList(family: Family(
         id: "preview",
         name: "Test Family",
         code: "H-123456",
         createdAt: Date(),
         members: []
     ))
     .environmentObject(AuthService())
 }
