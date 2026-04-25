import SwiftUI
import AVFoundation

struct PhoneCameraSourceView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var captureManager = CameraCaptureManager()
    @State private var permissionGranted = false
    @State private var appeared = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var showControls = true
    @State private var controlsTimer: Timer?

    private var isDemo: Bool { connectivity.isDemoMode }

    var body: some View {
        ZStack {
            if permissionGranted || isDemo {
                // Full-screen camera
                Group {
                    if isDemo {
                        MockCameraView()
                    } else {
                        CameraPreviewView(session: captureManager.session)
                    }
                }
                .ignoresSafeArea()
                .onTapGesture { toggleControls() }

                // Overlays
                if showControls {
                    VStack(spacing: 0) {
                        // Top bar
                        HStack(alignment: .center) {
                            LiveBadge()
                            Spacer()
                            // Status pill
                            HStack(spacing: 5) {
                                Image(systemName: "applewatch")
                                    .font(.system(size: 11))
                                Text(isDemo ? "Demo" : "Streaming")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.black.opacity(0.35)))

                            Spacer()

                            Text(formattedTime)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(.black.opacity(0.35)))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 56)

                        Spacer()

                        // Bottom controls
                        HStack(spacing: 20) {
                            CameraControlButton(
                                icon: captureManager.isNightMode ? "moon.fill" : "moon",
                                label: "Night",
                                isActive: captureManager.isNightMode,
                                activeColor: BabymonTheme.softGreen
                            ) {
                                captureManager.toggleNightMode()
                            }

                            // Stop (larger)
                            Button { stop() } label: {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Circle().fill(BabymonTheme.warmPink))
                            }

                            CameraControlButton(
                                icon: captureManager.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill",
                                label: "Light",
                                isActive: captureManager.isTorchOn,
                                activeColor: BabymonTheme.warmOrange
                            ) {
                                captureManager.setTorch(on: !captureManager.isTorchOn, level: 0.3)
                            }
                        }
                        .padding(.bottom, 36)
                    }
                    .transition(.opacity)
                }
            } else {
                // Permission denied
                VStack(spacing: 16) {
                    GlowingIcon(systemName: "camera.fill", color: BabymonTheme.warmPink, size: 56)

                    Text("Camera Access Required")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Babymon needs camera and microphone\naccess to monitor your baby.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: 220, minHeight: 46)
                            .background(Capsule().fill(BabymonTheme.accentGradient))
                    }
                    .padding(.top, 4)

                    Button("Go Back") {
                        withAnimation { connectivity.currentMode = nil }
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .task {
            if isDemo {
                startTimer()
                scheduleControlsHide()
                withAnimation(.easeOut(duration: 0.4)) { appeared = true }
                return
            }
            await requestPermissions()
            if permissionGranted {
                captureManager.onFrameReady = { data in connectivity.sendStreamData(data) }
                captureManager.onAudioReady = { data in connectivity.sendStreamData(data) }
                captureManager.startCapture()
                startTimer()
                scheduleControlsHide()
                withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            }
        }
    }

    // MARK: - Controls

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
        if showControls { scheduleControlsHide() }
    }

    private func scheduleControlsHide() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) { showControls = false }
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
        controlsTimer?.invalidate()
        captureManager.stopCapture()
        withAnimation { connectivity.currentMode = nil }
    }

    private func requestPermissions() async {
        let videoGranted = await AVCaptureDevice.requestAccess(for: .video)
        let audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run { permissionGranted = videoGranted && audioGranted }
    }
}

// MARK: - Camera Control Button

struct CameraControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isActive ? activeColor : .white.opacity(0.65))
            .frame(width: 52, height: 52)
            .background(
                Circle().fill(isActive ? activeColor.opacity(0.18) : .white.opacity(0.08))
            )
        }
    }
}

// MARK: - Mock Camera

struct MockCameraView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var shimmerY: CGFloat = -1

    var body: some View {
        ZStack {
            BabymonTheme.backgroundGradient

            VStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(BabymonTheme.hairline, lineWidth: 1)
                        .frame(width: 200, height: 130)
                    Image(systemName: "figure.child")
                        .font(.system(size: 44))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }

            // Scanline
            Rectangle()
                .fill(LinearGradient(colors: [.clear, scanlineTint, .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: 50)
                .offset(y: shimmerY * 200)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("CAM 1")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(10)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                shimmerY = 1
            }
        }
    }

    private var scanlineTint: Color {
        scheme == .light ? BabymonTheme.accent.opacity(0.04) : .green.opacity(0.025)
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator { var previewLayer: AVCaptureVideoPreviewLayer? }
}
