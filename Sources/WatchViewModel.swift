#if os(watchOS)
import Foundation
import SwiftUI
import Combine

@MainActor
public final class WatchViewModel: ObservableObject {
    @Published public var recoveryScore: Int = 0
    @Published public var stressScore: Int? = 0
    @Published public var sleepScore: Int = 0
    @Published public var stressZone: StressZone = .rest
    @Published public var aiBriefing: AIService.HealthBriefing?
    @Published public var isLoading: Bool = false
    @Published public var lastUpdated: Date = Date()

    // Real Sensor Exposing
    @Published public var liveHeartRate: Double = 0.0
    @Published public var latestHRV: Double = 0.0
    @Published public var baselineHRV: Double = 50.0
    @Published public var restingHeartRate: Double = 60.0
    @Published public var baselineRHR: Double = 60.0
    @Published public var todaySteps: Double = 0.0
    @Published public var recentSteps: Double = 0.0
    @Published public var lastStationaryStress: Int = 22
    @Published public var sleepData: SleepSessionSummary?
    @Published public var chronologicalAge: Double = 25.0
    @Published public var vo2Max: Double? = nil
    @Published public var bioSyncAgeResult: BioSyncAgeResult = BioSyncAgeResult(
        bioSyncAge: 25.0,
        chronologicalAge: 25.0,
        ageDelta: 0.0,
        isYounger: true,
        rhrYearsModifier: 0.0,
        hrvYearsModifier: 0.0,
        sleepYearsModifier: 0.0,
        activityYearsModifier: 0.0,
        longevityTier: "Synchronizing Biometrics...",
        primaryDriver: "Analyzing Apple Health data"
    )
    @Published public var isSensorScanning: Bool = false
    @Published public var authorizationMessage: String = "Connecting..."
    @Published public var isAuthorized: Bool = false
    @Published public var isNotificationsAuthorized: Bool = false
    @Published public var pendingAlertsCount: Int = 0
    @Published public var latestDetailedBriefing: GeminiAIService.AIDetailedBriefing? = nil

    // 7-Day Past Week Analytics
    @Published public var pastWeekRHR: Double = 0.0
    @Published public var pastWeekMinRHR: Double = 0.0
    @Published public var pastWeekMaxRHR: Double = 0.0
    @Published public var pastWeekHRV: Double = 0.0
    @Published public var pastWeekMinHRV: Double = 0.0
    @Published public var pastWeekMaxHRV: Double = 0.0
    @Published public var pastWeekSteps: Double = 0.0
    @Published public var pastWeekTotalSteps: Double = 0.0
    @Published public var pastWeekTotalDistanceKm: Double = 0.0
    @Published public var pastWeekTotalActiveCalories: Double = 0.0
    @Published public var pastWeekSleepScore: Double = 0.0
    @Published public var pastWeekSleepHours: Double = 0.0
    @Published public var pastWeekDeepPercentage: Int = 0
    @Published public var pastWeekRemPercentage: Int = 0
    @Published public var pastWeekCorePercentage: Int = 0
    @Published public var pastWeekSleepEfficiency: Int = 0

    // Today's Extremes
    @Published public var minHeartRateToday: Double = 0.0
    @Published public var maxHeartRateToday: Double = 0.0
    @Published public var avgHeartRateToday: Double = 0.0

    public var pastWeekRecoveryScore: Int {
        BiometricEngine.calculateRecovery(
            currentHRV: pastWeekHRV > 0 ? pastWeekHRV : latestHRV,
            baselineHRV: baselineHRV,
            currentRHR: pastWeekRHR > 0 ? pastWeekRHR : restingHeartRate,
            baselineRHR: baselineRHR,
            sleepScore: pastWeekSleepScore > 0 ? pastWeekSleepScore : Double(sleepScore),
            dailySteps: pastWeekSteps > 0 ? pastWeekSteps : todaySteps
        )
    }

    private let healthKitManager = HealthKitManager.shared
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // Forward live hardware states from HealthKitManager
        healthKitManager.$currentHeartRate
            .assign(to: &$liveHeartRate)

        healthKitManager.$latestHRV_SDNN
            .assign(to: &$latestHRV)

        healthKitManager.$restingHeartRate
            .assign(to: &$restingHeartRate)

        healthKitManager.$baselineHRV
            .assign(to: &$baselineHRV)

        healthKitManager.$baselineRestingHeartRate
            .assign(to: &$baselineRHR)

        healthKitManager.$todaySteps
            .assign(to: &$todaySteps)

