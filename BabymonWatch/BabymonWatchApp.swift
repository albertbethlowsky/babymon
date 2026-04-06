import SwiftUI

@main
struct BabymonWatchApp: App {
    @StateObject private var connectivity = ConnectivityManager.shared

    init() {
        ConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(connectivity)
        }
    }
}
