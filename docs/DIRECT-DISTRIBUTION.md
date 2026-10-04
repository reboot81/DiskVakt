# Direct distribution checklist

DiskVakt is distributed outside the Mac App Store as a Developer ID signed and notarized macOS application.

## Before archiving

- Confirm the version and build number.
- Run the complete test suite.
- Review privacy, notification, login-item, external-volume, and ntfy behaviour.
- Confirm that App Sandbox and Hardened Runtime remain enabled.
- Confirm that the Release configuration uses the intended Apple Developer team.
- Check that no secrets, local preferences, build products, or user-specific Xcode data are tracked by Git.

## Archive and notarize

1. Select the `DiskVakt` scheme and **Any Mac (arm64, x86_64)**.
2. Choose **Product → Archive**.
3. In Organizer, choose **Distribute App → Direct Distribution**.
4. Allow Xcode to sign with Developer ID and submit the application to Apple's notarization service.
5. Wait for Organizer to report **Ready to distribute**.
6. Export the notarized application to the ignored `Distribution/<version>/` directory.

## Validate the exported application

Run these checks outside a restricted shell environment that can access the system trust store:

```sh
codesign --verify --deep --strict --verbose=2 DiskVakt.app
xcrun stapler validate DiskVakt.app
spctl --assess --type execute --verbose=2 DiskVakt.app
```

Test the exported application on a separate Mac or a clean macOS user account before publishing it. Verify first launch, notification permission, launch at login, simple and advanced modes, ntfy opt-in, localization, and update/replacement behaviour.

## Publish

- Package the application in a user-friendly signed DMG or ZIP.
- Record a SHA-256 checksum.
- Create a GitHub release with concise release notes and supported macOS versions.
- Upload only the final validated package, never an Xcode archive or signing material.
