import Foundation

#if os(watchOS)
import WatchKit

/// Handles watchOS background execution to keep scores, Apple Health biometrics,
/// and AI hourly briefings timely without compromising Apple Watch SE battery life.
public final class BackgroundManager {
    public static let shared = BackgroundManager()

    /// Hourly interval in seconds (1 hour = 3600 seconds)
    public let refreshIntervalSeconds: TimeInterval = 60 * 60
    private var lastBackgroundUpdateTime: Date? = nil

    private init() {}

    /// Schedules the next background wake-up with watchOS for exactly 1 hour from now
    public func scheduleNextBackgroundRefresh() {
        let targetDate = Date().addingTimeInterval(refreshIntervalSeconds)
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: targetDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("Failed to schedule hourly background refresh: \(error)")
            } else {
                print("Successfully scheduled next Apple Health hourly background refresh for \(targetDate)")
            }
        }
    }

    /// Handles the background task when watchOS wakes up the app hourly
    @MainActor
    public func handleBackgroundTask(_ task: WKApplicationRefreshBackgroundTask) async {
        print("Executing hourly background Apple Health & AI briefing check at \(Date())...")

        // 1. Fetch latest real biometrics & past week analytics from Apple Health
        await HealthKitManager.shared.fetchLatestBiometrics()
        await HealthKitManager.shared.calculatePastWeekAnalytics()

        let currentHRV = HealthKitManager.shared.latestHRV_SDNN
        let currentHR = HealthKitManager.shared.currentHeartRate
        let currentRHR = HealthKitManager.shared.restingHeartRate
        let baselineHRV = HealthKitManager.shared.baselineHRV
        let baselineRHR = HealthKitManager.shared.baselineRestingHeartRate
        let sleep = HealthKitManager.shared.sleepData
        let steps = HealthKitManager.shared.todaySteps
        let recentSteps = HealthKitManager.shared.recentSteps
        let chronoAge = HealthKitManager.shared.chronologicalAge
        let vo2 = HealthKitManager.shared.vo2Max

        // 2. Re-compute algorithmic scores
        let sleepScore = sleep.map { BiometricEngine.calculateSleepScore(summary: $0) } ?? 75

        let effectiveHRV = currentHRV > 0 ? currentHRV : baselineHRV
        let effectiveRHR = currentRHR > 0 ? currentRHR : baselineRHR

        let recoveryScore = BiometricEngine.calculateRecovery(
            currentHRV: effectiveHRV,
            baselineHRV: baselineHRV,
            currentRHR: effectiveRHR,
            baselineRHR: baselineRHR,
            sleepScore: Double(sleepScore)
        )

        let momentaryStress = BiometricEngine.calculateMomentaryStress(
            currentHR: currentHR,
            restingHR: effectiveRHR,
            liveHRV: effectiveHRV,
            baselineHRV: baselineHRV,
            recentSteps: recentSteps
        )

        let bioAgeRHR = HealthKitManager.shared.pastWeekAverageRHR > 0 ? HealthKitManager.shared.pastWeekAverageRHR : effectiveRHR
        let bioAgeHRV = HealthKitManager.shared.pastWeekAverageHRV > 0 ? HealthKitManager.shared.pastWeekAverageHRV : effectiveHRV
        let bioAgeSteps = HealthKitManager.shared.pastWeekAverageDailySteps > 0 ? HealthKitManager.shared.pastWeekAverageDailySteps : steps
        let bioAgeSleep = HealthKitManager.shared.pastWeekAverageSleepScore > 0 ? HealthKitManager.shared.pastWeekAverageSleepScore : Double(sleepScore)

        let bioSyncAge = BiometricEngine.calculateBioSyncAge(
            chronologicalAge: chronoAge,
            currentRHR: bioAgeRHR,
            baselineRHR: baselineRHR,
            currentHRV: bioAgeHRV,
            baselineHRV: baselineHRV,
            vo2Max: vo2,
            sleepScore: bioAgeSleep,
            dailySteps: bioAgeSteps
        )

        // 3. Fetch fresh AI briefing from OpenRouter / Gemini key
        let detailedBriefing = await GeminiAIService.shared.fetchAIBriefing(
            recoveryScore: recoveryScore,
            sleepScore: sleepScore,
            stressScore: momentaryStress,
            currentHRV: effectiveHRV,
            baselineHRV: baselineHRV,
            currentRHR: effectiveRHR,
            baselineRHR: baselineRHR,
            sleepSummary: sleep,
            bioSyncAge: bioSyncAge
        )

        // 4. Post immediate notification & schedule guaranteed recurring hourly queue
        await BioSyncNotificationManager.shared.postAISummaryNotification(
            briefing: detailedBriefing,
            bioSyncAge: bioSyncAge,
            recoveryScore: recoveryScore,
            sleepScore: sleepScore
        )

        await BioSyncNotificationManager.shared.scheduleRecurringHourlyNotifications(
            briefing: detailedBriefing,
            bioSyncAge: bioSyncAge,
            recoveryScore: recoveryScore,
            sleepScore: sleepScore
        )

        // 5. Schedule next hourly cycle
        scheduleNextBackgroundRefresh()

        // 6. Complete task and update app switcher snapshot
        task.setTaskCompletedWithSnapshot(true)
    }

    /// Invoked when HealthKit observer queries detect new biometrics in the background
    @MainActor
    public func handleHealthKitBackgroundUpdate() async {
        // Debounce to at most once every 20 minutes to conserve battery
        if let lastUpdate = lastBackgroundUpdateTime, Date().timeIntervalSince(lastUpdate) < 1200 {
            return
        }
        lastBackgroundUpdateTime = Date()
        print("HealthKit background update triggered at \(Date())")

        await HealthKitManager.shared.fetchLatestBiometrics()
        await HealthKitManager.shared.calculatePastWeekAnalytics()

        let currentHRV = HealthKitManager.shared.latestHRV_SDNN
        let currentHR = HealthKitManager.shared.currentHeartRate
        let currentRHR = HealthKitManager.shared.restingHeartRate
        let baselineHRV = HealthKitManager.shared.baselineHRV
        let baselineRHR = HealthKitManager.shared.baselineRestingHeartRate
        let sleep = HealthKitManager.shared.sleepData
        let steps = HealthKitManager.shared.todaySteps
        let recentSteps = HealthKitManager.shared.recentSteps
        let chronoAge = HealthKitManager.shared.chronologicalAge
        let vo2 = HealthKitManager.shared.vo2Max

        let sleepScore = sleep.map { BiometricEngine.calculateSleepScore(summary: $0) } ?? 75
        let effectiveHRV = currentHRV > 0 ? currentHRV : baselineHRV
        let effectiveRHR = currentRHR > 0 ? currentRHR : baselineRHR

        let recoveryScore = BiometricEngine.calculateRecovery(
            currentHRV: effectiveHRV,
            baselineHRV: baselineHRV,
            currentRHR: effectiveRHR,
            baselineRHR: baselineRHR,
            sleepScore: Double(sleepScore)
        )

        let momentaryStress = BiometricEngine.calculateMomentaryStress(
            currentHR: currentHR,
            restingHR: effectiveRHR,
            liveHRV: effectiveHRV,
            baselineHRV: baselineHRV,
            recentSteps: recentSteps
        )

        let bioAgeRHR = HealthKitManager.shared.pastWeekAverageRHR > 0 ? HealthKitManager.shared.pastWeekAverageRHR : effectiveRHR
        let bioAgeHRV = HealthKitManager.shared.pastWeekAverageHRV > 0 ? HealthKitManager.shared.pastWeekAverageHRV : effectiveHRV
        let bioAgeSteps = HealthKitManager.shared.pastWeekAverageDailySteps > 0 ? HealthKitManager.shared.pastWeekAverageDailySteps : steps
        let bioAgeSleep = HealthKitManager.shared.pastWeekAverageSleepScore > 0 ? HealthKitManager.shared.pastWeekAverageSleepScore : Double(sleepScore)

        let bioSyncAge = BiometricEngine.calculateBioSyncAge(
            chronologicalAge: chronoAge,
            currentRHR: bioAgeRHR,
            baselineRHR: baselineRHR,
            currentHRV: bioAgeHRV,
            baselineHRV: baselineHRV,
            vo2Max: vo2,
            sleepScore: bioAgeSleep,
            dailySteps: bioAgeSteps
        )

        let detailedBriefing = await GeminiAIService.shared.fetchAIBriefing(
            recoveryScore: recoveryScore,
            sleepScore: sleepScore,
            stressScore: momentaryStress,
            currentHRV: effectiveHRV,
            baselineHRV: baselineHRV,
            currentRHR: effectiveRHR,
            baselineRHR: baselineRHR,
            sleepSummary: sleep,
            bioSyncAge: bioSyncAge
        )

        // Pre-schedule upcoming hourly notifications with fresh biometrics
        await BioSyncNotificationManager.shared.scheduleRecurringHourlyNotifications(
            briefing: detailedBriefing,
            bioSyncAge: bioSyncAge,
            recoveryScore: recoveryScore,
            sleepScore: sleepScore
        )
    }
}
#else
/// Fallback stub when previewing or testing on Mac/iOS
public final class BackgroundManager {
    public static let shared = BackgroundManager()
    public let refreshIntervalSeconds: TimeInterval = 60 * 60
    private init() {}
    public func scheduleNextBackgroundRefresh() {}
    public func handleHealthKitBackgroundUpdate() async {}
}
#endif
