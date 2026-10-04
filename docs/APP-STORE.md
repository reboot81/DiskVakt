# Mac App Store Preparation

## What the developer must arrange

1. Apple Account with two-factor authentication.
2. Apple Developer Program membership. Apple currently lists the fee as USD 99 per membership year or local equivalent.
3. Final legal seller identity: individual or organisation.
4. Final bundle identifier and App ID.
5. App Store Connect app record. Apple requires the latest agreement to be accepted before creating it.
6. Stable HTTPS support and privacy-policy URLs.
7. App Store metadata and localized screenshots.

## Project requirements

- App Sandbox must remain enabled for Mac App Store distribution.
- Outbound network entitlement is needed only for optional ntfy.
- Add the Time Sensitive Notifications capability and matching entitlement only after the final App ID, Development Team, and provisioning profile are configured. It is intentionally omitted from the unsigned development project.
- Hardened Runtime should remain enabled.
- Privacy manifest must declare required-reason API use accurately. `CA92.1` covers app-local `UserDefaults`; disk-space access still needs an approved reason after internet delivery of disk-space information is removed from the MAS configuration.
- The ntfy payload, `NSPrivacyCollectedDataTypes`, App Store Connect privacy answers, and the published privacy policy must describe the same data flow.
- Replace the development build's undocumented notification-settings deep link before submission; App Review requires public APIs.
- The signed archive must use the final App Store bundle identifier and team.
- Login at startup must use `SMAppService`, not a manually installed LaunchAgent.

## App Store Connect metadata

- Name, maximum 30 characters
- Subtitle, maximum 30 characters
- Description and keywords
- Utilities category
- Support URL
- Privacy Policy URL, required for macOS apps
- Copyright owner and year entered with the final individual legal identity in App Store Connect
- Screenshots showing both Simple and Advanced Mode
- App Review contact and notes
- Price: Free
- No in-app purchases

## Review notes should explain

- DiskVakt is menu-bar-only (`LSUIElement`).
- Simple Mode intentionally hides technical data.
- Advanced Mode reveals thresholds and optional ntfy.
- The app never deletes files or scans file contents.
- The thermal health check is best effort.
- Exact steps for testing every notification trigger.
- Why outbound networking is present and when it activates.

## Official references

- Apple Developer Program: https://developer.apple.com/programs/whats-included/
- App Sandbox requirement: https://developer.apple.com/documentation/security/app-sandbox
- Required-reason APIs: https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
- Create an app record: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/
- Upload builds: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- Submit for review: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app
- App information and privacy URL: https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
