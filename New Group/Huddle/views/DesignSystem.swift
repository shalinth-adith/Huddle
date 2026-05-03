import SwiftUI

// MARK: - Lush Color

enum LushColor {
    case coral, rose, amber, plum, slate

    var gradient: [Color] {
        switch self {
        case .coral: return [Color(hex: "FFB68A"), Color(hex: "F26A45"), Color(hex: "A8381B")]
        case .rose:  return [Color(hex: "F4A0B5"), Color(hex: "E85A7A"), Color(hex: "6B2B3D")]
        case .amber: return [Color(hex: "FFD89A"), Color(hex: "F5A742"), Color(hex: "B47312")]
        case .plum:  return [Color(hex: "C078A0"), Color(hex: "6B2B3D"), Color(hex: "2C0F1B")]
        case .slate: return [Color(hex: "4A3530"), Color(hex: "2A1D1A"), Color(hex: "16100F")]
        }
    }

    var shine: Color {
        switch self {
        case .coral: return Color(hex: "FFE6D2")
        case .rose:  return Color(hex: "FFDCE6")
        case .amber: return Color(hex: "FFF0D2")
        case .plum:  return Color(hex: "FFD2E1")
        case .slate: return Color(hex: "FFC8AA")
        }
    }
}

// MARK: - Aurora Background

struct AuroraBackground: View {
    var intensity: Double = 1.0
    @State private var phase = false
    @Environment(\.colorScheme) private var colorScheme

    private var blobMult: Double { colorScheme == .light ? 0.20 : 1.0 }

    var body: some View {
        ZStack {
            Color.huddleBackground
            Circle()
                .fill(Color(hex: "FF6A3D"))
                .frame(width: 300, height: 300)
                .blur(radius: 48)
                .opacity(0.65 * intensity * blobMult)
                .offset(x: phase ? -40 : -90, y: phase ? -60 : -120)
                .animation(.easeInOut(duration: 14).repeatForever(autoreverses: true), value: phase)
            Circle()
                .fill(Color(hex: "E85A7A"))
                .frame(width: 260, height: 260)
                .blur(radius: 44)
                .opacity(0.50 * intensity * blobMult)
                .offset(x: phase ? 150 : 110, y: phase ? -10 : -55)
                .animation(.easeInOut(duration: 18).repeatForever(autoreverses: true), value: phase)
            Circle()
                .fill(Color(hex: "F5A742"))
                .frame(width: 340, height: 340)
                .blur(radius: 55)
                .opacity(0.35 * intensity * blobMult)
                .offset(x: phase ? 20 : -30, y: phase ? 320 : 270)
                .animation(.easeInOut(duration: 22).repeatForever(autoreverses: true), value: phase)
        }
        .drawingGroup()
        .ignoresSafeArea()
        .onAppear { phase = true }
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    var isHero: Bool = false
    var radius: CGFloat = 24
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(padding: CGFloat = 18, isHero: Bool = false, radius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.isHero = isHero
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.huddleGlassFill)
                    .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color.huddleBorder, lineWidth: 1))
            )
            .shadow(
                color: colorScheme == .light ? .black.opacity(0.08) : .black.opacity(isHero ? 0.55 : 0.40),
                radius: colorScheme == .light ? 8 : (isHero ? 28 : 14),
                x: 0,
                y: colorScheme == .light ? 4 : (isHero ? 18 : 10)
            )
    }
}

// MARK: - Clay Icon

