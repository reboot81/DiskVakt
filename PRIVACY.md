# Privacy

DiskVakt is designed to minimise data access.

## Data processed on the Mac

- Available and total capacity reported by macOS for visible volumes
- The combined macOS thermal state
- App preferences, ignored-volume identifiers, and daily notification suppression dates
- Optional ntfy topic entered by the user
- A user-editable device name, with a hardware-based Mac description used when the field is empty

DiskVakt does not inspect file names or file contents and never deletes files.

## Network access

Network access is used only when the user configures ntfy. DiskVakt then sends a UTF-8 JSON payload containing the topic, alert title, message, priority, event tags, the selected or hardware-based device name, and relevant health or capacity values to `https://ntfy.sh/`. A topic acts like a secret channel key and should be long and difficult to guess.

DiskVakt does not add a local IP address, serial number, hardware UUID, user name, or file information to ntfy messages. As with any HTTPS request, the ntfy server can observe ordinary connection metadata such as the public source IP address.

No analytics, advertising SDK, crash-reporting SDK, account system, or tracking is included.

## App Store disclosure

Before release, publish this policy at a stable HTTPS URL. A privacy-policy URL is required for a macOS App Store record. Reconfirm the App Privacy answers against the final binary and ntfy wording.
