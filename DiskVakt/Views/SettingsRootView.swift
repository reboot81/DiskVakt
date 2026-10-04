import AppKit
import SwiftUI
import UserNotifications

enum SupportLinks {
    static let ntfyGuide = URL(string: "https://docs.ntfy.sh/")!

    static func appleStorageGuide(locale: Locale) -> URL {
        let languageCode = locale.language.languageCode?.identifier.lowercased()
        let localePath = switch languageCode {
        case "sv": "sv-se"
        case "da": "da-dk"
        case "nb", "no": "no-no"
        default: "en-us"
        }
        return URL(string: "https://support.apple.com/\(localePath)/102624")!
    }
}

struct SettingsRootView: View {
    @ObservedObject var monitor: DiskMonitor
    @AppStorage(SettingsKey.appMode) private var modeRaw = AppMode.standard.rawValue
    let showAbout: () -> Void

    init(monitor: DiskMonitor, showAbout: @escaping () -> Void = {}) {
        self.monitor = monitor
        self.showAbout = showAbout
    }

    private var mode: AppMode { AppMode(rawValue: modeRaw) ?? .standard }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Picker("Visningsläge", selection: $modeRaw) {
                    ForEach(AppMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 320, alignment: .leading)

                Spacer(minLength: 0)
                Button(action: showAbout) {
                    Label("Om DiskVakt…", systemImage: "info.circle")
                }
            }

            StatusCard(monitor: monitor)
            ProtectionCard(monitor: monitor)
            NotificationPermissionNotice(monitor: monitor)

            Divider()

            if mode == .standard {
                StandardSettingsView()
            } else {
                AdvancedSettingsView(monitor: monitor)
            }
        }
        .padding(24)
        .frame(width: 680, height: 760)
        .onAppear { monitor.refreshNotificationAuthorization() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            monitor.refreshNotificationAuthorization()
        }
    }
}

private struct StatusCard: View {
    @ObservedObject var monitor: DiskMonitor
    @Environment(\.locale) private var locale

