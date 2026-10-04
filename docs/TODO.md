# Project TODO

## P0 — before external testing

- [ ] Decide final publisher name and bundle identifier.
- [ ] Add a developer-controlled support email address.
- [ ] Add a stable HTTPS privacy-policy URL.
- [ ] Verify system-disk capacity access inside App Sandbox.
- [ ] Verify external-volume discovery inside App Sandbox.
- [ ] Verify that `Open in Finder` never requests file-content access; remove the action if macOS cannot present it without a misleading permission prompt.
- [ ] Remove internet delivery of disk-space values and derived low-space status from the MAS configuration before declaring required-reason API usage.
- [ ] Add `NSPrivacyAccessedAPICategoryDiskSpace` with the correct approved reason after the remote-delivery conflict is resolved.
- [ ] Move ntfy topic and device label out of `UserDefaults` before any value derived from them is sent off-device.
- [ ] Reconcile the ntfy payload with `NSPrivacyCollectedDataTypes`, the App Store Connect privacy answers, and the published privacy policy.
- [ ] Replace the undocumented `x-apple.systempreferences` notification-settings deep link with a documented system-settings route.
- [x] Implement real notification escalation and once-per-level-per-day suppression in the new monitor.
- [x] Add contextual first-launch choices for login startup and local notifications.
- [x] Make external-volume warnings opt-in.
- [x] Mirror system-space and serious/critical thermal alerts to ntfy in the development build.
- [ ] Add a provider registry so remote services can be enabled independently.
- [ ] Store remote-provider topics, tokens, and webhook URLs in Keychain rather than `UserDefaults`.
- [ ] Specify and implement a generic webhook provider after defining authentication and payload rules.
- [ ] Evaluate Gotify and Pushover from user demand; do not add service-specific UI without a clear use case.
- [x] Add every trigger test from the prototype to Advanced Mode.
- [x] Add a visible local-notification permission repair flow.
- [ ] Validate `SMAppService` login-item behaviour after install, update, logout, and reboot.
- [x] Exclude unfinished SMART functionality from the version 1 UI and runtime.
- [ ] Perform native-speaker review of the Danish and Norwegian translations.
- [ ] Run accessibility audit with VoiceOver and keyboard-only navigation.

## P1 — before TestFlight/App Review

- [ ] Join the Apple Developer Program.
- [ ] Create the final App ID and App Store Connect record.
- [ ] Set the Xcode Development Team and final bundle identifier.
- [ ] Create Mac Development and Mac App Distribution signing assets.
- [ ] Validate the App Sandbox entitlement in the signed binary.
- [ ] Verify Hardened Runtime in the archive.
- [ ] Add and validate the Time Sensitive Notifications capability and entitlement for the final App ID and provisioning profile; keep it out of unsigned local builds.
- [ ] Revalidate `PrivacyInfo.xcprivacy` against the final source and dependencies.
- [ ] Complete App Privacy answers and privacy-policy page.
- [ ] Prepare App Store name, subtitle, description, keywords, category, support URL, and copyright.
- [ ] Produce localized screenshots for Simple and Advanced Mode.
- [ ] Add App Review notes explaining menu-bar-only UI, login item, ntfy, and best-effort health checks.
- [ ] Test TestFlight installation on clean user accounts.
- [ ] Test update over an older TestFlight build without losing preferences.

## P2 — before public open source

- [x] License the source code under MIT with `DiskVakt contributors` as the notice holder.
- [ ] Search the repository for secrets, personal paths, topics, certificates, and build artifacts.
- [ ] Choose repository organisation/account and public project URL.
- [ ] Add issue templates and private vulnerability reporting.
- [ ] Enable branch protection and CI.
- [ ] Add screenshots that contain no private volume names or paths.
- [ ] Decide trademark policy for the DiskVakt name and icon.
- [ ] Add third-party notices if any third-party assets or code are introduced.

## Later

- [ ] Reconsider SMART only if a documented sandbox-compatible API works in a signed MAS build.
- [ ] Investigate Critical Alerts entitlement only after normal notifications and ntfy are proven insufficient.
- [ ] Consider Intel support based on actual demand and test hardware.
- [ ] Consider direct Developer ID distribution only if there is a real need outside the Mac App Store.
