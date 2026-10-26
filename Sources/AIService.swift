import Foundation

/// AI Service that analyzes biometric scores and sensor deviations to provide
/// actionable coaching, recovery explanations, and stress mitigation prompts.
public final class AIService {
    public static let shared = AIService()

    private init() {}

    public struct HealthBriefing: Codable, Sendable {
        public let headline: String
        public let overallProgress: String
        public let biologicalAgeAnalysis: String
        public let cardiovascularStatus: String
        public let nervousSystemStatus: String
        public let trainingGuidance: String
        public let sleepArchitectureInsight: String
        public let stressIntervention: String?

        // Backward compatibility
        public var explanation: String {
            "\(biologicalAgeAnalysis) \(overallProgress)"
        }

        public init(
            headline: String,
            overallProgress: String,
            biologicalAgeAnalysis: String,
            cardiovascularStatus: String,
            nervousSystemStatus: String,
            trainingGuidance: String,
            sleepArchitectureInsight: String,
            stressIntervention: String?
        ) {
            self.headline = headline
            self.overallProgress = overallProgress
            self.biologicalAgeAnalysis = biologicalAgeAnalysis
            self.cardiovascularStatus = cardiovascularStatus
            self.nervousSystemStatus = nervousSystemStatus
            self.trainingGuidance = trainingGuidance
            self.sleepArchitectureInsight = sleepArchitectureInsight
            self.stressIntervention = stressIntervention
        }
    }

    // MARK: - Prompt Builder for LLM (OpenRouter / Gemini / Groq)
    public func generateAIPrompt(
        recoveryScore: Int,
        sleepScore: Int,
        stressScore: Int?,
        currentHRV: Double,
        baselineHRV: Double,
        currentRHR: Double,
        baselineRHR: Double,
        sleepSummary: SleepSessionSummary?,
        bioSyncAge: BioSyncAgeResult? = nil
    ) -> String {
        let hrvDelta = ((currentHRV - baselineHRV) / max(1, baselineHRV)) * 100.0
        let rhrDelta = currentRHR - baselineRHR

        var sleepStr = "No sleep recorded"
        if let s = sleepSummary {
            sleepStr = String(format: "Total: %.1fh, Deep: %.1fh, REM: %.1fh, Awake: %.0fm",
                              s.totalHours, s.deepHours, s.remHours, s.awakeHours * 60)
        }

        var ageSnippet = ""
        if let age = bioSyncAge {
            let relation = age.isYounger ? "younger than" : "older than"
            ageSnippet = """
            - Chronological Age: \(String(format: "%.1f", age.chronologicalAge)) yrs
            - BioSync Biological Age: \(String(format: "%.1f", age.bioSyncAge)) yrs (\(String(format: "%.1f", abs(age.ageDelta))) yrs \(relation) calendar age)
            - Longevity Tier: \(age.longevityTier)
            - Primary Driver: \(age.primaryDriver) (RHR Mod: \(age.rhrYearsModifier)y, HRV Mod: \(age.hrvYearsModifier)y, Sleep Mod: \(age.sleepYearsModifier)y, Activity Mod: \(age.activityYearsModifier)y)
            """
        }

        let hrvString = currentHRV > 0
            ? String(format: "%.0f ms (%+.1f%% vs baseline)", currentHRV, hrvDelta)
            : "No watch paired (local iPhone motion & steps active)"
        let rhrString = currentRHR > 0
            ? String(format: "%.0f bpm (%+.0f bpm vs baseline)", currentRHR, rhrDelta)
            : "No watch paired (local iPhone motion & steps active)"

        return """
        You are an elite sports physiologist and longevity AI coach analyzing biometric data from Apple Health.
        Provide a comprehensive clinical and athletic coaching breakdown in valid JSON.

        Telemetry:
        - Recovery Readiness: \(recoveryScore)%
        - Sleep Quality: \(sleepScore)% (\(sleepStr))
        - Momentary Inactivity Stress: \(stressScore.map { "\($0)/100" } ?? (currentRHR > 0 ? "In Motion" : "Requires Apple Watch"))
        - Nocturnal HRV: \(hrvString)
        - Nocturnal Resting HR: \(rhrString)
        \(ageSnippet)

        Respond ONLY in valid JSON matching this schema:
        {
          "headline": "Punchy 3-word title",
          "overallProgress": "1-2 sentences analyzing overall 30-day adaptation trend and physical progression.",
          "biologicalAgeAnalysis": "1-2 sentences on BioSync biological age versus calendar age and primary driver.",
          "cardiovascularStatus": "1 sentence on resting heart rate, stroke volume efficiency, and arterial workload.",
          "nervousSystemStatus": "1 sentence on autonomic balance and parasympathetic vagal tone.",
          "trainingGuidance": "1 sentence with clear training load recommendations (e.g. Zone 2, high strain, or active rest).",
          "sleepArchitectureInsight": "1 sentence on deep/REM restorative sleep stages.",
          "stressIntervention": "1 actionable nervous system regulation cue if stress is elevated, else null"
        }
        """
    }

