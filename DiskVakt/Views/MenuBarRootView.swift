import AppKit
import SwiftUI

struct MenuBarRootView: View {
    @ObservedObject var monitor: DiskMonitor
    @ObservedObject var windows: WindowCoordinator
    @AppStorage(SettingsKey.appMode) private var modeRaw = AppMode.standard.rawValue

    private var mode: AppMode { AppMode(rawValue: modeRaw) ?? .standard }

    var body: some View {
        if mode == .standard {
            StandardMenuView(monitor: monitor)
        } else {
            AdvancedMenuView(monitor: monitor)
        }
        Divider()
        if mode == .advanced {
            Button("Kontrollera nu") { monitor.checkAll() }
        }
        Button("Inställningar…") { windows.showSettings(monitor: monitor) }
        Divider()
        Button("Om DiskVakt…") { windows.showAbout(monitor: monitor) }
        Button("Avsluta DiskVakt") { NSApp.terminate(nil) }
    }
}

private struct StandardMenuView: View {
    @ObservedObject var monitor: DiskMonitor

    var body: some View {
        Label(statusTitle, systemImage: statusSymbol)
        if let statusSummary {
            Text(statusSummary)
        }
    }

    private var statusTitle: LocalizedStringKey {
        switch monitor.health.level {
        case .ok: "Systemdisken är OK"
        case .attention, .critical: "Åtgärd krävs"
        case .unknown: "Status okänd"
        }
    }

    private var statusSummary: LocalizedStringKey? {
        switch monitor.health.level {
        case .ok: nil
        case .attention, .critical: "DiskVakt har upptäckt något som behöver åtgärdas"
        case .unknown: "DiskVakt har ännu inte kunnat slutföra en kontroll"
        }
    }

    private var statusSymbol: String {
        switch monitor.health.level {
        case .ok: "checkmark.circle.fill"
        case .attention: "exclamationmark.triangle.fill"
        case .critical: "exclamationmark.octagon.fill"
        case .unknown: "questionmark.circle"
        }
    }
}

#if DEBUG
#Preview("Simple Menu – OK") {
    let defaults = UserDefaults.diskVaktPreview(named: "menu-ok", mode: .standard)
    StandardMenuView(monitor: .preview(level: .ok, defaults: defaults))
        .padding(16)
        .frame(width: 360, alignment: .leading)
        .defaultAppStorage(defaults)
}

#Preview("Simple Menu – Warning") {
    let defaults = UserDefaults.diskVaktPreview(named: "menu-warning", mode: .standard)
    StandardMenuView(
        monitor: .preview(level: .attention, systemAvailableGB: 90, defaults: defaults)
    )
    .padding(16)
    .frame(width: 360, alignment: .leading)
    .defaultAppStorage(defaults)
}

#Preview("Simple Menu – Critical") {
    let defaults = UserDefaults.diskVaktPreview(named: "menu-critical", mode: .standard)
    StandardMenuView(
        monitor: .preview(level: .critical, systemAvailableGB: 40, defaults: defaults)
    )
    .padding(16)
    .frame(width: 360, alignment: .leading)
    .defaultAppStorage(defaults)
}

#Preview("Simple Menu – Unknown") {
    let defaults = UserDefaults.diskVaktPreview(named: "menu-unknown", mode: .standard)
    StandardMenuView(monitor: .preview(level: .unknown, defaults: defaults))
        .padding(16)
        .frame(width: 360, alignment: .leading)
        .defaultAppStorage(defaults)
}

#Preview("Advanced Menu") {
    let defaults = UserDefaults.diskVaktPreview(named: "menu-advanced", mode: .advanced)
    AdvancedMenuView(monitor: .preview(defaults: defaults))
        .padding(16)
        .frame(width: 420, alignment: .leading)
        .defaultAppStorage(defaults)
}
#endif

private struct AdvancedMenuView: View {
    @ObservedObject var monitor: DiskMonitor

    var body: some View {
        if let system = monitor.systemVolume {
            volumeMenu(system)
        }
        ForEach(monitor.otherVolumes) { volume in
            volumeMenu(volume)
        }
        if let checkedAt = monitor.health.checkedAt {
            Divider()
            Text("Senaste lyckade kontroll: \(checkedAt.formatted(date: .omitted, time: .shortened))")
        }
    }

    private func volumeMenu(_ volume: VolumeSnapshot) -> some View {
        Menu("\(volume.name): \(StorageCapacityFormatter.string(fromByteCount: volume.availableBytes)) ledigt") {
            Text(capacitySummary(for: volume))
            Button("Öppna \(volume.name) i Finder") {
                monitor.openInFinder(volume)
            }
            if !volume.isSystem {
                Button(monitor.isMonitored(volume) ? "Ignorera varningar" : "Aktivera varningar") {
                    monitor.setMonitored(!monitor.isMonitored(volume), volume: volume)
                }
            }
        }
    }

    private func capacitySummary(for volume: VolumeSnapshot) -> String {
        String.localizedStringWithFormat(
            String(localized: "%d %% ledigt av %@"),
            volume.freePercent,
            StorageCapacityFormatter.string(fromByteCount: volume.totalBytes)
        )
    }
}
