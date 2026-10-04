# Open-source Preparation

Free of charge and open source are compatible with Mac App Store distribution when the selected license permits App Store distribution. DiskVakt source code is licensed under MIT. Mac App Store distribution uses Apple's applicable App Store terms.

## Before making the repository public

- Confirm that the DiskVakt name and icon can be used publicly.
- Review copyright years and contributor notices before each public release.
- Remove all ntfy topics, personal paths, signing identities, provisioning profiles, and Derived Data.
- Do not publish App Store Connect API keys or certificates.
- Do not bundle the ntfy logo without resolving its asset license and trademark use.
- Add third-party notices for every external asset or dependency.
- Publish a support email and private vulnerability-reporting route.
- Enable CI, dependency review, secret scanning, and branch protection.

## Reproducibility

- Keep version and build numbers in Xcode build settings.
- Commit the `.xcodeproj`, source, resources, tests, and privacy manifest.
- Do not commit `xcuserdata`, archives, Derived Data, or signing material.
- Tag App Store source releases with the matching marketing version and build.

## Suggested repository settings

- Public repository after the first security/privacy review
- MIT license detection enabled
- Issues and discussions enabled
- Private vulnerability reporting enabled
- Protected `main` branch requiring CI
- Signed release tags if practical
