import Foundation
@preconcurrency import UserNotifications

enum LocalNotificationError: LocalizedError {
    case notAuthorized
    case alertsDisabled

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            String(localized: "Lokala notiser är inte tillåtna.")
        case .alertsDisabled:
            String(localized: "Notiscenter visar inte aviseringar från DiskVakt.")
        }
    }
}

@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center: UNUserNotificationCenter

    override init() {
        center = UNUserNotificationCenter.current()
        super.init()
        center.delegate = self
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

#if DEBUG
    init(previewAuthorizationStatus: UNAuthorizationStatus) {
        center = UNUserNotificationCenter.current()
        authorizationStatus = previewAuthorizationStatus
        super.init()
        center.delegate = self
    }
#endif

    func requestAuthorization() {
        Task { [weak self] in
            guard let self else { return }
            _ = await self.requestAuthorizationAndWait()
        }
    }

    func requestAuthorizationAndWait() async -> Bool {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            refreshAuthorization()
            return false
        }

        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        return settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional
    }

    func refreshAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            let rawValue = settings.authorizationStatus.rawValue
            Task { @MainActor in
                self?.authorizationStatus = UNAuthorizationStatus(rawValue: rawValue) ?? .notDetermined
            }
        }
    }

    func send(title: String, body: String, timeSensitive: Bool) {
        center.add(request(title: title, body: body, timeSensitive: timeSensitive))
    }

    func sendTest(title: String, body: String, timeSensitive: Bool) async throws {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        guard settings.authorizationStatus == .authorized ||
                settings.authorizationStatus == .provisional else {
            throw LocalNotificationError.notAuthorized
        }
        guard settings.alertSetting == .enabled else {
            throw LocalNotificationError.alertsDisabled
        }
        try await center.add(
            request(title: title, body: body, timeSensitive: timeSensitive)
        )
    }

    private func request(
        title: String,
        body: String,
        timeSensitive: Bool
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = timeSensitive ? .timeSensitive : .active
        return UNNotificationRequest(
            identifier: "diskvakt.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
