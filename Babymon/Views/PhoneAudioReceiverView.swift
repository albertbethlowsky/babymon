import SwiftUI

struct PhoneAudioReceiverView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var audioPlayer = AudioPlayerManager()
    @State private var isActive = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "ear.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
                .symbolEffect(.pulse, isActive: isActive)

            Text("Listening to Watch")
                .font(.title2)

            Text("Audio from Apple Watch microphone")
                .foregroundStyle(.secondary)

            Spacer()

            Button("Stop") {
                audioPlayer.stop()
                connectivity.currentMode = nil
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding()
        }
        .onAppear {
            audioPlayer.setup()
            connectivity.onAudioDataReceived = { data in
                audioPlayer.playAudioData(data)
            }
            isActive = true
        }
        .onDisappear {
            audioPlayer.stop()
            connectivity.onAudioDataReceived = nil
            isActive = false
        }
    }
}
