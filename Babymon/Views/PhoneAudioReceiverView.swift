import SwiftUI
import UserNotifications

struct PhoneAudioReceiverView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var audioPlayer = AudioPlayerManager()
    @StateObject private var soundAnalyzer = SoundLevelAnalyzer()
    @State private var detectedSound: String = "All Quiet"
    @State private var appeared = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var showCryAlert = false
    @State private var notificationsGranted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { stop() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(.white.opacity(0.07)))
                    }

                    Spacer()
                    LiveBadge()
                    Spacer()

                    Text(formattedTime)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                        .fixedSize()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)

                // Circular visualizer
                ZStack {
                    CircularSoundVisualizer(
                        level: soundAnalyzer.currentLevel,
                        isAlert: showCryAlert
                    )
                    .frame(width: 200, height: 200)

                    VStack(spacing: 4) {
                        Image(systemName: showCryAlert ? "exclamationmark.triangle.fill" : "waveform")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(showCryAlert ? BabymonTheme.warmPink : BabymonTheme.softGreen)
                            .contentTransition(.symbolEffect(.replace))

                        Text(showCryAlert ? "Baby\nCrying" : detectedSound)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .contentTransition(.numericText())
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)

                // Sound level
                VStack(spacing: 6) {
                    HStack {
                        Text("Sound Level")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                        Spacer()
                        Text(soundLevelText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(soundLevelColor)
                            .contentTransition(.numericText())
                    }
                    SoundMeter(level: soundAnalyzer.currentLevel)
                        .frame(height: 5)
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)

                // Source card
                HStack(spacing: 11) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 16))
                        .foregroundStyle(BabymonTheme.accent)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 10).fill(BabymonTheme.accent.opacity(0.1)))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Apple Watch Microphone")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Streaming audio in real-time")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    Spacer()
                    Circle()
                        .fill(BabymonTheme.softGreen)
                        .frame(width: 7, height: 7)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(BabymonTheme.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.04), lineWidth: 1))
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .opacity(appeared ? 1 : 0)

                // Notification info
                if !notificationsGranted {
                    notificationCard
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(BabymonTheme.softGreen)
                        Text("Alerts enabled when phone is locked")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(.top, 16)
                }

                // Stop
                StopButton { stop() }
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
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
                simulateDemoAudio()
            }

            connectivity.onCryAlertReceived = { triggerCryAlert() }
            soundAnalyzer.onCryDetected = { triggerCryAlert() }

            startTimer()
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) { appeared = true }
        }
        .onDisappear { stop() }
    }

    // MARK: - Notification Card

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(BabymonTheme.warmOrange)
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 9).fill(BabymonTheme.warmOrange.opacity(0.1)))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Enable Notifications")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Get alerted even when your phone is locked.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }

            Button {
                NotificationManager.shared.requestPermission()
                withAnimation(.spring(duration: 0.3)) { notificationsGranted = true }
            } label: {
                Text("Allow Notifications")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(BabymonTheme.warmOrange))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(BabymonTheme.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(BabymonTheme.warmOrange.opacity(0.1), lineWidth: 1))
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
            }
        }
    }

    private func triggerCryAlert() {
        DispatchQueue.main.async {
            withAnimation(.spring(duration: 0.3)) {
                showCryAlert = true
                detectedSound = "Baby\nCrying"
            }
            NotificationManager.shared.sendCryAlert()
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.spring(duration: 0.3)) {
                    showCryAlert = false
                    detectedSound = "All Quiet"
                }
            }
        }
    }

    private func simulateDemoAudio() {
        Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            DispatchQueue.main.async {
                soundAnalyzer.currentLevel = Float.random(in: 0.02...0.22)
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
        audioPlayer.stop()
        connectivity.onAudioDataReceived = nil
        connectivity.onCryAlertReceived = nil
        withAnimation { connectivity.currentMode = nil }
    }
}

// MARK: - Circular Sound Visualizer

struct CircularSoundVisualizer: View {
    let level: Float
    let isAlert: Bool

    private let barCount = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(0.08), .clear],
                        center: .center, startRadius: 25, endRadius: 85
                    )
                )
            Canvas { context, size in
                drawBars(context: context, size: size)
            }
        }
        .animation(.easeOut(duration: 0.08), value: level)
    }

    private var glowColor: Color { isAlert ? BabymonTheme.warmPink : BabymonTheme.softGreen }

    private func drawBars(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2.0
        let innerR = radius * 0.72
        let maxExt = radius - innerR

        for i in 0..<barCount {
            let angle = (Double(i) / Double(barCount)) * 2.0 * .pi - .pi / 2.0
            let h = barHeight(for: i)
            let outerR = innerR + maxExt * CGFloat(h)
            let cosA = cos(angle)
            let sinA = sin(angle)

            var path = Path()
            path.move(to: CGPoint(x: center.x + innerR * cosA, y: center.y + innerR * sinA))
            path.addLine(to: CGPoint(x: center.x + outerR * cosA, y: center.y + outerR * sinA))

            let opacity = 0.25 + Double(h) * 0.75
            context.stroke(path, with: .color(barColor.opacity(opacity)), lineWidth: 2.5)
        }
    }

    private var barColor: Color { isAlert ? BabymonTheme.warmPink : BabymonTheme.softGreen }

    private func barHeight(for index: Int) -> Float {
        let v = Float(sin(Double(index) * 0.8) * 0.3 + 0.7)
        let n = Float(sin(Double(index) * 2.3 + Double(level) * 10) * 0.2 + 0.8)
        return min(max(level * v * n * 1.5, 0.04), 1.0)
    }
}

// MARK: - Sound Meter

struct SoundMeter: View {
    let level: Float

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.05))
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(
                        colors: [BabymonTheme.softGreen, BabymonTheme.warmOrange, BabymonTheme.warmPink],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: max(geo.size.width * CGFloat(level), 2))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
    }
}
