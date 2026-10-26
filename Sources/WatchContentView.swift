#if os(watchOS)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct WatchContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    @State private var selectedTab: Int = 0
    @State private var isShowingSplash: Bool = true

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            // PAGE 1: Readiness Tri-Ring Dashboard
            DashboardPageView(viewModel: viewModel)
                .tag(0)

            // PAGE 2: BioSync Biological Age & Longevity Analysis
            BioSyncAgePageView(viewModel: viewModel)
                .tag(1)

            // PAGE 3: Live Vitals & Optical Sensor Scanner (Physical Green LEDs)
            LiveVitalsPageView(viewModel: viewModel)
                .tag(2)

            // PAGE 4: Deep Sleep Architecture & Stage Breakdown
            SleepDetailsPageView(viewModel: viewModel)
                .tag(3)

            // PAGE 5: Biometric Statistical Registry
            BiometricStatsPageView(viewModel: viewModel)
                .tag(4)

            // PAGE 6: AI Physiological Health Coach
            AICoachPageView(viewModel: viewModel)
                .tag(5)
        }
        #if os(watchOS) || os(iOS)
        .tabViewStyle(.page)
        #endif
        .overlay {
            if isShowingSplash {
                BioSyncSplashScreenView(isShowing: $isShowingSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            await viewModel.start()
        }
    }
}

// MARK: - PAGE 1: Dashboard
struct DashboardPageView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Top Brand & Live Status Row
                HStack(spacing: 6) {
                    BioSyncLogoImage()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                        )
                    Text("BIOSYNC")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                    Spacer()
                    if viewModel.isNotificationsAuthorized {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 7.5))
                            .foregroundStyle(.mint)
                    }
                    Circle()
                        .fill(viewModel.isSensorScanning ? Color.green : Color.cyan)
                        .frame(width: 5, height: 5)
                    Text(viewModel.isSensorScanning ? "LIVE" : "SYNCED")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 2)

                // Tri-Ring Metric Row
                HStack(spacing: 8) {
                    MetricRingView(
                        title: "REC",
                        value: "\(viewModel.recoveryScore)%",
                        progress: Double(viewModel.recoveryScore) / 100.0,
                        tintColor: recoveryColor(viewModel.recoveryScore)
                    )

                    MetricRingView(
                        title: "STRESS",
                        value: viewModel.stressScore.map { "\($0)" } ?? (viewModel.recentSteps >= 60 ? "ACTV" : "\(viewModel.lastStationaryStress)"),
                        progress: Double(viewModel.stressScore ?? (viewModel.recentSteps >= 60 ? 50 : viewModel.lastStationaryStress)) / 100.0,
                        tintColor: stressColor(viewModel.stressScore ?? (viewModel.recentSteps >= 60 ? nil : viewModel.lastStationaryStress))
                    )

                    MetricRingView(
                        title: "SLEEP",
                        value: "\(viewModel.sleepScore)%",
                        progress: Double(viewModel.sleepScore) / 100.0,
                        tintColor: Color.indigo
                    )
                }
                .padding(.top, 2)

                // BioSync Biological Age Summary Card
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Image(systemName: "dna")
                            .foregroundStyle(.mint)
                            .font(.system(size: 10, weight: .bold))
                        Text("BIOSYNC AGE")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.secondary)
                        Spacer()
                        let delta = viewModel.bioSyncAgeResult.ageDelta
                        let sign = viewModel.bioSyncAgeResult.isYounger ? "-" : "+"
                        Text("\(sign)\(String(format: "%.1f", abs(delta))) yrs")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(viewModel.bioSyncAgeResult.isYounger ? .green : .orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill((viewModel.bioSyncAgeResult.isYounger ? Color.green : Color.orange).opacity(0.18)))
                    }

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f", viewModel.bioSyncAgeResult.bioSyncAge))
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("years old")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.mint)
                        Spacer()
                        Text(String(format: "Cal: %.0fy", viewModel.bioSyncAgeResult.chronologicalAge))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(7)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))

                // Quick AI Summary Card
                VStack(alignment: .leading, spacing: 4) {
                    if let briefing = viewModel.aiBriefing {
                        Text(briefing.headline)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(briefing.trainingGuidance)
                            .font(.system(size: 9))
                            .foregroundStyle(.green)
                            .lineLimit(2)
                    }
                }
                .padding(7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))

                // Watch Face Complication & Widget Glance (Age, Stress, Recovery)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.8))
                        Text("WATCH FACE WIDGET")
                            .font(.system(size: 7.5, weight: .heavy))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1)
                        Spacer()
                        Text("LIVE")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 5) {
                        // BioSync Age
                        VStack(alignment: .leading, spacing: 1) {
                            Text("AGE")
                                .font(.system(size: 6.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            Text(String(format: "%.1fy", viewModel.bioSyncAgeResult.bioSyncAge))
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text(String(format: "%@%.1fy", viewModel.bioSyncAgeResult.isYounger ? "-" : "+", abs(viewModel.bioSyncAgeResult.ageDelta)))
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundColor(viewModel.bioSyncAgeResult.isYounger ? .mint : .orange)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)

                        // Stress (Green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("STRESS")
                                .font(.system(size: 6.5, weight: .bold))
                                .foregroundColor(stressColor(viewModel.stressScore))
                            Text(viewModel.stressScore.map { "\($0)" } ?? "ACTV")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(stressColor(viewModel.stressScore))
                            Text(viewModel.stressZone.rawValue)
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundColor(stressColor(viewModel.stressScore).opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                        .background(stressColor(viewModel.stressScore).opacity(0.12))
                        .cornerRadius(6)

                        // Recovery (Yellow)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("RECV")
                                .font(.system(size: 6.5, weight: .bold))
                                .foregroundColor(recoveryColor(viewModel.recoveryScore))
                            Text("\(viewModel.recoveryScore)%")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(recoveryColor(viewModel.recoveryScore))
                            Text(viewModel.recoveryScore >= 67 ? "PRIMED" : (viewModel.recoveryScore >= 34 ? "BAL" : "REST"))
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundColor(recoveryColor(viewModel.recoveryScore).opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                        .background(recoveryColor(viewModel.recoveryScore).opacity(0.15))
                        .cornerRadius(6)
                    }

                    Text("Long-press watch face → Edit → Complications → Choose BioSync to display on your face.")
                        .font(.system(size: 7))
                        .foregroundColor(.white.opacity(0.55))
                        .lineSpacing(1.1)
                }
                .padding(7)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )

                Text("Swipe left for BioSync Age →")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
        }
    }
}

