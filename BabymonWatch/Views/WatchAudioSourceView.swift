import SwiftUI
import WatchKit

struct WatchAudioSourceView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var captureManager = WatchAudioCaptureManager()
    @State private var extendedSession: WKExtendedRuntimeSession?
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.5

    var body: some View {
        VStack(spacing: 6) {
            Spacer()

            // Animated mic indicator with sound level ring
            ZStack {
                // Pulsing ring
                Circle()
                    .stroke(ringColor.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 50, height: 50)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

                // Sound level ring
                Circle()
                    .trim(from: 0, to: CGFloat(captureManager.soundAnalyzer.currentLevel))
                    .stroke(ringColor, lineWidth: 3)
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.1), value: captureManager.soundAnalyzer.currentLevel)

                // Icon
                ZStack {
                    Circle()
                        .fill(ringColor.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: captureManager.soundAnalyzer.isCryDetected ? "exclamationmark.triangle.fill" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(ringColor)
                }
            }

            // Status
            VStack(spacing: 2) {
                if captureManager.soundAnalyzer.isCryDetected {
                    Text("Sound Detected!")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(BabymonTheme.warmPink)
                } else {
                    Text("Monitoring")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text(formattedTime)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))

                // Level bar
                SoundLevelBar(level: captureManager.soundAnalyzer.currentLevel)
                    .frame(height: 4)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }

            Spacer()

            // Stop button
            Button {
                stop()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 10))
                    Text("Stop")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(BabymonTheme.warmPink.opacity(0.8))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .onAppear {
            startExtendedSession()
            captureManager.onAudioReady = { data in
                connectivity.sendStreamData(data)
            }
            captureManager.soundAnalyzer.onCryDetected = {
                connectivity.sendCryAlert()
                WKInterfaceDevice.current().play(.notification)
            }
            captureManager.startCapture()
            startTimer()

            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                ringScale = 2.0
                ringOpacity = 0
            }
        }
        .onDisappear {
            stop()
        }
    }

    private var ringColor: Color {
        captureManager.soundAnalyzer.isCryDetected ? BabymonTheme.warmPink : BabymonTheme.softGreen
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
        captureManager.stopCapture()
        extendedSession?.invalidate()
        extendedSession = nil
        connectivity.currentMode = nil
    }

    private func startExtendedSession() {
        let session = WKExtendedRuntimeSession()
        session.start()
        extendedSession = session
    }
}

struct SoundLevelBar: View {
    let level: Float

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.1))

                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: geo.size.width * CGFloat(level))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
    }

    private var barColor: Color {
        if level > 0.7 { return BabymonTheme.warmPink }
        if level > 0.4 { return BabymonTheme.warmOrange }
        return BabymonTheme.softGreen
    }
}
