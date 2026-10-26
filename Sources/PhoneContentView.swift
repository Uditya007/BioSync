#if os(iOS)
import SwiftUI

public struct PhoneContentView: View {
    @StateObject private var viewModel = PhoneViewModel()
    @State private var showingSettingsSheet: Bool = false
    @State private var showingStatsSheet: Bool = false
    @State private var testNotificationScheduled: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background: Pure Black Aesthetic
                Color.black
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Top Header & Watch Status Pill
                        headerBar

                        // Hero Section: BioSync Biological Age (Past Week 7D Calibration)
                        bioSyncAgeCard

                        // Core Daily Metrics: Recovery Ring, Autonomic Stress, Sleep Architecture
                        coreMetricsRow

                        // Sleep Stage Breakdown
                        sleepBreakdownCard

                        // Comprehensive Statistical Telemetry (All The Things)
                        comprehensiveStatsCard

                        // AI Health Intelligence & Longevity Protocol
                        aiIntelligenceCard

                        // Apple Watch Companion Bridge OR Standalone iPhone Motion Sensors
                        if viewModel.isWatchPaired {
                            watchCompanionCard
                        } else {
                            phoneMotionSensorsCard
                        }

                        // Footer
                        footerInfo
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
                .refreshable {
                    await viewModel.refreshAllData()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettingsSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 26, height: 26)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                                )

                            Text("BIOSYNC")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingStatsSheet = true
                        } label: {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }

                        Button {
                            Task {
                                await viewModel.refreshAllData()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                PhoneSettingsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingStatsSheet) {
                BiometricStatisticsHubSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header Bar & Watch Connectivity Pill
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Health Intelligence")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .textCase(.uppercase)
                    .tracking(1.2)
                Text("Longitudinal Analytics")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            // Status Pill (Watch Active/Paired vs iPhone Health Local)
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
                Image(systemName: viewModel.isWatchPaired ? "applewatch" : "iphone.gen3")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(viewModel.isWatchPaired ? (viewModel.isWatchReachable ? "Active" : "Paired") : "iPhone Health")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            )
        }
    }

    // MARK: - Hero Biological Age Card
    private var bioSyncAgeCard: some View {
        let ageRes = viewModel.bioSyncAgeResult
        let bioAge = ageRes?.bioSyncAge ?? viewModel.chronologicalAge
        let chrono = viewModel.chronologicalAge
        let delta = ageRes?.ageDelta ?? 0.0

        return VStack(spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    Text("BIOSYNC BIOLOGICAL AGE")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .tracking(1.5)
                }

                Spacer()

                Text("PAST WEEK (7D) CALIBRATION")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
            }

            // Big Numbers Row
            HStack(alignment: .lastTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f", bioAge))
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Biological Years")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    // Delta badge
                    HStack(spacing: 4) {
                        Image(systemName: delta <= 0 ? "arrow.down.right" : "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                        Text(String(format: "%@%.1f YRS", delta <= 0 ? "" : "+", delta))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())

                    Text("Chronological: \(String(format: "%.0f", chrono)) yrs")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Divider()
                .background(Color.white.opacity(0.12))

            // 7D Factor Grid
            VStack(spacing: 10) {
                factorRow(
                    title: "7D Resting Heart Rate",
                    value: viewModel.hasRestingHRData
                        ? (viewModel.pastWeekAverageRHR > 0 ? "\(Int(viewModel.pastWeekAverageRHR)) bpm" : "\(Int(viewModel.restingHeartRate)) bpm")
                        : "No Watch Synced",
                    impact: viewModel.hasRestingHRData ? ageRes?.rhrYearsModifier : nil,
                    icon: "heart.fill",
                    color: .white.opacity(0.85)
                )

                factorRow(
                    title: "7D Nocturnal HRV (SDNN)",
                    value: viewModel.hasHRVData
                        ? (viewModel.pastWeekAverageHRV > 0 ? "\(Int(viewModel.pastWeekAverageHRV)) ms" : "\(Int(viewModel.latestHRV)) ms")
                        : "No Watch Synced",
                    impact: viewModel.hasHRVData ? ageRes?.hrvYearsModifier : nil,
                    icon: "waveform.path.ecg",
                    color: .white.opacity(0.85)
                )

                factorRow(
                    title: "7D Sleep Quality & Hours",
                    value: (viewModel.hasSleepData || viewModel.pastWeekAverageSleepHours > 0)
                        ? (viewModel.pastWeekAverageSleepHours > 0 ? String(format: "%.1fh (%d%%)", viewModel.pastWeekAverageSleepHours, Int(viewModel.pastWeekAverageSleepScore)) : "\(viewModel.sleepScore)%")
                        : "No Sleep Logged",
                    impact: (viewModel.hasSleepData || viewModel.pastWeekAverageSleepHours > 0) ? ageRes?.sleepYearsModifier : nil,
                    icon: "moon.fill",
                    color: .indigo // sleep as it is
                )

                factorRow(
                    title: "7D Daily Volume (Steps)",
                    value: viewModel.pastWeekAverageDailySteps > 0
                        ? "\(Int(viewModel.pastWeekAverageDailySteps)) /day"
                        : (viewModel.todaySteps > 0 ? "\(Int(viewModel.todaySteps)) today" : "0 steps"),
                    impact: ageRes?.activityYearsModifier,
                    icon: "figure.walk",
                    color: .white.opacity(0.85)
                )
            }

            if !viewModel.hasRestingHRData && !viewModel.hasHRVData {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Calculated strictly from \(UIDevice.current.name)'s local motion & step data")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func factorRow(title: String, value: String, impact: Double?, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let imp = impact {
                Text(String(format: "%@%.1fy", imp <= 0 ? "" : "+", imp))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 48, alignment: .trailing)
            } else {
                Text("0.0y")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 48, alignment: .trailing)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Core Metrics Row: Recovery Ring & Autonomic Stress
    private var coreMetricsRow: some View {
        HStack(spacing: 14) {
            // Recovery Score Ring Card (YELLOW)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bolt.heart.fill")
                        .foregroundColor(recoveryColor)
                    Text("RECOVERY")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                }

                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 10)
                            .frame(width: 86, height: 86)

                        Circle()
                            .trim(from: 0.0, to: CGFloat(viewModel.recoveryScore) / 100.0)
                            .stroke(
                                recoveryColor,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 86, height: 86)
                            .animation(.easeOut(duration: 0.8), value: viewModel.recoveryScore)

                        VStack(spacing: 0) {
                            Text("\(viewModel.recoveryScore)%")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }

                HStack {
                    Spacer()
                    Text(recoveryStatus)
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(recoveryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(recoveryColor.opacity(0.18))
                        .clipShape(Capsule())
                    Spacer()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )

            // Autonomic Stress Card (GREEN)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "waveform.path.badge.plus")
                        .foregroundColor(stressColor)
                    Text("STRESS")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                }

                HStack {
                    Spacer()
                    if let stress = viewModel.stressScore {
                        VStack(spacing: 2) {
                            Text("\(stress)")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(stressColor)
                            Text("/ 100")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    } else if viewModel.hasHeartRateData {
                        VStack(spacing: 4) {
                            Text("ACTV")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(stressColor)
                            Text("In Motion")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(stressColor.opacity(0.8))
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("--")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                            Text("No Watch")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    Spacer()
                }

                HStack {
                    Spacer()
                    Text(viewModel.hasHeartRateData ? stressLabel : "OPTICAL PPG REQ")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(viewModel.hasHeartRateData ? stressColor : .white.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((viewModel.hasHeartRateData ? stressColor : Color.white.opacity(0.5)).opacity(0.18))
                        .clipShape(Capsule())
                    Spacer()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
    }

    private var recoveryColor: Color {
        return Color(red: 0.98, green: 0.82, blue: 0.22) // Yellow
    }

    private var recoveryStatus: String {
        if viewModel.recoveryScore >= 67 { return "PRIMED" }
        if viewModel.recoveryScore >= 34 { return "BALANCED" }
        return "STRAINED"
    }

    private var stressColor: Color {
        return Color(red: 0.25, green: 0.85, blue: 0.45) // Green
    }

    private var stressLabel: String {
        guard let s = viewModel.stressScore else { return "ACTIVE" }
        if s < 30 { return "RESTORED" }
        if s < 60 { return "CALM" }
        if s < 80 { return "MODERATE" }
        return "HIGH STRESS"
    }

    // MARK: - Sleep Architecture Breakdown Card
    private var sleepBreakdownCard: some View {
        let sleep = viewModel.sleepData
        let totalHrs = sleep?.totalHours ?? viewModel.pastWeekAverageSleepHours
        let deepPct = sleep?.deepPercentage ?? 18
        let remPct = sleep?.remPercentage ?? 22
        let corePct = sleep?.corePercentage ?? 54

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.indigo)
                    Text("SLEEP ARCHITECTURE")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.indigo)
                        .tracking(1.2)
                }

                Spacer()

                Text(totalHrs > 0 ? String(format: "%.1f Hours Total", totalHrs) : "7.5 Hours Avg")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Sleep Stage Stacked Bar
            GeometryReader { geo in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.purple)
                        .frame(width: geo.size.width * CGFloat(deepPct) / 100.0)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cyan)
                        .frame(width: geo.size.width * CGFloat(remPct) / 100.0)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: max(0, geo.size.width * CGFloat(corePct) / 100.0 - 6))
                }
            }
            .frame(height: 12)

            // Legend
            HStack(spacing: 16) {
                stageBadge(title: "Deep", percent: deepPct, color: .purple)
                stageBadge(title: "REM", percent: remPct, color: .cyan)
                stageBadge(title: "Core", percent: corePct, color: .blue)
                Spacer()
                Text("Score: \(viewModel.sleepScore)%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func stageBadge(title: String, percent: Int, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(title) \(percent)%")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Comprehensive Statistical Telemetry Card (All The Things)
    private var comprehensiveStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.white)
                    Text("STATISTICAL BIOMETRIC TELEMETRY")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .tracking(1.2)
                }

                Spacer()

                Button {
                    showingStatsSheet = true
                } label: {
                    HStack(spacing: 3) {
                        Text("Hub")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            Text("7-Day Longitudinal Moving Averages • 30-Day Baselines • Min/Max Extremes")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            // 6-Tile High-Density Statistical Comparison Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                // 1. Recovery Score (Yellow)
                statTile(
                    title: "RECOVERY CAPACITY",
                    icon: "bolt.heart.fill",
                    accentColor: recoveryColor,
                    primaryLabel: "Today",
                    primaryVal: "\(viewModel.recoveryScore)%",
                    secondaryLabel: "7D Moving Avg",
                    secondaryVal: "\(Int(viewModel.pastWeekAverageRecoveryScore))%",
                    extraDetail: viewModel.recoveryStatus
                )

                // 2. Autonomic Stress (Green)
                statTile(
                    title: "AUTONOMIC STRESS",
                    icon: "waveform.path.badge.plus",
                    accentColor: stressColor,
                    primaryLabel: "Momentary",
                    primaryVal: viewModel.stressScore != nil ? "\(viewModel.stressScore!)" : (viewModel.hasHeartRateData ? "ACTV" : "--"),
                    secondaryLabel: "Autonomic Zone",
                    secondaryVal: viewModel.hasHeartRateData ? viewModel.stressZone.rawValue : "PPG Req",
                    extraDetail: "\(Int(viewModel.recentSteps)) steps / 15m"
                )

                // 3. Resting Heart Rate
                statTile(
                    title: "RESTING HEART RATE",
                    icon: "heart.fill",
                    accentColor: .white,
                    primaryLabel: "Today's RHR",
                    primaryVal: viewModel.hasRestingHRData ? "\(Int(viewModel.restingHeartRate)) bpm" : "No Watch",
                    secondaryLabel: "7D Avg • 30D Base",
                    secondaryVal: viewModel.pastWeekAverageRHR > 0 ? "\(Int(viewModel.pastWeekAverageRHR)) • \(Int(viewModel.baselineRHR))" : "--",
                    extraDetail: viewModel.pastWeekMinRHR > 0 ? "7D: \(Int(viewModel.pastWeekMinRHR)) - \(Int(viewModel.pastWeekMaxRHR)) bpm" : nil
                )

                // 4. Nocturnal HRV (SDNN)
                statTile(
                    title: "NOCTURNAL HRV",
                    icon: "waveform.path.ecg",
                    accentColor: .white,
                    primaryLabel: "Latest SDNN",
                    primaryVal: viewModel.hasHRVData ? "\(Int(viewModel.latestHRV)) ms" : "No Watch",
                    secondaryLabel: "7D Avg • 30D Base",
                    secondaryVal: viewModel.pastWeekAverageHRV > 0 ? "\(Int(viewModel.pastWeekAverageHRV)) • \(Int(viewModel.baselineHRV))" : "--",
                    extraDetail: viewModel.pastWeekMinHRV > 0 ? "7D: \(Int(viewModel.pastWeekMinHRV)) - \(Int(viewModel.pastWeekMaxHRV)) ms" : nil
                )

                // 5. Sleep Architecture (Indigo)
                statTile(
                    title: "SLEEP DURATION & SCORE",
                    icon: "moon.fill",
                    accentColor: .indigo,
                    primaryLabel: "Last Night",
                    primaryVal: viewModel.sleepData != nil ? String(format: "%.1fh (%d%%)", viewModel.sleepData!.totalHours, viewModel.sleepScore) : "--",
                    secondaryLabel: "7D Avg Duration",
                    secondaryVal: viewModel.pastWeekAverageSleepHours > 0 ? String(format: "%.1fh (%d%%)", viewModel.pastWeekAverageSleepHours, Int(viewModel.pastWeekAverageSleepScore)) : "--",
                    extraDetail: viewModel.pastWeekSleepEfficiency > 0 ? "Efficiency: \(viewModel.pastWeekSleepEfficiency)%" : nil
                )

                // 6. Movement & Daily Steps
                statTile(
                    title: "DAILY STEP VOLUME",
                    icon: "figure.walk",
                    accentColor: .white,
                    primaryLabel: "Today",
                    primaryVal: "\(Int(viewModel.todaySteps))",
                    secondaryLabel: "7D Daily Avg",
                    secondaryVal: "\(Int(viewModel.pastWeekAverageDailySteps)) /day",
                    extraDetail: "\(Int(viewModel.pastWeekTotalSteps)) total 7D steps"
                )
            }

            // 4-Pill Cumulative Weekly Volume Strip
            HStack(spacing: 8) {
                statsStripItem(label: "7D Steps", val: "\(Int(viewModel.pastWeekTotalSteps))")
                statsStripItem(label: "7D Dist", val: String(format: "%.1f km", viewModel.pastWeekTotalDistanceKm))
                statsStripItem(label: "7D Burn", val: "\(Int(viewModel.pastWeekTotalActiveCalories)) kcal")
                statsStripItem(label: "7D Floors", val: "\(Int(viewModel.pastWeekTotalFlightsClimbed))")
            }
            .padding(.top, 2)

            // Deep Hub Button
            Button {
                showingStatsSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                    Text("Explore Full Statistical Registry (All 7 Domains)")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func statTile(
        title: String,
        icon: String,
        accentColor: Color,
        primaryLabel: String,
        primaryVal: String,
        secondaryLabel: String,
        secondaryVal: String,
        extraDetail: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.8)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(primaryLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(primaryVal)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(accentColor == .indigo ? .white : accentColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(secondaryLabel)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(secondaryVal)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }

            if let extra = extraDetail {
                Text(extra)
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 2)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func statsStripItem(label: String, val: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8.5, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Text(val)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }

    // MARK: - Gemini AI Health Intelligence Card
    private var aiIntelligenceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                    Text("AI LONGEVITY INTELLIGENCE")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .tracking(1.2)
                }

                Spacer()

                if viewModel.isRefreshingAI {
                    ProgressView()
                        .tint(.white)
                } else {
                    Button {
                        Task {
                            await viewModel.fetchAIBriefing()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Refresh")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }

            if let briefing = viewModel.detailedBriefing {
                VStack(alignment: .leading, spacing: 10) {
                    Text(briefing.headline)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(briefing.overallProgress)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(3)

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Daily Protocol Grid
                    VStack(alignment: .leading, spacing: 8) {
                        aiProtocolRow(
                            icon: "waveform.path.ecg",
                            label: "Biological Longevity",
                            detail: briefing.biologicalAgeAnalysis,
                            color: .white
                        )

                        aiProtocolRow(
                            icon: "figure.run.circle.fill",
                            label: "Workout Strain & Guidance",
                            detail: briefing.trainingGuidance,
                            color: .white
                        )

                        aiProtocolRow(
                            icon: "bed.double.fill",
                            label: "Sleep Architecture Insight",
                            detail: briefing.sleepArchitectureInsight,
                            color: .indigo // sleep as it is
                        )

                        aiProtocolRow(
                            icon: "heart.text.square.fill",
                            label: "Autonomic Nervous Status",
                            detail: briefing.nervousSystemStatus,
                            color: .white
                        )
                    }
                }
            } else {
                Text("Analyzing your 7-day Apple Health trend data and synthesizing biological recommendations...")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 6)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func aiProtocolRow(icon: String, label: String, detail: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
                Text(detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }

    // MARK: - Apple Watch Companion Bridge Card
    private var watchCompanionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "applewatch.radiowaves.left.and.right")
                        .foregroundColor(.white)
                    Text("APPLE WATCH COMPANION")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .tracking(1.2)
                }

                Spacer()

                if let date = viewModel.lastWatchSyncDate {
                    Text("Synced \(date.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            HStack(spacing: 12) {
                watchMetricPill(title: "Watch Recv", val: viewModel.watchRecoveryScore != nil ? "\(viewModel.watchRecoveryScore!)%" : "--")
                watchMetricPill(title: "Watch Stress", val: viewModel.watchStressScore != nil ? "\(viewModel.watchStressScore!)" : "--")
                watchMetricPill(title: "Watch Sleep", val: viewModel.watchSleepScore != nil ? "\(viewModel.watchSleepScore!)%" : "--")
            }

            HStack {
                Button {
                    viewModel.syncToWatch()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                        Text("Sync Baselines to Watch")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }

                Button {
                    Task {
                        await viewModel.sendTestNotification(delaySeconds: 1.0)
                        testNotificationScheduled = true
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        testNotificationScheduled = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: testNotificationScheduled ? "checkmark.circle.fill" : "bell.badge.fill")
                        Text(testNotificationScheduled ? "Delivered" : "Test Alert")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func watchMetricPill(title: String, val: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            Text(val)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }

    // MARK: - Standalone iPhone Motion Sensors Card
    private var phoneMotionSensorsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "iphone.gen3")
                        .foregroundColor(.white)
                    Text("IPHONE MOTION & HEALTH SENSORS")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .tracking(1.2)
                }

                Spacer()

                Text("Local Device")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
            }

            Text("Connected strictly to \(UIDevice.current.name)'s local Apple Health motion sensors and step volume telemetry.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(2)

            // 4-Stat Motion Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                motionStatTile(
                    title: "Today's Steps",
                    value: "\(Int(viewModel.todaySteps))",
                    unit: "steps",
                    icon: "figure.walk",
                    color: .white
                )
                motionStatTile(
                    title: "Walking Distance",
                    value: String(format: "%.1f", viewModel.todayDistanceKm),
                    unit: "km",
                    icon: "location.fill",
                    color: .white
                )
                motionStatTile(
                    title: "Active Burned",
                    value: "\(Int(viewModel.todayActiveCalories))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .white
                )
                motionStatTile(
                    title: "Flights Climbed",
                    value: "\(Int(viewModel.todayFlightsClimbed))",
                    unit: "floors",
                    icon: "stairs",
                    color: .white
                )
            }

            HStack {
                Button {
                    Task {
                        await viewModel.refreshAllData()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Health Data")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                }

                Button {
                    Task {
                        await viewModel.sendTestNotification(delaySeconds: 1.0)
                        testNotificationScheduled = true
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        testNotificationScheduled = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: testNotificationScheduled ? "checkmark.circle.fill" : "bell.badge.fill")
                        Text(testNotificationScheduled ? "Delivered" : "Test Alert")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func motionStatTile(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }

    // MARK: - Footer Info
    private var footerInfo: some View {
        VStack(spacing: 4) {
            Text("BioSync for iOS & watchOS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
            Text("HealthKit • Gemini AI • Autonomic Vitals Engine")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.top, 10)
    }
}

// MARK: - Settings Sheet
struct PhoneSettingsSheet: View {
    @ObservedObject var viewModel: PhoneViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var apiKeyInput: String = GeminiAIService.shared.apiKey ?? ""
    @State private var customAgeInput: Double = 25.0

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Apple Health User Profile
                Section("Apple Health Profile & Identity") {
                    dataRow(icon: "iphone.gen3", title: "Active Device", value: UIDevice.current.name, color: .white)
                    dataRow(icon: "person.text.rectangle", title: "Biological Sex", value: viewModel.biologicalSexString, color: .white)
                    
                    let chrono = viewModel.chronologicalAge
                    dataRow(icon: "calendar", title: "Chronological Age", value: String(format: "%.0f yrs (%@)", chrono, viewModel.isAgeFromHealthProfile ? "From Health Profile" : "User Set"), color: .gray)

                    if !viewModel.isAgeFromHealthProfile {
                        VStack(alignment: .leading, spacing: 8) {
                            Stepper("Adjust Age: \(Int(customAgeInput)) years", value: $customAgeInput, in: 15...110, step: 1)
                                .font(.system(size: 14))
                            if customAgeInput != viewModel.chronologicalAge {
                                Button("Save Custom Age") {
                                    viewModel.updateCustomAge(newAge: customAgeInput)
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - Local iPhone Motion & Activity Data
                Section("iPhone Health & Motion Telemetry") {
                    dataRow(icon: "figure.walk", title: "Today's Steps", value: "\(Int(viewModel.todaySteps)) steps", color: .white)
                    dataRow(icon: "location.fill", title: "Walking & Running Distance", value: String(format: "%.2f km", viewModel.todayDistanceKm), color: .white)
                    dataRow(icon: "flame.fill", title: "Active Energy Burned", value: "\(Int(viewModel.todayActiveCalories)) kcal", color: .white)
                    dataRow(icon: "stairs", title: "Flights Climbed", value: "\(Int(viewModel.todayFlightsClimbed)) flights", color: .white)
                    dataRow(icon: "chart.line.uptrend.xyaxis.circle.fill", title: "7-Day Avg Daily Steps", value: viewModel.pastWeekAverageDailySteps > 0 ? "\(Int(viewModel.pastWeekAverageDailySteps)) /day" : "\(Int(viewModel.todaySteps)) /day", color: .white)
                    dataRow(icon: "figure.walk.motion", title: "Recent Steps (15m window)", value: "\(Int(viewModel.recentSteps)) steps", color: .white)
                    dataRow(icon: "heart.fill", title: "Walking Heart Rate Avg", value: viewModel.walkingHeartRateAverage > 0 ? "\(Int(viewModel.walkingHeartRateAverage)) bpm" : "Not Logged", color: .white)
                }

                // MARK: - Biological Age Analytics
                Section("Biological Longevity Analytics") {
                    let ageRes = viewModel.bioSyncAgeResult
                    let bioAge = ageRes?.bioSyncAge ?? viewModel.chronologicalAge
                    let chrono = viewModel.chronologicalAge
                    let delta = ageRes?.ageDelta ?? 0.0

                    dataRow(icon: "flame.fill", title: "BioSync Biological Age", value: String(format: "%.1f yrs", bioAge), color: .white)
                    dataRow(icon: "calendar", title: "Chronological Age", value: String(format: "%.0f yrs", chrono), color: .gray)
                    dataRow(icon: delta <= 0 ? "arrow.down.right" : "arrow.up.right", title: "Longevity Delta", value: String(format: "%@%.1f yrs", delta <= 0 ? "" : "+", delta), color: .white)
                    dataRow(icon: "trophy.fill", title: "Longevity Tier", value: ageRes?.longevityTier ?? "Optimal", color: .white)
                    dataRow(icon: "star.fill", title: "Primary Driver", value: ageRes?.primaryDriver ?? "Daily Steps", color: .white)
                }

                // MARK: - Cardiovascular & Heart Rate Telemetry
                Section("Cardiovascular & Heart Rate Data") {
                    let liveHR = Int(viewModel.currentHeartRate)
                    dataRow(icon: "waveform.path.ecg", title: "Current Heart Rate", value: viewModel.hasHeartRateData ? "\(liveHR) bpm" : "No Watch Paired", color: .white)
                    dataRow(icon: "heart.fill", title: "Today's Resting Heart Rate", value: viewModel.hasRestingHRData ? "\(Int(viewModel.restingHeartRate)) bpm" : "No Watch Paired", color: .white)
                    dataRow(icon: "chart.line.uptrend.xyaxis", title: "7-Day Avg Resting HR", value: viewModel.pastWeekAverageRHR > 0 ? "\(Int(viewModel.pastWeekAverageRHR)) bpm" : (viewModel.hasRestingHRData ? "\(Int(viewModel.restingHeartRate)) bpm" : "No Watch Paired"), color: .white)
                    dataRow(icon: "clock.arrow.circlepath", title: "30-Day Baseline Resting HR", value: viewModel.baselineRHR > 0 ? "\(Int(viewModel.baselineRHR)) bpm" : "No Watch Paired", color: .white)
                    dataRow(icon: "lungs.fill", title: "Cardiorespiratory VO2 Max", value: viewModel.vo2Max != nil ? String(format: "%.1f mL/kg/min", viewModel.vo2Max!) : "Not Recorded", color: .white)
                }

                // MARK: - Autonomic Nervous System & HRV
                Section("Autonomic Nervous System & HRV") {
                    dataRow(icon: "waveform.path", title: "Latest HRV (SDNN)", value: viewModel.hasHRVData ? "\(Int(viewModel.latestHRV)) ms" : "No Watch Paired", color: .white)
                    dataRow(icon: "chart.bar.fill", title: "7-Day Nocturnal HRV Avg", value: viewModel.pastWeekAverageHRV > 0 ? "\(Int(viewModel.pastWeekAverageHRV)) ms" : (viewModel.hasHRVData ? "\(Int(viewModel.latestHRV)) ms" : "No Watch Paired"), color: .white)
                    dataRow(icon: "clock.arrow.circlepath", title: "30-Day Baseline HRV", value: viewModel.baselineHRV > 0 ? "\(Int(viewModel.baselineHRV)) ms" : "No Watch Paired", color: .white)
                    dataRow(icon: "waveform.path.badge.plus", title: "Momentary Stress Score", value: viewModel.stressScore != nil ? "\(viewModel.stressScore!)/100" : (viewModel.hasHeartRateData ? "In Motion (ACTV)" : "Requires Apple Watch PPG"), color: .green)
                    dataRow(icon: "gauge.with.needle", title: "Autonomic Stress Zone", value: viewModel.hasHeartRateData ? viewModel.stressZone.rawValue : "Sensors Inactive", color: .green)
                    dataRow(icon: "bolt.heart.fill", title: "Daily Recovery Score", value: "\(viewModel.recoveryScore)%", color: .yellow)
                }

                // MARK: - Sleep Architecture & Nocturnal Recovery
                Section("Sleep Architecture & Nocturnal Recovery") {
                    let sleep = viewModel.sleepData
                    let totalSleep = sleep?.totalHours ?? viewModel.pastWeekAverageSleepHours
                    dataRow(icon: "moon.fill", title: "Sleep Score", value: (viewModel.hasSleepData || viewModel.pastWeekAverageSleepScore > 0) ? "\(viewModel.sleepScore)%" : "No Sleep Logged", color: .indigo)
                    dataRow(icon: "chart.line.flattrend.xyaxis", title: "7-Day Avg Sleep Score", value: viewModel.pastWeekAverageSleepScore > 0 ? "\(Int(viewModel.pastWeekAverageSleepScore))%" : "No Sleep Logged", color: .indigo)
                    dataRow(icon: "bed.double.fill", title: "Total Sleep Duration", value: totalSleep > 0 ? String(format: "%.1f hrs", totalSleep) : "No Sleep Logged", color: .cyan)
                    dataRow(icon: "clock.badge.checkmark", title: "7-Day Avg Sleep Duration", value: viewModel.pastWeekAverageSleepHours > 0 ? String(format: "%.1f hrs", viewModel.pastWeekAverageSleepHours) : "No Sleep Logged", color: .cyan)
                    if let s = sleep {
                        dataRow(icon: "circle.fill", title: "Deep Sleep Stage", value: "\(s.deepPercentage)% (\(String(format: "%.1fh", s.deepHours)))", color: .purple)
                        dataRow(icon: "circle.fill", title: "REM Sleep Stage", value: "\(s.remPercentage)% (\(String(format: "%.1fh", s.remHours)))", color: .cyan)
                        dataRow(icon: "circle.fill", title: "Core Sleep Stage", value: "\(s.corePercentage)% (\(String(format: "%.1fh", s.coreHours)))", color: .blue)
                        dataRow(icon: "sun.max.fill", title: "Awake Duration", value: String(format: "%.1f hrs", s.awakeHours), color: .yellow)
                    }
                }

                // MARK: - Gemini AI API
                Section("Gemini AI API Configuration") {
                    SecureField("OpenRouter / Gemini API Key", text: $apiKeyInput)
                    Button("Save & Sync to Watch") {
                        GeminiAIService.shared.apiKey = apiKeyInput
                        viewModel.syncToWatch()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                // MARK: - Apple Health Integration Status
                Section("Apple Health System & Integration") {
                    dataRow(icon: "heart.text.square.fill", title: "HealthKit Status", value: "Connected & Reading Local Health", color: .white)
                    dataRow(icon: "iphone.gen3", title: "Hardware Data Source", value: UIDevice.current.name, color: .white)
                    dataRow(icon: "arrow.triangle.2.circlepath", title: "Background Delivery", value: "Hourly Frequency (Active)", color: .white)
                    dataRow(icon: "clock.badge", title: "Last Biometric Query", value: viewModel.lastUpdated.formatted(date: .omitted, time: .standard), color: .gray)

                    Button {
                        Task {
                            await viewModel.refreshAllData()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            Text("Force Sync All Apple Health Data")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                    }
                }

                // MARK: - About BioSync
                Section("About BioSync") {
                    dataRow(icon: "info.circle.fill", title: "Version", value: "1.0.0", color: .gray)
                    dataRow(icon: "apps.iphone", title: "Compatible Platforms", value: "iOS & watchOS", color: .white)
                }

                // MARK: - Statistical Registry Overview
                Section("Statistical Registry Overview") {
                    dataRow(icon: "heart.fill", title: "7D Avg Resting HR", value: viewModel.pastWeekAverageRHR > 0 ? "\(Int(viewModel.pastWeekAverageRHR)) bpm" : "No Watch Paired", color: .white)
                    dataRow(icon: "waveform.path.ecg", title: "7D Avg Nocturnal HRV", value: viewModel.pastWeekAverageHRV > 0 ? "\(Int(viewModel.pastWeekAverageHRV)) ms" : "No Watch Paired", color: .white)
                    dataRow(icon: "bolt.heart.fill", title: "7D Moving Avg Recovery", value: "\(Int(viewModel.pastWeekAverageRecoveryScore))%", color: .yellow)
                    dataRow(icon: "waveform.path.badge.plus", title: "Autonomic Stress Zone", value: viewModel.hasHeartRateData ? viewModel.stressZone.rawValue : "PPG Required", color: .green)
                    dataRow(icon: "moon.fill", title: "7D Avg Sleep Duration", value: viewModel.pastWeekAverageSleepHours > 0 ? String(format: "%.1f hrs", viewModel.pastWeekAverageSleepHours) : "No Sleep Logged", color: .indigo)
                    dataRow(icon: "figure.walk", title: "7D Cumulative Step Volume", value: "\(Int(viewModel.pastWeekTotalSteps)) steps", color: .white)
                    dataRow(icon: "flame.fill", title: "7D Cumulative Active Burn", value: "\(Int(viewModel.pastWeekTotalActiveCalories)) kcal", color: .white)

                    Button {
                        showingStatsHubFromSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Open Full Statistical Hub (All 7 Domains)")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("BioSync Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                customAgeInput = viewModel.chronologicalAge
            }
            .sheet(isPresented: $showingStatsHubFromSettings) {
                BiometricStatisticsHubSheet(viewModel: viewModel)
            }
        }
    }

    @State private var showingStatsHubFromSettings: Bool = false

    private func dataRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 22)
            Text(title)
                .font(.system(size: 14))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Full Biometric Statistics Hub Sheet (All The Things)
struct BiometricStatisticsHubSheet: View {
    @ObservedObject var viewModel: PhoneViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDomain: StatisticalDomain = .all

    enum StatisticalDomain: String, CaseIterable, Identifiable {
        case all = "All Domains"
        case cardio = "Cardio"
        case hrv = "HRV"
        case recovery = "Recovery"
        case stress = "Stress"
        case sleep = "Sleep"
        case movement = "Movement"
        case longevity = "Longevity"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Domain Filter Bar
                        domainFilterBar

                        // 1. Cardiovascular & Vitals
                        if selectedDomain == .all || selectedDomain == .cardio {
                            cardioSection
                        }

                        // 2. Autonomic HRV (SDNN)
                        if selectedDomain == .all || selectedDomain == .hrv {
                            hrvSection
                        }

                        // 3. Autonomic Stress (Green)
                        if selectedDomain == .all || selectedDomain == .stress {
                            stressSection
                        }

                        // 4. Recovery & Readiness (Yellow)
                        if selectedDomain == .all || selectedDomain == .recovery {
                            recoverySection
                        }

                        // 5. Sleep Architecture (Indigo/Purple/Cyan/Blue)
                        if selectedDomain == .all || selectedDomain == .sleep {
                            sleepSection
                        }

                        // 6. Movement & Step Volume
                        if selectedDomain == .all || selectedDomain == .movement {
                            movementSection
                        }

                        // 7. Biological Longevity & Age
                        if selectedDomain == .all || selectedDomain == .longevity {
                            longevitySection
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Statistical Registry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Domain Filter Pills
    private var domainFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StatisticalDomain.allCases) { domain in
                    Button {
                        selectedDomain = domain
                    } label: {
                        Text(domain.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(selectedDomain == domain ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedDomain == domain ? Color.white : Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 1. Cardiovascular & Vitals Section
    private var cardioSection: some View {
        statsCard(title: "CARDIOVASCULAR & VITALS", icon: "heart.fill", tint: .white) {
            VStack(spacing: 12) {
                fourGrid(
                    c1Title: "Current HR", c1Val: viewModel.hasHeartRateData ? "\(Int(viewModel.currentHeartRate)) bpm" : "No Watch",
                    c2Title: "Resting HR", c2Val: viewModel.hasRestingHRData ? "\(Int(viewModel.restingHeartRate)) bpm" : "No Watch",
                    c3Title: "7D Avg RHR", c3Val: viewModel.pastWeekAverageRHR > 0 ? "\(Int(viewModel.pastWeekAverageRHR)) bpm" : "--",
                    c4Title: "30D Base RHR", c4Val: viewModel.baselineRHR > 0 ? "\(Int(viewModel.baselineRHR)) bpm" : "--"
                )

                Divider().background(Color.white.opacity(0.1))

                statsRow(label: "Today's Discrete HR Range", val: viewModel.minHeartRateToday > 0 ? "\(Int(viewModel.minHeartRateToday)) - \(Int(viewModel.maxHeartRateToday)) bpm (Avg: \(Int(viewModel.avgHeartRateToday)))" : "Sensor Inactive")
                statsRow(label: "7-Day RHR Discrete Range", val: viewModel.pastWeekMinRHR > 0 ? "\(Int(viewModel.pastWeekMinRHR)) - \(Int(viewModel.pastWeekMaxRHR)) bpm" : "Calibrating")
                statsRow(label: "RHR Baseline Variance", val: String(format: "%@%.1f bpm from 30D baseline", viewModel.rhrDeltaFromBaseline >= 0 ? "+" : "", viewModel.rhrDeltaFromBaseline))
                statsRow(label: "Walking Heart Rate Avg", val: viewModel.walkingHeartRateAverage > 0 ? "\(Int(viewModel.walkingHeartRateAverage)) bpm" : "Not Logged")
                statsRow(label: "VO2 Max Cardiorespiratory", val: viewModel.vo2Max != nil ? String(format: "%.1f mL/kg/min (%@)", viewModel.vo2Max!, viewModel.vo2MaxClassification) : "Building Baseline")
            }
        }
    }

    // MARK: - 2. Autonomic HRV (SDNN) Section
    private var hrvSection: some View {
        statsCard(title: "NOCTURNAL HRV (SDNN)", icon: "waveform.path.ecg", tint: .white) {
            VStack(spacing: 12) {
                fourGrid(
                    c1Title: "Latest SDNN", c1Val: viewModel.hasHRVData ? "\(Int(viewModel.latestHRV)) ms" : "No Watch",
                    c2Title: "7D Avg HRV", c2Val: viewModel.pastWeekAverageHRV > 0 ? "\(Int(viewModel.pastWeekAverageHRV)) ms" : "--",
                    c3Title: "30D Baseline", c3Val: viewModel.baselineHRV > 0 ? "\(Int(viewModel.baselineHRV)) ms" : "--",
                    c4Title: "Net Variance", c4Val: String(format: "%@%.1f ms", viewModel.hrvDeltaFromBaseline >= 0 ? "+" : "", viewModel.hrvDeltaFromBaseline)
                )

                Divider().background(Color.white.opacity(0.1))

                statsRow(label: "7-Day HRV Range (Min - Max)", val: viewModel.pastWeekMinHRV > 0 ? "\(Int(viewModel.pastWeekMinHRV)) - \(Int(viewModel.pastWeekMaxHRV)) ms" : "Calibrating")
                statsRow(label: "Autonomic Balance Assessment", val: viewModel.autonomicBalanceDescription)
                statsRow(label: "Nocturnal Stability Index", val: viewModel.pastWeekAverageHRV > 0 ? (viewModel.pastWeekAverageHRV >= viewModel.baselineHRV ? "Elevated (Restorative)" : "Suppressed (Recovery Debt)") : "Awaiting Data")
            }
        }
    }

    // MARK: - 3. Autonomic Stress Section (GREEN)
    private var stressSection: some View {
        let greenColor = Color(red: 0.25, green: 0.85, blue: 0.45)
        return statsCard(title: "AUTONOMIC STRESS & TENSION", icon: "waveform.path.badge.plus", tint: greenColor) {
            VStack(spacing: 12) {
                fourGrid(
                    c1Title: "Stress Score", c1Val: viewModel.stressScore != nil ? "\(viewModel.stressScore!) / 100" : (viewModel.hasHeartRateData ? "In Motion" : "PPG Req"),
                    c2Title: "Stress Zone", c2Val: viewModel.hasHeartRateData ? viewModel.stressZone.rawValue : "Inactive",
                    c3Title: "Motion Window", c3Val: "\(Int(viewModel.recentSteps)) steps",
                    c4Title: "Filter State", c4Val: viewModel.recentSteps >= 60 ? "Active Suppress" : "Stationary PPG"
                )

                Divider().background(Color.white.opacity(0.1))

                statsRow(label: "Stress Measurement Logic", val: "HR Elevation + HRV Suppression vs Resting Baseline")
                statsRow(label: "Stationary Inactivity Filter", val: viewModel.recentSteps < 60 ? "Passing (< 60 steps/15m)" : "Filtered (Physical Movement Engaged)")
                statsRow(label: "Autonomic Nervous Status", val: viewModel.stressScore != nil ? (viewModel.stressScore! < 30 ? "Vagal Tone Restored" : (viewModel.stressScore! < 60 ? "Homeostatic Calm" : "Sympathetic Dominance")) : "Optical PPG Sensor Required", color: greenColor)
            }
        }
    }

    // MARK: - 4. Recovery & Readiness Section (YELLOW)
    private var recoverySection: some View {
        let yellowColor = Color(red: 0.98, green: 0.82, blue: 0.22)
        return statsCard(title: "RECOVERY & READINESS CAPACITY", icon: "bolt.heart.fill", tint: yellowColor) {
            VStack(spacing: 12) {
                fourGrid(
                    c1Title: "Recovery Score", c1Val: "\(viewModel.recoveryScore)%",
                    c2Title: "7D Moving Avg", c2Val: "\(Int(viewModel.pastWeekAverageRecoveryScore))%",
                    c3Title: "Readiness State", c3Val: viewModel.recoveryStatus,
                    c4Title: "Optimal Strain", c4Val: viewModel.recoveryScore >= 67 ? "High (14-18)" : (viewModel.recoveryScore >= 34 ? "Balanced (9-13)" : "Low (0-8)")
                )

                Divider().background(Color.white.opacity(0.1))

                statsRow(label: "Algorithm Weight Distribution", val: "HRV (50%) + Resting HR (25%) + Sleep (25%)")
                statsRow(label: "Physiological Capacity", val: viewModel.recoveryScore >= 67 ? "Cellular systems primed for strenuous training" : (viewModel.recoveryScore >= 34 ? "Standard homeostatic load recommended" : "Systemic fatigue detected; prioritize restoration"), color: yellowColor)
            }
        }
    }

    // MARK: - 5. Sleep Architecture Section (INDIGO/PURPLE/CYAN/BLUE)
    private var sleepSection: some View {
        statsCard(title: "SLEEP ARCHITECTURE & EFFICIENCY", icon: "moon.stars.fill", tint: .indigo) {
            VStack(spacing: 12) {
                let sleep = viewModel.sleepData
                fourGrid(
                    c1Title: "Last Night Sleep", c1Val: sleep != nil ? String(format: "%.1f hrs", sleep!.totalHours) : "--",
                    c2Title: "7D Avg Duration", c2Val: viewModel.pastWeekAverageSleepHours > 0 ? String(format: "%.1f hrs", viewModel.pastWeekAverageSleepHours) : "--",
                    c3Title: "Sleep Score", c3Val: "\(viewModel.sleepScore)%",
                    c4Title: "7D Avg Score", c4Val: viewModel.pastWeekAverageSleepScore > 0 ? "\(Int(viewModel.pastWeekAverageSleepScore))%" : "--"
                )

                Divider().background(Color.white.opacity(0.1))

                statsRow(label: "Sleep Efficiency Index", val: viewModel.pastWeekSleepEfficiency > 0 ? "\(viewModel.pastWeekSleepEfficiency)% time asleep in bed" : "88% Estimated")
                statsRow(label: "Cumulative Sleep Debt", val: String(format: "%.1f hrs deficit (vs 8h/night)", viewModel.sleepDebtHours))

                // Stage Breakdowns
                statsRow(label: "Deep Sleep (Tissue & Physical Repair)", val: "\(sleep?.deepPercentage ?? viewModel.pastWeekDeepPercentage)% (\(String(format: "%.1fh", sleep?.deepHours ?? viewModel.pastWeekAverageDeepHours)))", color: .purple)
                statsRow(label: "REM Sleep (Cognitive & Memory Consolidation)", val: "\(sleep?.remPercentage ?? viewModel.pastWeekRemPercentage)% (\(String(format: "%.1fh", sleep?.remHours ?? viewModel.pastWeekAverageRemHours)))", color: .cyan)
                statsRow(label: "Core Sleep (Light Transitional)", val: "\(sleep?.corePercentage ?? viewModel.pastWeekCorePercentage)% (\(String(format: "%.1fh", sleep?.coreHours ?? viewModel.pastWeekAverageCoreHours)))", color: .blue)
                statsRow(label: "Nocturnal Awake Time", val: String(format: "%.1f hrs", sleep?.awakeHours ?? viewModel.pastWeekAverageAwakeHours), color: .yellow)
            }
        }
    }

    // MARK: - 6. Movement & Step Volume Section
    private var movementSection: some View {
        statsCard(title: "MOVEMENT, STEPS & ENERGY BURN", icon: "figure.walk", tint: .white) {
            VStack(spacing: 12) {
                fourGrid(
                    c1Title: "Today's Steps", c1Val: "\(Int(viewModel.todaySteps))",
                    c2Title: "7D Daily Avg", c2Val: "\(Int(viewModel.pastWeekAverageDailySteps)) /day",
                    c3Title: "7D Total Steps", c3Val: "\(Int(viewModel.pastWeekTotalSteps))",
                    c4Title: "Step Goal %", c4Val: "\(Int(viewModel.stepGoalProgress * 100))%"
                )

                Divider().background(Color.white.opacity(0.1))

                statsRow(label: "Walking & Running Distance Today", val: String(format: "%.2f km", viewModel.todayDistanceKm))
                statsRow(label: "7-Day Cumulative Distance", val: String(format: "%.1f km", viewModel.pastWeekTotalDistanceKm))
                statsRow(label: "Active Calories Burned Today", val: "\(Int(viewModel.todayActiveCalories)) kcal")
                statsRow(label: "7-Day Cumulative Active Burn", val: "\(Int(viewModel.pastWeekTotalActiveCalories)) kcal")
                statsRow(label: "Flights Climbed Today", val: "\(Int(viewModel.todayFlightsClimbed)) floors")
                statsRow(label: "7-Day Cumulative Flights", val: "\(Int(viewModel.pastWeekTotalFlightsClimbed)) floors")
                statsRow(label: "Recent Step Telemetry (15m)", val: "\(Int(viewModel.recentSteps)) steps")
            }
        }
    }

    // MARK: - 7. Biological Longevity Section
    private var longevitySection: some View {
        let ageRes = viewModel.bioSyncAgeResult
        let bioAge = ageRes?.bioSyncAge ?? viewModel.chronologicalAge
        let chrono = viewModel.chronologicalAge
        let delta = ageRes?.ageDelta ?? 0.0

        return statsCard(title: "BIOLOGICAL LONGEVITY & ATTRIBUTION", icon: "flame.fill", tint: .white) {
            VStack(spacing: 12) {
                fourGrid(
                    c1Title: "BioSync Age", c1Val: String(format: "%.1f yrs", bioAge),
                    c2Title: "Chronological", c2Val: String(format: "%.0f yrs", chrono),
                    c3Title: "Net Delta", c3Val: String(format: "%@%.1f yrs", delta <= 0 ? "" : "+", delta),
                    c4Title: "Longevity Tier", c4Val: ageRes?.longevityTier ?? "Optimal"
                )

                Divider().background(Color.white.opacity(0.1))

                statsRow(label: "Resting Heart Rate Impact", val: String(format: "%@%.2f yrs", (ageRes?.rhrYearsModifier ?? 0) <= 0 ? "" : "+", ageRes?.rhrYearsModifier ?? 0))
                statsRow(label: "Nocturnal HRV Impact", val: String(format: "%@%.2f yrs", (ageRes?.hrvYearsModifier ?? 0) <= 0 ? "" : "+", ageRes?.hrvYearsModifier ?? 0))
                statsRow(label: "Sleep Architecture Impact", val: String(format: "%@%.2f yrs", (ageRes?.sleepYearsModifier ?? 0) <= 0 ? "" : "+", ageRes?.sleepYearsModifier ?? 0), color: .indigo)
                statsRow(label: "Movement & Steps Impact", val: String(format: "%@%.2f yrs", (ageRes?.activityYearsModifier ?? 0) <= 0 ? "" : "+", ageRes?.activityYearsModifier ?? 0))
                statsRow(label: "Primary Longevity Driver", val: ageRes?.primaryDriver ?? "Daily Steps")
            }
        }
    }

    // MARK: - Shared UI Helpers
    private func statsCard<Content: View>(title: String, icon: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(tint)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(tint)
                    .tracking(1.2)
            }

            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func fourGrid(c1Title: String, c1Val: String, c2Title: String, c2Val: String, c3Title: String, c3Val: String, c4Title: String, c4Val: String) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            miniCell(title: c1Title, val: c1Val)
            miniCell(title: c2Title, val: c2Val)
            miniCell(title: c3Title, val: c3Val)
            miniCell(title: c4Title, val: c4Val)
        }
    }

    private func miniCell(title: String, val: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Text(val)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }

    private func statsRow(label: String, val: String, color: Color = .white) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
            Text(val)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.vertical, 1)
    }
}
#endif
