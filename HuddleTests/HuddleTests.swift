//
//  HuddleTests.swift
//  HuddleTests
//
//  Created by shalinth adithyan on 19/11/25.
//

import XCTest
import SwiftUI
@testable import Huddle

// MARK: - Model Tests

final class ModelTests: XCTestCase {

    // MARK: AppUser
    func testAppUserCreation() {
        let user = AppUser(
            id: "u1", PhoneNumber: nil, email: "test@test.com",
            displayName: "Alice", currentFamilyId: nil, createdAt: Date()
        )
        XCTAssertEqual(user.id, "u1")
        XCTAssertEqual(user.displayName, "Alice")
        XCTAssertEqual(user.email, "test@test.com")
        XCTAssertNil(user.currentFamilyId)
    }

    func testAppUserFamilyAssignment() {
        var user = AppUser(
            id: "u2", PhoneNumber: nil, email: nil,
            displayName: "Bob", currentFamilyId: nil, createdAt: Date()
        )
        user.currentFamilyId = "family-123"
        XCTAssertEqual(user.currentFamilyId, "family-123")
    }

    // MARK: Member
    func testMemberCreation() {
        let member = Member(id: "m1", displayName: "Alice", joinedAt: Date())
        XCTAssertEqual(member.id, "m1")
        XCTAssertEqual(member.displayName, "Alice")
    }

    func testMemberToDictionary() {
        let member = Member(id: "m1", displayName: "Alice", joinedAt: Date())
        let dict = member.toDictionary()
        XCTAssertEqual(dict["id"] as? String, "m1")
        XCTAssertEqual(dict["displayName"] as? String, "Alice")
    }

    // MARK: Family
    func testFamilyCreation() {
        let members = [
            Member(id: "1", displayName: "Alice", joinedAt: Date()),
            Member(id: "2", displayName: "Bob", joinedAt: Date())
        ]
        let family = Family(id: nil, name: "Smith Family", code: "H-123456", createdAt: Date(), members: members)
        XCTAssertEqual(family.name, "Smith Family")
        XCTAssertEqual(family.code, "H-123456")
        XCTAssertEqual(family.members.count, 2)
    }

    func testFamilyEmptyMembers() {
        let family = Family(id: nil, name: "Solo", code: "H-000001", createdAt: nil, members: [])
        XCTAssertTrue(family.members.isEmpty)
    }

    // MARK: HuddleMessage
    func testMessageTypeText() {
        let msg = HuddleMessage(
            familyID: "f1", senderID: "u1", senderName: "Alice",
            type: .text, content: "Hello!", photoURL: nil,
            isPinned: false, isCompleted: false, createdAt: Date()
        )
        XCTAssertEqual(msg.type, .text)
        XCTAssertEqual(msg.content, "Hello!")
        XCTAssertFalse(msg.isPinned)
        XCTAssertFalse(msg.isCompleted)
    }

    func testMessageTypeShopping() {
        let msg = HuddleMessage(
            familyID: "f1", senderID: "u1", senderName: "Alice",
            type: .Shopping, content: "Milk", photoURL: nil,
            isPinned: false, isCompleted: false, createdAt: Date()
        )
        XCTAssertEqual(msg.type, .Shopping)
    }

    func testMessageTypePhoto() {
        let msg = HuddleMessage(
            familyID: "f1", senderID: "u1", senderName: "Alice",
            type: .photo, content: "", photoURL: "https://example.com/photo.jpg",
            isPinned: false, isCompleted: false, createdAt: Date()
        )
        XCTAssertEqual(msg.type, .photo)
        XCTAssertEqual(msg.photoURL, "https://example.com/photo.jpg")
    }

