# Architecture

## Product boundary

DiskVakt is a warning utility, not a cleaner, file analyser, or full system monitor.

## Layers

- `Models`: pure state and adaptive threshold policy
- `Services`: volume monitoring, local notifications, remote-alert providers, login-item registration, and health providers
- `Views`: menu-bar presentation, settings, and About window
- `App`: lifecycle and cross-Space window presentation

## Two-mode model

Both modes consume the same `DiskMonitor` and `UserDefaults` domain.

- Simple Mode reduces the visible state to OK, action required, or unknown.
- Advanced Mode exposes technical measurements and configuration.
- Switching modes never resets thresholds, monitored volumes, or ntfy.

## Monitoring cadence

- System disk: every 15 minutes and immediately after wake
- Full volume scan: every 2–4 hours, configurable in Advanced Mode
- Thermal status: event-driven through `ProcessInfo`

## Remote alerts

Remote delivery uses a provider protocol. ntfy is the first implementation, not a permanent special case in the monitoring engine.

- Local notifications always remain available without a remote service.
- Simple Mode never exposes provider configuration.
- Advanced Mode owns provider setup and explicit tests.
- Each provider must document what leaves the Mac and how secrets are stored.
- A provider failure must never block another provider or a local critical dialog.

### ntfy automation contract

- Alert titles and messages are identical between live and explicit test delivery, except that test titles begin with `TEST `.
- Tests preserve the live priority and tags.
- Stable event tags are `system-space-warning`, `system-space-persistent`, `system-space-critical`, `thermal-serious`, and `thermal-critical`.
- Every remote alert also includes `diskvakt`, a severity tag, and a normalized `source-<device-name>` tag.
- The human-readable message includes the user-editable device name, or a hardware-based Mac name when the field is empty. Hostnames are never used as the fallback.
- Disk-capacity alerts include available capacity, total capacity, and percentage. Capacities use rounded whole GB or TB in both UI and alerts.
- The current internet delivery of disk-capacity values is not eligible for the Mac App Store build under Apple's required-reason API terms and must be removed or isolated in a separate distribution configuration.
- ntfy publishing uses a UTF-8 JSON body so localized titles and messages do not depend on non-ASCII HTTP-header handling.
- DiskVakt does not add a local IP address, serial number, or hardware UUID to the payload.

## Failure semantics

- A failed system-disk read produces `Status Unknown`, not `The System Disk is OK`.
- Critical health signals may override lower-priority space status.
- The app never deletes files.

## Distribution boundary

The local prototype and DiskVakt Next intentionally use different bundle identifiers. The App Store project must never overwrite the prototype during development.
