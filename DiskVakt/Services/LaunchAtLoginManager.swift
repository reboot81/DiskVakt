import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var statusText = ""
    private let isPreview: Bool

    init() {
        isPreview = false
        refresh()
    }

#if DEBUG
    init(previewEnabled: Bool) {
        isPreview = true
        isEnabled = previewEnabled
        statusText = previewEnabled ? String(localized: "På") : String(localized: "Av")
    }
#endif

    func refresh() {
        guard !isPreview else { return }
        isEnabled = SMAppService.mainApp.status == .enabled
        statusText = switch SMAppService.mainApp.status {
        case .enabled: String(localized: "På")
        case .requiresApproval: String(localized: "Kräver godkännande i Systeminställningar")
        case .notRegistered: String(localized: "Av")
        case .notFound: String(localized: "Inte tillgängligt")
        @unknown default: String(localized: "Okänd status")
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        if isPreview {
            isEnabled = enabled
            statusText = enabled ? String(localized: "På") : String(localized: "Av")
            return
        }
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
        refresh()
    }
}
