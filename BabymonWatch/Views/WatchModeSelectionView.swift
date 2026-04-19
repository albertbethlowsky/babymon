import SwiftUI

struct WatchModeSelectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 10) {
            // Header
            VStack(spacing: 3) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(BabymonTheme.accentGradient)
                    .scaleEffect(appeared ? 1 : 0.4)
                    .opacity(appeared ? 1 : 0)

                Text("Babymon")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Status
            HStack(spacing: 4) {
                Circle()
                    .fill(connectivity.isReachable ? BabymonTheme.softGreen : BabymonTheme.warmOrange)
                    .frame(width: 5, height: 5)
                Text(connectivity.isReachable ? "Connected" : "Searching...")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(connectivity.isReachable ? BabymonTheme.softGreen : BabymonTheme.warmOrange)
            }
            .opacity(appeared ? 1 : 0)

            // Buttons
            VStack(spacing: 8) {
                WatchModeButton(
                    icon: "video.fill",
                    title: "Watch Baby",
                    color: BabymonTheme.accent,
                    disabled: !connectivity.isReachable
                ) {
                    withAnimation { connectivity.currentMode = .phoneSource }
                    connectivity.sendModeSelection(.phoneSource)
                }

                WatchModeButton(
                    icon: "mic.fill",
                    title: "Send Audio",
                    color: BabymonTheme.softGreen,
                    disabled: !connectivity.isReachable
                ) {
                    withAnimation { connectivity.currentMode = .watchSource }
                    connectivity.sendModeSelection(.watchSource)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
        }
        .padding(.horizontal, 2)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                appeared = true
            }
        }
    }
}

struct WatchModeButton: View {
    let icon: String
    let title: String
    let color: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 26, height: 26)
                    .background(RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.15)))

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 12).fill(BabymonTheme.watchCardBg))
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.35 : 1)
        .disabled(disabled)
    }
}
