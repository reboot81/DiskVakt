import Foundation

enum SettingsKey {
    static let appMode = "appMode"
    static let onboardingCompleted = "onboardingCompleted"
    static let defaultsConfigured = "defaultsConfigured"
    static let warningGB = "systemWarningGB"
    static let persistentGB = "systemPersistentGB"
    static let criticalGB = "systemCriticalGB"
    static let otherDiskUsedPercent = "otherDiskUsedPercent"
    static let fullCheckHours = "fullCheckHours"
    static let ntfyTopic = "ntfyTopic"
    static let remoteDeviceName = "remoteDeviceName"
    static let monitoredVolumes = "monitoredVolumeIDs"
    static let alertLastSentPrefix = "alertLastSent."
}

struct SettingsStore {
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            SettingsKey.appMode: AppMode.standard.rawValue,
            SettingsKey.otherDiskUsedPercent: 75.0,
            SettingsKey.fullCheckHours: 3.0,
            SettingsKey.ntfyTopic: "",
            SettingsKey.remoteDeviceName: ""
        ])
    }

    func configureThresholdsIfNeeded(totalBytes: Int64) {
        guard !defaults.bool(forKey: SettingsKey.defaultsConfigured) else { return }
        let profile = ThresholdProfile.defaults(totalBytes: totalBytes)
        defaults.set(profile.warningGB, forKey: SettingsKey.warningGB)
        defaults.set(profile.persistentGB, forKey: SettingsKey.persistentGB)
        defaults.set(profile.criticalGB, forKey: SettingsKey.criticalGB)
        defaults.set(true, forKey: SettingsKey.defaultsConfigured)
    }

    var thresholds: ThresholdProfile {
        ThresholdProfile(
            warningGB: defaults.double(forKey: SettingsKey.warningGB),
            persistentGB: defaults.double(forKey: SettingsKey.persistentGB),
            criticalGB: defaults.double(forKey: SettingsKey.criticalGB)
        )
    }

    var monitoredVolumeIDs: Set<String> {
        Set(defaults.stringArray(forKey: SettingsKey.monitoredVolumes) ?? [])
    }

    var configuredNtfyTopic: String? {
        let value = defaults.string(forKey: SettingsKey.ntfyTopic) ?? ""
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard NtfyTopicValidator.validate(cleanValue) == .valid else { return nil }
        return cleanValue
    }

    var onboardingCompleted: Bool {
        defaults.bool(forKey: SettingsKey.onboardingCompleted)
    }

    func completeOnboarding() {
        defaults.set(true, forKey: SettingsKey.onboardingCompleted)
    }

    var remoteDeviceName: String {
        let value = defaults.string(forKey: SettingsKey.remoteDeviceName) ?? ""
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanValue.isEmpty ? DeviceIdentity.fallbackDisplayName : cleanValue
    }

    func shouldDeliverAlert(id: String, now: Date = .now) -> Bool {
        let key = SettingsKey.alertLastSentPrefix + id
        if let lastSent = defaults.object(forKey: key) as? Date,
           Calendar.current.isDate(lastSent, inSameDayAs: now) {
            return false
        }
        defaults.set(now, forKey: key)
        return true
    }
}

#if DEBUG
extension UserDefaults {
    static func diskVaktPreview(named name: String, mode: AppMode) -> UserDefaults {
        let safeName = name.replacingOccurrences(of: " ", with: "-")
        let defaults = UserDefaults(suiteName: "com.bosaurage.diskvakt.preview.\(safeName)")!
        defaults.set(mode.rawValue, forKey: SettingsKey.appMode)
        defaults.set(150.0, forKey: SettingsKey.warningGB)
        defaults.set(100.0, forKey: SettingsKey.persistentGB)
        defaults.set(60.0, forKey: SettingsKey.criticalGB)
        defaults.set(75.0, forKey: SettingsKey.otherDiskUsedPercent)
        defaults.set(3.0, forKey: SettingsKey.fullCheckHours)
        defaults.set("", forKey: SettingsKey.ntfyTopic)
        defaults.set("Preview Mac", forKey: SettingsKey.remoteDeviceName)
        defaults.set([], forKey: SettingsKey.monitoredVolumes)
        defaults.set(true, forKey: SettingsKey.onboardingCompleted)
        return defaults
    }
}
#endif