        healthKitManager.$recentSteps
            .assign(to: &$recentSteps)

        healthKitManager.$sleepData
            .assign(to: &$sleepData)

        healthKitManager.$chronologicalAge
            .assign(to: &$chronologicalAge)

        healthKitManager.$vo2Max
            .assign(to: &$vo2Max)

        healthKitManager.$isSensorScanning
            .assign(to: &$isSensorScanning)

        healthKitManager.$isAuthorized
            .assign(to: &$isAuthorized)

        healthKitManager.$authorizationStatusMessage
            .assign(to: &$authorizationMessage)

        BioSyncNotificationManager.shared.$isAuthorized
            .assign(to: &$isNotificationsAuthorized)

        BioSyncNotificationManager.shared.$pendingAlertsCount
            .assign(to: &$pendingAlertsCount)

        healthKitManager.$pastWeekAverageRHR
            .assign(to: &$pastWeekRHR)

        healthKitManager.$pastWeekAverageHRV
            .assign(to: &$pastWeekHRV)

        healthKitManager.$pastWeekAverageDailySteps
            .assign(to: &$pastWeekSteps)

        healthKitManager.$pastWeekAverageSleepScore
            .assign(to: &$pastWeekSleepScore)

        healthKitManager.$pastWeekAverageSleepHours
            .assign(to: &$pastWeekSleepHours)

        healthKitManager.$pastWeekMinRHR
            .assign(to: &$pastWeekMinRHR)

        healthKitManager.$pastWeekMaxRHR
            .assign(to: &$pastWeekMaxRHR)

        healthKitManager.$pastWeekMinHRV
            .assign(to: &$pastWeekMinHRV)

        healthKitManager.$pastWeekMaxHRV
            .assign(to: &$pastWeekMaxHRV)

        healthKitManager.$pastWeekTotalSteps
            .assign(to: &$pastWeekTotalSteps)

        healthKitManager.$pastWeekTotalDistanceKm
            .assign(to: &$pastWeekTotalDistanceKm)

        healthKitManager.$pastWeekTotalActiveCalories
            .assign(to: &$pastWeekTotalActiveCalories)

        healthKitManager.$pastWeekDeepPercentage
            .assign(to: &$pastWeekDeepPercentage)

        healthKitManager.$pastWeekRemPercentage
            .assign(to: &$pastWeekRemPercentage)

        healthKitManager.$pastWeekCorePercentage
            .assign(to: &$pastWeekCorePercentage)

        healthKitManager.$pastWeekSleepEfficiency
            .assign(to: &$pastWeekSleepEfficiency)

        healthKitManager.$minHeartRateToday
            .assign(to: &$minHeartRateToday)

        healthKitManager.$maxHeartRateToday
            .assign(to: &$maxHeartRateToday)

        healthKitManager.$avgHeartRateToday
            .assign(to: &$avgHeartRateToday)

