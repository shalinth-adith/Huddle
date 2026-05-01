import SwiftUI

struct ShoppingList: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel: ShoppingListViewModel
    @State private var newItem: String = ""
    @State private var itemToDelete: HuddleMessage?
    @FocusState private var isInputFocused: Bool

    let family: Family

    init(family: Family) {
        self.family = family
        let familyId = family.id ?? ""
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
                        .padding(.top, 40)
                    Spacer()
                } else {
                    shoppingListSection
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear { viewModel.loadItems() }
        .alert("Delete Item?", isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete { viewModel.deleteItem(item: item) }
                itemToDelete = nil
            }
            Button("Cancel", role: .cancel) { itemToDelete = nil }
        } message: {
            if let item = itemToDelete {
                Text("\"\(item.content)\" will be removed from the list.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Shopping List")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Color.huddleTextPrimary)
                if !viewModel.shoppingItems.isEmpty {
                    let done = viewModel.shoppingItems.filter { $0.isCompleted }.count
                    Text("\(viewModel.shoppingItems.count) items · \(done) done")
                        .font(.system(size: 13))
                        .foregroundColor(Color.huddleTextTertiary)
                }
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.huddleTextTertiary)
                    .padding(8)
                    .background(Color.huddleSecondaryFixed)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.huddleBackground)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.huddleBorder), alignment: .bottom)
    }

    // MARK: - Add Item

    private var addItemSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "cart")
                    .font(.system(size: 15))
                    .foregroundColor(isInputFocused ? Color.huddleCoral : Color.huddleTextTertiary)

                TextField("Add an item...", text: $newItem)
                    .font(.system(size: 15))
                    .foregroundColor(Color.huddleTextPrimary)
                    .autocorrectionDisabled(true)
                    .focused($isInputFocused)
                    .onSubmit { addItem() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.huddleCard)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isInputFocused ? Color.huddleCoral : Color.huddleBorder, lineWidth: 1.5)
            )

            Button(action: addItem) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        newItem.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.huddleTextTertiary.opacity(0.3)
                            : Color.huddleCoral
                    )
                    .clipShape(Circle())
            }
            .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.huddleBackground)
    }

    // MARK: - List

    private var shoppingListSection: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.shoppingItems.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.huddleSecondaryFixed)
                            .frame(width: 80, height: 80)
                        Image(systemName: "cart")
                            .font(.system(size: 34))
                            .foregroundColor(Color.huddleTextTertiary)
                    }
                    .padding(.top, 60)
                    Text("Your list is empty")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.huddleTextPrimary)
                    Text("Add items above to get started")
                        .font(.system(size: 14))
                        .foregroundColor(Color.huddleTextTertiary)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.shoppingItems) { item in
                        shoppingItemRow(item: item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 24)
            }
        }
    }

    private func shoppingItemRow(item: HuddleMessage) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.toggleComplete(item: item)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(item.isCompleted ? Color.huddleCoral : Color.huddleTextTertiary.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.content)
                    .font(.system(size: 15))
                    .foregroundColor(item.isCompleted ? Color.huddleTextTertiary : Color.huddleTextPrimary)
                    .strikethrough(item.isCompleted, color: Color.huddleTextTertiary)

                Text("Added by \(item.senderName)")
                    .font(.system(size: 12))
                    .foregroundColor(Color.huddleTextTertiary.opacity(0.7))
            }

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                itemToDelete = item
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Color.huddleTextTertiary.opacity(0.5))
                    .padding(8)
                    .background(Color.huddleSecondaryFixed)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.huddleCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
        .opacity(item.isCompleted ? 0.7 : 1)
    }

    // MARK: - Add Item Action

    private func addItem() {
        guard let userId = authService.currentUser?.id,
              let userName = authService.currentUser?.displayName else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.addItem(content: newItem, senderId: userId, senderName: userName)
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
