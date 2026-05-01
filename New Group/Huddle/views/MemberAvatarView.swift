import SwiftUI

struct MemberAvatarView: View {
    let name: String
    let photoBase64: String?
    let size: CGFloat

    @State private var image: UIImage?

    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 100
        return c
    }()

    var body: some View {
        Group {
            if let img = image {
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
        .task(id: photoBase64) {
            image = await decode(photoBase64)
        }
    }

    private var initials: String {
        String(name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }

    private func decode(_ base64: String?) async -> UIImage? {
        guard let base64 else { return nil }
        let key = NSString(string: String(base64.prefix(128)))
        if let cached = Self.cache.object(forKey: key) { return cached }
        return await Task.detached(priority: .utility) {
            guard let data = Data(base64Encoded: base64),
                  let img = UIImage(data: data) else { return nil }
            Self.cache.setObject(img, forKey: key)
            return img
        }.value
    }
}
