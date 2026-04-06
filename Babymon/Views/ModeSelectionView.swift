import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // App icon + title
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(BabymonTheme.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(BabymonTheme.accent.opacity(0.06))
                            .frame(width: 105, height: 105)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(BabymonTheme.accentGradient)
                    }
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                    Text("Babymon")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Keep an eye on your little one")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                // Long-press the logo to enable demo mode on a real device
                .onLongPressGesture(minimumDuration: 2) {
                    if !connectivity.isDemoMode {
                        connectivity.enableDemoMode()
                    }
                }

                // Status
                StatusPill(isConnected: connectivity.isReachable)
                    .padding(.bottom, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                // Mode cards
                VStack(spacing: 16) {
                    ModeCard(
                        icon: "video.fill",
                        title: "Video Monitor",
                        subtitle: "Stream iPhone camera & audio to your Watch",
                        gradient: BabymonTheme.accentGradient,
                        iconColor: BabymonTheme.accentLight,
                        disabled: !connectivity.isReachable
                    ) {
                        connectivity.currentMode = .phoneSource
                        connectivity.sendModeSelection(.phoneSource)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)

                    ModeCard(
                        icon: "waveform",
                        title: "Audio Monitor",
                        subtitle: "Listen to your Watch microphone on iPhone",
                        gradient: BabymonTheme.greenGradient,
                        iconColor: BabymonTheme.softGreen,
                        disabled: !connectivity.isReachable
                    ) {
                        connectivity.currentMode = .watchSource
                        connectivity.sendModeSelection(.watchSource)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                }
                .padding(.horizontal, 20)

                // Footer
                Group {
                    if !connectivity.isReachable && !connectivity.isDemoMode {
                        Text("Open Babymon on your Apple Watch to connect")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.35))
                            .multilineTextAlignment(.center)
                    } else if connectivity.isDemoMode {
                        Text("Demo Mode")
                            .font(.caption2)
                            .foregroundStyle(BabymonTheme.warmOrange.opacity(0.6))
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                appeared = true
            }
        }
    }
}

struct ModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let iconColor: Color
    let disabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(BabymonTheme.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.4 : 1)
        .disabled(disabled)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) { isPressed = pressing }
        }, perform: {})
    }
}
