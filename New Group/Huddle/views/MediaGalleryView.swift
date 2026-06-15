//
//  MediaGalleryView.swift
//  Huddle
//
//  All photos shared in the family, in one grid. Tap a photo to view it
//  full-screen. Decrypts on the fly (cached by Storage path).
//

import SwiftUI

struct MediaGalleryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: MediaGalleryViewModel
    @State private var selected: HuddleMessage?

    private let columns = [GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3)]

    init(messageService: MessageService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: MediaGalleryViewModel(messageService: messageService, authService: authService))
    }

    var body: some View {
        ZStack {
            Color.huddleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading {
                    Spacer(); ProgressView().tint(Color.huddleCoral); Spacer()
                } else if viewModel.photos.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 3) {
                            ForEach(viewModel.photos) { photo in
                                GalleryThumb(message: photo, viewModel: viewModel)
                                    .onTapGesture { selected = photo }
                            }
                        }
                        .padding(.horizontal, 3)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .fullScreenCover(item: $selected) { photo in
            GalleryDetailView(message: photo, viewModel: viewModel)
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                LushEyebrow(text: "Shared media")
                Text("Photos").font(.system(size: 24, weight: .bold)).foregroundColor(Color.huddleTextPrimary).tracking(-0.6)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Color.huddleTextPrimary.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.huddleGlassFill).overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1)))
            }
        }
        .padding(.horizontal, 20).padding(.top, 64).padding(.bottom, 14)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            ClayIcon(systemImage: "photo.on.rectangle.angled", lushColor: .coral, size: 64)
            Text("No photos yet").font(.system(size: 18, weight: .semibold)).foregroundColor(Color.huddleTextPrimary)
            Text("Photos shared in the chat will appear here.")
                .font(.system(size: 14)).foregroundColor(Color.huddleTextPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Thumbnail

private struct GalleryThumb: View {
    let message: HuddleMessage
    @ObservedObject var viewModel: MediaGalleryViewModel
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle().fill(Color.huddleGlassFill)
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ProgressView().tint(Color.huddleCoral.opacity(0.6))
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
        .task(id: message.photoURL) {
            let loaded = await withCheckedContinuation { (c: CheckedContinuation<UIImage?, Never>) in
                viewModel.loadImage(for: message) { c.resume(returning: $0) }
            }
            await MainActor.run { image = loaded }
        }
    }
}

// MARK: - Full-screen detail

private struct GalleryDetailView: View {
    let message: HuddleMessage
    @ObservedObject var viewModel: MediaGalleryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable().scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale = max(1, lastScale * $0) }
                            .onEnded { _ in lastScale = scale }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3)) { scale = scale > 1 ? 1 : 2.5; lastScale = scale }
                    }
            } else {
                ProgressView().tint(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            .frame(width: 36, height: 36).background(Circle().fill(Color.white.opacity(0.18)))
                    }
                    .padding(.trailing, 20).padding(.top, 8)
                }
                Spacer()
                if !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(message.content)
                        .font(.system(size: 15)).foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                        .padding(.bottom, 30)
                }
            }
        }
        .task(id: message.photoURL) {
            let loaded = await withCheckedContinuation { (c: CheckedContinuation<UIImage?, Never>) in
                viewModel.loadImage(for: message) { c.resume(returning: $0) }
            }
            await MainActor.run { image = loaded }
        }
    }
}
