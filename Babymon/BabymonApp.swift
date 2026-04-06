import SwiftUI

@main
struct BabymonApp: App {
    @StateObject private var connectivity = ConnectivityManager.shared

    init() {
        ConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivity)
        }
    }
}
