import CryptoKit
import Security
import Foundation

enum EncryptionService {

    // MARK: - User Key Pair

    static func generateAndStoreKeyPair() throws -> String {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        try saveToKeychain(key: "huddle_privateKey", data: privateKey.rawRepresentation)
        return privateKey.publicKey.rawRepresentation.base64EncodedString()
    }

    static func loadPrivateKey() throws -> Curve25519.KeyAgreement.PrivateKey {
        let data = try loadFromKeychain(key: "huddle_privateKey")
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
    }

    // MARK: - Group Key

    static func generateGroupKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    static func saveGroupKey(_ key: SymmetricKey, familyId: String) throws {
        let data = key.withUnsafeBytes { Data($0) }
        try saveToKeychain(key: "huddle_groupKey_\(familyId)", data: data)
    }

    /// Serialize a group key for storage in the members-only Firestore secret.
    static func exportKey(_ key: SymmetricKey) -> String {
        key.withUnsafeBytes { Data($0) }.base64EncodedString()
    }

    static func importKey(_ base64: String) -> SymmetricKey? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return SymmetricKey(data: data)
    }

    static func loadGroupKey(familyId: String) -> SymmetricKey? {
        guard let data = try? loadFromKeychain(key: "huddle_groupKey_\(familyId)") else { return nil }
        return SymmetricKey(data: data)
    }

    // MARK: - Group Key Distribution (ECDH)

    static func encryptGroupKey(_ groupKey: SymmetricKey, for recipientPublicKeyBase64: String, senderPrivateKey: Curve25519.KeyAgreement.PrivateKey) throws -> String {
        guard let recipientPubData = Data(base64Encoded: recipientPublicKeyBase64) else {
            throw EncryptionError.invalidPublicKey
        }
        let recipientPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientPubData)
        let sharedSecret = try senderPrivateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)
        let derivedKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("huddle-group-key".utf8),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        let groupKeyData = groupKey.withUnsafeBytes { Data($0) }
        let sealed = try AES.GCM.seal(groupKeyData, using: derivedKey)
        return sealed.combined!.base64EncodedString()
    }

    // Try decrypting using each candidate sender public key until one succeeds
    static func decryptGroupKey(_ encryptedBase64: String, candidateSenderPublicKeys: [String], recipientPrivateKey: Curve25519.KeyAgreement.PrivateKey) -> SymmetricKey? {
        guard let encryptedData = Data(base64Encoded: encryptedBase64) else { return nil }
        for senderPubBase64 in candidateSenderPublicKeys {
            guard let senderPubData = Data(base64Encoded: senderPubBase64),
                  let senderPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: senderPubData),
                  let sharedSecret = try? recipientPrivateKey.sharedSecretFromKeyAgreement(with: senderPublicKey) else { continue }
            let derivedKey = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Data("huddle-group-key".utf8),
                sharedInfo: Data(),
                outputByteCount: 32
            )
            guard let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData),
                  let groupKeyData = try? AES.GCM.open(sealedBox, using: derivedKey) else { continue }
            return SymmetricKey(data: groupKeyData)
        }
        return nil
    }

    // MARK: - Message Encryption

    static func encrypt(_ plaintext: String, groupKey: SymmetricKey) throws -> String {
        let data = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(data, using: groupKey)
        return sealed.combined!.base64EncodedString()
    }

    static func decrypt(_ cipherBase64: String, groupKey: SymmetricKey) -> String? {
        guard let data = Data(base64Encoded: cipherBase64),
              let sealedBox = try? AES.GCM.SealedBox(combined: data),
              let plainData = try? AES.GCM.open(sealedBox, using: groupKey),
              let plaintext = String(data: plainData, encoding: .utf8) else { return nil }
        return plaintext
    }

    // MARK: - Binary Encryption (photos / attachments)
    // Returns the raw combined GCM box (nonce + ciphertext + tag) as Data,
    // ready to upload to Storage. Unlike the String variants this skips
    // base64 — the blob is opaque bytes either way, so we avoid the 33% inflation.

    static func encryptData(_ plaintext: Data, groupKey: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: groupKey)
        guard let combined = sealed.combined else { throw EncryptionError.decryptionFailed }
        return combined
    }

    static func decryptData(_ cipher: Data, groupKey: SymmetricKey) -> Data? {
        guard let sealedBox = try? AES.GCM.SealedBox(combined: cipher),
              let plainData = try? AES.GCM.open(sealedBox, using: groupKey) else { return nil }
        return plainData
    }

    // MARK: - Keychain

    private static func saveToKeychain(key: String, data: Data) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else {
            throw EncryptionError.keychainError
        }
    }

    static func loadFromKeychain(key: String) throws -> Data {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { throw EncryptionError.keychainError }
        return data
    }

    enum EncryptionError: Error {
        case keychainError, invalidPublicKey, decryptionFailed
    }
}
