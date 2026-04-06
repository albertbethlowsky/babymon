import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @State private var appeared = false

    var body: some View {
        ZStack {
            BabymonTheme.backgroundGradient
                .ignoresSafeArea()

            Group {
                switch connectivity.currentMode {
                case .none:
                    ModeSelectionView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 1.05))
                        ))
                case .phoneSource:
                    PhoneCameraSourceView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                case .watchSource:
                    PhoneAudioReceiverView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.5, bounce: 0.2), value: connectivity.currentMode == nil)
        }
        .preferredColorScheme(.dark)
    }
}
