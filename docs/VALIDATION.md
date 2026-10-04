# Validation Checklist

## Build integrity

- [ ] Debug build succeeds with zero compiler errors.
- [ ] Release archive succeeds with zero unexpected warnings.
- [ ] Unit tests pass on Apple silicon.
- [ ] `codesign --verify --deep --strict` succeeds on the archive.
- [ ] `spctl` and App Store validation accept the signed archive.
- [ ] App Sandbox and Hardened Runtime are visible in the signed binary.
- [ ] No absolute developer paths exist in the bundle.

## Simple Mode

- [ ] A healthy system disk shows only `The System Disk is OK` plus last check time.
- [ ] Warning and critical simulations show `Action Required` without GB or ntfy controls.
- [ ] Unknown disk-read status never appears as OK.
- [ ] No technical disk details are visible.
- [ ] Switching to Simple Mode preserves all Advanced Mode values.

## Advanced Mode

- [ ] System disk shows available capacity and percentage.
- [ ] Adaptive defaults match 256/512/1 TB profiles on first launch.
- [ ] Existing custom thresholds are never overwritten.
- [ ] External volumes remain visible and never warn until individually enabled.
- [ ] Every alert type has an explicit test control.
- [ ] The thermal health check is labelled best effort.
- [ ] ntfy topic persists and test results are understandable.
- [ ] Every ntfy test matches its live title, message, priority, and tags, with only the `TEST ` title prefix added.
- [ ] Device name is editable and no local IP address or hardware identifier appears in the payload.
- [ ] Disk submenu shows available percentage and approximate total capacity.
- [ ] Opening an external volume delegates to Finder without asking DiskVakt for file-content access.

## Notification matrix

- [ ] Notifications allowed / denied / not determined.
- [ ] Focus enabled with and without time-sensitive permission.
- [ ] Screen unlocked, locked, asleep, and immediately after wake.
- [ ] User active and another user active through fast user switching.
- [ ] Local-only, ntfy-only, and both enabled.
- [ ] Once-per-level-per-day suppression does not block explicit tests.

## Lifecycle

- [ ] First launch asks for notification permission with context.
- [ ] Login item can be enabled and disabled.
- [ ] App starts after login when enabled.
- [ ] App does not restart after an intentional quit unless product policy says otherwise.
- [ ] Crash behaviour is documented and tested.
- [ ] Full-screen apps do not hide Settings, About, or critical dialogs.

## Storage scenarios

- [ ] 256 GB, 512 GB, 1 TB, and larger system disks.
- [ ] APFS snapshots and purgeable-space behaviour documented.
- [ ] Rapid consumption crossing multiple thresholds within 15 minutes.
- [ ] Volume unmounted during a check.
- [ ] Read-only, removable, network, and cloud-backed volumes ignored as designed.
- [ ] Localized volume names and Unicode paths.

## Localisation and accessibility

- [ ] Swedish, English, Danish, and Norwegian Bokmål selectable per app.
- [ ] No clipped or untranslated text in either mode.
- [ ] VoiceOver labels every icon-only test button.
- [ ] Keyboard navigation reaches all controls.
- [ ] High contrast, Reduce Transparency, and larger text remain usable.

## Privacy

- [ ] No file names or contents are read.
- [ ] No network request occurs until ntfy is configured or tested.
- [ ] ntfy messages contain no unintended volume names or private paths.
- [ ] The MAS build sends no disk-space values or derived low-space status over the internet.
- [ ] Privacy manifest matches the final binary.
- [ ] App Store privacy answers match the published privacy policy.
