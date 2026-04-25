import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private func adaptiveColor(
    dark: (Double, Double, Double, Double) = (0, 0, 0, 1),
    light: (Double, Double, Double, Double) = (0, 0, 0, 1)
) -> Color {
    #if canImport(UIKit)
    return Color(UIColor { trait in
        let c = trait.userInterfaceStyle == .light ? light : dark
        return UIColor(red: CGFloat(c.0), green: CGFloat(c.1), blue: CGFloat(c.2), alpha: CGFloat(c.3))
    })
    #else
    let c = dark
    return Color(red: c.0, green: c.1, blue: c.2).opacity(c.3)
    #endif
}

private func adaptiveColor(
    dark: (Double, Double, Double),
    light: (Double, Double, Double)
) -> Color {
    adaptiveColor(
        dark: (dark.0, dark.1, dark.2, 1),
        light: (light.0, light.1, light.2, 1)
    )
}

enum BabymonTheme {
    // Core palette — warm, calming tones
    static let accent = Color(red: 0.42, green: 0.35, blue: 0.85)
    static let accentLight = Color(red: 0.58, green: 0.52, blue: 0.95)
    static let warmPink = Color(red: 0.92, green: 0.45, blue: 0.55)
    static let softGreen = Color(red: 0.35, green: 0.78, blue: 0.65)
    static let softBlue = Color(red: 0.4, green: 0.65, blue: 0.95)
    static let warmOrange = Color(red: 0.95, green: 0.6, blue: 0.35)

    // Adaptive backgrounds: deep night palette in dark mode, soft lavender in light mode.
    static let darkBg = adaptiveColor(
        dark: (0.08, 0.07, 0.14),
        light: (0.96, 0.95, 0.99)
    )
    static let cardBg = adaptiveColor(
        dark: (0.12, 0.11, 0.20),
        light: (1.00, 1.00, 1.00)
    )
    private static let bgGradientEnd = adaptiveColor(
        dark: (0.10, 0.08, 0.18),
        light: (0.92, 0.91, 0.97)
    )

    /// Subtle hairline used for card outlines. White-on-dark, black-on-light.
    static let hairline = adaptiveColor(
        dark: (1.0, 1.0, 1.0, 0.05),
        light: (0.0, 0.0, 0.0, 0.06)
    )

    static let backgroundGradient = LinearGradient(
        colors: [darkBg, bgGradientEnd],
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

    // Watch-specific
    static let watchCardBg = Color(red: 0.15, green: 0.14, blue: 0.24)
}

// MARK: - Reusable Components

struct GlowingIcon: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    var isAnimating: Bool = true

    @State private var glowOpacity: Double = 0.2

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(glowOpacity))
                .frame(width: size * 2.2, height: size * 2.2)
                .blur(radius: size * 0.4)

            Circle()
                .fill(color.opacity(0.12))
                .frame(width: size * 1.6, height: size * 1.6)

            Image(systemName: systemName)
                .font(.system(size: size * 0.55, weight: .semibold))
                .foregroundStyle(color)
        }
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.45
                }
            }
        }
        .onChange(of: isAnimating) { _, active in
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowOpacity = active ? 0.45 : 0.2
            }
        }
    }
}

struct PulsingRing: View {
    let color: Color
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 1.5)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    scale = 1.6
                    opacity = 0.08
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
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isConnected ? BabymonTheme.softGreen : BabymonTheme.warmOrange)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill((isConnected ? BabymonTheme.softGreen : BabymonTheme.warmOrange).opacity(0.1))
        )
    }
}

struct LiveBadge: View {
    @State private var dotOpacity: Double = 1

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(.red)
                .frame(width: 7, height: 7)
                .opacity(dotOpacity)
            Text("LIVE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(.red.opacity(0.75)))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                dotOpacity = 0.25
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

    @State private var phase: Double = 0

    init(color: Color, barCount: Int = 20) {
        self.color = color
        self.barCount = barCount
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08)) { timeline in
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    let height = barHeight(for: i, date: timeline.date)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.5 + height * 0.5))
                        .frame(width: 4, height: 12 + height * 48)
                }
            }
        }
    }

    private func barHeight(for index: Int, date: Date) -> Double {
        let t = date.timeIntervalSinceReferenceDate
        let wave1 = sin(t * 3.0 + Double(index) * 0.6) * 0.4
        let wave2 = sin(t * 5.0 + Double(index) * 1.2) * 0.3
        let wave3 = sin(t * 1.5 + Double(index) * 0.3) * 0.3
        return max(0.05, (wave1 + wave2 + wave3 + 1.0) / 2.0)
    }
}
