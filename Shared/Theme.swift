import SwiftUI

enum BabymonTheme {
    // Core palette — warm, calming tones
    static let accent = Color(red: 0.42, green: 0.35, blue: 0.85)       // Soft purple
    static let accentLight = Color(red: 0.58, green: 0.52, blue: 0.95)  // Light purple
    static let warmPink = Color(red: 0.92, green: 0.45, blue: 0.55)     // Warm pink
    static let softGreen = Color(red: 0.35, green: 0.78, blue: 0.65)    // Mint green
    static let softBlue = Color(red: 0.4, green: 0.65, blue: 0.95)      // Sky blue
    static let warmOrange = Color(red: 0.95, green: 0.6, blue: 0.35)    // Warm orange
    static let darkBg = Color(red: 0.08, green: 0.07, blue: 0.14)       // Deep navy
    static let cardBg = Color(red: 0.12, green: 0.11, blue: 0.20)       // Card surface
    static let cardBgLight = Color(red: 0.16, green: 0.15, blue: 0.25)  // Card hover

    static let backgroundGradient = LinearGradient(
        colors: [darkBg, Color(red: 0.10, green: 0.08, blue: 0.18)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [accent, accentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pinkGradient = LinearGradient(
        colors: [warmPink, Color(red: 0.85, green: 0.35, blue: 0.65)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let greenGradient = LinearGradient(
        colors: [softGreen, Color(red: 0.25, green: 0.7, blue: 0.75)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Watch-specific (smaller, bolder)
    static let watchAccent = accent
    static let watchCardBg = Color(red: 0.15, green: 0.14, blue: 0.24)
}

// MARK: - Reusable Components

struct GlowingIcon: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    var isAnimating: Bool = false

    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(color.opacity(glowOpacity))
                .frame(width: size * 2.2, height: size * 2.2)
                .blur(radius: size * 0.4)

            // Icon circle
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size * 1.6, height: size * 1.6)

            Image(systemName: systemName)
                .font(.system(size: size * 0.55, weight: .semibold))
                .foregroundStyle(color)
        }
        .onChange(of: isAnimating) { _, active in
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowOpacity = active ? 0.6 : 0.3
            }
        }
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.6
                }
            }
        }
    }
}

struct PulsingRing: View {
    let color: Color
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    scale = 2.5
                    opacity = 0
                }
            }
    }
}

struct StatusPill: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? BabymonTheme.softGreen : BabymonTheme.warmOrange)
                .frame(width: 8, height: 8)
            Text(isConnected ? "Watch Connected" : "Searching for Watch...")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isConnected ? BabymonTheme.softGreen : BabymonTheme.warmOrange)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill((isConnected ? BabymonTheme.softGreen : BabymonTheme.warmOrange).opacity(0.12))
        )
    }
}

struct LiveBadge: View {
    @State private var isVisible = true

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(.red)
                .frame(width: 7, height: 7)
                .opacity(isVisible ? 1 : 0.3)
            Text("LIVE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(.red.opacity(0.8)))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isVisible.toggle()
            }
        }
    }
}

struct StopButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("End Monitoring")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(BabymonTheme.warmPink.opacity(0.9))
            )
        }
        .padding(.horizontal, 24)
    }
}

struct AudioWaveView: View {
    let color: Color
    let barCount: Int
    @State private var levels: [CGFloat]

    init(color: Color, barCount: Int = 20) {
        self.color = color
        self.barCount = barCount
        _levels = State(initialValue: (0..<barCount).map { _ in CGFloat.random(in: 0.1...0.3) })
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.6 + Double(levels[i]) * 0.4))
                    .frame(width: 4, height: 20 + levels[i] * 40)
            }
        }
        .onAppear {
            animateBars()
        }
    }

    private func animateBars() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                levels = (0..<barCount).map { _ in CGFloat.random(in: 0.1...1.0) }
            }
        }
    }
}
