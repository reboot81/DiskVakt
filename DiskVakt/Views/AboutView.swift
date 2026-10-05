import SwiftUI

struct AboutView: View {
    @ObservedObject var monitor: DiskMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                RetroAppIcon(size: 80)
                VStack(alignment: .leading) {
                    Text("DiskVakt").font(.largeTitle.bold())
                    Text("Version \(version) (\(build))")
                        .foregroundStyle(.secondary)
                }
            }
            Text("DiskVakt har som uppgift att informera dig när systemdisken börjar få ont om utrymme, eller när det kan finnas problem av allvarligare karaktär. \nAvancerat läge visar detaljer och tekniska inställningar.")
            GroupBox("Integritet") {
                Text("DiskVakt analyserar inte filinnehåll och raderar aldrig filer. När ntfy används skickas varningstext, valt enhetsnamn och tekniska eventtaggar. Lokal IP-adress och maskinvaru-ID inkluderas inte i meddelandet.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            GroupBox("Övervakade resurser") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Systemdisk: ledigt utrymme")
                    Text("• Termisk status: macOS sammanvägda nivå normal, förhöjd, allvarlig eller kritisk. Inga temperaturer i °C läses.")
                    Text("• SMART: macOS övergripande diskstatus en gång per dygn. Endast uttryckligt diskfel varnas; otillgänglig data ignoreras.")
                    ForEach(monitor.otherVolumes) { volume in
                        Text(volumeSummary(volume))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            GroupBox("Relevanta filer") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String.localizedStringWithFormat(String(localized: "App: %@"), Bundle.main.bundlePath))
                    Text(String.localizedStringWithFormat(String(localized: "Programfil: %@"), Bundle.main.executablePath ?? "–"))
                    Text(String.localizedStringWithFormat(String(localized: "Start vid inloggning: hanteras av macOS (%@)"), monitor.launchAtLogin.statusText))
                    Text(String.localizedStringWithFormat(String(localized: "Inställningar: %@"), preferencesPath))
                }
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            GroupBox("Teknisk status") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bundle-ID: \(Bundle.main.bundleIdentifier ?? "–")")
                    Text("App: \(Bundle.main.bundlePath)")
                    Text("Senaste kontroll: \(monitor.health.checkedAt?.formatted() ?? "–")")
                }
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
        .padding(24)
        .frame(width: 760, height: 700)
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
    }

    private var preferencesPath: String {
        let identifier = Bundle.main.bundleIdentifier ?? "com.bosaurage.diskvakt.next"
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        return library?
            .appendingPathComponent("Preferences", isDirectory: true)
            .appendingPathComponent("\(identifier).plist")
            .path ?? "–"
    }

    private func volumeSummary(_ volume: VolumeSnapshot) -> String {
        let notificationSuffix = monitor.isMonitored(volume)
            ? ""
            : String(localized: ", notiser av")
        return String.localizedStringWithFormat(
            String(localized: "• %@: %d %% använt%@"),
            volume.name,
            volume.usedPercent,
            notificationSuffix
        )
    }
}

#if DEBUG
#Preview("About DiskVakt") {
    let defaults = UserDefaults.diskVaktPreview(named: "about", mode: .standard)
    AboutView(monitor: .preview(defaults: defaults))
        .defaultAppStorage(defaults)
        .environment(\.locale, Locale(identifier: "sv"))
}
#endif
