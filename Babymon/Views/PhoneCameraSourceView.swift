import SwiftUI
import AVFoundation

struct PhoneCameraSourceView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var captureManager = CameraCaptureManager()
    @State private var permissionGranted = false
    @State private var appeared = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            if permissionGranted {
                // Full-screen camera preview
                CameraPreviewView(session: captureManager.session)
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
                        Text("Streaming to Apple Watch")
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
