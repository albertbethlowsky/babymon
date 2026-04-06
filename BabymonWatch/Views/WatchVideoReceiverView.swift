import SwiftUI
import WatchKit

struct WatchVideoReceiverView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var audioPlayer = WatchAudioPlayerManager()
    @State private var currentFrame: UIImage?
    @State private var extendedSession: WKExtendedRuntimeSession?
    @State private var showControls = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let frame = currentFrame {
                // Video frame fills the screen
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                // Tap overlay for controls
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showControls.toggle()
                        }
                    }

                // Controls overlay
                if showControls {
                    VStack {
                        // Top: LIVE badge
                        HStack {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 5, height: 5)
                                Text("LIVE")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(.red.opacity(0.7)))

                            Spacer()
                        }
                        .padding(.top, 2)
                        .padding(.horizontal, 8)

                        Spacer()

                        // Bottom: Stop
                        Button {
                            stop()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.8))
                                .background(Circle().fill(.black.opacity(0.5)).padding(-2))
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 4)
                    }
                    .transition(.opacity)
                }
            } else {
                // Waiting state
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(BabymonTheme.accent)
                    Text("Connecting...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .onAppear {
            startExtendedSession()
            audioPlayer.setup()
            showControls = true

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

            // Auto-hide controls
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { showControls = false }
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
