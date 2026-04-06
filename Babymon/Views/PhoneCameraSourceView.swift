import SwiftUI
import AVFoundation

struct PhoneCameraSourceView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var captureManager = CameraCaptureManager()
    @State private var permissionGranted = false

    var body: some View {
        VStack {
            if permissionGranted {
                CameraPreviewView(session: captureManager.session)
                    .ignoresSafeArea()
                    .overlay(alignment: .top) {
                        Text("Streaming to Watch")
                            .font(.caption)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(.top, 8)
                    }
            } else {
                ContentUnavailableView(
                    "Camera Access Required",
                    systemImage: "camera.fill",
                    description: Text("Open Settings to grant camera and microphone access.")
                )
            }

            Button("Stop") {
                captureManager.stopCapture()
                connectivity.currentMode = nil
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding()
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
            }
        }
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
