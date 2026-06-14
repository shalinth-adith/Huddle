//
//  PhotoMessageView.swift
//  Huddle
//
//  Renders a `.photo` chat message: lazily decrypts + loads the blob from
//  Storage, shows a rounded thumbnail with an optional caption, and opens a
//  zoomable full-screen viewer on tap.
//

import SwiftUI

struct PhotoMessageView: View {
    let message: HuddleMessage
    let isMe: Bool
    @ObservedObject var viewModel: FamilyFeedViewModel

    @State private var image: UIImage?
    @State private var failed = false
    @State private var showFullScreen = false

    private let maxWidth: CGFloat = 240
    private let cornerRadius: CGFloat = 18

    var body: some View {
        VStack(alignment: isMe ? .trailing : .leading, spacing: 6) {
            thumbnail
            caption
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            if let image {
                FullScreenPhotoView(image: image, isPresented: $showFullScreen)
            }
        }
        .task(id: message.photoURL) { await load() }
    }

    @ViewBuilder
    private var thumbnail: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: maxWidth, height: thumbnailHeight(for: image))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showFullScreen = true
                    }
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.huddleGlassFill)
                    .frame(width: maxWidth, height: 180)
                    .overlay {
                        if failed {
                            VStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 20))
                                Text("Couldn't load photo")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Color.huddleTextPrimary.opacity(0.4))
                        } else {
                            ProgressView().tint(Color.huddleCoral)
                        }
                    }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.huddleBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private var caption: some View {
        if !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(isMe ? .white : Color.huddleTextPrimary)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(
                    Group {
                        if isMe {
                            RoundedRectangle(cornerRadius: 18).fill(
                                LinearGradient(colors: [Color(hex: "FFA078"), Color(hex: "D8512B")],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        } else {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.huddleGlassFill)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.huddleBorder, lineWidth: 1))
                        }
                    }
                )
                .frame(maxWidth: maxWidth, alignment: isMe ? .trailing : .leading)
        }
    }

    private func thumbnailHeight(for image: UIImage) -> CGFloat {
        let ratio = image.size.height / max(image.size.width, 1)
        // Clamp to keep very tall/wide photos from dominating the feed.
        return min(max(maxWidth * ratio, 120), 320)
    }

    private func load() async {
        failed = false
        let loaded = await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            viewModel.loadPhoto(for: message) { continuation.resume(returning: $0) }
        }
        await MainActor.run {
            if let loaded { image = loaded } else { failed = true }
        }
    }
}

/// Pinch-to-zoom, drag-to-dismiss full-screen photo viewer.
private struct FullScreenPhotoView: View {
    let image: UIImage
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in scale = max(1, lastScale * value) }
                        .onEnded { _ in lastScale = scale }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3)) {
                        scale = scale > 1 ? 1 : 2.5
                        lastScale = scale
                    }
                }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.18)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
    }
}
