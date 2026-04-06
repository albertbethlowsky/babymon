import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                connectionStatus

                Button {
                    connectivity.currentMode = .phoneSource
                    connectivity.sendModeSelection(.phoneSource)
                } label: {
                    Label("Use iPhone Camera", systemImage: "video.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!connectivity.isReachable)

                Button {
                    connectivity.currentMode = .watchSource
                    connectivity.sendModeSelection(.watchSource)
                } label: {
                    Label("Listen to Watch Mic", systemImage: "ear.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!connectivity.isReachable)

                Spacer()
            }
            .padding()
            .navigationTitle("Babymon")
        }
    }

    private var connectionStatus: some View {
        HStack {
            Circle()
                .fill(connectivity.isReachable ? .green : .red)
                .frame(width: 12, height: 12)
            Text(connectivity.isReachable ? "Watch Connected" : "Watch Not Connected")
                .foregroundStyle(.secondary)
        }
    }
}
