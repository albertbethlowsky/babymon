import SwiftUI
import AVFoundation

struct PhoneCameraSourceView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var captureManager = CameraCaptureManager()
    @State private var permissionGranted = false
    @State private var appeared = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?

    private var isDemo: Bool { connectivity.isDemoMode }

    var body: some View {
        ZStack {
            if permissionGranted || isDemo {
                // Full-screen camera preview (or mock in demo)
                Group {
                    if isDemo {
                        MockCameraView()
                    } else {
                        CameraPreviewView(session: captureManager.session)
                    }
                }
                .ignoresSafeArea()

                // Top overlay
                VStack {
                    HStack {
                        LiveBadge()
                        Spacer()
                        Text(formattedTime)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.black.opacity(0.4)))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    HStack(spacing: 6) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 12))
                        Text(isDemo ? "Demo Mode — Streaming to Watch" : "Streaming to Apple Watch")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.black.opacity(0.4)))
                    .padding(.top, 8)

                    Spacer()

                    // Bottom controls
                    StopButton {
                        stop()
                    }
                    .padding(.bottom, 40)
                }
                .opacity(appeared ? 1 : 0)

            } else {
                // Permission denied state
                VStack(spacing: 20) {
                    GlowingIcon(systemName: "camera.fill", color: BabymonTheme.warmPink, size: 60)

                    Text("Camera Access Required")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Babymon needs camera and microphone\naccess to monitor your baby.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 200, height: 50)
                            .background(Capsule().fill(BabymonTheme.accentGradient))
                    }
                    .padding(.top, 8)

                    Button("Go Back") {
                        connectivity.currentMode = nil
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 4)
                }
            }
        }
        .task {
            if isDemo {
                // Skip permissions in demo mode
                startTimer()
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
                return
            }
            await requestPermissions()
            if permissionGranted {
                captureManager.onFrameReady = { data in
                    connectivity.sendStreamData(data)
                }
                captureManager.onAudioReady = { data in
                    connectivity.sendStreamData(data)
                }
                captureManager.startCapture()
                startTimer()
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
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
        connectivity.currentMode = nil
    }

    private func requestPermissions() async {
        let videoGranted = await AVCaptureDevice.requestAccess(for: .video)
        let audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            permissionGranted = videoGranted && audioGranted
        }
    }
}

// MARK: - Mock Camera for Simulator

struct MockCameraView: View {
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        ZStack {
            // Simulated dark room / nursery background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.14),
                    Color(red: 0.12, green: 0.10, blue: 0.18),
                    Color(red: 0.06, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Simulated night-vision scene elements
            VStack(spacing: 0) {
                Spacer()

                // Crib outline
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.08), lineWidth: 1.5)
                        .frame(width: 220, height: 140)

                    // Baby silhouette
                    Image(systemName: "figure.child")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.12))

                    // Night vision scanline effect
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .green.opacity(0.03), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 60)
                        .offset(y: shimmerOffset * 70)
                }

                Spacer()
            }

            // Subtle noise overlay
            Rectangle()
                .fill(.white.opacity(0.015))

            // Corner timestamp (like a real camera)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("CAM 1")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.2))
                        .padding(12)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                shimmerOffset = 1
            }
        }
    }
}

// MARK: - Real Camera Preview

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

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
