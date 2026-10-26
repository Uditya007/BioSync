#if os(iOS)
import Foundation
import SwiftUI
import Combine
import HealthKit

@MainActor
public final class PhoneViewModel: ObservableObject {
    // MARK: - Algorithmic Longevity & Health Scores
    @Published public var recoveryScore: Int = 0
    @Published public var stressScore: Int? = 0
    @Published public var sleepScore: Int = 0
    @Published public var stressZone: StressZone = .rest
    @Published public var bioSyncAgeResult: BioSyncAgeResult? = nil

    // MARK: - Biometric Readings
    @Published public var currentHeartRate: Double = 0.0
    @Published public var latestHRV: Double = 0.0
    @Published public var baselineHRV: Double = 0.0
    @Published public var restingHeartRate: Double = 0.0
    @Published public var baselineRHR: Double = 0.0
    @Published public var todaySteps: Double = 0.0
    @Published public var recentSteps: Double = 0.0
    @Published public var todayDistanceKm: Double = 0.0
    @Published public var todayActiveCalories: Double = 0.0
    @Published public var todayFlightsClimbed: Double = 0.0
    @Published public var walkingHeartRateAverage: Double = 0.0
    @Published public var biologicalSexString: String = "Not Set"
    @Published public var isAgeFromHealthProfile: Bool = false
    @Published public var hasHeartRateData: Bool = false
    @Published public var hasHRVData: Bool = false
    @Published public var hasRestingHRData: Bool = false
    @Published public var hasSleepData: Bool = false
    @Published public var sleepData: SleepSessionSummary? = nil
    @Published public var chronologicalAge: Double = 25.0
    @Published public var vo2Max: Double? = nil

    // MARK: - 7-Day Past Week Analytics
    @Published public var pastWeekAverageRHR: Double = 0.0
    @Published public var pastWeekMinRHR: Double = 0.0
    @Published public var pastWeekMaxRHR: Double = 0.0
    @Published public var pastWeekAverageHRV: Double = 0.0
    @Published public var pastWeekMinHRV: Double = 0.0
    @Published public var pastWeekMaxHRV: Double = 0.0
    @Published public var pastWeekAverageDailySteps: Double = 0.0
    @Published public var pastWeekTotalSteps: Double = 0.0
    @Published public var pastWeekTotalDistanceKm: Double = 0.0
    @Published public var pastWeekTotalActiveCalories: Double = 0.0
    @Published public var pastWeekTotalFlightsClimbed: Double = 0.0
    @Published public var pastWeekAverageSleepScore: Double = 0.0
    @Published public var pastWeekAverageSleepHours: Double = 0.0
    @Published public var pastWeekAverageDeepHours: Double = 0.0
    @Published public var pastWeekAverageRemHours: Double = 0.0
    @Published public var pastWeekAverageCoreHours: Double = 0.0
    @Published public var pastWeekAverageAwakeHours: Double = 0.0
    @Published public var pastWeekDeepPercentage: Int = 0
    @Published public var pastWeekRemPercentage: Int = 0
    @Published public var pastWeekCorePercentage: Int = 0
    @Published public var pastWeekSleepEfficiency: Int = 0
    @Published public var pastWeekAverageRecoveryScore: Double = 0.0

    // MARK: - Today's Discrete Vitals
    @Published public var minHeartRateToday: Double = 0.0
    @Published public var maxHeartRateToday: Double = 0.0
    @Published public var avgHeartRateToday: Double = 0.0

    // MARK: - Statistical Calculations
    public var stepGoalProgress: Double {
        min(1.0, todaySteps / 10000.0)
    }

    public var distanceGoalProgress: Double {
        min(1.0, todayDistanceKm / 8.0)
    }

    public var caloriesGoalProgress: Double {
        min(1.0, todayActiveCalories / 500.0)
    }

    public var flightsGoalProgress: Double {
        min(1.0, todayFlightsClimbed / 10.0)
    }

    public var rhrDeltaFromBaseline: Double {
        (pastWeekAverageRHR > 0 && baselineRHR > 0) ? (pastWeekAverageRHR - baselineRHR) : 0.0
    }

    public var hrvDeltaFromBaseline: Double {
        (pastWeekAverageHRV > 0 && baselineHRV > 0) ? (pastWeekAverageHRV - baselineHRV) : 0.0
    }

