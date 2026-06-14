//
//  StorageService.swift
//  Huddle
//
//  Uploads and downloads end-to-end encrypted photo blobs to Firebase Storage.
//  The bytes on Storage are AES-256-GCM ciphertext (sealed with the family
//  group key), so Storage never sees a plaintext image. Firestore messages
//  only carry the Storage path, never the image itself.
//

import UIKit
import CryptoKit
import FirebaseStorage

final class StorageService {
    private let storage = Storage.storage()

    /// Max edge length for an uploaded photo. Family chat doesn't need full-res;
    /// 1600px keeps detail while cutting upload size and decrypt cost.
    private static let maxDimension: CGFloat = 1600
    private static let jpegQuality: CGFloat = 0.7

    enum StorageError: Error { case encodeFailed, encryptFailed, emptyDownload }

    /// Storage path for a message's photo blob. Membership-gated by storage.rules.
    static func photoPath(familyId: String, messageId: String) -> String {
        "families/\(familyId)/photos/\(messageId).enc"
    }

    // MARK: - Upload

    /// Downscales + JPEG-compresses the image, encrypts the bytes with the
    /// family group key, and uploads the ciphertext. Returns the Storage path.
    func uploadEncryptedPhoto(
        image: UIImage,
        familyId: String,
        messageId: String,
        groupKey: SymmetricKeyBox,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let path = Self.photoPath(familyId: familyId, messageId: messageId)

        DispatchQueue.global(qos: .userInitiated).async {
            guard let jpeg = Self.downscaledJPEG(image) else {
                DispatchQueue.main.async { completion(.failure(StorageError.encodeFailed)) }
                return
            }
            guard let cipher = try? EncryptionService.encryptData(jpeg, groupKey: groupKey.key) else {
                DispatchQueue.main.async { completion(.failure(StorageError.encryptFailed)) }
                return
            }

            let ref = self.storage.reference(withPath: path)
            let meta = StorageMetadata()
            meta.contentType = "application/octet-stream"  // opaque ciphertext

            ref.putData(cipher, metadata: meta) { _, error in
                if let error {
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }
                // Cache the plaintext locally so the sender skips a round-trip.
                PhotoCache.shared.insert(image, forPath: path)
                DispatchQueue.main.async { completion(.success(path)) }
            }
        }
    }

    // MARK: - Download

    /// Downloads the ciphertext at `path`, decrypts with the group key, and
    /// returns a UIImage. Results are cached in-memory by path.
    func downloadDecryptedPhoto(
        path: String,
        groupKey: SymmetricKeyBox,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        if let cached = PhotoCache.shared.image(forPath: path) {
            completion(.success(cached))
            return
        }

        let ref = storage.reference(withPath: path)
        // 12 MB ceiling — ciphertext of a 1600px JPEG is comfortably under this.
        ref.getData(maxSize: 12 * 1024 * 1024) { data, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data, !data.isEmpty else {
                completion(.failure(StorageError.emptyDownload))
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                guard let plain = EncryptionService.decryptData(data, groupKey: groupKey.key),
                      let image = UIImage(data: plain) else {
                    DispatchQueue.main.async { completion(.failure(StorageError.encryptFailed)) }
                    return
                }
                PhotoCache.shared.insert(image, forPath: path)
                DispatchQueue.main.async { completion(.success(image)) }
            }
        }
    }

    /// Best-effort delete of the blob backing a photo message.
    func deletePhoto(path: String) {
        storage.reference(withPath: path).delete(completion: nil)
        PhotoCache.shared.remove(forPath: path)
    }

    /// Best-effort delete of every photo blob for a family (used when the last
    /// member leaves and the whole group is wiped).
    func deleteAllPhotos(familyId: String) {
        storage.reference(withPath: "families/\(familyId)/photos").listAll { result, _ in
            guard let result else { return }
            for item in result.items { item.delete(completion: nil) }
        }
    }

    // MARK: - Image processing

    private static func downscaledJPEG(_ image: UIImage) -> Data? {
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1.0

        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1  // target is already in pixels
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.jpegData(compressionQuality: jpegQuality)
    }
}

/// Thin wrapper so callers pass the group key without importing CryptoKit
/// throughout the view layer.
struct SymmetricKeyBox {
    let key: SymmetricKey
    init?(familyId: String) {
        guard let key = EncryptionService.loadGroupKey(familyId: familyId) else { return nil }
        self.key = key
    }
}

/// In-memory cache of decrypted photos keyed by Storage path.
final class PhotoCache {
    static let shared = PhotoCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() { cache.countLimit = 80 }

    func image(forPath path: String) -> UIImage? { cache.object(forKey: path as NSString) }
    func insert(_ image: UIImage, forPath path: String) { cache.setObject(image, forKey: path as NSString) }
    func remove(forPath path: String) { cache.removeObject(forKey: path as NSString) }
}