func recoveryColor(_ score: Int) -> Color {
    return Color(red: 0.98, green: 0.82, blue: 0.22) // Yellow
}

func stressColor(_ score: Int?) -> Color {
    return Color(red: 0.25, green: 0.85, blue: 0.45) // Green
}

// MARK: - PAGE 2: BioSync Biological Age & Longevity
struct BioSyncAgePageView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "dna")
                        .foregroundStyle(.mint)
                        .font(.system(size: 13, weight: .bold))
                    Text("BioSync Age")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Spacer()
                    let delta = viewModel.bioSyncAgeResult.ageDelta
                    let sign = viewModel.bioSyncAgeResult.isYounger ? "-" : "+"
                    Text("\(sign)\(String(format: "%.1f", abs(delta)))y")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(viewModel.bioSyncAgeResult.isYounger ? .green : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill((viewModel.bioSyncAgeResult.isYounger ? Color.green : Color.orange).opacity(0.18)))
                }

                // Big Hero Biological Age Box
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", viewModel.bioSyncAgeResult.bioSyncAge))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.mint, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Biological Longevity Age")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Text(String(format: "Calendar: %.0f yrs", viewModel.bioSyncAgeResult.chronologicalAge))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(viewModel.bioSyncAgeResult.isYounger ? "Youthful Vitality" : "Fatigued")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(viewModel.bioSyncAgeResult.isYounger ? .green : .orange)
                    }
                    .padding(.top, 1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))

                // Longevity Tier Badge
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 10))
                    Text(viewModel.bioSyncAgeResult.longevityTier)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.10)))

                // Primary Longevity Driver
                VStack(alignment: .leading, spacing: 2) {
                    Text("PRIMARY DRIVER")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(.mint)
                    Text(viewModel.bioSyncAgeResult.primaryDriver)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.mint.opacity(0.12)))

                // 7-Day Calibration Header
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 8))
                        .foregroundStyle(.cyan)
                    Text("PAST WEEK (7D) CALIBRATION")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(.cyan)
                    Spacer()
                }
                .padding(.top, 1)

                // 4 Factors Breakdown
                VStack(spacing: 4) {
                    let rhrDisplay = viewModel.pastWeekRHR > 0 ? "\(Int(viewModel.pastWeekRHR)) bpm (7D)" : (viewModel.restingHeartRate > 0 ? "\(Int(viewModel.restingHeartRate)) bpm" : "\(Int(viewModel.baselineRHR)) bpm")
                    AgeFactorRow(
                        title: "Cardio (RHR)",
                        value: rhrDisplay,
                        modifier: viewModel.bioSyncAgeResult.rhrYearsModifier,
                        tint: .red
                    )
                    let hrvDisplay = viewModel.pastWeekHRV > 0 ? "\(Int(viewModel.pastWeekHRV)) ms (7D)" : (viewModel.latestHRV > 0 ? "\(Int(viewModel.latestHRV)) ms" : "\(Int(viewModel.baselineHRV)) ms")
                    AgeFactorRow(
                        title: "Vagal Tone (HRV)",
                        value: hrvDisplay,
                        modifier: viewModel.bioSyncAgeResult.hrvYearsModifier,
                        tint: .cyan
                    )
                    let sleepDisplay = viewModel.pastWeekSleepScore > 0 ? "\(Int(viewModel.pastWeekSleepScore))% (\(String(format: "%.1fh", viewModel.pastWeekSleepHours)))" : "\(viewModel.sleepScore)%"
                    AgeFactorRow(
                        title: "Sleep (7D)",
                        value: sleepDisplay,
                        modifier: viewModel.bioSyncAgeResult.sleepYearsModifier,
                        tint: .indigo
                    )
                    let stepDisplay = viewModel.pastWeekSteps > 0 ? "\(Int(viewModel.pastWeekSteps)) stp/d" : "\(Int(viewModel.todaySteps)) stp"
                    AgeFactorRow(
                        title: "Activity / Steps",
                        value: stepDisplay,
                        modifier: viewModel.bioSyncAgeResult.activityYearsModifier,
                        tint: .green
                    )
                }
            }
            .padding(.horizontal, 6)
        }
    }
}

