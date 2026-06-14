//
//  CapsuleViewModel.swift
//  Huddle
//

import Foundation
import Combine
import FirebaseFirestore

class CapsuleViewModel: ObservableObject {
    @Published var capsules: [TimeCapsule] = []
    @Published var isLoading = true

    private let capsuleService: CapsuleService
    private let authService: AuthService
    private var listener: ListenerRegistration?

    init(capsuleService: CapsuleService, authService: AuthService) {
        self.capsuleService = capsuleService
        self.authService = authService
    }

    deinit { listener?.remove() }

    var sealed: [TimeCapsule] {
        capsules.filter { $0.isSealed }.sorted { $0.deliverAt < $1.deliverAt }
    }

    var opened: [TimeCapsule] {
        capsules.filter { !$0.isSealed }.sorted { $0.deliverAt > $1.deliverAt }
    }

    func start() {
        guard let familyId = authService.currentUser?.currentFamilyId else { isLoading = false; return }
        listener?.remove()
        listener = capsuleService.listenToCapsules(familyId: familyId) { [weak self] result in
            self?.isLoading = false
            if case .success(let capsules) = result { self?.capsules = capsules }
        }
    }

    func stop() { listener?.remove(); listener = nil }

    func createCapsule(message: String, deliverAt: Date) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let familyId = authService.currentUser?.currentFamilyId,
              let userId = authService.currentUser?.id,
              let userName = authService.currentUser?.displayName else { return }
        capsuleService.createCapsule(familyId: familyId, message: trimmed, deliverAt: deliverAt, creatorId: userId, creatorName: userName) { _ in }
    }

    func deleteCapsule(_ capsule: TimeCapsule) {
        guard let familyId = authService.currentUser?.currentFamilyId,
              let id = capsule.id,
              capsule.createdBy == authService.currentUser?.id else { return }
        capsules.removeAll { $0.id == id }
        capsuleService.deleteCapsule(familyId: familyId, capsuleId: id) { _ in }
    }

    func canDelete(_ capsule: TimeCapsule) -> Bool {
        capsule.createdBy == authService.currentUser?.id
    }
}
