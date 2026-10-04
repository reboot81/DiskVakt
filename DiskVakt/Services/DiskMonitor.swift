import AppKit
import Foundation

enum SystemSpaceAlertLevel: Sendable {
    case warning
    case persistent
    case critical
}

struct DiskAlert: Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let timeSensitive: Bool
    let criticalDialog: Bool
    let remote: Bool
    let priority: Int
    let tags: [String]

    var testVariant: DiskAlert {
        DiskAlert(
            id: id,
            title: "TEST \(title)",
            message: message,
            timeSensitive: timeSensitive,
            criticalDialog: criticalDialog,
            remote: remote,
            priority: priority,
            tags: tags
        )
    }

    var remoteAlert: RemoteAlert {
        RemoteAlert(title: title, message: message, priority: priority, tags: tags)
    }
}

@MainActor
final class DiskMonitor: ObservableObject {
    @Published private(set) var systemVolume: VolumeSnapshot?
    @Published private(set) var otherVolumes: [VolumeSnapshot] = []
    @Published private(set) var health = HealthSnapshot.unknown
    @Published private(set) var thermalState = ProcessInfo.processInfo.thermalState
    @Published private(set) var lastFullCheck: Date?

    let notifications: NotificationService
    let launchAtLogin: LaunchAtLoginManager

    private let settings: SettingsStore
    private let isPreview: Bool
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var thermalObserver: NSObjectProtocol?

