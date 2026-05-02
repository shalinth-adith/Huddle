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
            Color(hex: "0E0809").ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                if !viewModel.shoppingItems.isEmpty {
                    progressSection
                }
                addItemSection
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "FF8A66"))
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
            VStack(alignment: .leading, spacing: 3) {
                Text("Shopping List")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(-0.5)
                if !viewModel.shoppingItems.isEmpty {
                    let done = viewModel.shoppingItems.filter { $0.isCompleted }.count
                    Text("\(viewModel.shoppingItems.count) items · \(done) done")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "F5E9E2").opacity(0.5))
                }
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "F5E9E2").opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(hex: "281A16").opacity(0.6)))
                    .overlay(Circle().stroke(Color(hex: "FFC8AA").opacity(0.14), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color(hex: "0E0809"))
    }

    // MARK: - Progress bar

    private var progressSection: some View {
        let total = viewModel.shoppingItems.count
        let done = viewModel.shoppingItems.filter { $0.isCompleted }.count
        let progress = total > 0 ? CGFloat(done) / CGFloat(total) : 0

        return VStack(spacing: 6) {
            HStack {
                Text("Progress")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "F5E9E2").opacity(0.45))
                    .tracking(0.5)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "FF8A66"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "281A16"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFA078"), Color(hex: "D8512B")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * progress), height: 6)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Add Item

    private var addItemSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isInputFocused ? Color(hex: "FF8A66") : Color(hex: "F5E9E2").opacity(0.35))

                TextField("Add an item...", text: $newItem)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .autocorrectionDisabled(true)
                    .focused($isInputFocused)
                    .onSubmit { addItem() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "281A16").opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isInputFocused ? Color(hex: "FF8A66").opacity(0.5) : Color(hex: "FFC8AA").opacity(0.14),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: isInputFocused ? Color(hex: "FF8A66").opacity(0.15) : .clear, radius: 8, x: 0, y: 0)

            Button(action: addItem) {
                let isEmpty = newItem.trimmingCharacters(in: .whitespaces).isEmpty
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background {
                        if isEmpty {
                            Circle()
                                .fill(Color(hex: "281A16").opacity(0.55))
                                .overlay(Circle().stroke(Color(hex: "FFC8AA").opacity(0.14), lineWidth: 1))
                        } else {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "FFA078"), Color(hex: "D8512B")],
                                    startPoint: .top, endPoint: .bottom
                                ))
                                .shadow(color: Color(hex: "D8512B").opacity(0.4), radius: 8, x: 0, y: 3)
                        }
                    }
            }
            .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    // MARK: - List

    private var shoppingListSection: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.shoppingItems.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "281A16").opacity(0.55))
                            .frame(width: 88, height: 88)
                            .overlay(Circle().stroke(Color(hex: "FFC8AA").opacity(0.12), lineWidth: 1))
                        Image(systemName: "cart")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "F5E9E2").opacity(0.25))
                    }
                    .padding(.top, 60)
                    Text("Your list is empty")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Add items above to get started")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "F5E9E2").opacity(0.45))
                }
                .frame(maxWidth: .infinity)
            } else {
                let pending = viewModel.shoppingItems.filter { !$0.isCompleted }
                let done = viewModel.shoppingItems.filter { $0.isCompleted }

                LazyVStack(spacing: 0) {
                    if !pending.isEmpty {
                        ForEach(pending) { item in
                            shoppingItemRow(item: item)
                                .padding(.bottom, 8)
                        }
                    }

                    if !done.isEmpty {
                        HStack {
                            Text("COMPLETED")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(Color(hex: "F5E9E2").opacity(0.3))
                            Rectangle()
                                .fill(Color(hex: "FFC8AA").opacity(0.12))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 12)

                        ForEach(done) { item in
                            shoppingItemRow(item: item)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func shoppingItemRow(item: HuddleMessage) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.toggleComplete(item: item)
            }) {
                ZStack {
                    Circle()
                        .fill(
                            item.isCompleted
                                ? LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color(hex: "281A16").opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle().stroke(
                                item.isCompleted ? Color.clear : Color(hex: "FFC8AA").opacity(0.3),
                                lineWidth: 1.5
                            )
                        )
                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.content)
                    .font(.system(size: 15))
                    .foregroundColor(item.isCompleted ? Color(hex: "F5E9E2").opacity(0.35) : .white)
                    .strikethrough(item.isCompleted, color: Color(hex: "F5E9E2").opacity(0.3))

                Text("Added by \(item.senderName)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "F5E9E2").opacity(0.3))
            }

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                itemToDelete = item
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "F5E9E2").opacity(0.3))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "281A16").opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "281A16").opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            item.isCompleted ? Color(hex: "FFC8AA").opacity(0.06) : Color(hex: "FFC8AA").opacity(0.12),
                            lineWidth: 1
                        )
                )
        )
        .opacity(item.isCompleted ? 0.75 : 1.0)
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
