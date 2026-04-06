import SwiftUI
import WatchKit

struct WatchAudioSourceView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var captureManager = WatchAudioCaptureManager()
    @State private var isActive = false
    @State private var extendedSession: WKExtendedRuntimeSession?
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.5

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            // Animated mic indicator
            ZStack {
                // Pulsing ring
                Circle()
                    .stroke(BabymonTheme.softGreen.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 50, height: 50)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

                // Icon
                ZStack {
                    Circle()
                        .fill(BabymonTheme.softGreen.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(BabymonTheme.softGreen)
                }
            }

            // Status
            VStack(spacing: 3) {
                Text("Sending Audio")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(formattedTime)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
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
            captureManager.startCapture()
            isActive = true
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
        isActive = false
    }

    private func startExtendedSession() {
        let session = WKExtendedRuntimeSession()
        session.start()
        extendedSession = session
    }
}