struct ClayIcon: View {
    var systemImage: String
    var lushColor: LushColor = .coral
    var size: CGFloat = 56
    var glow: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30)
                .fill(LinearGradient(colors: lushColor.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.40), radius: 8, x: 0, y: 5)
                .shadow(color: glow ? Color(hex: "FF8A66").opacity(0.45) : .clear, radius: 14, x: 0, y: 0)
                .overlay(
                    LinearGradient(colors: [lushColor.shine.opacity(0.45), .clear], startPoint: .top, endPoint: .center)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.28))
                        .padding(3)
                )
            Image(systemName: systemImage)
                .font(.system(size: size * 0.40, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Lush Avatar

struct LushAvatar: View {
    var letter: String
    var lushColor: LushColor = .coral
    var size: CGFloat = 36
    var glow: Bool = false
    var photoBase64: String? = nil

    @State private var cachedImage: UIImage? = nil

    var body: some View {
        ZStack {
            if let img = cachedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(LinearGradient(colors: lushColor.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size, height: size)
                    .overlay(
                        LinearGradient(colors: [lushColor.shine.opacity(0.45), .clear], startPoint: .top, endPoint: .center)
                            .clipShape(Circle())
                            .padding(2)
                    )
                    .shadow(color: glow ? Color(hex: "FF8A66").opacity(0.55) : .clear, radius: 10, x: 0, y: 0)
                Text(String(letter.prefix(1)).uppercased())
                    .font(.system(size: size * 0.40, weight: .bold))
                    .foregroundColor(Color(hex: "FFE6DD"))
            }
        }
        .frame(width: size, height: size)
        .task(id: photoBase64) {
            guard let base64 = photoBase64, !base64.isEmpty else { cachedImage = nil; return }
            let decoded = await Task.detached(priority: .utility) {
                guard let data = Data(base64Encoded: base64) else { return nil as UIImage? }
                return UIImage(data: data)
            }.value
            await MainActor.run { cachedImage = decoded }
        }
    }
}

// MARK: - Brand Row

struct BrandRow: View {
    var size: CGFloat = 18
    var animate: Bool = false
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "heart.fill")
                .font(.system(size: size + 4, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FFD2BD"), Color(hex: "FF8A66"), Color(hex: "D8512B")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "FF8A66").opacity(0.6), radius: 6)
                .scaleEffect(heartScale)
                .onAppear {
                    guard animate else { return }
                    withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { heartScale = 1.14 }
                }
            Text("Huddle")
                .font(.system(size: size, weight: .bold))
                .foregroundColor(Color(hex: "FF8A66"))
                .tracking(-0.3)
        }
    }
}

// MARK: - Eyebrow

struct LushEyebrow: View {
    var text: String
    var color: Color = Color(hex: "FFB68A").opacity(0.85)

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .tracking(1.6)
            .foregroundColor(color)
    }
}

// MARK: - Ember Button

struct EmberButton: View {
    var label: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    @GestureState private var isPressed = false

    var body: some View {
        Button(action: { if !isDisabled && !isLoading { action() } }) {
            HStack(spacing: 8) {
                if let img = systemImage {
                    Image(systemName: img).font(.system(size: 18, weight: .semibold))
                }
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .transition(.opacity)
                } else {
                    Text(label).font(.system(size: 16, weight: .semibold)).tracking(-0.1)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    if isDisabled {
                        RoundedRectangle(cornerRadius: 18).fill(Color(hex: "F5E9E2").opacity(0.12))
                    } else {
                        LinearGradient(
                            colors: [Color(hex: "FFA078"), Color(hex: "F26A45"), Color(hex: "D8512B")],
                            startPoint: .top, endPoint: .bottom
                        )
                        VStack {
                            LinearGradient(colors: [Color.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center)
                                .frame(height: 24).padding(.horizontal, 8)
                            Spacer()
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
            )
            .scaleEffect(isPressed && !isDisabled ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .disabled(isDisabled || isLoading)
        .simultaneousGesture(DragGesture(minimumDistance: 0).updating($isPressed) { _, state, _ in state = true })
        .shadow(color: isDisabled ? .clear : Color(hex: "D8512B").opacity(0.45), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Ghost Button

struct GhostButton: View {
    var label: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let img = systemImage {
                    Image(systemName: img).font(.system(size: 18, weight: .semibold))
                }
                Text(label).font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(hex: "F5E9E2"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "281A16").opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "FFC8AA").opacity(0.18), lineWidth: 1))
            )
        }
        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Glass Circle Button

struct GlassCircleButton: View {
    var systemImage: String
    var size: CGFloat = 38
    var action: () -> Void

    @GestureState private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundColor(Color.huddleTextPrimary.opacity(0.9))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.huddleGlassFill)
                        .overlay(Circle().stroke(Color.huddleBorder, lineWidth: 1))
                )
                .scaleEffect(isPressed ? 0.88 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0).updating($isPressed) { _, state, _ in state = true })
    }
}
