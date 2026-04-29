//
//  MemberAvatarView.swift
//  Huddle
//

import SwiftUI

struct MemberAvatarView: View {
    let name: String
    let photoBase64: String?
    let size: CGFloat

    // Decoded once per unique name — avoids re-running base64 decode on every SwiftUI render
    private static let imageCache = NSCache<NSString, UIImage>()

    private var decodedImage: UIImage? {
        guard let base64 = photoBase64 else { return nil }
        let key = String(base64.prefix(64)) as NSString
        if let cached = Self.imageCache.object(forKey: key) { return cached }
        guard let data = Data(base64Encoded: base64), let img = UIImage(data: data) else { return nil }
        Self.imageCache.setObject(img, forKey: key)
        return img
    }

    var body: some View {
        Group {
            if let img = decodedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color.huddleCoral.opacity(0.12))
                    .overlay(
                        Text(initials)
                            .font(.system(size: size * 0.35, weight: .semibold))
                            .foregroundColor(Color.huddleCoral)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1))
    }

    private var initials: String {
        String(name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }
}
