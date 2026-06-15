//
//  MediaGalleryViewModel.swift
//  Huddle
//
//  Backs the media gallery: a live list of every photo shared in the family.
//

import Foundation
import Combine
import FirebaseFirestore
import UIKit

class MediaGalleryViewModel: ObservableObject {
    @Published var photos: [HuddleMessage] = []
    @Published var isLoading = true

    private let messageService: MessageService
    private let authService: AuthService
    private var listener: ListenerRegistration?

    init(messageService: MessageService, authService: AuthService) {
        self.messageService = messageService
        self.authService = authService
    }

    deinit { listener?.remove() }

    func start() {
        guard let familyId = authService.currentUser?.currentFamilyId else { isLoading = false; return }
        listener?.remove()
        listener = messageService.listenToPhotos(familyId: familyId) { [weak self] result in
            self?.isLoading = false
            if case .success(let photos) = result { self?.photos = photos }
        }
    }

    func stop() { listener?.remove(); listener = nil }

    func loadImage(for message: HuddleMessage, completion: @escaping (UIImage?) -> Void) {
        guard let familyId = authService.currentUser?.currentFamilyId,
              let path = message.photoURL else { completion(nil); return }
        messageService.loadPhoto(familyId: familyId, path: path) { completion(try? $0.get()) }
    }

    func senderName(_ message: HuddleMessage) -> String { message.senderName }
}