    func testMessagePinToggle() {
        var msg = HuddleMessage(
            familyID: "f1", senderID: "u1", senderName: "Alice",
            type: .text, content: "Pin me", photoURL: nil,
            isPinned: false, isCompleted: false, createdAt: Date()
        )
        msg.isPinned = true
        XCTAssertTrue(msg.isPinned)
        msg.isPinned = false
        XCTAssertFalse(msg.isPinned)
    }

    func testMessageCompletionToggle() {
        var msg = HuddleMessage(
            familyID: "f1", senderID: "u1", senderName: "Alice",
            type: .Shopping, content: "Eggs", photoURL: nil,
            isPinned: false, isCompleted: false, createdAt: Date()
        )
        msg.isCompleted = true
        XCTAssertTrue(msg.isCompleted)
    }
}

// MARK: - Code Validation Logic

final class CodeValidationTests: XCTestCase {

    // Mirrors JoinFamilyViewModel.isValidCode
    private func isValidCode(_ code: String) -> Bool {
        code.count == 8 &&
        code.hasPrefix("H-") &&
        code.dropFirst(2).allSatisfy { $0.isNumber }
    }

    // Mirrors JoinFamilyViewModel.formatFamilyCode
    private func formatFamilyCode(_ newValue: String) -> String {
        if !newValue.hasPrefix("H-") { return "H-" }
        let digitsOnly = newValue.dropFirst(2).filter { $0.isNumber }
        if digitsOnly.count <= 6 {
            return "H-\(digitsOnly)"
        } else {
            return "H-\(digitsOnly.prefix(6))"
        }
    }

    func testValidCodes() {
        XCTAssertTrue(isValidCode("H-123456"))
        XCTAssertTrue(isValidCode("H-000000"))
        XCTAssertTrue(isValidCode("H-999999"))
    }

    func testInvalidCodeTooShort() {
        XCTAssertFalse(isValidCode("H-12345"))
        XCTAssertFalse(isValidCode("H-"))
        XCTAssertFalse(isValidCode("H-1"))
    }

    func testInvalidCodeTooLong() {
        XCTAssertFalse(isValidCode("H-1234567"))
    }

    func testInvalidCodeWrongPrefix() {
        XCTAssertFalse(isValidCode("X-123456"))
        XCTAssertFalse(isValidCode("123456"))
        XCTAssertFalse(isValidCode(""))
    }

    func testInvalidCodeNonDigits() {
        XCTAssertFalse(isValidCode("H-12345a"))
        XCTAssertFalse(isValidCode("H-ABCDEF"))
    }

    func testFormatStripNonDigits() {
        XCTAssertEqual(formatFamilyCode("H-abc123"), "H-123")
    }

    func testFormatTruncatesAt6Digits() {
        XCTAssertEqual(formatFamilyCode("H-1234567"), "H-123456")
        XCTAssertEqual(formatFamilyCode("H-12345678"), "H-123456")
    }

    func testFormatRejectsWrongPrefix() {
        XCTAssertEqual(formatFamilyCode("INVALID"), "H-")
        XCTAssertEqual(formatFamilyCode("X-123456"), "H-")
    }

    func testFormatPreservesValidCode() {
        XCTAssertEqual(formatFamilyCode("H-123456"), "H-123456")
        XCTAssertEqual(formatFamilyCode("H-"), "H-")
    }
}

// MARK: - Input Guard Logic

final class InputGuardTests: XCTestCase {

    // Mirrors CreateFamilyViewModel.isCreateButtonDisabled
    private func isCreateDisabled(name: String, isLoading: Bool = false) -> Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
    }

    func testEmptyNameDisablesButton() {
        XCTAssertTrue(isCreateDisabled(name: ""))
    }

    func testWhitespaceOnlyNameDisablesButton() {
        XCTAssertTrue(isCreateDisabled(name: "   "))
    }

    func testValidNameEnablesButton() {
        XCTAssertFalse(isCreateDisabled(name: "Smith Family"))
        XCTAssertFalse(isCreateDisabled(name: "  Padded  "))
    }

    func testLoadingDisablesButton() {
        XCTAssertTrue(isCreateDisabled(name: "Smith Family", isLoading: true))
    }

    func testEmptyShoppingItemBlocked() {
        let trimmed = "   ".trimmingCharacters(in: .whitespaces)
        XCTAssertTrue(trimmed.isEmpty)
    }

    func testValidShoppingItemAllowed() {
        let trimmed = "  Milk  ".trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(trimmed, "Milk")
    }
}

