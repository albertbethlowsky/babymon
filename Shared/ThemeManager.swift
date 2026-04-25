import SwiftUI

enum AppearanceOption: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone.gen3"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    @AppStorage("babymon.appearance") private var stored: String = AppearanceOption.dark.rawValue

    var appearance: AppearanceOption {
        get { AppearanceOption(rawValue: stored) ?? .dark }
        set {
            stored = newValue.rawValue
            objectWillChange.send()
        }
    }

    var colorScheme: ColorScheme? { appearance.colorScheme }
}