    public var sleepDebtHours: Double {
        pastWeekAverageSleepHours > 0 ? max(0, (8.0 - pastWeekAverageSleepHours) * 7.0) : 0.0
    }

    public var vo2MaxClassification: String {
        guard let vo2 = vo2Max, vo2 > 0 else { return "Calibrating Cardio Base" }
        if vo2 >= 52.0 { return "Elite (Top 5%)" }
        if vo2 >= 45.0 { return "Superior (Top 15%)" }
        if vo2 >= 38.0 { return "Good (Top 35%)" }
        if vo2 >= 32.0 { return "Fair (Average)" }
        return "Building VO2 Endurance"
    }

    public var autonomicBalanceDescription: String {
        guard hasHRVData || pastWeekAverageHRV > 0 else { return "No Optical HRV" }
        let current = latestHRV > 0 ? latestHRV : pastWeekAverageHRV
        guard baselineHRV > 0 else { return "Calibrating" }
        let ratio = current / baselineHRV
        if ratio >= 1.15 { return "Parasympathetic Dominant (Primed)" }
        if ratio >= 0.85 { return "Optimal Homeostasis (Balanced)" }
        return "Sympathetic Strain (Recovery Needed)"
    }

    public var recoveryStatus: String {
        if recoveryScore >= 67 { return "PRIMED" }
        if recoveryScore >= 34 { return "BALANCED" }
        return "STRAINED"
    }

    // MARK: - AI Intelligence & State
    @Published public var detailedBriefing: GeminiAIService.AIDetailedBriefing? = nil
    @Published public var isLoading: Bool = false
    @Published public var isRefreshingAI: Bool = false
    @Published public var lastUpdated: Date = Date()
    @Published public var statusMessage: String = "Ready"

    // MARK: - Apple Watch Companion Telemetry
    @Published public var isWatchPaired: Bool = false
    @Published public var isWatchAppInstalled: Bool = false
    @Published public var isWatchReachable: Bool = false
    @Published public var watchRecoveryScore: Int? = nil
    @Published public var watchStressScore: Int? = nil
    @Published public var watchSleepScore: Int? = nil
    @Published public var lastWatchSyncDate: Date? = nil

    private var cancellables = Set<AnyCancellable>()
    private let healthKit = HealthKitManager.shared
    private let watchConnectivity = WatchConnectivityManager.shared
    private let gemini = GeminiAIService.shared

    public init() {
        setupSubscriptions()
        Task {
            await start()
        }
    }

    private func setupSubscriptions() {
        // Subscribe to HealthKit updates
        healthKit.$currentHeartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.currentHeartRate = $0 }
            .store(in: &cancellables)