    var body: some View {
        GroupBox("Status") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: statusSymbol)
                        .font(.title2)
                        .foregroundStyle(statusColor)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(statusTitle)
                            .font(.headline)
                        Text(statusSummary)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(lastCheckText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Button("Kontrollera nu") { monitor.checkAll() }
                }
                Divider()
                Link(
                    destination: SupportLinks.appleStorageGuide(locale: locale)
                ) {
                    Label(
                        "Apples guide för att frigöra lagringsutrymme",
                        systemImage: "arrow.up.right.square"
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var lastCheckText: String {
        let value: String
        if let checkedAt = monitor.health.checkedAt {
            value = checkedAt.formatted(
                date: Calendar.current.isDateInToday(checkedAt) ? .omitted : .abbreviated,
                time: .shortened
            )
        } else {
            value = "–"
        }
        return String.localizedStringWithFormat(
            String(localized: "Senast: %@"),
            value
        )
    }

    private var statusTitle: LocalizedStringKey {
        switch monitor.health.level {
        case .ok: "Systemdisken är OK"
        case .attention, .critical: "Åtgärd krävs"
        case .unknown: "Status okänd"
        }
    }

    private var statusSummary: LocalizedStringKey {
        switch monitor.health.level {
        case .ok: "DiskVakt bevakar diskars lediga utrymme"
        case .attention, .critical: "Växla till Avancerat läge för mer information"
        case .unknown: "Klicka på Kontrollera nu och försök igen"
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

    private var statusColor: Color {
        switch monitor.health.level {
        case .ok: .green
        case .attention: .orange
        case .critical: .red
        case .unknown: .secondary
        }
    }

}

private struct ProtectionCard: View {
    @ObservedObject var monitor: DiskMonitor
    @ObservedObject private var notifications: NotificationService
    @State private var launchError = ""

    init(monitor: DiskMonitor) {
        self.monitor = monitor
        _notifications = ObservedObject(wrappedValue: monitor.notifications)
    }

    var body: some View {
        GroupBox("Skydd") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Starta DiskVakt vid inloggning")
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { monitor.launchAtLogin.isEnabled },
                            set: { enabled in
                                do { try monitor.launchAtLogin.setEnabled(enabled) }
                                catch { launchError = error.localizedDescription }
                            }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .frame(width: 44, alignment: .center)
                }
                HStack {
                    Text("Lokala notiser")
                    Spacer()
                    Text(notificationStatus)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .center)
                }
                if !launchError.isEmpty {
                    Text(launchError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var notificationStatus: LocalizedStringKey {
        switch notifications.authorizationStatus {
        case .authorized, .provisional: "På"
        case .denied: "Av"
        case .notDetermined: "Inte avgjort"
        @unknown default: "Okänd status"
        }
    }
}

private struct NotificationPermissionNotice: View {
    @ObservedObject var monitor: DiskMonitor
    @ObservedObject private var notifications: NotificationService

    init(monitor: DiskMonitor) {
        self.monitor = monitor
        _notifications = ObservedObject(wrappedValue: monitor.notifications)
    }

    @ViewBuilder
    var body: some View {
        switch notifications.authorizationStatus {
        case .denied:
            permissionRow(
                title: "Lokala notiser är avstängda",
                message: "DiskVakt kan inte varna lokalt förrän notiser aktiveras i Systeminställningar.",
                buttonTitle: "Öppna notisinställningar",
                action: { monitor.openNotificationSettings() }
            )
        case .notDetermined:
            permissionRow(
                title: "Lokala notiser är inte aktiverade",
                message: "Tillåt lokala notiser så att DiskVakt kan varna när något är fel.",
                buttonTitle: "Tillåt notiser",
                action: { monitor.requestNotificationAuthorization() }
            )
        default:
            EmptyView()
        }
    }

    private func permissionRow(
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        buttonTitle: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: action) { Text(buttonTitle) }
        }
        .padding(10)
        .background(.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct StandardSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Avancerade inställningar är fortfarande aktiva men dolda. Växla till Avancerat läge för att ändra dem.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

private enum AdvancedSettingsSection: String, CaseIterable, Identifiable {
    case systemDisk
    case disks
    case health
    case ntfy

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .systemDisk: "Systemdisk"
        case .disks: "Diskar"
        case .health: "Hälsa"
        case .ntfy: "ntfy"
        }
    }
}

private struct AdvancedSettingsView: View {
    @ObservedObject var monitor: DiskMonitor
    @State private var section = AdvancedSettingsSection.systemDisk

    var body: some View {
        VStack(spacing: 12) {
            Picker("Avancerade inställningar", selection: $section) {
                ForEach(AdvancedSettingsSection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Group {
                switch section {
                case .systemDisk:
                    SystemDiskSettings(monitor: monitor)
                case .disks:
                    OtherDiskSettings(monitor: monitor)
                case .health:
                    HealthSettings(monitor: monitor)
                case .ntfy:
                    NtfySettings(monitor: monitor)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct TestPlaneButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "paperplane")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help(Text(title))
        .accessibilityLabel(Text(title))
    }
}

private struct EditableNumberRow: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let suffix: LocalizedStringKey
    var testTitle: LocalizedStringKey?
    var testAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
            Spacer()
            TextField("", value: $value, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 86)
                .multilineTextAlignment(.trailing)
            Text(suffix)
                .foregroundStyle(.secondary)
                .frame(minWidth: 34, alignment: .leading)
            if let testTitle, let testAction {
                TestPlaneButton(title: testTitle, action: testAction)
            }
        }
    }
}

private struct SystemDiskSettings: View {
    @ObservedObject var monitor: DiskMonitor
    @AppStorage(SettingsKey.warningGB) private var warningGB = 150.0
    @AppStorage(SettingsKey.persistentGB) private var persistentGB = 100.0
    @AppStorage(SettingsKey.criticalGB) private var criticalGB = 60.0
    @AppStorage(SettingsKey.fullCheckHours) private var fullCheckHours = 3.0

    var body: some View {
        Form {
            Section("Systemdisk") {
                EditableNumberRow(
                    title: "Vanlig notis under",
                    value: $warningGB,
                    suffix: "GB",
                    testTitle: "Testa vanlig utrymmesvarning",
                    testAction: { monitor.testSystemSpaceAlert(.warning) }
                )
                EditableNumberRow(
                    title: "Beständig varning under",
                    value: $persistentGB,
                    suffix: "GB",
                    testTitle: "Testa beständig utrymmesvarning",
                    testAction: { monitor.testSystemSpaceAlert(.persistent) }
                )
                EditableNumberRow(
                    title: "Kritisk varning under",
                    value: $criticalGB,
                    suffix: "GB",
                    testTitle: "Testa kritisk utrymmesvarning",
                    testAction: { monitor.testSystemSpaceAlert(.critical) }
                )
            }
            Section("Kontroll") {
                Text("Systemdisken kontrolleras var 15:e minut.")
                EditableNumberRow(
                    title: "Samtliga bevakade diskar",
                    value: $fullCheckHours,
                    suffix: "timmar"
                )
            }
        }
        .formStyle(.grouped)
    }
}

private struct OtherDiskSettings: View {
    @ObservedObject var monitor: DiskMonitor
    @AppStorage(SettingsKey.otherDiskUsedPercent) private var usedPercent = 75.0

    var body: some View {
        Form {
            Section("Övriga diskar") {
                EditableNumberRow(
                    title: "Varna när mer än",
                    value: $usedPercent,
                    suffix: "% använt",
                    testTitle: "Testa extern diskvarning",
                    testAction: { monitor.testExternalDiskAlert() }
                )
                ForEach(monitor.otherVolumes) { volume in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(volume.name)
                            Text(
                                String.localizedStringWithFormat(
                                    String(localized: "%@ ledigt"),
                                    StorageCapacityFormatter.string(
                                        fromByteCount: volume.availableBytes
                                    )
                                )
                            )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { monitor.isMonitored(volume) },
                                set: { monitor.setMonitored($0, volume: volume) }
                            )
                        )
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .accessibilityLabel(
                            Text("Varna för \(volume.name)")
                        )
                    }
                }
            }
            Text("I en Mac App Store-sandbox kan externa volymer vara begränsade. Funktionen måste valideras på en signerad testversion.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

private struct HealthSettings: View {
    @ObservedObject var monitor: DiskMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Den termiska kontrollen kompletterar utrymmesbevakningen men är endast en övergripande status från macOS.")
                .font(.caption)
                .foregroundStyle(.secondary)

            GroupBox("Termisk status") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(thermalText)
                        Spacer()
                        TestPlaneButton(
                            title: "Testa allvarlig termisk varning",
                            action: { monitor.testThermalAlert(critical: false) }
                        )
                        TestPlaneButton(
                            title: "Testa kritisk termisk varning",
                            action: { monitor.testThermalAlert(critical: true) }
                        )
                    }
                    Text("DiskVakt använder macOS sammanvägda termiska status och läser inte temperatur i °C.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }

    private var thermalText: LocalizedStringKey {
        switch monitor.thermalState {
        case .nominal: "Normal"
        case .fair: "Förhöjd"
        case .serious: "Allvarlig"
        case .critical: "Kritisk"
        @unknown default: "Okänd"
        }
    }
}

private struct NtfySettings: View {
    @ObservedObject var monitor: DiskMonitor
    @AppStorage(SettingsKey.ntfyTopic) private var topic = ""
    @AppStorage(SettingsKey.remoteDeviceName) private var deviceName = ""
    @State private var testStatus = ""

    private var validation: NtfyTopicValidation {
        NtfyTopicValidator.validate(topic)
    }

    var body: some View {
        Form {
            Section("ntfy") {
                LabeledContent("Topic") {
                    HStack(spacing: 8) {
                        TextField(
                            text: $topic,
                            prompt: Text("diskvakt-a7f24c91e30b")
                        ) {
                            Text("Topic")
                        }
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 260)
                        Button {
                            topic = NtfyTopicGenerator.makeTopic()
                        } label: {
                            Image(systemName: "dice")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help(Text("Skapa säkert topic"))
                        .accessibilityLabel(Text("Skapa säkert topic"))
                        TestPlaneButton(title: "Testa notis") {
                            Task {
                                do {
                                    try await monitor.testNtfy()
                                    testStatus = String(localized: "Testmeddelande skickat")
                                } catch {
                                    testStatus = error.localizedDescription
                                }
                            }
                        }
                        .disabled(validation != .valid)
                    }
                }
                if let validationMessage {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                LabeledContent("Enhetsnamn") {
                    TextField(text: $deviceName, prompt: Text(DeviceIdentity.fallbackDisplayName)) {
                        Text("Enhetsnamn")
                    }
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                }
                Text(deviceNameHelpText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Link(destination: SupportLinks.ntfyGuide) {
                        Label("Vad är ntfy?", systemImage: "arrow.up.right.square")
                    }
                    Spacer()
                }
                if !testStatus.isEmpty { Text(testStatus).font(.caption) }
            }
            Text("ntfy skickar även stabila eventtaggar och prioritet. Topic fungerar som en hemlig kanalnyckel och externa diskars utrymmesvarningar skickas aldrig.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .onChange(of: topic) { _, _ in testStatus = "" }
    }

    private var deviceNameHelpText: String {
        let fallbackDescription = String.localizedStringWithFormat(
            String(localized: "Tomt fält använder: %@"),
            DeviceIdentity.fallbackDisplayName
        )
        return "\(fallbackDescription). \(String(localized: "Enhetsnamnet skickas med ntfy-varningar och kan användas i automationer. Lokal IP-adress och maskinvaru-ID skickas inte."))"
    }

    private var validationMessage: LocalizedStringKey? {
        switch validation {
        case .empty, .valid:
            nil
        case .tooLong:
            "Topic får vara högst 64 tecken."
        case .invalidCharacters:
            "Använd endast A–Z, a–z, 0–9, bindestreck och understreck."
        }
    }
}

#if DEBUG
#Preview("Settings – Simple OK") {
    let defaults = UserDefaults.diskVaktPreview(named: "settings-simple-ok", mode: .standard)
    SettingsRootView(monitor: .preview(level: .ok, defaults: defaults))
        .defaultAppStorage(defaults)
        .environment(\.locale, Locale(identifier: "sv"))
}

#Preview("Settings – Simple Action Required") {
    let defaults = UserDefaults.diskVaktPreview(named: "settings-simple-warning", mode: .standard)
    SettingsRootView(
        monitor: .preview(level: .attention, systemAvailableGB: 90, defaults: defaults)
    )
    .defaultAppStorage(defaults)
    .environment(\.locale, Locale(identifier: "sv"))
}

#Preview("Settings – Advanced") {
    let defaults = UserDefaults.diskVaktPreview(named: "settings-advanced", mode: .advanced)
    SettingsRootView(monitor: .preview(defaults: defaults))
        .defaultAppStorage(defaults)
        .environment(\.locale, Locale(identifier: "sv"))
}

#Preview("Settings – English") {
    let defaults = UserDefaults.diskVaktPreview(named: "settings-english", mode: .standard)
    SettingsRootView(monitor: .preview(level: .ok, defaults: defaults))
        .defaultAppStorage(defaults)
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Settings – Danish") {
    let defaults = UserDefaults.diskVaktPreview(named: "settings-danish", mode: .standard)
    SettingsRootView(monitor: .preview(level: .ok, defaults: defaults))
        .defaultAppStorage(defaults)
        .environment(\.locale, Locale(identifier: "da"))
}

#Preview("Settings – Norwegian Bokmål") {
    let defaults = UserDefaults.diskVaktPreview(named: "settings-norwegian", mode: .standard)
    SettingsRootView(monitor: .preview(level: .ok, defaults: defaults))
        .defaultAppStorage(defaults)
        .environment(\.locale, Locale(identifier: "nb"))
}
#endif
