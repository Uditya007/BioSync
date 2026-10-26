<div align="center">

# ⚡ BioSync
### Open-Source Biometric Intelligence, Biological Age & Recovery for Apple Watch & iPhone

[![Platform](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20watchOS%2010%2B-black?style=flat-square&logo=apple)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square&logo=swift)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Zero Subscription](https://img.shields.io/badge/Pricing-100%25%20Free%20%26%20Open%20Source-green?style=flat-square)](#)
[![Privacy First](https://img.shields.io/badge/Privacy-100%25%20On--Device-brightgreen?style=flat-square)](#)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](CONTRIBUTING.md)

**BioSync is a privacy-first, zero-subscription alternative to WHOOP, Oura, and proprietary fitness trackers.**  
By unlocking the optical PPG sensors, accelerometer telemetry, and sleep stages of your Apple Watch and iPhone, BioSync gives you clinical-grade physiological analytics, real-time biological longevity calculations, and custom watch face complications — entirely for free.

[Key Features](#-key-features) • [The Science](#-the-science--algorithms) • [Architecture](#-project-architecture) • [Getting Started](#-getting-started) • [Contributing](#-contributing)

</div>

---

## 💡 Why BioSync?

Most commercial recovery monitors (WHOOP, Oura) charge **\$300+ every single year** through recurring paywalls while locking your health data in proprietary cloud silos. 

Your Apple Watch already has some of the most accurate optical biometric sensors in consumer tech. **BioSync unlocks them:**

* 🔓 **100% Free & Open Source**: No monthly subscriptions, in-app purchases, or paywalls ever.
* 🛡️ **Zero Cloud Dependency & Absolute Privacy**: All calculations (HRV baseline, strain, stress, longevity) run locally on-device via Apple HealthKit. Your health telemetry never leaves your device.
* ⌚ **Designed for Apple Watch SE 2, Series 7–10, and Ultra**: Engineered to extract high-accuracy recovery and stationary stress scores even without specialized hardware like wrist temperature or continuous ECG sensors.
* 🧬 **Biological Age Engine**: Continuous longevity scoring that reflects true biological health delta based on your past week's physiological trends.

---

## ✨ Key Features

### 1. 🧬 Biological Age & Longevity Analytics
* **BioSync Age Calculation**: Tracks chronological age vs. dynamic biological age using rolling 7-day health metrics.
* **Longevity Delta & Tier**: Quantifies your aging trajectory (e.g., `-1.6 yrs • Optimal Tier`) based on nocturnal autonomic recovery, daily step frequency, resting heart rate dips, and deep sleep ratios.
* **Driver Attribution**: Pinpoints the exact lifestyle variable driving your biological score.

### 2. ⚡ Autonomic Recovery & Strain (Pure Yellow & Green UI)
* **Daily Recovery Score (0–100%)**: Evaluates morning/nocturnal HRV (SDNN) and Resting Heart Rate against a personalized 14–30 day rolling baseline using statistical z-scores.
* **Momentary Stationary Stress (0–100)**: Real-time sympathetic nervous system tone detector. Uses accelerometer step filtering to ensure workout elevation isn't falsely marked as stress.
* **Color Hierarchy**: Pure minimalist OLED Black-and-White theme with **Recovery highlighted strictly in Yellow** (`#FAD138`) and **Stress highlighted strictly in Green** (`#40D973`).

### 3. 🌙 Clinical Sleep Architecture Breakdown
* **Native Apple Machine Learning Staging**: Directly processes `asleepDeep`, `asleepREM`, `asleepCore`, and `awake` phases from HealthKit.
* **Restorative Sleep Ratio**: Calculates the exact percentage of sleep spent in restorative phases (Deep + REM) to detect neurological fatigue.

### 4. ⌚ Apple Watch Face Complications & Smart Stack
Full ClockKit & WidgetKit integration supporting every Apple Watch face family:
* **Graphic Rectangular** (Modular, Modular Ultra): Live Biological Age, Longevity Delta, Recovery %, and Stress Zone.
* **Graphic Circular / Circular Small**: Recovery ring gauge with live age readout.
* **Graphic Corner & Graphic Bezel**: Curved corner percentage gauges for Infograph and California faces.
* **Utilitarian Large / Modular Large**: Glanceable text providers with instantaneous status.

### 5. 🤖 Dual-Provider AI Health Coach (Optional)
* **Local Sports-Science Heuristics**: Runs 100% offline with zero latency to analyze autonomic tone and box-breathing cues.
* **Bring-Your-Own-Key LLM**: Optional integration with OpenRouter or Google Gemini. Simply paste your API key in settings — keys are stored in encrypted local storage and never exposed.

---

## 🔬 The Science & Algorithms

### 1. Recovery Formulation (Z-Score Normalization)
$$Z_{\text{HRV}} = \frac{\text{HRV}_{\text{nocturnal}} - \mu_{\text{HRV}, 30d}}{\sigma_{\text{HRV}, 30d}}$$
$$Z_{\text{RHR}} = \frac{\text{RHR}_{\text{waking}} - \mu_{\text{RHR}, 30d}}{\sigma_{\text{RHR}, 30d}}$$
$$\text{Recovery} = 0.50 \cdot f(Z_{\text{HRV}}) + 0.35 \cdot f(-Z_{\text{RHR}}) + 0.15 \cdot \text{SleepEfficiency}$$

### 2. Stationary Stress Detection (Motion Filtering)
$$\text{Motion Filter} = \begin{cases} \text{Active Exercise (Excluded)}, & \text{if Steps}_{15m} \ge 60 \\ \text{Physiological Stress Evaluated}, & \text{if Steps}_{15m} < 60 \end{cases}$$

### 3. Biological Longevity Delta
$$\Delta_{\text{Age}} = -0.40 \cdot \Delta_{\text{Steps}} - 0.30 \cdot \Delta_{\text{HRV}} - 0.20 \cdot \Delta_{\text{Sleep}} + 0.10 \cdot \Delta_{\text{RHR}}$$

---

## 🏗️ Project Architecture

```
BioSync/
├── BioSync.xcodeproj/               # Multiplatform Xcode project (watchOS & iOS)
├── BioSync.entitlements            # HealthKit & background refresh capabilities
├── Sources/
│   ├── BioSyncApp.swift            # iOS App entrypoint & lifecycle
│   ├── App.swift                   # watchOS App entrypoint
│   ├── PhoneContentView.swift      # Modern iPhone telemetry dashboard & settings
│   ├── WatchContentView.swift      # 6-Page watchOS interface & optical PPG visualizer
│   ├── PhoneViewModel.swift        # iOS HealthKit aggregator & Combine pipeline
│   ├── WatchViewModel.swift        # watchOS Combine state manager & sensor subscriber
│   ├── BiometricEngine.swift       # Biological age, recovery, stress, and sleep algorithms
│   ├── HealthKitManager.swift      # HealthKit background delivery & query pipelines
│   ├── WatchConnectivityManager.swift # Bidirectional WatchConnectivity bridge
│   ├── GeminiAIService.swift       # Secure OpenRouter / Gemini client with offline heuristics
│   ├── AIService.swift             # Clinical prompt engineering & rules engine
│   ├── BackgroundManager.swift     # Periodic background task dispatcher
│   ├── BioSyncNotificationManager.swift # Smart actionable notifications
│   ├── Complications/
│   │   ├── ComplicationController.swift # ClockKit complication data source (all families)
│   │   └── BioSyncComplications.swift   # WidgetKit complication definitions
│   └── Assets.xcassets/            # App icons and vector branding
├── Config/
│   └── Info.plist.example          # Sample permissions & background mode declarations
├── Tests/
│   └── BiometricEngineTests.swift  # Automated validation test suite
├── Package.swift                   # Swift Package Manager manifest
├── CONTRIBUTING.md                 # Contribution guidelines
├── LICENSE                         # MIT License
└── README.md
```

---

## 🚀 Getting Started

Deploy BioSync to your own personal iPhone and Apple Watch in less than 3 minutes.

### Prerequisites
- Mac running macOS Sonoma or Sequoia
- [Xcode 15.0+](https://developer.apple.com/xcode/) installed
- iPhone running **iOS 17.0+**
- Apple Watch running **watchOS 10.0+**
- Free Apple ID / Apple Developer Account

### Installation Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Uditya007/BioSync.git
   cd BioSync
   ```

2. **Open in Xcode**:
   ```bash
   open BioSync.xcodeproj
   ```

3. **Configure Code Signing**:
   - In Xcode, select the **BioSync** project in the navigator.
   - For both **BioSync** (watchOS) and **BioSyncPhone** (iOS) targets:
     - Go to **Signing & Capabilities**.
     - Check **Automatically manage signing**.
     - Select your **Personal Team** from the Team dropdown.

4. **Build & Run**:
   - Connect your iPhone and Apple Watch via USB/Wi-Fi.
   - Select **BioSyncPhone** -> your iPhone and press `Cmd + R` to deploy the iOS app.
   - Select **BioSync** -> your Apple Watch and press `Cmd + R` to deploy the watch app.
   - On first launch, grant HealthKit permissions to start live tracking immediately!

---

## 🔒 Security & Privacy Statement

* **Zero Health Data Transmission**: HealthKit data stays on your personal device and is never sent to any remote server.
* **No Hardcoded Secrets**: The repository contains zero API keys or credentials.
* **Local Heuristic Guarantee**: BioSync functions 100% autonomously without requiring any external cloud services or network connectivity.

---

## 🤝 Contributing

Contributions are what make the open-source community thrive! Whether it's optimizing biological age models, improving watch face complications, or translating to other languages:

1. Fork the Project (`https://github.com/Uditya007/BioSync/fork`)
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

---

<div align="center">
  <b>Built with ❤️ for privacy, health sovereignty, and the open-source community.</b><br>
  <sub>If you find BioSync useful, please consider giving it a ⭐ on GitHub!</sub>
</div>