    // MARK: - On-Device Fast Inference (Rule-based / Local AI fallback)
    public func generateLocalInsight(
        recoveryScore: Int,
        sleepScore: Int,
        stressScore: Int?,
        currentHRV: Double,
        baselineHRV: Double,
        currentRHR: Double,
        baselineRHR: Double,
        bioSyncAge: BioSyncAgeResult? = nil
    ) -> HealthBriefing {
        let hrvDelta = currentHRV - baselineHRV
        let rhrDelta = currentRHR - baselineRHR

        let headline: String
        let progress: String
        var bioAgeStr = "Biological age calibrated to baseline."
        let cardio: String
        let nervous: String
        let training: String
        let sleepInsight: String
        var intervention: String? = nil

        if let age = bioSyncAge {
            let sign = age.isYounger ? "-" : "+"
            bioAgeStr = "BioSync Age is \(String(format: "%.1f", age.bioSyncAge)) yrs (\(sign)\(String(format: "%.1f", abs(age.ageDelta)))y vs calendar age), driven by \(age.primaryDriver)."
        }

        let hasOptical = currentRHR > 0 && currentHRV > 0

        if recoveryScore >= 67 {
            headline = "Prime Recovery"
            progress = "Positive physiological trend with robust recovery resilience."
            cardio = hasOptical ? "Resting HR of \(Int(currentRHR)) bpm indicates high stroke volume efficiency and optimal myocardial recovery." : "Cardiovascular and motion telemetry tracked via local iPhone Health."
            nervous = hasOptical ? "Elevated HRV of \(Int(currentHRV)) ms confirms strong parasympathetic dominance." : "Autonomic nervous system is calibrated to current activity readiness."
            training = "Optimal readiness for progressive overload, conditioning, or daily activity goals."
            sleepInsight = "Restorative sleep architecture enabled effective neurovascular and tissue repair."
        } else if recoveryScore >= 34 {
            headline = "Moderate Readiness"
            progress = "Biometrics are holding steady within your standard physiological baseline range."
            cardio = hasOptical ? (rhrDelta > 3 ? "Resting HR is elevated by +\(Int(rhrDelta)) bpm, reflecting mild cardiovascular workload." : "Resting HR is stable near baseline.") : "Cardiovascular telemetry is in steady balance."
            nervous = hasOptical ? "Autonomic tone is balanced with moderate parasympathetic capacity." : "Autonomic tone is steady."
            training = "Maintain moderate training volume. Zone 2 cardio or steady-state resistance training recommended."
            sleepInsight = "Sleep quality provided baseline maintenance; aim for 30 minutes earlier bedtime tonight."
        } else {
            headline = "Recovery Suppressed"
            progress = "Biometrics indicate acute systemic strain or temporary recovery deficit."
            cardio = hasOptical ? "Elevated resting HR signals increased sympathetic cardiovascular demand." : "Cardiovascular demand is elevated; prioritize hydration and rest."
            nervous = hasOptical ? (hrvDelta < -10 ? "HRV suppressed by \(abs(Int(hrvDelta))) ms below baseline, reflecting blunted vagal tone." : "Autonomic nervous system is under strain.") : "Autonomic system indicates fatigue."
            training = "Prioritize active recovery, light walking, mobility work, and hydration today."
            sleepInsight = "Insufficient restorative deep sleep; prioritize recovery sleep cycles tonight."
        }

        if let stress = stressScore, stress > 65 {
            intervention = "High stationary stress (\(stress)/100). Take 2 minutes for 4-7-8 parasympathetic box breathing."
        }

        return HealthBriefing(
            headline: headline,
            overallProgress: progress,
            biologicalAgeAnalysis: bioAgeStr,
            cardiovascularStatus: cardio,
            nervousSystemStatus: nervous,
            trainingGuidance: training,
            sleepArchitectureInsight: sleepInsight,
            stressIntervention: intervention
        )
    }
}
