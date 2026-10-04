import XCTest
@testable import DiskVaktNext

final class HealthClassificationTests: XCTestCase {
    private let thresholds = ThresholdProfile(
        warningGB: 150,
        persistentGB: 100,
        criticalGB: 60
    )

    func testHealthySpaceIsOK() {
        XCTAssertEqual(DiskMonitor.classify(freeGB: 151, thresholds: thresholds), .ok)
    }

    func testWarningSpaceNeedsAttention() {
        XCTAssertEqual(DiskMonitor.classify(freeGB: 149, thresholds: thresholds), .attention)
    }

    func testCriticalSpaceIsCritical() {
        XCTAssertEqual(DiskMonitor.classify(freeGB: 59, thresholds: thresholds), .critical)
    }

    func testModeRoundTripsWithoutTouchingAdvancedSettings() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(73.0, forKey: SettingsKey.warningGB)
        defaults.set(AppMode.advanced.rawValue, forKey: SettingsKey.appMode)
        defaults.set(AppMode.standard.rawValue, forKey: SettingsKey.appMode)
        XCTAssertEqual(defaults.double(forKey: SettingsKey.warningGB), 73.0)
    }

    func testOnboardingCompletionIsPersisted() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        XCTAssertFalse(store.onboardingCompleted)
        store.completeOnboarding()
        XCTAssertTrue(store.onboardingCompleted)
    }

    @MainActor
    func testExternalVolumesAreOptIn() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let monitor = DiskMonitor.preview(defaults: defaults)
        let volume = monitor.otherVolumes[0]

        XCTAssertFalse(monitor.isMonitored(volume))
        monitor.setMonitored(true, volume: volume)
        XCTAssertTrue(monitor.isMonitored(volume))
        monitor.setMonitored(false, volume: volume)
        XCTAssertFalse(monitor.isMonitored(volume))
    }

    func testNtfyTopicAcceptsDocumentedASCIICharacters() {
        XCTAssertEqual(NtfyTopicValidator.validate("diskvakt-A7_9-test"), .valid)
    }

    func testNtfyIsDisabledUntilUserConfiguresATopic() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        XCTAssertNil(store.configuredNtfyTopic)

        defaults.set("   \n", forKey: SettingsKey.ntfyTopic)
        XCTAssertNil(store.configuredNtfyTopic)

        defaults.set("diskvakt-user-topic", forKey: SettingsKey.ntfyTopic)
        XCTAssertEqual(store.configuredNtfyTopic, "diskvakt-user-topic")
    }

    func testNtfyTopicRejectsSwedishCharacters() {
        XCTAssertEqual(
            NtfyTopicValidator.validate("ett-långt-svårgissat-topic"),
            .invalidCharacters
        )
    }

    func testNtfyTopicRejectsMoreThan64Characters() {
        XCTAssertEqual(
            NtfyTopicValidator.validate(String(repeating: "a", count: 65)),
            .tooLong
        )
    }

    func testNtfyTopicGeneratorUsesTwelveHexCharacters() {
        XCTAssertEqual(
            NtfyTopicGenerator.topic(hexValue: 0xA7F2_4C91_E30B),
            "diskvakt-a7f24c91e30b"
        )
        XCTAssertEqual(
            NtfyTopicGenerator.topic(hexValue: 0xF),
            "diskvakt-00000000000f"
        )
        XCTAssertEqual(
            NtfyTopicValidator.validate(NtfyTopicGenerator.makeTopic()),
            .valid
        )
    }

    func testAppleStorageGuideUsesTheAppLanguage() {
        XCTAssertEqual(
            SupportLinks.appleStorageGuide(locale: Locale(identifier: "sv_SE")).absoluteString,
            "https://support.apple.com/sv-se/102624"
        )
        XCTAssertEqual(
            SupportLinks.appleStorageGuide(locale: Locale(identifier: "da_DK")).absoluteString,
            "https://support.apple.com/da-dk/102624"
        )
        XCTAssertEqual(
            SupportLinks.appleStorageGuide(locale: Locale(identifier: "nb_NO")).absoluteString,
            "https://support.apple.com/no-no/102624"
        )
        XCTAssertEqual(
            SupportLinks.appleStorageGuide(locale: Locale(identifier: "en_GB")).absoluteString,
            "https://support.apple.com/en-us/102624"
        )
    }

    func testNtfyJSONPreservesSwedishText() throws {
        let alert = RemoteAlert(
            title: "TEST DiskVakt: systemdisken börjar bli full",
            message: "Systemdisken har för lite utrymme. Frigör utrymme snart.",
            priority: 4,
            tags: ["warning", "diskvakt", "system-space-persistent"]
        )
        let request = try NtfyProvider(topic: "diskvakt-test").request(for: alert)
        let payload = try JSONDecoder().decode(
            NtfyPublishPayload.self,
            from: XCTUnwrap(request.httpBody)
        )

        XCTAssertEqual(request.url?.absoluteString, "https://ntfy.sh/")
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "application/json; charset=utf-8"
        )
        XCTAssertEqual(payload.topic, "diskvakt-test")
        XCTAssertEqual(payload.title, alert.title)
        XCTAssertEqual(payload.message, alert.message)
        XCTAssertEqual(payload.priority, alert.priority)
        XCTAssertEqual(payload.tags, alert.tags)
    }

    func testAlertTestVariantOnlyPrefixesTitle() {
        let alert = DiskAlert(
            id: "system-space-warning",
            title: "DiskVakt: system disk",
            message: "The real message",
            timeSensitive: false,
            criticalDialog: false,
            remote: true,
            priority: 4,
            tags: ["warning", "diskvakt", "system-space-warning"]
        )

        let testAlert = alert.testVariant
        XCTAssertEqual(testAlert.title, "TEST DiskVakt: system disk")
        XCTAssertEqual(testAlert.message, alert.message)
        XCTAssertEqual(testAlert.priority, alert.priority)
        XCTAssertEqual(testAlert.tags, alert.tags)
        XCTAssertEqual(testAlert.timeSensitive, alert.timeSensitive)
        XCTAssertEqual(testAlert.criticalDialog, alert.criticalDialog)
        XCTAssertEqual(testAlert.remote, alert.remote)
    }

    func testAlertRateLimitAllowsOnePerEventAndDay() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        let firstDay = Date(timeIntervalSince1970: 1_700_000_000)
        let nextDay = firstDay.addingTimeInterval(25 * 60 * 60)

        XCTAssertTrue(store.shouldDeliverAlert(id: "warning", now: firstDay))
        XCTAssertFalse(store.shouldDeliverAlert(id: "warning", now: firstDay))
        XCTAssertTrue(store.shouldDeliverAlert(id: "critical", now: firstDay))
        XCTAssertTrue(store.shouldDeliverAlert(id: "warning", now: nextDay))
    }

    func testDeviceAutomationTagIsStableASCII() {
        XCTAssertEqual(DeviceIdentity.automationTag(for: "Bös Mac Studio M2"), "source-bos-mac-studio-m2")
    }

    func testHardwareDisplayNameUsesModelFamilyAndChip() {
        XCTAssertEqual(
            DeviceIdentity.hardwareDisplayName(
                modelIdentifier: "Mac14,13",
                chipName: "Apple M2 Max"
            ),
            "Mac Studio M2 Max"
        )
    }

    func testEmptyDeviceNameUsesHardwareFallback() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        defaults.set("   ", forKey: SettingsKey.remoteDeviceName)

        XCTAssertEqual(store.remoteDeviceName, DeviceIdentity.fallbackDisplayName)
        XCTAssertFalse(store.remoteDeviceName.isEmpty)
    }

    func testCapacityFormatterUsesWholeGigabytesAndDecimalTerabytes() {
        let locale = Locale(identifier: "sv_SE")

        XCTAssertEqual(
            StorageCapacityFormatter.string(
                fromByteCount: 262_960_000_000,
                locale: locale
            ),
            "263 GB"
        )
        XCTAssertEqual(
            StorageCapacityFormatter.string(
                fromByteCount: 994_660_000_000,
                locale: locale
            ),
            "995 GB"
        )
        XCTAssertEqual(
            StorageCapacityFormatter.string(
                fromByteCount: 1_500_000_000_000,
                locale: locale
            ),
            "1,5 TB"
        )
        XCTAssertEqual(
            StorageCapacityFormatter.string(
                fromByteCount: 2_000_000_000_000,
                locale: locale
            ),
            "2 TB"
        )
        XCTAssertEqual(
            StorageCapacityFormatter.string(
                fromByteCount: 1_500_000_000_000,
                locale: Locale(identifier: "en_US")
            ),
            "1.5 TB"
        )
    }
}
