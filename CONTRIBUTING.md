# Contributing to BioSync

Thank you for your interest in contributing to BioSync! BioSync is built to give everyone an open-source, private, subscription-free alternative to fitness rings and trackers by unlocking the full sensor hardware of the Apple Watch and iPhone.

## Ways to Contribute
- **Algorithm Enhancements**: Improve biological age models, VO2 max estimations, or HRV circadian baseline analysis in `Sources/BiometricEngine.swift`.
- **Watch Face Complications**: Add support for new WidgetKit complication templates or watchOS 10 Smart Stacks in `Sources/Complications/`.
- **UI/UX Polish**: Enhance the pure Black-and-White AMOLED styling or telemetry cards in `Sources/WatchContentView.swift` and `Sources/PhoneContentView.swift`.
- **Bug Fixes & Device Testing**: Test across different Apple Watch models (SE, Series 7–10, Ultra) and iPhones.

## Development Workflow
1. **Fork the repository** on GitHub.
2. **Clone your fork**:
   ```bash
   git clone https://github.com/<your-username>/BioSync.git
   cd BioSync
   ```
3. **Open the project**:
   Double click `BioSync.xcodeproj` or open it with Xcode.
4. **Select your development team**:
   Under Target settings -> Signing & Capabilities, select your Personal Apple Developer Team.
5. **Create a branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
6. **Commit changes**:
   Keep commits focused and informative. Ensure code builds cleanly without warnings:
   ```bash
   xcodebuild -project BioSync.xcodeproj -scheme BioSync -destination "generic/platform=watchOS" build
   xcodebuild -project BioSync.xcodeproj -scheme BioSyncPhone -destination "generic/platform=iOS" build
   ```
7. **Open a Pull Request**:
   Describe your changes and link any related issues.

## Security & Privacy Guidelines
- **Zero Telemetry Leakage**: BioSync is strictly privacy-first. Do not add tracking libraries, analytics SDKs, or external network requests that transmit health data.
- **Never Commit Credentials**: Never commit API keys, personal certificates, or `.env` files.