struct AgeFactorRow: View {
    let title: String
    let value: String
    let modifier: Double
    let tint: Color

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Circle().fill(tint).frame(width: 5, height: 5)
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white)
            }
            Spacer()
            Text(value)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
            let sign = modifier <= 0 ? "-" : "+"
            Text("\(sign)\(String(format: "%.1f", abs(modifier)))y")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(modifier <= 0 ? .green : .orange)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
    }
}

// MARK: - PAGE 3: Live Vitals & Optical Sensor Scanner
struct LiveVitalsPageView: View {
    @ObservedObject var viewModel: WatchViewModel
    @State private var isPulsing: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Heart Pulse Hero
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.red)
                        .scaleEffect(isPulsing ? 1.25 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)
                        .onAppear { isPulsing = true }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.liveHeartRate > 0 ? "\(Int(viewModel.liveHeartRate))" : "--")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("BPM LIVE PULSE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                // Physical Sensor Scan Button
                Button(action: {
                    viewModel.toggleLiveSensorScan()
                }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.isSensorScanning ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(viewModel.isSensorScanning ? "Scanning (Green LEDs On)" : "Start Real-Time Scan")
                            .font(.system(size: 11, weight: .bold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isSensorScanning ? .green : .red.opacity(0.8))

                // Real Biometrics Grid
                VStack(spacing: 6) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("HRV (SDNN)")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text(viewModel.latestHRV > 0 ? "\(Int(viewModel.latestHRV)) ms" : "50 ms")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.cyan)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("30D Baseline")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text("\(Int(viewModel.baselineHRV)) ms")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Resting Heart Rate")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text(viewModel.restingHeartRate > 0 ? "\(Int(viewModel.restingHeartRate)) bpm" : "60 bpm")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Today's Steps")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text("\(Int(viewModel.todaySteps))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Autonomic Stress")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            HStack(spacing: 3) {
                                Text(viewModel.stressScore.map { "\($0)" } ?? (viewModel.recentSteps >= 60 ? "Active" : "\(viewModel.lastStationaryStress)"))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(stressColor(viewModel.stressScore))
                                Text("• \(viewModel.stressZone.rawValue)")
                                    .font(.system(size: 8.5, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("15m Steps")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text("\(Int(viewModel.recentSteps))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.recentSteps >= 60 ? .green : .secondary)
                        }
                    }
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                }
            }
            .padding(.horizontal, 6)
        }
    }
}

