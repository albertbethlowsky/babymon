import SwiftUI
import UserNotifications

struct PhoneAudioReceiverView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var audioPlayer = AudioPlayerManager()
    @StateObject private var soundAnalyzer = SoundLevelAnalyzer()
    @State private var appeared = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var showCryAlert = false
    @State private var notificationsGranted = false
    @State private var showNotificationPrompt = true

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        stop()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }

                    Spacer()

                    LiveBadge()

                    Spacer()

                    Text(formattedTime)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Circular audio visualizer
                ZStack {
                    // Outer ring — sound level
                    CircularSoundVisualizer(
                        level: soundAnalyzer.currentLevel,
                        isAlert: showCryAlert
                    )
                    .frame(width: 220, height: 220)

                    // Center content
                    VStack(spacing: 6) {
                        Image(systemName: showCryAlert ? "exclamationmark.triangle.fill" : "waveform")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(showCryAlert ? BabymonTheme.warmPink : BabymonTheme.softGreen)
                            .contentTransition(.symbolEffect(.replace))

                        Text(showCryAlert ? "Sound\nDetected" : "All\nQuiet")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)

                // Sound level meter
                VStack(spacing: 8) {
                    HStack {
                        Text("Sound Level")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        Text(soundLevelText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(soundLevelColor)
                    }

                    SoundMeter(level: soundAnalyzer.currentLevel)
                        .frame(height: 6)
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)

                // Source info card
                HStack(spacing: 12) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 18))
                        .foregroundStyle(BabymonTheme.accent)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(BabymonTheme.accent.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Watch Microphone")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Streaming audio in real-time")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    Circle()
                        .fill(BabymonTheme.softGreen)
                        .frame(width: 8, height: 8)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(BabymonTheme.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.05), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)

                // Notification info card
                if showNotificationPrompt && !notificationsGranted {
                    notificationCard
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Confirmed notification status
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(BabymonTheme.softGreen)
                        Text("Notifications enabled — alerts will sound even when locked")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }

                // Stop button
                StopButton {
                    stop()
                }
                .padding(.top, 32)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            checkNotificationStatus()
            NotificationManager.shared.requestPermission()

            if !connectivity.isDemoMode {
                audioPlayer.setup()
                connectivity.onAudioDataReceived = { data in
                    audioPlayer.playAudioData(data)
                    soundAnalyzer.analyze(int16Data: data)
                }
            } else {
                // Demo: simulate some sound activity
                simulateDemoAudio()
            }

            connectivity.onCryAlertReceived = {
                triggerCryAlert()
            }
            soundAnalyzer.onCryDetected = {
                triggerCryAlert()
            }

            startTimer()
            withAnimation(.spring(duration: 0.7, bounce: 0.3)) {
                appeared = true
            }
        }
        .onDisappear {
            stop()
        }
    }

    // MARK: - Notification Card

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(BabymonTheme.warmOrange)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(BabymonTheme.warmOrange.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Notifications")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Get alerted when we detect sound, even when your phone is locked.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                NotificationManager.shared.requestPermission()
                withAnimation {
                    notificationsGranted = true
                    showNotificationPrompt = false
                }
            } label: {
                Text("Allow Notifications")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(BabymonTheme.warmOrange)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BabymonTheme.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(BabymonTheme.warmOrange.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private var soundLevelText: String {
        if soundAnalyzer.currentLevel > 0.7 { return "Loud" }
        if soundAnalyzer.currentLevel > 0.35 { return "Moderate" }
        if soundAnalyzer.currentLevel > 0.1 { return "Soft" }
        return "Silent"
    }

    private var soundLevelColor: Color {
        if soundAnalyzer.currentLevel > 0.7 { return BabymonTheme.warmPink }
        if soundAnalyzer.currentLevel > 0.35 { return BabymonTheme.warmOrange }
        return BabymonTheme.softGreen
    }

    private var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsGranted = settings.authorizationStatus == .authorized
                showNotificationPrompt = !notificationsGranted
            }
        }
    }

    private func triggerCryAlert() {
        DispatchQueue.main.async {
            withAnimation { showCryAlert = true }
            NotificationManager.shared.sendCryAlert()
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { showCryAlert = false }
            }
        }
    }

    private func simulateDemoAudio() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            let fakeLevel = Float.random(in: 0.02...0.25)
            DispatchQueue.main.async {
                soundAnalyzer.currentLevel = fakeLevel
            }
        }
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
        connectivity.onCryAlertReceived = nil
        connectivity.currentMode = nil
    }
}

// MARK: - Circular Sound Visualizer

struct CircularSoundVisualizer: View {
    let level: Float
    let isAlert: Bool

    private let barCount = 48

    var body: some View {
        ZStack {
            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 90
                    )
                )

            // Bars drawn via Canvas
            Canvas { context, size in
                drawBars(context: context, size: size)
            }
        }
        .animation(.easeOut(duration: 0.1), value: level)
    }

    private var glowColor: Color {
        isAlert ? BabymonTheme.warmPink : BabymonTheme.softGreen
    }

    private func drawBars(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2.0
        let innerR = radius * 0.72
        let maxExtension = radius - innerR

        for i in 0..<barCount {
            let angle = (Double(i) / Double(barCount)) * 2.0 * .pi - .pi / 2.0
            let barLevel = barHeight(for: i)
            let outerR = innerR + maxExtension * CGFloat(barLevel)

            let cosA = cos(angle)
            let sinA = sin(angle)
            let innerPoint = CGPoint(x: center.x + innerR * cosA, y: center.y + innerR * sinA)
            let outerPoint = CGPoint(x: center.x + outerR * cosA, y: center.y + outerR * sinA)

            var path = Path()
            path.move(to: innerPoint)
            path.addLine(to: outerPoint)

            let opacity = 0.3 + Double(barLevel) * 0.7
            context.stroke(path, with: .color(barColor.opacity(opacity)), lineWidth: 3)
        }
    }

    private var barColor: Color {
        isAlert ? BabymonTheme.warmPink : BabymonTheme.softGreen
    }

    private func barHeight(for index: Int) -> Float {
        let variation = Float(sin(Double(index) * 0.8) * 0.3 + 0.7)
        let noise = Float(sin(Double(index) * 2.3 + Double(level) * 10) * 0.2 + 0.8)
        return min(max(level * variation * noise * 1.5, 0.05), 1.0)
    }
}

// MARK: - Sound Meter

struct SoundMeter: View {
    let level: Float

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.06))

                RoundedRectangle(cornerRadius: 4)
                    .fill(barGradient)
                    .frame(width: max(geo.size.width * CGFloat(level), 2))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [BabymonTheme.softGreen, BabymonTheme.warmOrange, BabymonTheme.warmPink],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