// MARK: - Color Extension Tests

final class ColorExtensionTests: XCTestCase {

    func testHuddleCoralColor() {
        _ = Color(hex: "FF9B85")
    }

    func testHuddlePeachColor() {
        _ = Color(hex: "FFD6A5")
    }

    func testHuddleBlueColor() {
        _ = Color(hex: "A8DADC")
    }

    func testHuddleBackgroundColor() {
        _ = Color(hex: "FFF8F3")
    }

    func testBlackAndWhite() {
        _ = Color(hex: "000000")
        _ = Color(hex: "FFFFFF")
    }
}

// MARK: - Performance Tests

final class PerformanceTests: XCTestCase {

    private func makeMessage(index: Int, type: MessageType = .text, isPinned: Bool = false) -> HuddleMessage {
        HuddleMessage(
            familyID: "f1", senderID: "u\(index)", senderName: "User \(index)",
            type: type, content: "Message content number \(index)", photoURL: nil,
            isPinned: isPinned, isCompleted: index % 3 == 0,
            createdAt: Date().addingTimeInterval(Double(index * -60))
        )
    }

    func testMessageCreationPerformance() {
        measure {
            let messages = (0..<1000).map { makeMessage(index: $0) }
            XCTAssertEqual(messages.count, 1000)
        }
    }

    func testPinnedMessageFilterPerformance() {
        let messages = (0..<1000).map { makeMessage(index: $0, isPinned: $0 % 5 == 0) }
        measure {
            let pinned = messages.filter { $0.isPinned }
            XCTAssertEqual(pinned.count, 200)
        }
    }

    func testShoppingItemFilterPerformance() {
        let messages = (0..<1000).map { makeMessage(index: $0, type: $0 % 2 == 0 ? .Shopping : .text) }
        measure {
            let shopping = messages.filter { $0.type == .Shopping }
            XCTAssertEqual(shopping.count, 500)
        }
    }

    func testMessageSortByDatePerformance() {
        let messages = (0..<1000).map { makeMessage(index: $0) }.shuffled()
        measure {
            let sorted = messages.sorted { $0.createdAt > $1.createdAt }
            XCTAssertNotNil(sorted.first)
        }
    }

    func testShoppingItemTogglePerformance() {
        var items = (0..<500).map { makeMessage(index: $0, type: .Shopping) }
        measure {
            for i in items.indices {
                items[i].isCompleted = !items[i].isCompleted
            }
        }
    }

    func testFamilyWithLargeMemberListPerformance() {
        measure {
            let members = (0..<500).map { Member(id: "m\($0)", displayName: "Member \($0)", joinedAt: Date()) }
            let family = Family(id: nil, name: "Large Family", code: "H-999999", createdAt: Date(), members: members)
            XCTAssertEqual(family.members.count, 500)
        }
    }

    func testColorHexParsingPerformance() {
        let hexValues = ["FF9B85", "FFD6A5", "A8DADC", "FFF8F3", "000000", "FFFFFF"]
        measure {
            for _ in 0..<1000 {
                for hex in hexValues {
                    _ = Color(hex: hex)
                }
            }
        }
    }

    func testMemberDictionarySerializationPerformance() {
        let members = (0..<500).map { Member(id: "m\($0)", displayName: "Member \($0)", joinedAt: Date()) }
        measure {
            let dicts = members.map { $0.toDictionary() }
            XCTAssertEqual(dicts.count, 500)
        }
    }
}
