//
//  AIService.swift
//  Huddle
//
//  On-device assistant via Apple Intelligence (FoundationModels, iOS 26+).
//  Everything runs locally — decrypted family content never leaves the device,
//  so the E2E guarantee is preserved and there's no API key or server cost.
//

import Foundation
import FoundationModels

final class AIService {
    enum AIError: LocalizedError {
        case unavailable(String)
        var errorDescription: String? {
            if case .unavailable(let msg) = self { return msg }
            return nil
        }
    }

    var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    var unavailableMessage: String {
        if case .available = SystemLanguageModel.default.availability { return "" }
        return "Ask Huddle runs entirely on your device with Apple Intelligence. It isn’t available here yet — it needs an Apple-Intelligence-capable device with the feature turned on in Settings."
    }

    /// Sends a prompt to the on-device model and returns its reply.
    func respond(to prompt: String, instructions: String) async throws -> String {
        guard isAvailable else { throw AIError.unavailable(unavailableMessage) }
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        return response.content
    }
}
