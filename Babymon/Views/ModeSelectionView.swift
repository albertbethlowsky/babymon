import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @State private var appeared = false
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Spacer()
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(BabymonTheme.cardBg.opacity(0.7)))
                                .overlay(Circle().stroke(BabymonTheme.hairline, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, max(geo.safeAreaInsets.top + 4, 12))
                    .opacity(appeared ? 1 : 0)

                    // Hero
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(BabymonTheme.accent.opacity(0.08))
                                .frame(width: 96, height: 96)
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(BabymonTheme.accentGradient)
                        }
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                        Text("Babymon")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .opacity(appeared ? 1 : 0)

                        Text("Keep an eye on your little one")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .opacity(appeared ? 1 : 0)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .onLongPressGesture(minimumDuration: 2) {
                        if !connectivity.isDemoMode {
                            connectivity.enableDemoMode()
                        }
                    }

                    // Status
                    StatusPill(isConnected: connectivity.isReachable)
                        .padding(.bottom, 24)
                        .opacity(appeared ? 1 : 0)

                    // Mode cards
                    VStack(spacing: 14) {
                        ModeCard(
                            icon: "video.fill",
                            title: "Video Monitor",
                            subtitle: "Stream camera & audio to Watch",
                            iconColor: BabymonTheme.accentLight,
                            disabled: !connectivity.isReachable
                        ) {
                            withAnimation { connectivity.currentMode = .phoneSource }
                            connectivity.sendModeSelection(.phoneSource)
                        }

                        ModeCard(
                            icon: "waveform",
                            title: "Audio Monitor",
                            subtitle: "Listen to Watch microphone",
                            iconColor: BabymonTheme.softGreen,
                            disabled: !connectivity.isReachable
                        ) {
                            withAnimation { connectivity.currentMode = .watchSource }
                            connectivity.sendModeSelection(.watchSource)
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                    // Footer
                    if !connectivity.isReachable && !connectivity.isDemoMode {
                        Text("Open Babymon on your Apple Watch to connect")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)
                    }

                    if connectivity.isDemoMode {
                        Text("Demo Mode")
                            .font(.caption2)
                            .foregroundStyle(BabymonTheme.warmOrange.opacity(0.5))
                            .padding(.top, 20)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: geo.size.height)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.25)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct ModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let disabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(BabymonTheme.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(BabymonTheme.hairline, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.35 : 1)
        .disabled(disabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