// MARK: - PAGE 3: Sleep Architecture
struct SleepDetailsPageView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(.indigo)
                    Text("Sleep Analysis")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Spacer()
                    Text("\(viewModel.sleepScore)%")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.indigo)
                }

                if let sleep = viewModel.sleepData {
                    Text(String(format: "%.1f Hours Total Sleep", sleep.totalHours))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    // Deep Sleep
                    SleepStageBar(
                        stage: "Deep (Physical Repair)",
                        hours: sleep.deepHours,
                        percentage: sleep.deepPercentage,
                        tint: .blue
                    )

                    // REM Sleep
                    SleepStageBar(
                        stage: "REM (Mental Repair)",
                        hours: sleep.remHours,
                        percentage: sleep.remPercentage,
                        tint: .purple
                    )

                    // Core Sleep
                    SleepStageBar(
                        stage: "Core Sleep",
                        hours: sleep.coreHours,
                        percentage: sleep.corePercentage,
                        tint: .cyan
                    )

                    // Awake Time
                    SleepStageBar(
                        stage: "Awake / Restless",
                        hours: sleep.awakeHours,
                        percentage: Int(round((sleep.awakeSeconds / max(1, sleep.totalSleepSeconds + sleep.awakeSeconds)) * 100)),
                        tint: .orange
                    )
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Sleep Logged Yet")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Wear your Apple Watch to bed tonight. BioSync will automatically record your Deep, REM, and Core sleep stages.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                }
            }
            .padding(.horizontal, 6)
        }
    }
}

