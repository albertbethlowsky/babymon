import SwiftUI
import WatchKit

struct WatchVideoReceiverView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var audioPlayer = WatchAudioPlayerManager()
    @State private var currentFrame: UIImage?
    @State private var extendedSession: WKExtendedRuntimeSession?

    var body: some View {
        VStack {
            if let frame = currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView("Waiting for video...")
            }

            Button("Stop", role: .destructive) {
                stop()
            }
            .font(.caption)
        }
        .onAppear {
            startExtendedSession()
            audioPlayer.setup()

            connectivity.onVideoDataReceived = { data in
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        currentFrame = image
                    }
                }
            }
            connectivity.onAudioDataReceived = { data in
                audioPlayer.playAudioData(data)
            }
        }
        .onDisappear {
            stop()
        }
    }

    private func stop() {
        audioPlayer.stop()
        extendedSession?.invalidate()
        extendedSession = nil
        connectivity.onVideoDataReceived = nil
        connectivity.onAudioDataReceived = nil
        connectivity.currentMode = nil
    }

    private func startExtendedSession() {
        let session = WKExtendedRuntimeSession()
        session.start()
        extendedSession = session
    }
}
