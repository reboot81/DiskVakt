# Security Policy

DiskVakt is pre-release software. Please do not publish a suspected vulnerability before the maintainer has had a reasonable opportunity to investigate it.

Before the public repository is created, choose and publish a private security contact address. Enable GitHub private vulnerability reporting if GitHub is used.

## Security principles

- App Sandbox enabled for Mac App Store builds
- Hardened Runtime enabled
- No automatic file deletion
- No shell execution in the App Store target
- No third-party runtime dependencies
- ntfy topics treated as secrets
- Remote-provider topics, tokens, and webhook URLs must move to Keychain before release
- Health checks fail to `unavailable`, never to a false failure
