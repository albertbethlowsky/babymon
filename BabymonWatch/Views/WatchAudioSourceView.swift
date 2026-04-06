import SwiftUI
import WatchKit

struct WatchAudioSourceView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var captureManager = WatchAudioCaptureManager()
    @State private var isActive = false
    @State private var extendedSession: WKExtendedRuntimeSession?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
                .symbolEffect(.pulse, isActive: isActive)

            Text("Sending Audio")
                .font(.headline)

            Button("Stop", role: .destructive) {
                stop()
            }
        }
        .onAppear {
            startExtendedSession()
            captureManager.onAudioReady = { data in
                connectivity.sendStreamData(data)
            }
            captureManager.startCapture()
            isActive = true
        }
        .onDisappear {
            stop()
        }
    }

    private func stop() {
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