struct SleepStageBar: View {
    let stage: String
    let hours: Double
    let percentage: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(stage)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1fh (%d%%)", hours, percentage))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(tint)
                        .frame(width: geo.size.width * CGFloat(min(1.0, max(0.05, Double(percentage) / 100.0))), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - PAGE 5: AI Coach
struct AICoachPageView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.cyan)
                    Text("AI Longevity Coach")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Spacer()
                    Text("AI Cloud")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.cyan.opacity(0.18)))
                }

                // BioSync Longevity Pill
                HStack(spacing: 4) {
                    Image(systemName: "dna")
                        .foregroundStyle(.mint)
                        .font(.system(size: 9, weight: .bold))
                    Text("BioSync Age: \(String(format: "%.1fy", viewModel.bioSyncAgeResult.bioSyncAge)) (\(viewModel.bioSyncAgeResult.isYounger ? "-" : "+")\(String(format: "%.1fy", abs(viewModel.bioSyncAgeResult.ageDelta))))")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.bioSyncAgeResult.isYounger ? .green : .orange)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.white.opacity(0.08)))

                if let briefing = viewModel.aiBriefing {
                    // Headline
                    Text(briefing.headline)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 2)

                    // 1. Biological Age & Longevity Diagnosis
                    CoachCard(
                        icon: "dna",
                        title: "BIOLOGICAL AGE & LONGEVITY",
                        text: briefing.biologicalAgeAnalysis,
                        tint: .mint
                    )

                    // 2. 30-Day Overall Progress & Adaptation
                    CoachCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "OVERALL PROGRESS & 30D TREND",
                        text: briefing.overallProgress,
                        tint: .cyan
                    )

                    // 3. Cardiovascular Efficiency
                    CoachCard(
                        icon: "heart.fill",
                        title: "CARDIOVASCULAR HEALTH",
                        text: briefing.cardiovascularStatus,
                        tint: .red
                    )

                    // 4. Autonomic Nervous System & Vagal Tone
                    CoachCard(
                        icon: "bolt.fill",
                        title: "NERVOUS SYSTEM & HRV",
                        text: briefing.nervousSystemStatus,
                        tint: .purple
                    )

                    // 5. Training Strain Recommendation
                    CoachCard(
                        icon: "figure.run",
                        title: "STRAIN TARGET & ACTIVITY",
                        text: briefing.trainingGuidance,
                        tint: .green
                    )

                    // 6. Sleep Architecture & Tissue Repair
                    CoachCard(
                        icon: "moon.stars.fill",
                        title: "SLEEP & CELLULAR REPAIR",
                        text: briefing.sleepArchitectureInsight,
                        tint: .indigo
                    )

                    // 7. Stress Mitigation Cue
                    if let intervention = briefing.stressIntervention {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "wind")
                                .foregroundStyle(.orange)
                                .font(.system(size: 10))
                            Text(intervention)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.orange)
                        }
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.12)))
                    }
                }

                Button(action: {
                    Task { await viewModel.triggerManualRefresh() }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-Calibrate All")
                    }
                    .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
                .padding(.top, 4)

                // Hourly Background & Notification Controls
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.mint)
                            .font(.system(size: 10, weight: .bold))
                        Text("HOURLY AI BRIEFINGS")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Circle()
                            .fill(viewModel.isNotificationsAuthorized ? Color.green : Color.orange)
                            .frame(width: 5, height: 5)
                        Text(viewModel.isNotificationsAuthorized ? "ON" : "OFF")
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(viewModel.isNotificationsAuthorized ? .green : .orange)
                    }

                    Text("Apple Health background sync runs every 1 hour to re-compute biometrics & deliver your longevity coach summary.")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.cyan)
                        Text("Active Schedule: \(max(1, viewModel.pendingAlertsCount)) hourly alerts queued")
                            .font(.system(size: 7.5, weight: .semibold))
                            .foregroundStyle(.cyan)
                    }

                    HStack(spacing: 4) {
                        Button(action: {
                            Task {
                                await viewModel.sendTestNotification(delaySeconds: 1.0)
                            }
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "bell.fill")
                                Text("Now")
                            }
                            .font(.system(size: 8.5, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.mint)

                        Button(action: {
                            Task {
                                await viewModel.sendTestNotification(delaySeconds: 10.0)
                            }
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up.right.video")
                                Text("In 10s (Exit)")
                            }
                            .font(.system(size: 8.5, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.cyan)

                        if !viewModel.isNotificationsAuthorized {
                            Button(action: {
                                Task {
                                    await viewModel.requestNotificationPermission()
                                }
                            }) {
                                Text("Enable")
                                    .font(.system(size: 8.5, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                        }
                    }
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
            }
            .padding(.horizontal, 6)
        }
    }
}

// MARK: - PAGE 5: Biometric Statistical Registry
struct BiometricStatsPageView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundStyle(.white)
                        .font(.system(size: 12, weight: .bold))
                    Text("Biometric Stats")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text("7D & 30D")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                // 1. Recovery & Readiness (Yellow)
                watchStatsSection(
                    title: "RECOVERY & READINESS",
                    icon: "bolt.heart.fill",
                    tint: Color(red: 0.98, green: 0.82, blue: 0.22),
                    items: [
                        ("Today's Score", "\(viewModel.recoveryScore)%"),
                        ("7D Moving Avg", "\(viewModel.pastWeekRecoveryScore)%"),
                        ("Readiness State", viewModel.recoveryScore >= 67 ? "PRIMED" : (viewModel.recoveryScore >= 34 ? "BALANCED" : "STRAINED"))
                    ]
                )

                // 2. Autonomic Stress (Green)
                watchStatsSection(
                    title: "AUTONOMIC STRESS",
                    icon: "waveform.path.badge.plus",
                    tint: Color(red: 0.25, green: 0.85, blue: 0.45),
                    items: [
                        ("Current Stress", viewModel.stressScore.map { "\($0) / 100" } ?? (viewModel.recentSteps >= 60 ? "In Motion" : "\(viewModel.lastStationaryStress)/100")),
                        ("Stress Zone", viewModel.stressZone.rawValue),
                        ("15m Movement", "\(Int(viewModel.recentSteps)) steps")
                    ]
                )

                // 3. Cardiovascular & Heart Rate (White)
                watchStatsSection(
                    title: "HEART RATE & VITALS",
                    icon: "heart.fill",
                    tint: .white,
                    items: [
                        ("Today's Range", viewModel.minHeartRateToday > 0 ? "\(Int(viewModel.minHeartRateToday))-\(Int(viewModel.maxHeartRateToday)) bpm" : "\(Int(viewModel.liveHeartRate)) bpm"),
                        ("Resting HR Today", "\(Int(viewModel.restingHeartRate)) bpm"),
                        ("7D Avg RHR", "\(Int(viewModel.pastWeekRHR)) bpm"),
                        ("7D RHR Range", "\(Int(viewModel.pastWeekMinRHR)) - \(Int(viewModel.pastWeekMaxRHR)) bpm"),
                        ("30D Base RHR", "\(Int(viewModel.baselineRHR)) bpm")
                    ]
                )

                // 4. Nocturnal HRV (White)
                watchStatsSection(
                    title: "NOCTURNAL HRV (SDNN)",
                    icon: "waveform.path.ecg",
                    tint: .white,
                    items: [
                        ("Latest SDNN", "\(Int(viewModel.latestHRV)) ms"),
                        ("7D Avg HRV", "\(Int(viewModel.pastWeekHRV)) ms"),
                        ("7D HRV Range", "\(Int(viewModel.pastWeekMinHRV)) - \(Int(viewModel.pastWeekMaxHRV)) ms"),
                        ("30D Base HRV", "\(Int(viewModel.baselineHRV)) ms")
                    ]
                )

                // 5. Sleep Architecture (Indigo/Purple/Cyan)
                watchStatsSection(
                    title: "SLEEP ARCHITECTURE",
                    icon: "moon.stars.fill",
                    tint: .indigo,
                    items: [
                        ("Last Night", viewModel.sleepData != nil ? String(format: "%.1fh (%d%%)", viewModel.sleepData!.totalHours, viewModel.sleepScore) : "--"),
                        ("7D Avg Sleep", String(format: "%.1fh (%d%%)", viewModel.pastWeekSleepHours, Int(viewModel.pastWeekSleepScore))),
                        ("7D Restorative", "Deep \(viewModel.pastWeekDeepPercentage)% • REM \(viewModel.pastWeekRemPercentage)%"),
                        ("7D Efficiency", "\(viewModel.pastWeekSleepEfficiency)% in bed")
                    ]
                )

                // 6. Movement & Volume (White)
                watchStatsSection(
                    title: "MOVEMENT & VOLUME",
                    icon: "figure.walk",
                    tint: .white,
                    items: [
                        ("Today's Steps", "\(Int(viewModel.todaySteps))"),
                        ("7D Daily Avg", "\(Int(viewModel.pastWeekSteps)) /day"),
                        ("7D Total Steps", "\(Int(viewModel.pastWeekTotalSteps))"),
                        ("7D Total Dist", String(format: "%.1f km", viewModel.pastWeekTotalDistanceKm)),
                        ("7D Active Cal", "\(Int(viewModel.pastWeekTotalActiveCalories)) kcal")
                    ]
                )

                // 7. Biological Longevity (White)
                watchStatsSection(
                    title: "LONGEVITY AGE",
                    icon: "flame.fill",
                    tint: .white,
                    items: [
                        ("BioSync Age", String(format: "%.1f yrs", viewModel.bioSyncAgeResult.bioSyncAge)),
                        ("Calendar Age", String(format: "%.0f yrs", viewModel.bioSyncAgeResult.chronologicalAge)),
                        ("Net Delta", String(format: "%@%.1f yrs", viewModel.bioSyncAgeResult.isYounger ? "-" : "+", abs(viewModel.bioSyncAgeResult.ageDelta)))
                    ]
                )
            }
            .padding(.horizontal, 6)
        }
    }

    private func watchStatsSection(title: String, icon: String, tint: Color, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.system(size: 8, weight: .bold))
                Text(title)
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundStyle(tint)
            }

            VStack(spacing: 2) {
                ForEach(items, id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text(item.1)
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
    }
}

