import SwiftUI

struct PhoneAudioReceiverView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var audioPlayer = AudioPlayerManager()
    @State private var isActive = false
    @State private var appeared = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated listening indicator
            ZStack {
                // Pulsing rings
                if isActive {
                    PulsingRing(color: BabymonTheme.softGreen)
                        .frame(width: 80, height: 80)
                    PulsingRing(color: BabymonTheme.softGreen.opacity(0.5))
                        .frame(width: 80, height: 80)
                }

                GlowingIcon(
                    systemName: "waveform",
                    color: BabymonTheme.softGreen,
                    size: 70,
                    isAnimating: isActive
                )
            }
            .frame(height: 200)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.7)

            // Title
            VStack(spacing: 8) {
                Text("Listening")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    LiveBadge()
                    Text(formattedTime)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, 16)

            // Audio wave visualization
            AudioWaveView(color: BabymonTheme.softGreen)
                .frame(height: 60)
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)

            // Info
            HStack(spacing: 6) {
                Image(systemName: "applewatch")
                    .font(.system(size: 12))
                Text("Audio from Apple Watch")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.4))
            .padding(.top, 24)

            Spacer()

            StopButton {
                stop()
            }
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, 40)
        }
        .onAppear {
            audioPlayer.setup()
            connectivity.onAudioDataReceived = { data in
                audioPlayer.playAudioData(data)
            }
            isActive = true
            startTimer()
            withAnimation(.spring(duration: 0.7, bounce: 0.3)) {
                appeared = true
            }
        }
        .onDisappear {
            stop()
        }
    }

    private var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        audioPlayer.stop()
        connectivity.onAudioDataReceived = nil
        isActive = false
        connectivity.currentMode = nil
    }
}
