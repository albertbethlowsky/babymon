import SwiftUI
import SwiftData

@main
struct BabymonApp: App {
    @StateObject private var connectivity = ConnectivityManager.shared
    @StateObject private var theme = ThemeManager()

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
                .environmentObject(theme)
        }
        .modelContainer(for: [SleepSession.self, WakeEvent.self])
    }
}
