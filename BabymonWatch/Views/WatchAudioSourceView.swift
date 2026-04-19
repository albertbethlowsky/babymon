import SwiftUI
import WatchKit

struct WatchAudioSourceView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var captureManager = WatchAudioCaptureManager()
    @State private var extendedSession: WKExtendedRuntimeSession?
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?

    private var isAlert: Bool {
        captureManager.cryClassifier.isCrying || captureManager.soundAnalyzer.isCryDetected
    }

    var body: some View {
        VStack(spacing: 4) {
            Spacer()

            // Animated indicator
            ZStack {
                // Breathing ring
                PulsingRing(color: ringColor)
                    .frame(width: 44, height: 44)

                // Sound level arc
                Circle()
                    .trim(from: 0, to: CGFloat(captureManager.soundAnalyzer.currentLevel))
                    .stroke(ringColor, lineWidth: 2.5)
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.08), value: captureManager.soundAnalyzer.currentLevel)

                // Icon
                ZStack {
                    Circle()
                        .fill(ringColor.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: isAlert ? "exclamationmark.triangle.fill" : "mic.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ringColor)
                        .contentTransition(.symbolEffect(.replace))
                }
            }

            // Status
            VStack(spacing: 1) {
                Group {
                    if captureManager.cryClassifier.isCrying {
                        Text("Baby Crying!")
                            .foregroundStyle(BabymonTheme.warmPink)
                    } else if captureManager.soundAnalyzer.isCryDetected {
                        Text("Sound Detected!")
                            .foregroundStyle(BabymonTheme.warmPink)
                    } else {
                        Text(captureManager.cryClassifier.dominantSound)
                            .foregroundStyle(.white)
                    }
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())

                Text(formattedTime)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }

            // Level bar
            WatchSoundLevelBar(level: captureManager.soundAnalyzer.currentLevel)
                .frame(height: 5)
                .padding(.horizontal, 24)
                .padding(.top, 2)

            Spacer()

            // Stop
            Button { stop() } label: {
                HStack(spacing: 3) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 9))
                    Text("Stop")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 10).fill(BabymonTheme.warmPink.opacity(0.8)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
        .onAppear {
            startExtendedSession()
            captureManager.onAudioReady = { data in connectivity.sendStreamData(data) }
            captureManager.cryClassifier.onCryDetected = {
                connectivity.sendCryAlert()
                WKInterfaceDevice.current().play(.notification)
            }
            captureManager.soundAnalyzer.onCryDetected = {
                if !captureManager.cryClassifier.isCrying {
                    connectivity.sendCryAlert()
                    WKInterfaceDevice.current().play(.notification)
                }
            }
            captureManager.startCapture()
            startTimer()
        }
        .onDisappear { stop() }
    }

    private var ringColor: Color {
        isAlert ? BabymonTheme.warmPink : BabymonTheme.softGreen
    }

    private var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in elapsedSeconds += 1 }
    }

    private func stop() {
        timer?.invalidate()
        captureManager.stopCapture()
        extendedSession?.invalidate()
        extendedSession = nil
        withAnimation { connectivity.currentMode = nil }
    }

    private func startExtendedSession() {
        let session = WKExtendedRuntimeSession()
        session.start()
        extendedSession = session
    }
}

struct WatchSoundLevelBar: View {
    let level: Float

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(barColor)
                    .frame(width: max(geo.size.width * CGFloat(level), 2))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
    }

    private var barColor: Color {
        if level > 0.7 { return BabymonTheme.warmPink }
        if level > 0.4 { return BabymonTheme.warmOrange }
        return BabymonTheme.softGreen
    }
}
