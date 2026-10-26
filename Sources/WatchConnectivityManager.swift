import Foundation
import WidgetKit

#if os(watchOS)
import ClockKit
#endif

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Manages background data transmission between Apple Watch SE 2 and the companion iPhone app.
/// Updates WidgetKit complications whenever new biometrics or AI briefings are finalized.
public final class WatchConnectivityManager: NSObject, ObservableObject {
    public static let shared = WatchConnectivityManager()

    @Published public var isReachable: Bool = false
    @Published public var isWatchPaired: Bool = false
    @Published public var isWatchAppInstalled: Bool = false
    @Published public var watchRecoveryScore: Int? = nil
    @Published public var watchStressScore: Int? = nil
    @Published public var watchSleepScore: Int? = nil
    @Published public var lastSyncDate: Date? = nil

    private override init() {
        super.init()
        #if canImport(WatchConnectivity) && !os(macOS)
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        #endif
    }

    // MARK: - Save Local Snapshot & Notify Complications
    public func updateComplicationsAndStorage(
        recovery: Int,
        stress: Int?,
        sleep: Int,
        bioAge: Double? = nil,
        bioDelta: Double? = nil
    ) {
        let defaults = UserDefaults.standard
        defaults.set(recovery, forKey: "latest_recovery_score")
        if let stress = stress {
            defaults.set(stress, forKey: "latest_stress_score")
        } else {
            defaults.removeObject(forKey: "latest_stress_score")
        }
        defaults.set(sleep, forKey: "latest_sleep_score")
        if let bioAge = bioAge {
            defaults.set(bioAge, forKey: "latest_biosync_age")
        }
        if let bioDelta = bioDelta {
            defaults.set(bioDelta, forKey: "latest_biosync_delta")
        }

        // Reload all watch face complications & WidgetKit
        #if os(watchOS) || os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif

        #if os(watchOS)
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
        #endif

        // Sync with iPhone companion if reachable
        sendLatestScoresToCompanion(recovery: recovery, stress: stress, sleep: sleep)
    }

    // MARK: - Send to iPhone Companion
    private func sendLatestScoresToCompanion(recovery: Int, stress: Int?, sleep: Int) {
        #if canImport(WatchConnectivity) && !os(macOS)
        guard WCSession.default.activationState == .activated else { return }

        let payload: [String: Any] = [
            "recoveryScore": recovery,
            "stressScore": stress ?? -1,
            "sleepScore": sleep,
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            try WCSession.default.updateApplicationContext(payload)
        } catch {
            print("Failed to sync application context with iPhone: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Send Settings to Watch
    public func syncSettingsToWatch(apiKey: String? = nil, baselineHRV: Double? = nil, baselineRHR: Double? = nil) {
        #if canImport(WatchConnectivity) && !os(macOS)
        guard WCSession.default.activationState == .activated else { return }
        var payload: [String: Any] = [:]
        if let key = apiKey { payload["gemini_api_key"] = key }
        if let hrv = baselineHRV { payload["baseline_hrv"] = hrv }
        if let rhr = baselineRHR { payload["baseline_rhr"] = rhr }
        payload["timestamp"] = Date().timeIntervalSince1970
        do {
            try WCSession.default.updateApplicationContext(payload)
            print("Successfully updated settings context for companion device.")
        } catch {
            print("Failed to sync settings context: \(error.localizedDescription)")
        }
        #endif
    }
}

#if canImport(WatchConnectivity) && !os(macOS)
extension WatchConnectivityManager: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            #if os(iOS)
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            #endif
        }
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            #if os(iOS)
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            #endif
        }
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    public func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
    }
    #endif

    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let recovery = applicationContext["recoveryScore"] as? Int {
                self.watchRecoveryScore = recovery
            }
            if let stress = applicationContext["stressScore"] as? Int {
                self.watchStressScore = stress >= 0 ? stress : nil
            }
            if let sleep = applicationContext["sleepScore"] as? Int {
                self.watchSleepScore = sleep
            }
            self.lastSyncDate = Date()
        }

        if let apiKey = applicationContext["gemini_api_key"] as? String {
            GeminiAIService.shared.apiKey = apiKey
        }
        if let baselineHRV = applicationContext["baseline_hrv"] as? Double {
            Task { @MainActor in
                HealthKitManager.shared.baselineHRV = baselineHRV
            }
        }
        if let baselineRHR = applicationContext["baseline_rhr"] as? Double {
            Task { @MainActor in
                HealthKitManager.shared.baselineRestingHeartRate = baselineRHR
            }
        }
    }
}
#endif
