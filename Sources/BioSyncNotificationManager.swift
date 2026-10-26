import Foundation
import UserNotifications
#if os(watchOS)
import WatchKit
#endif

/// Manages watchOS local notifications for hourly AI summaries, longevity alerts,
/// and guaranteed recurring background notifications.
@MainActor
public final class BioSyncNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = BioSyncNotificationManager()

    @Published public var isAuthorized: Bool = false
    @Published public var lastNotificationDate: Date? = nil
    @Published public var lastNotificationSummary: String = ""
    @Published public var pendingAlertsCount: Int = 0

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    /// Configures the notification center delegate and checks current authorization status
    public func configure() {
        notificationCenter.delegate = self

        // Register custom category for watchOS long-look / short-look presentation
        let category = UNNotificationCategory(
            identifier: "BIOSYNC_HOURLY_BRIEFING",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        notificationCenter.setNotificationCategories([category])

        Task {
            await checkAuthorization()
            await refreshPendingCount()
        }
    }

    /// Requests user authorization for alert, sound, badge, and time-sensitive notifications
    @discardableResult
    public func requestAuthorization() async -> Bool {
        do {
            var options: UNAuthorizationOptions = [.alert, .sound, .badge]
            #if os(watchOS) || os(iOS)
            options.insert(.timeSensitive)
            #endif

            let granted = try await notificationCenter.requestAuthorization(options: options)
            self.isAuthorized = granted
            print("BioSync Notification permission granted: \(granted)")
            await refreshPendingCount()
            return granted
        } catch {
            print("BioSync Notification permission error: \(error.localizedDescription)")
            self.isAuthorized = false
            return false
        }
    }

    /// Checks the current authorization status
    public func checkAuthorization() async {
        let settings = await notificationCenter.notificationSettings()
        self.isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
    }

    /// Refreshes the count of pending scheduled notifications
    public func refreshPendingCount() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        self.pendingAlertsCount = pending.count
    }

    // MARK: - Guaranteed Recurring Hourly Notifications Schedule
    /// Schedules a rolling sequence of hourly notifications + an autonomous recurring trigger.
    /// This guarantees that watchOS delivers notifications even if the app process is terminated or background refresh budget is delayed.
    public func scheduleRecurringHourlyNotifications(
        briefing: GeminiAIService.AIDetailedBriefing,
        bioSyncAge: BioSyncAgeResult,
        recoveryScore: Int,
        sleepScore: Int
    ) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        // Remove only previously queued hourly sequence notifications so delayed test alerts remain intact
        let sequenceIds = (1...12).map { "biosync.hourly.sequence.\($0)" } + ["biosync.hourly.repeating"]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: sequenceIds)

        let deltaSign = bioSyncAge.isYounger ? "-" : "+"
        let deltaFormatted = String(format: "%.1f", abs(bioSyncAge.ageDelta))
        let ageSubtitle = "Age: \(String(format: "%.1f", bioSyncAge.bioSyncAge)) (\(deltaSign)\(deltaFormatted)y) • Rec: \(recoveryScore)%"

        // 1. Pre-schedule targeted hourly check-ins for the next 8 hours
        let hourlyThemes: [(title: String, insight: String)] = [
            ("🧬 BioSync Hourly Longevity Check", briefing.overallProgress),
            ("⚡ BioSync Autonomic Nervous Status", briefing.nervousSystemStatus),
            ("❤️ BioSync Cardiovascular Health", briefing.cardiovascularStatus),
            ("🏃 BioSync Activity & Strain Target", briefing.trainingGuidance),
            ("🧠 BioSync Recovery & Stress Balance", briefing.stressIntervention ?? "Check posture, hydrate, and maintain deep diaphragmatic breathing."),
            ("🌙 BioSync Sleep & Tissue Repair", briefing.sleepArchitectureInsight),
            ("🧬 BioSync Biological Age Update", "Pacing at \(String(format: "%.1f", bioSyncAge.bioSyncAge))y. Keep autonomic balance high through steady respiration."),
            ("📈 BioSync Daily Health Synthesis", briefing.headline)
        ]

        for (index, theme) in hourlyThemes.enumerated() {
            let hourOffset = Double(index + 1)
            let secondsFromNow = hourOffset * 3600.0 // 1 hr, 2 hrs, 3 hrs, etc.

            let content = UNMutableNotificationContent()
            content.title = theme.title
            content.subtitle = ageSubtitle
            content.body = "💡 \(theme.insight)\n\n• Recovery: \(recoveryScore)% | BioSync Age: \(String(format: "%.1f", bioSyncAge.bioSyncAge))y"
            content.sound = .default
            #if os(watchOS) || os(iOS)
            content.interruptionLevel = .timeSensitive
            content.categoryIdentifier = "BIOSYNC_HOURLY_BRIEFING"
            #endif

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsFromNow, repeats: false)
            let request = UNNotificationRequest(
                identifier: "biosync.hourly.sequence.\(index + 1)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to schedule hourly notification #\(index + 1): \(error)")
            }
        }

        // 2. Fallback repeating trigger every 3600s (1 hour)
        let repeatingContent = UNMutableNotificationContent()
        repeatingContent.title = "🧬 BioSync AI Hourly Briefing"
        repeatingContent.subtitle = ageSubtitle
        repeatingContent.body = "💡 \(briefing.headline)\n\n• Progress: \(briefing.overallProgress)\n• Guidance: \(briefing.trainingGuidance)"
        repeatingContent.sound = .default
        #if os(watchOS) || os(iOS)
        repeatingContent.interruptionLevel = .timeSensitive
        repeatingContent.categoryIdentifier = "BIOSYNC_HOURLY_BRIEFING"
        #endif

        let repeatingTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600.0, repeats: true)
        let repeatingRequest = UNNotificationRequest(
            identifier: "biosync.hourly.repeating",
            content: repeatingContent,
            trigger: repeatingTrigger
        )

        do {
            try await notificationCenter.add(repeatingRequest)
            print("Successfully registered repeating hourly notification with watchOS")
        } catch {
            print("Failed to register repeating notification: \(error)")
        }

        await refreshPendingCount()
    }

    // MARK: - Immediate Notification Posting
    /// Posts an immediate AI Health Briefing notification to the Apple Watch
    public func postAISummaryNotification(
        briefing: GeminiAIService.AIDetailedBriefing,
        bioSyncAge: BioSyncAgeResult,
        recoveryScore: Int,
        sleepScore: Int,
        delaySeconds: TimeInterval = 1.0
    ) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        let content = UNMutableNotificationContent()
        content.title = "🧬 BioSync AI Health Briefing"

        let deltaSign = bioSyncAge.isYounger ? "-" : "+"
        let deltaFormatted = String(format: "%.1f", abs(bioSyncAge.ageDelta))
        content.subtitle = "Age: \(String(format: "%.1f", bioSyncAge.bioSyncAge)) (\(deltaSign)\(deltaFormatted)y) • Rec: \(recoveryScore)%"

        var bodyLines: [String] = []
        if !briefing.headline.isEmpty {
            bodyLines.append("💡 \(briefing.headline)")
        }
        if !briefing.overallProgress.isEmpty {
            bodyLines.append("📈 Progress: \(briefing.overallProgress)")
        }
        if !briefing.biologicalAgeAnalysis.isEmpty {
            bodyLines.append("🧬 Longevity: \(briefing.biologicalAgeAnalysis)")
        }
        if !briefing.trainingGuidance.isEmpty {
            bodyLines.append("⚡ Guidance: \(briefing.trainingGuidance)")
        }

        content.body = bodyLines.joined(separator: "\n\n")
        content.sound = .default
        #if os(watchOS) || os(iOS)
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "BIOSYNC_HOURLY_BRIEFING"
        #endif

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1.0, delaySeconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "biosync.immediate.ai.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            self.lastNotificationDate = Date()
            self.lastNotificationSummary = briefing.headline
            print("BioSync AI Summary notification queued (delay: \(delaySeconds)s)")

            #if os(watchOS)
            if delaySeconds <= 2.0 {
                WKInterfaceDevice.current().play(.notification)
            }
            #endif
        } catch {
            print("Failed to add notification request: \(error.localizedDescription)")
        }

        await refreshPendingCount()
    }

    /// Sends a test notification (either immediate in 1s or background in 10s)
    public func sendTestNotification(
        briefing: GeminiAIService.AIDetailedBriefing?,
        bioSyncAge: BioSyncAgeResult,
        recoveryScore: Int,
        sleepScore: Int,
        delaySeconds: TimeInterval = 1.0
    ) async {
        let fallbackBriefing = briefing ?? GeminiAIService.AIDetailedBriefing(
            headline: "Optimal Autonomic Balance",
            overallProgress: "Your resting heart rate and HRV reflect positive autonomic balance.",
            biologicalAgeAnalysis: "Cellular rejuvenation pace is \(bioSyncAge.isYounger ? "ahead of" : "tracking") chronological baseline.",
            cardiovascularStatus: "Myocardial efficiency stable with balanced stroke volume.",
            nervousSystemStatus: "Parasympathetic tone dominant with robust vagal modulation.",
            trainingGuidance: "Target moderate aerobic zone strain today.",
            sleepArchitectureInsight: "Sleep architecture sustained restorative REM stages.",
            stressIntervention: "Maintain current hydration protocol and steady respiration.",
            generatedAt: Date()
        )

        await postAISummaryNotification(
            briefing: fallbackBriefing,
            bioSyncAge: bioSyncAge,
            recoveryScore: recoveryScore,
            sleepScore: sleepScore,
            delaySeconds: delaySeconds
        )
    }

    // MARK: - UNUserNotificationCenterDelegate
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        #if os(watchOS) || os(iOS)
        completionHandler([.banner, .sound, .list])
        #else
        completionHandler([.sound])
        #endif
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
