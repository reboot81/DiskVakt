# Decisions

## Preserve the local prototype

Decision: keep `~/Applications/DiskVakt.app` and its `com.bosaurage.diskvakt` preferences untouched while DiskVakt Next is developed.

Development identifier: `com.bosaurage.diskvakt.next`.

## Final bundle identifier is not decided

Do not create the App Store Connect record until the final identifier is chosen. Bundle identifiers are durable product identity, not marketing text.

Recommended approaches:

1. Keep `com.bosaurage.diskvakt` if `bosaurage` is the long-term publisher namespace.
2. Acquire and control a product or publisher domain, then reverse that domain for the identifier.
3. Do not use a namespace belonging to a domain or organisation you do not control.

The public app name can remain **DiskVakt** regardless of bundle identifier.

## License

The code uses MIT because it is permissive and compatible with free Mac App Store distribution.

## ntfy branding

The new project does not bundle the official ntfy logo. Linking to ntfy and implementing its HTTP API is separate from permission to redistribute its logo or imply endorsement. Resolve logo licensing and trademark use before adding it.

## SMART

SMART is excluded from the version 1 UI and runtime. The prototype's `diskutil` subprocess is not carried into the sandbox target. Reconsider SMART only if a documented, sandbox-compatible implementation can be validated in a signed Mac App Store build.

## Required-reason disk-space API

Disk-space values and derived low-space status must not be sent to `ntfy.sh` in the Mac App Store build under Apple's approved required-reason API terms. Resolve this before adding the disk-space reason to the privacy manifest and before external testing. Values that are sent off-device, including ntfy topic and device label, must also move out of `UserDefaults`. A separately distributed non-MAS build may use a different remote-alert policy.
