import Foundation
import Combine

final class ServiceContainer: ObservableObject {
    let familyService = FamilyService()
    let messageService = MessageService()
}
