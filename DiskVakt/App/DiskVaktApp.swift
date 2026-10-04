import SwiftUI

@main
struct DiskVaktApp: App {
    @StateObject private var monitor: DiskMonitor
    @StateObject private var windows: WindowCoordinator

    init() {
        let monitor = DiskMonitor()
        let windows = WindowCoordinator()
        _monitor = StateObject(wrappedValue: monitor)
        _windows = StateObject(wrappedValue: windows)

        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            Task { @MainActor in
                await Task.yield()
                windows.showOnboardingIfNeeded(monitor: monitor)
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(monitor: monitor, windows: windows)
        } label: {
            Image(systemName: "internaldrive")
                .accessibilityLabel("DiskVakt")
        }
        .menuBarExtraStyle(.menu)
    }
}
