import SwiftUI

@main
struct BabymonApp: App {
    @StateObject private var connectivity = ConnectivityManager.shared

    init() {
        ConnectivityManager.shared.activate()
        #if targetEnvironment(simulator)
        ConnectivityManager.shared.enableDemoMode()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivity)
        }
    }
}
