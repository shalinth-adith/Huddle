//
//  FamilyFeedViewModel.swift
//  Huddle
//
//  Created by shalinth adithyan on 22/12/25.
//
import Foundation
 import SwiftUI
 import Combine
 import FirebaseFirestore

class FamilyFeedViewModel: ObservableObject {
    @Published var family: Family?
    @Published var isLoading = true
    @Published var showShareSheet = false
    @Published var showShoppingList = false
    
    
    @Published var messages: [HuddleMessage] = []
    private var messageListener: ListenerRegistration?
    
    private let familyService: FamilyService
    private let authService: AuthService
    private let messageService: MessageService
    @Published var shoppingItems: [HuddleMessage] = []
     private var shoppingListener: ListenerRegistration?
    
    init(familyService: FamilyService, authService: AuthService, messageService: MessageService) {
        self.familyService = familyService
        self.authService = authService
        self.messageService = messageService
    }
    
    func loadFamily() {
        print("🔍 Loading family...")
        
        guard let familyId = authService.currentUser?.currentFamilyId else {
            print("❌ No familyId found!")
            self.isLoading = false
            return
        }
        
        print("✅ FamilyId found: \(familyId)")
        
        familyService.fetchFamily(familyId: familyId) { result in
            print("📦 Fetch completed")
            self.isLoading = false
            
            switch result {
            case .success(let fetchedFamily):
                print("✅ Family loaded: \(fetchedFamily.name)")
                self.family = fetchedFamily
            case .failure(let error):
                print("❌ Error loading family: \(error.localizedDescription)")
            }
        }
    }
    
    func loadMessages() {
        print("💬 Loading messages...")
        
        guard let familyId = authService.currentUser?.currentFamilyId else {
            print("❌ No familyId found for messages!")
            return
        }
        
        print("✅ FamilyId found, starting listener: \(familyId)")
        
        self.messageListener = messageService.listenToMessages(familyId: familyId) { result in
            switch result {
            case .success(let fetchedMessages):
                print("✅ Messages loaded: \(fetchedMessages.count) messages")
                self.messages = fetchedMessages
            case .failure(let error):
                print("❌ Error loading messages: \(error.localizedDescription)")
            }
        }
    }
    
    func loadShoppingItems() {
        guard let familyId = authService.currentUser?.currentFamilyId else {
            print("❌ No familyId for shopping items!")
            return
        }
        
        print("🛒 Loading shopping items...")
        
        messageService.fetchShoppingItems(familyId: familyId) { result in
            switch result {
            case .success(let items):
                print("✅ Shopping items loaded: \(items.count)")
                self.shoppingItems = items
            case .failure(let error):
                print("❌ Error loading shopping items: \(error.localizedDescription)")
            }
        }
    }
    
    func toggleShoppingItem(_ item: HuddleMessage) {
        guard let familyId = authService.currentUser?.currentFamilyId,
              let itemId = item.id else { return }
        
        messageService.toggleCompletion(
            familyId: familyId,
            messageId: itemId,
            isCompleted: !item.isCompleted
        ) { result in
            switch result {
            case .success:
                print("✅ Item toggled")
                self.loadShoppingItems() // Reload to update
            case .failure(let error):
                print("❌ Toggle failed: \(error.localizedDescription)")
            }
        }
    }
    
    
    func sendMessage(content: String) {
        guard let familyId = authService.currentUser?.currentFamilyId,
              let userId = authService.currentUser?.id,
              let userName = authService.currentUser?.displayName else {
            print("❌ Missing user info for sending message")
            return
        }
        
        print("📤 Sending message: \(content)")
        
        messageService.sendChatMessage(
            familyId: familyId,
            content: content,
            senderId: userId,
            senderName: userName
        ) { result in
            switch result {
            case .success:
                print("✅ Message sent successfully!")
            case .failure(let error):
                print("❌ Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    func cleanup() {
        messageListener?.remove()
        shoppingListener?.remove()
        print("🧹 Listeners removed")
    }
}