struct CoachCard: View {
    let icon: String
    let title: String
    let text: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.system(size: 8, weight: .bold))
                Text(title)
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(tint)
            }
            Text(text)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
    }
}

// MARK: - Micro Circular Ring Widget
struct MetricRingView: View {
    let title: String
    let value: String
    let progress: Double
    let tintColor: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(tintColor.opacity(0.2), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, max(0.05, progress))))
                    .stroke(tintColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 48, height: 48)

            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Logo Image Component
struct BioSyncLogoImage: View {
    var body: some View {
        Group {
            #if canImport(UIKit)
            if let uiImg = UIImage(named: "AppLogo") {
                Image(uiImage: uiImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                defaultVectorLogo
            }
            #else
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            #endif
        }
    }

    private var defaultVectorLogo: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: max(3, size * 0.22), style: .continuous)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: max(3, size * 0.22), style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: max(0.8, size * 0.05))
                    )
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: max(8, size * 0.55), weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - App Startup / Splash Screen View
public struct BioSyncSplashScreenView: View {
    @Binding var isShowing: Bool

    @State private var logoScale: CGFloat = 0.78
    @State private var logoOpacity: Double = 0.0
    @State private var ringRotation: Double = 0.0
    @State private var pulseGlow: Bool = false
    @State private var statusStep: Int = 0

