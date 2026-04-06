import SwiftUI

struct WatchModeSelectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                connectionStatus

                Button {
                    connectivity.currentMode = .phoneSource
                    connectivity.sendModeSelection(.phoneSource)
                } label: {
                    Label("Watch Baby", systemImage: "video.fill")
                }
                .disabled(!connectivity.isReachable)

                Button {
                    connectivity.currentMode = .watchSource
                    connectivity.sendModeSelection(.watchSource)
                } label: {
                    Label("Send Audio", systemImage: "mic.fill")
                }
                .disabled(!connectivity.isReachable)
            }
        }
        .navigationTitle("Babymon")
    }

    private var connectionStatus: some View {
        HStack {
            Circle()
                .fill(connectivity.isReachable ? .green : .red)
                .frame(width: 8, height: 8)
            Text(connectivity.isReachable ? "Connected" : "Not Connected")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
