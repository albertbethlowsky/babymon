import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var connectivity: ConnectivityManager

    var body: some View {
        Group {
            switch connectivity.currentMode {
            case .none:
                WatchModeSelectionView()
            case .phoneSource:
                WatchVideoReceiverView()
            case .watchSource:
                WatchAudioSourceView()
            }
        }
    }
}