    init(
        notifications: NotificationService = NotificationService(),
        launchAtLogin: LaunchAtLoginManager = LaunchAtLoginManager(),
        settings: SettingsStore = SettingsStore()
    ) {
        self.notifications = notifications
        self.launchAtLogin = launchAtLogin
        self.settings = settings
        isPreview = false
        notifications.refreshAuthorization()

        wakeObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.checkAll() }
        }
        thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateThermalState() }
        }

        checkAll()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkIfDue() }
        }
    }

    nonisolated static func classify(freeGB: Double, thresholds: ThresholdProfile) -> HealthLevel {
        if freeGB < thresholds.criticalGB { return .critical }
        if freeGB < thresholds.warningGB { return .attention }
        return .ok
    }

    func checkIfDue() {
        guard !isPreview else { return }
        if health.checkedAt == nil || Date().timeIntervalSince(health.checkedAt!) >= 15 * 60 {
            checkSystemDisk()
        }
        let hours = max(2, min(4, UserDefaults.standard.double(forKey: SettingsKey.fullCheckHours)))
        if lastFullCheck == nil || Date().timeIntervalSince(lastFullCheck!) >= hours * 3600 {
            checkAll()
        }
    }

    func checkAll() {
        guard !isPreview else { return }
        checkSystemDisk()
        otherVolumes = readOtherVolumes()
        evaluateOtherVolumeAlerts()
        lastFullCheck = Date()
    }

    func setMonitored(_ monitored: Bool, volume: VolumeSnapshot) {
        var monitoredIDs = settings.monitoredVolumeIDs
        if monitored { monitoredIDs.insert(volume.id) } else { monitoredIDs.remove(volume.id) }
        settings.defaults.set(
            Array(monitoredIDs).sorted(),
            forKey: SettingsKey.monitoredVolumes
        )
        evaluateHealth()
    }

    func isMonitored(_ volume: VolumeSnapshot) -> Bool {
        settings.monitoredVolumeIDs.contains(volume.id)
    }

    func openInFinder(_ volume: VolumeSnapshot) {
        guard !isPreview else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.addsToRecentItems = false
        configuration.promptsUserIfNeeded = false
        NSWorkspace.shared.open(
            URL(fileURLWithPath: volume.id, isDirectory: true),
            configuration: configuration
        ) { _, error in
            guard error != nil else { return }
            DispatchQueue.main.async {
                NSWorkspace.shared.activateFileViewerSelecting([
                    URL(fileURLWithPath: volume.id, isDirectory: true)
                ])
            }
        }
    }

    func refreshNotificationAuthorization() {
        guard !isPreview else { return }
        notifications.refreshAuthorization()
    }

    func requestNotificationAuthorization() {
        guard !isPreview else { return }
        notifications.requestAuthorization()
    }

    func requestNotificationAuthorizationAndWait() async -> Bool {
        guard !isPreview else { return false }
        return await notifications.requestAuthorizationAndWait()
    }

    func openNotificationSettings() {
        guard !isPreview,
              let url = URL(
                string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
              ) else { return }
        NSWorkspace.shared.open(url)
    }

    func testNtfy() async throws {
        if isPreview { throw CancellationError() }
        guard let topic = settings.configuredNtfyTopic else {
            throw NtfyError.invalidTopic
        }
        let provider = NtfyProvider(topic: topic)
        let alert = makeSystemSpaceAlert(.warning, volume: systemVolumeForTesting).testVariant
        try await provider.send(alert.remoteAlert)
    }

    func testLocalNotification() {
        guard !isPreview else { return }
        deliver(makeSystemSpaceAlert(.warning, volume: systemVolumeForTesting), asTest: true)
    }

    func testSystemSpaceAlert(_ level: SystemSpaceAlertLevel) {
        guard !isPreview else { return }
        deliver(makeSystemSpaceAlert(level, volume: systemVolumeForTesting), asTest: true)
    }

    func testExternalDiskAlert() {
        guard !isPreview else { return }
        deliver(
            makeExternalDiskAlert(otherVolumes.first ?? externalVolumeForTesting),
            asTest: true
        )
    }

    func testThermalAlert(critical: Bool) {
        guard !isPreview else { return }
        deliver(makeThermalAlert(critical: critical), asTest: true)
    }

    private func deliverIfDue(_ alert: DiskAlert) {
        guard canDeliver(alert) else { return }
        guard settings.shouldDeliverAlert(id: alert.id) else { return }
        deliver(alert, asTest: false)
    }

    private func canDeliver(_ alert: DiskAlert) -> Bool {
        if alert.criticalDialog { return true }
        if notifications.isAuthorized { return true }
        return alert.remote && settings.configuredNtfyTopic != nil
    }

    private func deliver(_ alert: DiskAlert, asTest: Bool) {
        let deliveredAlert = asTest ? alert.testVariant : alert
        if deliveredAlert.remote {
            sendRemote(deliveredAlert)
        }
        if deliveredAlert.criticalDialog {
            showCriticalDialog(title: deliveredAlert.title, message: deliveredAlert.message)
        } else {
            notifications.send(
                title: deliveredAlert.title,
                body: deliveredAlert.message,
                timeSensitive: deliveredAlert.timeSensitive
            )
        }
    }

    private func sendRemote(_ alert: DiskAlert) {
        guard let topic = settings.configuredNtfyTopic else { return }
        Task {
            try? await NtfyProvider(topic: topic).send(alert.remoteAlert)
        }
    }

    private func showCriticalDialog(title: String, message: String) {
        NSApp.activate()
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: String(localized: "Jag förstår"))
        alert.runModal()
    }

    private func makeSystemSpaceAlert(
        _ level: SystemSpaceAlertLevel,
        volume: VolumeSnapshot
    ) -> DiskAlert {
        let details = String.localizedStringWithFormat(
            String(localized: "Systemdisken på %@ har %@ ledigt av %@ (%d %% ledigt)."),
            settings.remoteDeviceName,
            StorageCapacityFormatter.string(fromByteCount: volume.availableBytes),
            StorageCapacityFormatter.string(fromByteCount: volume.totalBytes),
            volume.freePercent
        )
        let sourceTag = DeviceIdentity.automationTag(for: settings.remoteDeviceName)

        switch level {
        case .warning:
            return DiskAlert(
                id: "system-space-warning",
                title: String(localized: "DiskVakt: systemdisken börjar bli full"),
                message: "\(details) \(String(localized: "Planera att frigöra utrymme."))",
                timeSensitive: false,
                criticalDialog: false,
                remote: true,
                priority: 3,
                tags: ["warning", "diskvakt", "system-space-warning", sourceTag]
            )
        case .persistent:
            return DiskAlert(
                id: "system-space-persistent",
                title: String(localized: "DiskVakt: lite diskutrymme"),
                message: "\(details) \(String(localized: "Frigör utrymme snart."))",
                timeSensitive: true,
                criticalDialog: false,
                remote: true,
                priority: 4,
                tags: ["warning", "diskvakt", "system-space-persistent", sourceTag]
            )
        case .critical:
            return DiskAlert(
                id: "system-space-critical",
                title: String(localized: "DiskVakt: kritiskt lite diskutrymme"),
                message: "\(details) \(String(localized: "Frigör utrymme nu för att undvika dataförlust och systemproblem."))",
                timeSensitive: true,
                criticalDialog: true,
                remote: true,
                priority: 5,
                tags: ["rotating_light", "diskvakt", "system-space-critical", sourceTag]
            )
        }
    }

    private func makeExternalDiskAlert(_ volume: VolumeSnapshot) -> DiskAlert {
        let message = String.localizedStringWithFormat(
            String(localized: "%@ på %@ är %d %% full och har %@ ledigt av %@."),
            volume.name,
            settings.remoteDeviceName,
            volume.usedPercent,
            StorageCapacityFormatter.string(fromByteCount: volume.availableBytes),
            StorageCapacityFormatter.string(fromByteCount: volume.totalBytes)
        )
        return DiskAlert(
            id: "external-space-\(volume.id)",
            title: String.localizedStringWithFormat(
                String(localized: "DiskVakt: %@ börjar bli full"),
                volume.name
            ),
            message: message,
            timeSensitive: false,
            criticalDialog: false,
            remote: false,
            priority: 3,
            tags: []
        )
    }

    private func makeThermalAlert(critical: Bool) -> DiskAlert {
        let detail = critical
            ? String(localized: "macOS rapporterar kritisk termisk belastning. Spara arbetet, kontrollera ventilationen och låt Macen svalna.")
            : String(localized: "macOS rapporterar allvarlig termisk belastning. Kontrollera ventilationen och minska belastningen.")
        let message = String.localizedStringWithFormat(
            String(localized: "%@: %@"),
            settings.remoteDeviceName,
            detail
        )
        let sourceTag = DeviceIdentity.automationTag(for: settings.remoteDeviceName)
        return DiskAlert(
            id: critical ? "thermal-critical" : "thermal-serious",
            title: critical
                ? String(localized: "DiskVakt: kritisk temperaturbelastning")
                : String(localized: "DiskVakt: termisk varning"),
            message: message,
            timeSensitive: true,
            criticalDialog: critical,
            remote: true,
            priority: critical ? 5 : 4,
            tags: [
                critical ? "rotating_light" : "warning",
                "diskvakt",
                critical ? "thermal-critical" : "thermal-serious",
                sourceTag
            ]
        )
    }

    private var systemVolumeForTesting: VolumeSnapshot {
        systemVolume ?? VolumeSnapshot(
            id: "/",
            name: String(localized: "Systemdisk"),
            totalBytes: 500_000_000_000,
            availableBytes: 75_000_000_000,
            isSystem: true
        )
    }

    private var externalVolumeForTesting: VolumeSnapshot {
        VolumeSnapshot(
            id: "/Volumes/Example",
            name: String(localized: "Exempeldisk"),
            totalBytes: 2_000_000_000_000,
            availableBytes: 400_000_000_000,
            isSystem: false
        )
    }

    private func checkSystemDisk() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard let volume = readVolume(at: home, isSystem: true) else {
            health = HealthSnapshot(
                level: .unknown,
                reason: String(localized: "Systemdisken kunde inte kontrolleras"),
                checkedAt: health.checkedAt
            )
            return
        }
        settings.configureThresholdsIfNeeded(totalBytes: volume.totalBytes)
        systemVolume = volume
        evaluateHealth(checkedAt: Date())
        if let level = systemSpaceAlertLevel(for: volume) {
            deliverIfDue(makeSystemSpaceAlert(level, volume: volume))
        }
    }

    private func updateThermalState() {
        thermalState = ProcessInfo.processInfo.thermalState
        evaluateHealth()
        if thermalState == .serious {
            deliverIfDue(makeThermalAlert(critical: false))
        } else if thermalState == .critical {
            deliverIfDue(makeThermalAlert(critical: true))
        }
    }

    private func systemSpaceAlertLevel(for volume: VolumeSnapshot) -> SystemSpaceAlertLevel? {
        let freeGB = Double(volume.availableBytes) / 1_000_000_000
        let thresholds = settings.thresholds
        if freeGB < thresholds.criticalGB { return .critical }
        if freeGB < thresholds.persistentGB { return .persistent }
        if freeGB < thresholds.warningGB { return .warning }
        return nil
    }

    private func evaluateOtherVolumeAlerts() {
        let threshold = settings.defaults.double(forKey: SettingsKey.otherDiskUsedPercent)
        for volume in otherVolumes where isMonitored(volume) && Double(volume.usedPercent) > threshold {
            deliverIfDue(makeExternalDiskAlert(volume))
        }
    }

    private func evaluateHealth(checkedAt: Date? = nil) {
        guard let systemVolume else { return }
        let freeGB = Double(systemVolume.availableBytes) / 1_000_000_000
        var level = Self.classify(freeGB: freeGB, thresholds: settings.thresholds)
        var reason: String?

        if level != .ok {
            reason = String(localized: "Systemdisken har ont om ledigt utrymme")
        }
        if thermalState == .serious {
            level = max(level, .attention)
            reason = String(localized: "Macen rapporterar hög termisk belastning")
        } else if thermalState == .critical {
            level = .critical
            reason = String(localized: "Macen rapporterar kritisk termisk belastning")
        }
        health = HealthSnapshot(
            level: level,
            reason: reason,
            checkedAt: checkedAt ?? health.checkedAt
        )
    }

    private func readVolume(at url: URL, isSystem: Bool) -> VolumeSnapshot? {
        let keys: Set<URLResourceKey> = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity,
              let available = values.volumeAvailableCapacityForImportantUsage else { return nil }
        return VolumeSnapshot(
            id: url.path,
            name: isSystem ? String(localized: "Systemdisk") : (values.volumeName ?? url.lastPathComponent),
            totalBytes: Int64(total),
            availableBytes: available,
            isSystem: isSystem
        )
    }

    private func readOtherVolumes() -> [VolumeSnapshot] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeIsLocalKey,
            .volumeIsBrowsableKey,
            .volumeIsRemovableKey,
            .volumeIsReadOnlyKey
        ]
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []
        return urls.compactMap { url in
            guard url.path.hasPrefix("/Volumes/"),
                  let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.volumeIsLocal == true,
                  values.volumeIsBrowsable == true,
                  values.volumeIsRemovable != true,
                  values.volumeIsReadOnly != true,
                  let total = values.volumeTotalCapacity,
                  Int64(total) >= 100_000_000_000,
                  let available = values.volumeAvailableCapacityForImportantUsage else { return nil }
            return VolumeSnapshot(
                id: url.path,
                name: values.volumeName ?? url.lastPathComponent,
                totalBytes: Int64(total),
                availableBytes: available,
                isSystem: false
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

#if DEBUG
    static func preview(
        level: HealthLevel = .ok,
        systemAvailableGB: Int64 = 180,
        thermalState: ProcessInfo.ThermalState = .nominal,
        defaults: UserDefaults
    ) -> DiskMonitor {
        let monitor = DiskMonitor(
            previewSystemVolume: VolumeSnapshot(
                id: "/",
                name: String(localized: "Systemdisk"),
                totalBytes: 1_000_000_000_000,
                availableBytes: systemAvailableGB * 1_000_000_000,
                isSystem: true
            ),
            previewOtherVolumes: [
                VolumeSnapshot(
                    id: "/Volumes/Archive",
                    name: "Archive",
                    totalBytes: 2_000_000_000_000,
                    availableBytes: 940_000_000_000,
                    isSystem: false
                ),
                VolumeSnapshot(
                    id: "/Volumes/Backup",
                    name: "Backup",
                    totalBytes: 4_000_000_000_000,
                    availableBytes: 760_000_000_000,
                    isSystem: false
                )
            ],
            previewHealth: HealthSnapshot(level: level, reason: nil, checkedAt: .now),
            previewThermalState: thermalState,
            defaults: defaults
        )
        return monitor
    }

    private init(
        previewSystemVolume: VolumeSnapshot,
        previewOtherVolumes: [VolumeSnapshot],
        previewHealth: HealthSnapshot,
        previewThermalState: ProcessInfo.ThermalState,
        defaults: UserDefaults
    ) {
        systemVolume = previewSystemVolume
        otherVolumes = previewOtherVolumes
        health = previewHealth
        thermalState = previewThermalState
        lastFullCheck = previewHealth.checkedAt
        notifications = NotificationService(previewAuthorizationStatus: .authorized)
        launchAtLogin = LaunchAtLoginManager(previewEnabled: true)
        settings = SettingsStore(defaults: defaults)
        isPreview = true
    }
#endif
}
