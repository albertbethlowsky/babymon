import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivity: ConnectivityManager

    var body: some View {
        Group {
            switch connectivity.currentMode {
            case .none:
                ModeSelectionView()
            case .phoneSource:
                PhoneCameraSourceView()
            case .watchSource:
                PhoneAudioReceiverView()
            }
        }
    }
}
