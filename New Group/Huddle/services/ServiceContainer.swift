import Foundation
import Combine

final class ServiceContainer: ObservableObject {
    let familyService = FamilyService()
    let messageService = MessageService()
    let storageService = StorageService()
    let eventService = EventService()
    let capsuleService = CapsuleService()
}