        healthKit.$latestHRV_SDNN
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.latestHRV = $0 }
            .store(in: &cancellables)

        healthKit.$baselineHRV
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.baselineHRV = $0 }
            .store(in: &cancellables)

        healthKit.$restingHeartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.restingHeartRate = $0 }
            .store(in: &cancellables)

        healthKit.$baselineRestingHeartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.baselineRHR = $0 }
            .store(in: &cancellables)

        healthKit.$todaySteps
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.todaySteps = $0 }
            .store(in: &cancellables)

        healthKit.$recentSteps
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.recentSteps = $0 }
            .store(in: &cancellables)

        healthKit.$sleepData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sleepData = $0 }
            .store(in: &cancellables)

        healthKit.$chronologicalAge
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.chronologicalAge = $0 }
            .store(in: &cancellables)

        healthKit.$vo2Max
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.vo2Max = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekAverageRHR
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekAverageRHR = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekAverageHRV
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekAverageHRV = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekAverageDailySteps
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekAverageDailySteps = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekAverageSleepScore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekAverageSleepScore = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekAverageSleepHours
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekAverageSleepHours = $0 }
            .store(in: &cancellables)

        healthKit.$todayDistanceKm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.todayDistanceKm = $0 }
            .store(in: &cancellables)

        healthKit.$todayActiveCalories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.todayActiveCalories = $0 }
            .store(in: &cancellables)

        healthKit.$todayFlightsClimbed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.todayFlightsClimbed = $0 }
            .store(in: &cancellables)

        healthKit.$walkingHeartRateAverage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.walkingHeartRateAverage = $0 }
            .store(in: &cancellables)

        healthKit.$biologicalSexString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.biologicalSexString = $0 }
            .store(in: &cancellables)

        healthKit.$isAgeFromHealthProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isAgeFromHealthProfile = $0 }
            .store(in: &cancellables)

        healthKit.$hasHeartRateData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hasHeartRateData = $0 }
            .store(in: &cancellables)

        healthKit.$hasHRVData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hasHRVData = $0 }
            .store(in: &cancellables)

        healthKit.$hasRestingHRData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hasRestingHRData = $0 }
            .store(in: &cancellables)

        healthKit.$hasSleepData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hasSleepData = $0 }
            .store(in: &cancellables)

        healthKit.$minHeartRateToday
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.minHeartRateToday = $0 }
            .store(in: &cancellables)

        healthKit.$maxHeartRateToday
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.maxHeartRateToday = $0 }
            .store(in: &cancellables)

        healthKit.$avgHeartRateToday
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.avgHeartRateToday = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekMinRHR
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekMinRHR = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekMaxRHR
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekMaxRHR = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekMinHRV
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekMinHRV = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekMaxHRV
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekMaxHRV = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekTotalSteps
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekTotalSteps = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekTotalDistanceKm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekTotalDistanceKm = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekTotalActiveCalories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekTotalActiveCalories = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekTotalFlightsClimbed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekTotalFlightsClimbed = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekDeepPercentage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekDeepPercentage = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekRemPercentage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekRemPercentage = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekCorePercentage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekCorePercentage = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekSleepEfficiency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekSleepEfficiency = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekAverageDeepHours
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekAverageDeepHours = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekAverageRemHours
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekAverageRemHours = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekAverageCoreHours
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekAverageCoreHours = $0 }
            .store(in: &cancellables)

        healthKit.$pastWeekAverageAwakeHours
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pastWeekAverageAwakeHours = $0 }
            .store(in: &cancellables)

        // Subscribe to Watch Connectivity updates
        watchConnectivity.$isWatchPaired
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isWatchPaired = $0 }
            .store(in: &cancellables)

        watchConnectivity.$isWatchAppInstalled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isWatchAppInstalled = $0 }
            .store(in: &cancellables)

        watchConnectivity.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isWatchReachable = $0 }
            .store(in: &cancellables)

        watchConnectivity.$watchRecoveryScore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.watchRecoveryScore = $0 }
            .store(in: &cancellables)

        watchConnectivity.$watchStressScore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.watchStressScore = $0 }
            .store(in: &cancellables)

        watchConnectivity.$watchSleepScore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.watchSleepScore = $0 }
            .store(in: &cancellables)

        watchConnectivity.$lastSyncDate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.lastWatchSyncDate = $0 }
            .store(in: &cancellables)
    }

    public func start() async {
        self.isLoading = true
        self.statusMessage = "Requesting Apple Health Access..."

        do {
            try await healthKit.requestAuthorization()
            self.statusMessage = "Reading Biometrics & 7D History..."
            await refreshAllData()
        } catch {
            self.statusMessage = "HealthKit: \(error.localizedDescription)"
        }

        self.isLoading = false
    }

    public func updateCustomAge(newAge: Double) {
        UserDefaults.standard.set(newAge, forKey: "user_custom_age")
        self.chronologicalAge = newAge
        self.isAgeFromHealthProfile = false
        Task {
            await refreshAllData()
        }
    }

    public func refreshAllData() async {
        await healthKit.calculateHistoricalBaselines()
        await healthKit.calculatePastWeekAnalytics()
        await healthKit.fetchLatestBiometrics()

        // 1. Compute Sleep Score from actual data
        if let sleep = healthKit.sleepData {
            self.sleepScore = BiometricEngine.calculateSleepScore(summary: sleep)
        } else if pastWeekAverageSleepScore > 0 {
            self.sleepScore = Int(pastWeekAverageSleepScore)
        } else {
            self.sleepScore = 0 // No fake baseline; unrecorded
        }

        // 2. Compute Recovery Score strictly from this device's readings
        self.recoveryScore = BiometricEngine.calculateRecovery(
            currentHRV: latestHRV,
            baselineHRV: baselineHRV,
            currentRHR: restingHeartRate,
            baselineRHR: baselineRHR,
            sleepScore: Double(sleepScore),
            dailySteps: todaySteps
        )

        // 3. Compute Momentary Stress strictly from this device's readings
        self.stressScore = BiometricEngine.calculateMomentaryStress(
            currentHR: currentHeartRate > 0 ? currentHeartRate : restingHeartRate,
            restingHR: restingHeartRate,
            liveHRV: latestHRV,
            baselineHRV: baselineHRV,
            recentSteps: recentSteps
        )

        self.stressZone = StressZone.classify(score: stressScore)

        // 4. Compute BioSync Biological Age from Past Week 7-Day Longitudinal Data
        let pastRHR = pastWeekAverageRHR > 0 ? pastWeekAverageRHR : restingHeartRate
        let pastHRV = pastWeekAverageHRV > 0 ? pastWeekAverageHRV : latestHRV
        let pastSteps = pastWeekAverageDailySteps > 0 ? pastWeekAverageDailySteps : todaySteps
        let pastSleepScore = pastWeekAverageSleepScore > 0 ? pastWeekAverageSleepScore : Double(sleepScore)

        self.bioSyncAgeResult = BiometricEngine.calculateBioSyncAge(
            chronologicalAge: chronologicalAge,
            currentRHR: pastRHR,
            baselineRHR: baselineRHR,
            currentHRV: pastHRV,
            baselineHRV: baselineHRV,
            vo2Max: vo2Max,
            sleepScore: pastSleepScore,
            dailySteps: pastSteps
        )

        // 5. 7-Day Average Recovery Score
        self.pastWeekAverageRecoveryScore = Double(BiometricEngine.calculateRecovery(
            currentHRV: pastHRV > 0 ? pastHRV : latestHRV,
            baselineHRV: baselineHRV,
            currentRHR: pastRHR > 0 ? pastRHR : restingHeartRate,
            baselineRHR: baselineRHR,
            sleepScore: pastSleepScore,
            dailySteps: pastSteps
        ))

        self.lastUpdated = Date()
        self.statusMessage = "Synced at \(Date().formatted(date: .omitted, time: .standard))"

        // Trigger AI Briefing if not generated yet
        if detailedBriefing == nil {
            await fetchAIBriefing()
        }
    }

    public func fetchAIBriefing() async {
        guard !isRefreshingAI else { return }
        self.isRefreshingAI = true

        let ageRes = bioSyncAgeResult ?? BiometricEngine.calculateBioSyncAge(
            chronologicalAge: chronologicalAge,
            currentRHR: restingHeartRate,
            baselineRHR: baselineRHR,
            currentHRV: latestHRV,
            baselineHRV: baselineHRV,
            vo2Max: vo2Max,
            sleepScore: Double(sleepScore),
            dailySteps: todaySteps
        )

        let briefing = await gemini.fetchAIBriefing(
            recoveryScore: recoveryScore,
            sleepScore: sleepScore,
            stressScore: stressScore,
            currentHRV: latestHRV,
            baselineHRV: baselineHRV,
            currentRHR: restingHeartRate,
            baselineRHR: baselineRHR,
            sleepSummary: sleepData,
            bioSyncAge: ageRes
        )

        self.detailedBriefing = briefing
        self.isRefreshingAI = false

        // Pre-arm notification queue
        await BioSyncNotificationManager.shared.scheduleRecurringHourlyNotifications(
            briefing: briefing,
            bioSyncAge: ageRes,
            recoveryScore: recoveryScore,
            sleepScore: sleepScore
        )
    }

    public func sendTestNotification(delaySeconds: TimeInterval = 1.0) async {
        let ageRes = bioSyncAgeResult ?? BiometricEngine.calculateBioSyncAge(
            chronologicalAge: chronologicalAge,
            currentRHR: restingHeartRate,
            baselineRHR: baselineRHR,
            currentHRV: latestHRV,
            baselineHRV: baselineHRV,
            vo2Max: vo2Max,
            sleepScore: Double(sleepScore),
            dailySteps: todaySteps
        )

        await BioSyncNotificationManager.shared.sendTestNotification(
            briefing: detailedBriefing,
            bioSyncAge: ageRes,
            recoveryScore: recoveryScore,
            sleepScore: sleepScore,
            delaySeconds: delaySeconds
        )
    }

    public func syncToWatch() {
        watchConnectivity.syncSettingsToWatch(
            apiKey: gemini.apiKey,
            baselineHRV: baselineHRV,
            baselineRHR: baselineRHR
        )
    }
}
#endif
