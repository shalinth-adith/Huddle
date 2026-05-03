import Foundation

final class ServiceContainer: ObservableObject {
    let familyService = FamilyService()
    let messageService = MessageService()
}
