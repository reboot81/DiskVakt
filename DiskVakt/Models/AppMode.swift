import SwiftUI

enum AppMode: String, CaseIterable, Identifiable {
    case standard
    case advanced

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .standard: "Enkelt läge"
        case .advanced: "Avancerat läge"
        }
    }
}
