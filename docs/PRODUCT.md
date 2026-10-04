# Product Brief

## Promise

DiskVakt stays out of the way and warns early enough that a full system disk does not become a surprise. It never deletes files and is not a general-purpose system monitor.

## Default experience: Simple Mode

Simple Mode is the default and is designed for a person who does not want to understand storage terminology.

- Show only `The System Disk is OK`, `Action Required`, or `Status Unknown`.
- Do not show GB, percentages, volume identifiers, or ntfy controls.
- Use plain-language notifications that say what the person should do next.
- Keep settings short enough to fit without scrolling.
- Treat failed checks as unknown, never as healthy.

## Advanced Mode

Advanced Mode is for setup, diagnostics, and technical users.

- Show disk capacity, percentages, thresholds, and last successful check.
- Make alerts for individual external volumes opt-in without hiding their status.
- Explain the thermal check accurately as best effort.
- Configure and test optional remote delivery; ntfy is the first provider.
- Provide an explicit test for every alert path.

## Switching modes

The mode is a presentation preference, not a separate configuration.

- Switching to Simple Mode must preserve thresholds, monitored volumes, ntfy topic, and monitoring behaviour.
- Advanced monitoring continues while its controls are hidden.
- A technical person can configure a Mac in Advanced Mode and return it to Simple Mode for everyday use.

## Non-goals

- Automatic cleanup or deletion
- File-content, folder-size, or cloud-storage analysis
- Continuous performance dashboards
- Hard-coded disk names or computer-specific paths
- Claims that best-effort health checks can predict every hardware failure

## Release principles

- Free in the Mac App Store
- Source available under the MIT License after security and asset review
- No analytics, advertising, tracking, or account requirement
- No network access unless the user enables or tests ntfy