    private let statusMessages = [
        "INITIALIZING SENSORS",
        "CONNECTING TO PPG",
        "SYNCING HEALTHKIT",
        "AI ENGINE READY"
    ]

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                Spacer()

                // Animated Logo Container
                ZStack {
                    // Outer neon glowing aura
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.95),
                                    Color.mint.opacity(0.85),
                                    Color.cyan.opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(ringRotation))
                        .blur(radius: pulseGlow ? 3 : 1)

                    // Core Circular Logo
                    BioSyncLogoImage()
                        .frame(width: 82, height: 82)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: .cyan.opacity(pulseGlow ? 0.45 : 0.2), radius: 8)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App Branding & Animated Status
                VStack(spacing: 3) {
                    Text("B I O S Y N C")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusStep == 3 ? Color.green : Color.cyan)
                            .frame(width: 5, height: 5)
                            .scaleEffect(pulseGlow ? 1.3 : 0.8)

                        Text(statusMessages[min(statusStep, statusMessages.count - 1)])
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(statusStep == 3 ? .green : .cyan.opacity(0.85))
                    }
                    .padding(.top, 2)
                }
                .opacity(logoOpacity)

                Spacer()

                // Tap to skip hint
                Text("TAP TO ENTER")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .padding(.bottom, 2)
            }
            .padding(.horizontal)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissSplash()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }

            Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                await MainActor.run { statusStep = 1 }
                try? await Task.sleep(nanoseconds: 450_000_000)
                await MainActor.run { statusStep = 2 }
                try? await Task.sleep(nanoseconds: 450_000_000)
                await MainActor.run { statusStep = 3 }
                try? await Task.sleep(nanoseconds: 450_000_000)
                await MainActor.run {
                    dismissSplash()
                }
            }
        }
    }

    private func dismissSplash() {
        guard isShowing else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            isShowing = false
        }
    }
}

#Preview {
    WatchContentView()
}
#endif
