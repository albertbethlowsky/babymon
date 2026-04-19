import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var connectivity: ConnectivityManager

    var body: some View {
        Group {
            switch connectivity.currentMode {
            case .none:
                WatchModeSelectionView()
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .phoneSource:
                WatchVideoReceiverView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .watchSource:
                WatchAudioSourceView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.15), value: connectivity.currentMode == nil)
    }
}
