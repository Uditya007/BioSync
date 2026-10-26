# BioSync: iOS & watchOS Biometric Health, Vitality & Longevity Platform

BioSync is a native Apple ecosystem health intelligence application engineered for **iOS 17+** and **watchOS 10+**. It computes real-time **Biological Age & Longevity**, **Autonomic Stress & Recovery**, and **Deep Sleep Architecture**, featuring native **Watch Face Complications** and dual-provider **AI Physiological Coaching** (OpenRouter / Google Gemini) with fallback to local sports-science heuristics.

---

## 1. Key Features

- **Biological Age & Longevity Analytics**: Dynamically estimates biological age versus chronological age using 7-day rolling biometric trends (daily steps, nocturnal HRV, resting heart rate, sleep duration).
- **Autonomic Stress & Recovery Tracking**: Continuous sympathetic and parasympathetic balance monitoring (Recovery in vibrant Yellow, Stress in vibrant Green).
- **Deep Sleep Architecture**: Clinical sleep stage breakdown (Deep, REM, Core, Awake, and efficiency).
- **Apple Watch Complications**: Full support across Modular, Graphic Rectangular, Corner, Bezel, Circular, Utilitarian, and Extra Large watch faces.
- **Bidirectional WCSession Sync**: Real-time telemetry communication between iPhone and Apple Watch.
- **Secure AI Coaching Engine**: Dual OpenRouter and Google Gemini intelligence with zero hardcoded credentials and offline local heuristic fallback.

---

## 2. Project Architecture

```
BioSyncWatch/
├── BioSync.xcodeproj/               # Multiplatform Xcode project (watchOS & iOS targets)
├── BioSync.entitlements            # HealthKit & background capabilities
├── Sources/
│   ├── BioSyncApp.swift            # iOS App entrypoint & lifecycle management
│   ├── App.swift                   # watchOS App entrypoint
│   ├── PhoneContentView.swift      # Modern black-and-white iOS SwiftUI interface & telemetry
│   ├── WatchContentView.swift      # 6-Page watchOS glanceable interface & PPG visualizer
│   ├── PhoneViewModel.swift        # iOS Combine view model & HealthKit aggregator
│   ├── WatchViewModel.swift        # watchOS Combine state manager & sensor subscriber
│   ├── BiometricEngine.swift       # Biological age, recovery, stress, and sleep algorithms
│   ├── HealthKitManager.swift      # HealthKit background delivery & query pipelines
│   ├── WatchConnectivityManager.swift # Bidirectional WatchConnectivity bridge & complication trigger
│   ├── GeminiAIService.swift       # Secure OpenRouter / Gemini LLM client with local heuristics fallback
│   ├── AIService.swift             # Clinical prompt engineering & sports-science rules engine
│   ├── BackgroundManager.swift     # Periodic background task dispatcher
│   ├── BioSyncNotificationManager.swift # Smart actionable notifications
│   ├── Complications/
│   │   ├── ComplicationController.swift # ClockKit complication data source (all families)
│   │   └── BioSyncComplications.swift   # WidgetKit complication definitions
│   └── Assets.xcassets/            # App icons (watchOS & iOS) and BioSync vector branding
├── Config/
│   └── Info.plist.example          # Sample permissions & background mode declarations
├── Tests/
│   └── BiometricEngineTests.swift  # Validation test suite for biometric algorithms
├── Package.swift                   # Swift Package Manager manifest
└── README.md
```

---

## 3. API Key & Security Configuration

The application does **not** contain any hardcoded API keys. All keys can be configured via environment variables or directly inside the app:

### Option A: App Settings (Recommended)
1. Open **BioSync** on your iPhone.
2. Tap the **Settings** icon on the navigation bar.
3. Scroll to **Gemini AI API Configuration**.
4. Enter your **OpenRouter** (`sk-or-v1-...`) or **Google Gemini** key and tap **Save & Sync to Watch**.
5. The key will be securely saved into encrypted local storage and synced to the paired Apple Watch.

### Option B: Environment Variables
For CI/CD or Xcode debugging schemes:
```bash
export OPENROUTER_API_KEY="your-openrouter-key"
export GEMINI_API_KEY="your-gemini-key"
```

> **Note:** If no API key is provided, BioSync seamlessly operates offline using its built-in sports-science heuristic engine without requiring an active internet connection or external API access.

---

## 4. Building & Running

### Requirements
- Xcode 15.0+ / 16.0+
- iOS 17.0+ deployment target
- watchOS 10.0+ deployment target
- Apple Developer Account (for HealthKit code signing entitlements)

### Build Targets
- **BioSync** (watchOS Scheme): Builds and deploys directly to Apple Watch.
- **BioSyncPhone** (iOS Scheme): Builds and deploys to iPhone.

```bash
# Build watchOS target
xcodebuild -project BioSync.xcodeproj -scheme BioSync -destination "generic/platform=watchOS" build

# Build iOS target
xcodebuild -project BioSync.xcodeproj -scheme BioSyncPhone -destination "generic/platform=iOS" build
```

---

## 5. License
MIT License.
