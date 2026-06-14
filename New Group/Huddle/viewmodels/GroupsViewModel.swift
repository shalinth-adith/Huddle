//
//  GroupsViewModel.swift
//  Huddle
//
//  Drives the Groups home screen: live list of every family the user belongs
//  to, with per-group unread state. Each family is watched with a real-time
//  listener so names, member counts, and unread dots stay current.
//

import Foundation
import Combine
import FirebaseFirestore

class GroupsViewModel: ObservableObject {
    @Published var groups: [Family] = []
    @Published var unreadGroupIds: Set<String> = []
    @Published var isLoading = true

    private let familyService: FamilyService
    private let authService: AuthService
    private var listeners: [ListenerRegistration] = []
    private var cache: [String: Family] = [:]

    init(familyService: FamilyService, authService: AuthService) {
        self.familyService = familyService
        self.authService = authService
    }

    deinit { stop() }

    func start() {
        stop()
        let ids = authService.currentUser?.familyIds ?? []
        if ids.isEmpty {
            groups = []
            unreadGroupIds = []
            isLoading = false
            return
        }
        for id in ids {
            let listener = familyService.listenToFamily(familyId: id) { [weak self] result in
                guard let self else { return }
                self.isLoading = false
                guard case .success(let fam) = result, let fid = fam.id else { return }
                self.cache[fid] = fam
                self.recompute()
            }
            listeners.append(listener)
        }
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    func markRead(_ familyId: String) {
        GroupReadTracker.markRead(familyId)
        recompute()
    }

    private func recompute() {
        // Preserve familyIds order so the list doesn't reshuffle.
        let ids = authService.currentUser?.familyIds ?? []
        groups = ids.compactMap { cache[$0] }
        unreadGroupIds = Set(groups.filter { GroupReadTracker.isUnread($0) }.compactMap { $0.id })

        // Publish the group index so the widget's group picker stays in sync.
        let widgetGroups = groups.compactMap { fam in
            fam.id.map { SharedDataManager.WidgetGroup(id: $0, name: fam.name) }
        }
        SharedDataManager.saveGroups(widgetGroups)
    }
}
