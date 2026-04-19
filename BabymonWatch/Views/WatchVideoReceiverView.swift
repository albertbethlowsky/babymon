import SwiftUI
import WatchKit

struct WatchVideoReceiverView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var audioPlayer = WatchAudioPlayerManager()
    @State private var currentFrame: UIImage?
    @State private var extendedSession: WKExtendedRuntimeSession?
    @State private var showControls = true
    @State private var controlsTimer: Timer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let frame = currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .onTapGesture { toggleControls() }

                if showControls {
                    VStack {
                        HStack {
                            HStack(spacing: 3) {
                                Circle().fill(.red).frame(width: 4, height: 4)
                                Text("LIVE")
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.red.opacity(0.7)))
                            Spacer()
                        }
                        .padding(.leading, 8)
                        .padding(.top, 4)

                        Spacer()

                        Button { stop() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 6)
                    }
                    .transition(.opacity)
                }
            } else {
                VStack(spacing: 6) {
                    ProgressView()
                        .tint(BabymonTheme.accent)
                    Text("Connecting...")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .onAppear {
            startExtendedSession()
            audioPlayer.setup()
            scheduleControlsHide()

            connectivity.onVideoDataReceived = { data in
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async { currentFrame = image }
                }
            }
            connectivity.onAudioDataReceived = { data in
                audioPlayer.playAudioData(data)
            }
        }
        .onDisappear { stop() }
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
        if showControls { scheduleControlsHide() }
    }

    private func scheduleControlsHide() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) { showControls = false }
        }
    }

    private func stop() {
        controlsTimer?.invalidate()
        audioPlayer.stop()
        extendedSession?.invalidate()
        extendedSession = nil
        connectivity.onVideoDataReceived = nil
        connectivity.onAudioDataReceived = nil
        withAnimation { connectivity.currentMode = nil }
    }

    private func startExtendedSession() {
        let session = WKExtendedRuntimeSession()
        session.start()
        extendedSession = session
    }
}
