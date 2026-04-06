import SwiftUI

struct WatchModeSelectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Header
                VStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(BabymonTheme.accentGradient)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                    Text("Babymon")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)

                // Status
                HStack(spacing: 5) {
                    Circle()
                        .fill(connectivity.isReachable ? BabymonTheme.softGreen : BabymonTheme.warmOrange)
                        .frame(width: 6, height: 6)
                    Text(connectivity.isReachable ? "iPhone Connected" : "Searching...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(connectivity.isReachable ? BabymonTheme.softGreen : BabymonTheme.warmOrange)
                }
                .opacity(appeared ? 1 : 0)

                // Mode buttons
                WatchModeButton(
                    icon: "video.fill",
                    title: "Watch Baby",
                    color: BabymonTheme.accent,
                    disabled: !connectivity.isReachable
                ) {
                    connectivity.currentMode = .phoneSource
                    connectivity.sendModeSelection(.phoneSource)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                WatchModeButton(
                    icon: "mic.fill",
                    title: "Send Audio",
                    color: BabymonTheme.softGreen,
                    disabled: !connectivity.isReachable
                ) {
                    connectivity.currentMode = .watchSource
                    connectivity.sendModeSelection(.watchSource)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
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
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(0.2))
                    )

                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(BabymonTheme.watchCardBg)
            )
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.4 : 1)
        .disabled(disabled)
    }
}
