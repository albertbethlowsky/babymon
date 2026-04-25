import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            BabymonTheme.backgroundGradient
                .ignoresSafeArea()

            Group {
                switch connectivity.currentMode {
                case .none:
                    ModeSelectionView()
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                case .phoneSource:
                    PhoneCameraSourceView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                case .watchSource:
                    PhoneAudioReceiverView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35, bounce: 0.15), value: connectivity.currentMode == nil)
        }
        .preferredColorScheme(theme.colorScheme)
    }
}