        // Automatically re-evaluate biometric scores when HealthKit updates (debounced to avoid sensor spam)
        Publishers.CombineLatest4(
            healthKitManager.$latestHRV_SDNN,
            healthKitManager.$currentHeartRate,
            healthKitManager.$restingHeartRate,
            healthKitManager.$sleepData
        )
        .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] hrv, hr, rhr, sleep in
            self?.calculateAllMetrics(hrv: hrv, hr: hr, rhr: rhr, sleep: sleep)
        }
        .store(in: &cancellables)
    }

    public func start() async {
        BioSyncNotificationManager.shared.configure()
        await requestPermissions()
        let notifGranted = await BioSyncNotificationManager.shared.requestAuthorization()
        if notifGranted {
            // Pre-arm background queue immediately so watchOS daemon has alerts even if app is closed immediately
            let initialBriefing = aiBriefing.map {
                GeminiAIService.AIDetailedBriefing(
                    headline: $0.headline,
                    overallProgress: $0.overallProgress,
                    biologicalAgeAnalysis: $0.biologicalAgeAnalysis,
                    cardiovascularStatus: $0.cardiovascularStatus,
                    nervousSystemStatus: $0.nervousSystemStatus,
                    trainingGuidance: $0.trainingGuidance,
                    sleepArchitectureInsight: $0.sleepArchitectureInsight,
                    stressIntervention: $0.stressIntervention,
                    generatedAt: Date()
                )
            } ?? GeminiAIService.AIDetailedBriefing(
                headline: "Biological Sync Ready",
                overallProgress: "Biometric monitoring calibrated.",
                biologicalAgeAnalysis: "Longevity engine running.",
                cardiovascularStatus: "Resting pulse normal.",
                nervousSystemStatus: "Autonomic state balanced.",
                trainingGuidance: "Maintain steady activity.",
                sleepArchitectureInsight: "Tracking nocturnal recovery.",
                stressIntervention: nil,
                generatedAt: Date()
            )
            await BioSyncNotificationManager.shared.scheduleRecurringHourlyNotifications(
                briefing: initialBriefing,
                bioSyncAge: bioSyncAgeResult,
                recoveryScore: recoveryScore > 0 ? recoveryScore : 75,
                sleepScore: sleepScore > 0 ? sleepScore : 80
            )
        }
        BackgroundManager.shared.scheduleNextBackgroundRefresh()
        await triggerManualRefresh()
    }

    public func requestPermissions() async {
        isLoading = true
        do {
            try await healthKitManager.requestAuthorization()
        } catch {
            print("HealthKit Auth Failed: \(error)")
        }
        isLoading = false
    }

    public func calculateAllMetrics(
        hrv: Double,
        hr: Double,
        rhr: Double,
        sleep: SleepSessionSummary?
    ) {
        // 1. Sleep Score
        let calculatedSleepScore: Int
        if let s = sleep {
            calculatedSleepScore = BiometricEngine.calculateSleepScore(summary: s)
        } else {
            calculatedSleepScore = 0
        }
        self.sleepScore = calculatedSleepScore

        // 2. Recovery Score
        let effectiveHRV = hrv > 0 ? hrv : healthKitManager.baselineHRV
        let effectiveRHR = rhr > 0 ? rhr : healthKitManager.baselineRestingHeartRate

        let calculatedRecovery = BiometricEngine.calculateRecovery(
            currentHRV: effectiveHRV,
            baselineHRV: healthKitManager.baselineHRV,
            currentRHR: effectiveRHR,
            baselineRHR: healthKitManager.baselineRestingHeartRate,
            sleepScore: Double(calculatedSleepScore)
        )
        self.recoveryScore = calculatedRecovery

        // 3. Momentary Inactivity Stress
        let effectiveLiveHR = hr > 0 ? hr : effectiveRHR
        let calculatedStress = BiometricEngine.calculateMomentaryStress(
            currentHR: effectiveLiveHR,
            restingHR: effectiveRHR,
            liveHRV: effectiveHRV,
            baselineHRV: healthKitManager.baselineHRV,
            recentSteps: healthKitManager.recentSteps
        )
        self.stressScore = calculatedStress
        if let s = calculatedStress {
            self.lastStationaryStress = s
            self.stressZone = StressZone.classify(score: s)
        } else {
            self.stressZone = .exercising
        }

        // 4. BioSync Age (7-Day Longitudinal Apple Health Calibration)
        let bioAgeRHR = healthKitManager.pastWeekAverageRHR > 0 ? healthKitManager.pastWeekAverageRHR : effectiveRHR
        let bioAgeHRV = healthKitManager.pastWeekAverageHRV > 0 ? healthKitManager.pastWeekAverageHRV : effectiveHRV
        let bioAgeSteps = healthKitManager.pastWeekAverageDailySteps > 0 ? healthKitManager.pastWeekAverageDailySteps : healthKitManager.todaySteps
        let bioAgeSleep = healthKitManager.pastWeekAverageSleepScore > 0 ? healthKitManager.pastWeekAverageSleepScore : Double(calculatedSleepScore)

        let calculatedBioSyncAge = BiometricEngine.calculateBioSyncAge(
            chronologicalAge: healthKitManager.chronologicalAge,
            currentRHR: bioAgeRHR,
            baselineRHR: healthKitManager.baselineRestingHeartRate,
            currentHRV: bioAgeHRV,
            baselineHRV: healthKitManager.baselineHRV,
            vo2Max: healthKitManager.vo2Max,
            sleepScore: bioAgeSleep,
            dailySteps: bioAgeSteps
        )
        self.bioSyncAgeResult = calculatedBioSyncAge

        // 5. AI Coaching Briefing (Instant local heuristic - 0ms on-device response)
        self.aiBriefing = aiService.generateLocalInsight(
            recoveryScore: calculatedRecovery,
            sleepScore: calculatedSleepScore,
            stressScore: calculatedStress,
            currentHRV: effectiveHRV,
            baselineHRV: healthKitManager.baselineHRV,
            currentRHR: effectiveRHR,
            baselineRHR: healthKitManager.baselineRestingHeartRate,
            bioSyncAge: calculatedBioSyncAge
        )

        // 6. Update Watch Complications & iPhone Sync
        WatchConnectivityManager.shared.updateComplicationsAndStorage(
            recovery: calculatedRecovery,
            stress: calculatedStress,
            sleep: calculatedSleepScore,
            bioAge: calculatedBioSyncAge.bioSyncAge,
            bioDelta: calculatedBioSyncAge.ageDelta
        )

        self.lastUpdated = Date()

        // 7. Controlled async AI update (strictly rate-limited to avoid memory/network floods)
        triggerThrottledAIFetchIfNeeded(
            recovery: calculatedRecovery,
            sleep: calculatedSleepScore,
            stress: calculatedStress,
            effectiveHRV: effectiveHRV,
            effectiveRHR: effectiveRHR,
            sleepSummary: sleep,
            bioSyncAge: calculatedBioSyncAge
        )
    }

    // MARK: - Safe Rate-Limited AI Fetching
    private var isFetchingAI: Bool = false
    private var lastAIFetchDate: Date? = nil

    private func triggerThrottledAIFetchIfNeeded(
        recovery: Int,
        sleep: Int,
        stress: Int?,
        effectiveHRV: Double,
        effectiveRHR: Double,
        sleepSummary: SleepSessionSummary?,
        bioSyncAge: BioSyncAgeResult
    ) {
        guard !isFetchingAI else { return }

        // Cooldown: at most once every 15 minutes during automatic sensor updates
        if let last = lastAIFetchDate, Date().timeIntervalSince(last) < 900 {
            return
        }

        isFetchingAI = true
        Task { [weak self] in
            guard let self = self else { return }
            defer { self.isFetchingAI = false }

            let geminiBriefing = await GeminiAIService.shared.fetchAIBriefing(
                recoveryScore: recovery,
                sleepScore: sleep,
                stressScore: stress,
                currentHRV: effectiveHRV,
                baselineHRV: self.healthKitManager.baselineHRV,
                currentRHR: effectiveRHR,
                baselineRHR: self.healthKitManager.baselineRestingHeartRate,
                sleepSummary: sleepSummary,
                bioSyncAge: bioSyncAge
            )

            await MainActor.run {
                self.lastAIFetchDate = Date()
                self.latestDetailedBriefing = geminiBriefing
                self.aiBriefing = AIService.HealthBriefing(
                    headline: geminiBriefing.headline,
                    overallProgress: geminiBriefing.overallProgress,
                    biologicalAgeAnalysis: geminiBriefing.biologicalAgeAnalysis,
                    cardiovascularStatus: geminiBriefing.cardiovascularStatus,
                    nervousSystemStatus: geminiBriefing.nervousSystemStatus,
                    trainingGuidance: geminiBriefing.trainingGuidance,
                    sleepArchitectureInsight: geminiBriefing.sleepArchitectureInsight,
                    stressIntervention: geminiBriefing.stressIntervention
                )
            }

            await self.notifyAISummaryIfNeeded(
                briefing: geminiBriefing,
                bioSyncAge: bioSyncAge,
                recovery: recovery,
                sleep: sleep
            )
        }
    }

    public func toggleLiveSensorScan() {
        healthKitManager.toggleLiveSensorScan()
    }

    public func triggerManualRefresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        await healthKitManager.fetchLatestBiometrics()
        await healthKitManager.calculateHistoricalBaselines()
        await healthKitManager.calculatePastWeekAnalytics()

        let bioAgeRHR = healthKitManager.pastWeekAverageRHR > 0 ? healthKitManager.pastWeekAverageRHR : (self.restingHeartRate > 0 ? self.restingHeartRate : self.baselineRHR)
        let bioAgeHRV = healthKitManager.pastWeekAverageHRV > 0 ? healthKitManager.pastWeekAverageHRV : (self.latestHRV > 0 ? self.latestHRV : self.baselineHRV)
        let bioAgeSteps = healthKitManager.pastWeekAverageDailySteps > 0 ? healthKitManager.pastWeekAverageDailySteps : self.todaySteps
        let bioAgeSleep = healthKitManager.pastWeekAverageSleepScore > 0 ? healthKitManager.pastWeekAverageSleepScore : Double(self.sleepScore)

        let freshBioSyncAge = BiometricEngine.calculateBioSyncAge(
            chronologicalAge: healthKitManager.chronologicalAge,
            currentRHR: bioAgeRHR,
            baselineRHR: self.baselineRHR,
            currentHRV: bioAgeHRV,
            baselineHRV: self.baselineHRV,
            vo2Max: healthKitManager.vo2Max,
            sleepScore: bioAgeSleep,
            dailySteps: bioAgeSteps
        )
        self.bioSyncAgeResult = freshBioSyncAge

        let effectiveLiveHR = self.liveHeartRate > 0 ? self.liveHeartRate : (self.restingHeartRate > 0 ? self.restingHeartRate : self.baselineRHR)
        let freshStress = BiometricEngine.calculateMomentaryStress(
            currentHR: effectiveLiveHR,
            restingHR: self.restingHeartRate > 0 ? self.restingHeartRate : self.baselineRHR,
            liveHRV: self.latestHRV > 0 ? self.latestHRV : self.baselineHRV,
            baselineHRV: self.baselineHRV,
            recentSteps: healthKitManager.recentSteps
        )
        self.stressScore = freshStress
        if let s = freshStress {
            self.lastStationaryStress = s
            self.stressZone = StressZone.classify(score: s)
        } else {
            self.stressZone = .exercising
        }

        isFetchingAI = true
        defer { isFetchingAI = false }

        let geminiBriefing = await GeminiAIService.shared.fetchAIBriefing(
            recoveryScore: self.recoveryScore,
            sleepScore: self.sleepScore,
            stressScore: self.stressScore,
            currentHRV: self.latestHRV > 0 ? self.latestHRV : self.baselineHRV,
            baselineHRV: self.baselineHRV,
            currentRHR: self.restingHeartRate > 0 ? self.restingHeartRate : self.baselineRHR,
            baselineRHR: self.baselineRHR,
            sleepSummary: self.sleepData,
            bioSyncAge: freshBioSyncAge
        )
        self.lastAIFetchDate = Date()
        self.latestDetailedBriefing = geminiBriefing
        self.aiBriefing = AIService.HealthBriefing(
            headline: geminiBriefing.headline,
            overallProgress: geminiBriefing.overallProgress,
            biologicalAgeAnalysis: geminiBriefing.biologicalAgeAnalysis,
            cardiovascularStatus: geminiBriefing.cardiovascularStatus,
            nervousSystemStatus: geminiBriefing.nervousSystemStatus,
            trainingGuidance: geminiBriefing.trainingGuidance,
            sleepArchitectureInsight: geminiBriefing.sleepArchitectureInsight,
            stressIntervention: geminiBriefing.stressIntervention
        )

        await self.notifyAISummaryIfNeeded(
            briefing: geminiBriefing,
            bioSyncAge: freshBioSyncAge,
            recovery: self.recoveryScore,
            sleep: self.sleepScore,
            force: true
        )
    }

    private var lastAIBriefingNotificationTime: Date? = nil

    public func notifyAISummaryIfNeeded(
        briefing: GeminiAIService.AIDetailedBriefing,
        bioSyncAge: BioSyncAgeResult,
        recovery: Int,
        sleep: Int,
        force: Bool = false
    ) async {
        let shouldNotify: Bool
        if force {
            shouldNotify = true
        } else if let lastTime = lastAIBriefingNotificationTime {
            shouldNotify = Date().timeIntervalSince(lastTime) >= 600
        } else {
            shouldNotify = true
        }

        if shouldNotify {
            lastAIBriefingNotificationTime = Date()
            await BioSyncNotificationManager.shared.postAISummaryNotification(
                briefing: briefing,
                bioSyncAge: bioSyncAge,
                recoveryScore: recovery,
                sleepScore: sleep
            )
        }

        // ALWAYS register and refresh the guaranteed rolling sequence of hourly notifications
        await BioSyncNotificationManager.shared.scheduleRecurringHourlyNotifications(
            briefing: briefing,
            bioSyncAge: bioSyncAge,
            recoveryScore: recovery,
            sleepScore: sleep
        )
    }

    public func sendTestNotification(delaySeconds: TimeInterval = 1.0) async {
        await BioSyncNotificationManager.shared.sendTestNotification(
            briefing: latestDetailedBriefing,
            bioSyncAge: bioSyncAgeResult,
            recoveryScore: recoveryScore,
            sleepScore: sleepScore,
            delaySeconds: delaySeconds
        )
    }

    public func requestNotificationPermission() async {
        await BioSyncNotificationManager.shared.requestAuthorization()
    }
}
#endif
