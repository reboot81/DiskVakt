import AppKit
import SwiftUI

@MainActor
final class WindowCoordinator: ObservableObject {
    private var onboardingWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?

    func showOnboardingIfNeeded(monitor: DiskMonitor) {
        let settings = SettingsStore()
        guard !settings.onboardingCompleted else { return }
        show(
            existing: onboardingWindow,
            title: String(localized: "Välkommen till DiskVakt"),
            size: NSSize(width: 560, height: 430),
            content: AnyView(
                OnboardingView(monitor: monitor) { [weak self] in
                    settings.completeOnboarding()
                    self?.onboardingWindow?.close()
                }
            )
        ) { onboardingWindow = $0 }
    }

    func showSettings(monitor: DiskMonitor) {
        monitor.refreshNotificationAuthorization()
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.show(
                existing: self?.settingsWindow,
                title: String(localized: "DiskVakt – Inställningar"),
                size: NSSize(width: 680, height: 720),
                content: AnyView(
                    SettingsRootView(monitor: monitor) { [weak self] in
                        self?.showAbout(monitor: monitor)
                    }
                )
            ) { self?.settingsWindow = $0 }
        }
    }

    func showAbout(monitor: DiskMonitor) {
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.show(
                existing: self?.aboutWindow,
                title: String(localized: "Om DiskVakt"),
                size: NSSize(width: 680, height: 520),
                content: AnyView(AboutView(monitor: monitor))
            ) { self?.aboutWindow = $0 }
        }
    }

    private func show(
        existing: NSWindow?,
        title: String,
        size: NSSize,
        content: AnyView,
        store: (NSWindow) -> Void
    ) {
        if let existing {
            bringToFront(existing)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.level = .floating
        window.contentView = NSHostingView(rootView: content)
        window.center()
        store(window)
        bringToFront(window)
    }

    private func bringToFront(_ window: NSWindow) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.unhide(nil)
        NSApp.activate()
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        window.level = .floating
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        window.makeMain()

        DispatchQueue.main.async {
            NSApp.activate()
            NSRunningApplication.current.activate(options: [.activateAllWindows])
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
        }
    }
}

private struct OnboardingView: View {
    @ObservedObject var monitor: DiskMonitor
    @State private var startAtLogin = true
    @State private var allowNotifications = true
    @State private var errorMessage = ""
    @State private var notificationApprovalFailed = false
    @State private var isSubmitting = false
    let completion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Välkommen till DiskVakt")
                        .font(.largeTitle.bold())
                    Text("DiskVakt har som uppgift att informera dig när systemdisken börjar få ont om utrymme.")
                        .foregroundStyle(.secondary)
                }
            }

            GroupBox("Välj hur DiskVakt ska fungera:") {
                VStack(alignment: .leading, spacing: 16) {
                    choiceRow(
                        title: "Starta DiskVakt vid inloggning",
                        explanation: "DiskVakt kan då kontrollera systemdisken efter varje inloggning.",
                        isOn: $startAtLogin
                    )
                    Divider()
                    choiceRow(
                        title: "Tillåt lokala notiser",
                        explanation: "macOS frågar om tillåtelse när du fortsätter.",
                        isOn: $allowNotifications
                    )
                }
                .frame(maxWidth: .infinity)
            }

            if !errorMessage.isEmpty {
                HStack(spacing: 12) {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                    if notificationApprovalFailed {
                        Button("Öppna notisinställningar") {
                            monitor.openNotificationSettings()
                        }
                    }
                }
            }

            HStack {
                Text("Du kan ändra båda valen senare i Inställningar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Fortsätt") {
                    Task { await continueSetup() }
                }
                    .keyboardShortcut(.defaultAction)
                    .disabled(isSubmitting)
            }
        }
        .padding(24)
        .frame(width: 560, height: 430)
        .onChange(of: allowNotifications) { _, _ in
            errorMessage = ""
            notificationApprovalFailed = false
        }
    }

    private func choiceRow(
        title: LocalizedStringKey,
        explanation: LocalizedStringKey,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    private func continueSetup() async {
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = ""
        notificationApprovalFailed = false

        do {
            if monitor.launchAtLogin.isEnabled != startAtLogin {
                try monitor.launchAtLogin.setEnabled(startAtLogin)
            }
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        if allowNotifications {
            let approved = await monitor.requestNotificationAuthorizationAndWait()
            guard approved else {
                errorMessage = String(localized: "Lokala notiser godkändes inte. Aktivera dem i Systeminställningar eller stäng av valet för att fortsätta.")
                notificationApprovalFailed = true
                return
            }
        }
        completion()
    }
}
