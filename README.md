# DiskVakt

DiskVakt is a small macOS menu-bar utility that warns before storage or basic system-health conditions require urgent attention. It does not inspect file contents and never deletes files.


## Product modes

- **Simple Mode** shows only `The System Disk is OK`, `Action Required`, or `Status Unknown`. Technical settings remain active but hidden.
- **Advanced Mode** exposes thresholds, volume details, health-check limitations, notification tests, and optional remote delivery. ntfy is the first provider.

Switching modes changes presentation only. It does not erase or disable advanced settings.

## Current status

This is pre-release software. Version 0.1.0 has been archived as a universal macOS application and notarized for direct distribution outside the Mac App Store.

- Native SwiftUI menu-bar app
- Swift 6 strict concurrency
- macOS 14 deployment target
- App Sandbox and outbound networking entitlements
- Hardened Runtime build setting
- `SMAppService` login-item API
- System-disk check every 15 minutes
- Adaptive defaults for 256 GB, 512 GB, and 1 TB-class disks
- Swedish, English, Danish, and Norwegian Bokmål resources
- Privacy manifest for app-local `UserDefaults`
- Unit tests for threshold profiles and health classification
- Isolated SwiftUI previews for status states, settings modes, About, and all four languages

External-volume visibility requires additional signed-sandbox validation before a stable release. SMART is intentionally excluded from the version 1 runtime until a documented sandbox-compatible implementation can be proven.

## Build

Open `DiskVaktNext.xcodeproj` in Xcode 26 or later, select the `DiskVakt` scheme, and build for **My Mac**.

Unsigned command-line build:

```sh
xcodebuild build \
  -project DiskVaktNext.xcodeproj \
  -scheme DiskVakt \
  -configuration Debug \
  -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO
```

Use **Any Mac (arm64, x86_64)** when creating a universal archive. Direct releases must be signed with Developer ID, notarized by Apple, stapled, and checked with Gatekeeper before publication. Build products and exported applications are intentionally excluded from Git.

## SwiftUI previews

Open a file in `DiskVakt/Views`, then choose **Editor → Canvas** or press **Option-Command-Return**. Use the preview selector above the Canvas to switch between OK, warning, critical, unknown, Advanced Mode, About, Swedish, English, Danish, and Norwegian Bokmål.

Preview fixtures use a separate `UserDefaults` suite and suppress notifications, Finder actions, login-item registration, timers, disk reads, and network delivery.

## Documentation

- [Product brief](docs/PRODUCT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Decisions](docs/DECISIONS.md)
- [Project TODO](docs/TODO.md)
- [Validation checklist](docs/VALIDATION.md)
- [Mac App Store checklist](docs/APP-STORE.md)
- [Direct distribution checklist](docs/DIRECT-DISTRIBUTION.md)
- [Open-source checklist](docs/OPEN-SOURCE.md)
- [Privacy](PRIVACY.md)
- [Security](SECURITY.md)

## License

MIT. See [LICENSE](LICENSE). The application name and icon should be reviewed separately as potential trademarks before public release.
