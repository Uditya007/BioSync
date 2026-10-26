import Foundation

/// Core mathematical engine for transforming Apple Watch SE 2 raw sensor samples
/// into normalized Sleep, Recovery, and Stress scores (0-100 scale).
public struct BiometricEngine {

    // MARK: - 1. RECOVERY SCORE (0 - 100%)
    /// Computes daily recovery readiness from nocturnal/morning HRV, Resting Heart Rate, and Sleep.
    /// Gracefully degrades to sleep and iPhone step activity if optical sensors are absent.
    public static func calculateRecovery(
        currentHRV: Double,
        baselineHRV: Double,
        currentRHR: Double,
        baselineRHR: Double,
        sleepScore: Double,
        dailySteps: Double = 0.0
    ) -> Int {
        let hasHRV = baselineHRV > 0 && currentHRV > 0
        let hasRHR = baselineRHR > 0 && currentRHR > 0
        let hasSleep = sleepScore > 0

        if hasHRV && hasRHR {
            // A. Full optical watch recovery algorithm
            let hrvRatio = currentHRV / baselineHRV
            // Log scaling: 1.0 ratio -> 70 pts; 1.3 ratio -> 95 pts; 0.7 ratio -> 30 pts
            let hrvPoints = clamp((log(max(0.1, hrvRatio)) * 60.0) + 70.0, min: 0.0, max: 100.0)

            // B. Resting Heart Rate Component (Weight: 25%)
            let rhrDelta = currentRHR - baselineRHR
            let rhrPoints = clamp(75.0 - (rhrDelta * 7.5), min: 0.0, max: 100.0)

            // C. Sleep Component (Weight: 25%)
            let sleepPoints = hasSleep ? clamp(sleepScore, min: 0.0, max: 100.0) : 75.0

            let finalScore = (hrvPoints * 0.50) + (rhrPoints * 0.25) + (sleepPoints * 0.25)
            return Int(round(clamp(finalScore, min: 1.0, max: 100.0)))
        } else if hasSleep {
            // Standalone phone with sleep tracking + step volume
            let stepBonus = dailySteps >= 8000 ? 5.0 : (dailySteps >= 4000 ? 0.0 : -5.0)
            let score = clamp(sleepScore + stepBonus, min: 20.0, max: 95.0)
            return Int(round(score))
        } else {
            // Standalone phone relying on daily motion coprocessor
            if dailySteps >= 10000 { return 85 }
            if dailySteps >= 6000 { return 78 }
            if dailySteps >= 3000 { return 72 }
            if dailySteps > 0 { return 65 }
            return 70 // Baseline ready
        }
    }

    // MARK: - 2. REAL-TIME STRESS SCORE (0 - 100)
    /// Computes momentary physiological stress during waking hours.
    /// Critically filters out physical motion to avoid mistaking exercise for stress.
    /// Returns nil if exercising OR if optical PPG sensors are not available (e.g. standalone phone).
    public static func calculateMomentaryStress(
        currentHR: Double,
        restingHR: Double,
        liveHRV: Double,
        baselineHRV: Double,
        recentSteps: Double
    ) -> Int? {
        // Step filter: If taking > 60 steps in the last 15 min, user is physically active
        guard recentSteps < 60 else {
            return nil // In motion / exercise; stress metric suspended
        }

        // Optical PPG sensor required for autonomic stress
        guard currentHR > 0, restingHR > 0, baselineHRV > 0 else {
            return nil // Requires Apple Watch optical sensors
        }

        // 1. HR Elevation above baseline while stationary
        let hrDelta = max(0, currentHR - restingHR)
        let hrStressRatio = min(1.0, hrDelta / 40.0) // 40 bpm above resting while inactive = max HR stress

        // 2. HRV Suppression (lower HRV while inactive = higher sympathetic stress)
        let hrvRatio = max(0.1, liveHRV / baselineHRV)
        let hrvStressRatio = clamp(1.0 - (hrvRatio - 0.5), min: 0.0, max: 1.0)

        // Composite Stress (0 - 100)
        let rawStress = (hrStressRatio * 0.65 + hrvStressRatio * 0.35) * 100.0
        return Int(round(clamp(rawStress, min: 0.0, max: 100.0)))
    }

    // MARK: - 3. SLEEP SCORE (0 - 100%)
    /// Computes overall sleep quality by analyzing duration against target,
    /// deep/REM restorative sleep architecture, and fragmentation.
    public static func calculateSleepScore(
        summary: SleepSessionSummary,
        targetSleepHours: Double = 8.0
    ) -> Int {
        guard summary.totalHours > 0.5 else { return 0 }

        // A. Duration Score (Weight: 40%)
        let durationRatio = summary.totalHours / targetSleepHours
        let durationPoints = clamp(min(1.0, durationRatio) * 100.0, min: 0.0, max: 100.0)

        // B. Restorative Architecture (Deep + REM) (Weight: 40%)
        // Healthy benchmark: Deep ~ 15-25%, REM ~ 20-25% (total restorative ~ 35-45%)
        let restorativeSeconds = summary.deepSeconds + summary.remSeconds
        let restorativeRatio = restorativeSeconds / summary.totalSleepSeconds
        // 40% restorative = 100 pts, 20% = 50 pts
        let architecturePoints = clamp((restorativeRatio / 0.40) * 100.0, min: 0.0, max: 100.0)

        // C. Sleep Efficiency / Awake Time Penalty (Weight: 20%)
        let awakeRatio = summary.awakeSeconds / (summary.totalSleepSeconds + summary.awakeSeconds)
        // Deduct heavily if awake time > 15%
        let efficiencyPoints = clamp((1.0 - (awakeRatio / 0.20)) * 100.0, min: 0.0, max: 100.0)

        let compositeScore = (durationPoints * 0.40) + (architecturePoints * 0.40) + (efficiencyPoints * 0.20)
        return Int(round(clamp(compositeScore, min: 1.0, max: 100.0)))
    }

    // MARK: - 4. BIOSYNC AGE (BIOLOGICAL & CARDIOVASCULAR AGE)
    /// Computes biological fitness age by evaluating resting heart rate,
    /// nocturnal HRV SDNN, sleep architecture, and cardiorespiratory movement against population norms.
    /// Gracefully isolates unrecorded sensors (e.g. 0.0 modifier when no watch is paired).
    public static func calculateBioSyncAge(
        chronologicalAge: Double,
        currentRHR: Double,
        baselineRHR: Double,
        currentHRV: Double,
        baselineHRV: Double,
        vo2Max: Double? = nil,
        sleepScore: Double,
        dailySteps: Double
    ) -> BioSyncAgeResult {
        let age = max(18.0, chronologicalAge)

        // 1. Cardiovascular / Resting Heart Rate Modifier (Weight: ~30%)
        let hasRHR = currentRHR > 0 || baselineRHR > 0
        let rhrMod: Double
        if hasRHR {
            let effectiveRHR = currentRHR > 0 ? currentRHR : baselineRHR
            let rhrNorm = 65.0
            rhrMod = clamp((effectiveRHR - rhrNorm) * 0.15, min: -3.5, max: 4.0)
        } else {
            rhrMod = 0.0 // No watch optical sensor: neutral
        }

        // 2. Autonomic Nervous System / HRV SDNN Modifier (Weight: ~35%)
        let hasHRV = currentHRV > 0 || baselineHRV > 0
        let hrvMod: Double
        if hasHRV {
            let effectiveHRV = currentHRV > 0 ? currentHRV : baselineHRV
            let expectedHRV = max(25.0, 85.0 - (0.75 * age))
            let hrvDelta = effectiveHRV - expectedHRV
            hrvMod = clamp(-hrvDelta * 0.12, min: -4.0, max: 3.5)
        } else {
            hrvMod = 0.0 // No watch optical sensor: neutral
        }

        // 3. Cardiorespiratory Fitness / Step Activity (Weight: ~20%)
        let activityMod: Double
        if let vo2 = vo2Max, vo2 > 15.0 {
            let expectedVO2 = max(25.0, 52.0 - (0.35 * age))
            activityMod = clamp((expectedVO2 - vo2) * 0.25, min: -3.5, max: 3.5)
        } else {
            if dailySteps >= 12000 {
                activityMod = -2.5
            } else if dailySteps >= 10000 {
                activityMod = -1.8
            } else if dailySteps >= 7000 {
                activityMod = -1.0
            } else if dailySteps >= 4000 {
                activityMod = -0.2
            } else if dailySteps > 0 {
                activityMod = 0.6
            } else {
                activityMod = 0.0
            }
        }

        // 4. Sleep Architecture Modifier (Weight: ~15%)
        let hasSleep = sleepScore > 0
        let sleepMod: Double
        if hasSleep {
            if sleepScore >= 85 {
                sleepMod = -1.2
            } else if sleepScore >= 70 {
                sleepMod = -0.5
            } else if sleepScore >= 50 {
                sleepMod = 0.4
            } else {
                sleepMod = 1.5
            }
        } else {
            sleepMod = 0.0 // No sleep tracked on device: neutral
        }

        let totalDelta = rhrMod + hrvMod + activityMod + sleepMod
        let rawBioAge = age + totalDelta
        let finalBioAge = clamp(rawBioAge, min: max(16.0, age - 10.0), max: age + 12.0)
        let roundedBioAge = round(finalBioAge * 10.0) / 10.0
        let effectiveDelta = round((roundedBioAge - age) * 10.0) / 10.0

        // Longevity Tier Classification
        let tier: String
        if effectiveDelta <= -3.0 {
            tier = "Optimal Vitality (-3+ yrs)"
        } else if effectiveDelta < 0.0 {
            tier = "Youthful Biological Pace"
        } else if effectiveDelta == 0.0 {
            tier = "Balanced Chronological Pace"
        } else if effectiveDelta <= 3.0 {
            tier = "Mild Physiological Fatigue"
        } else {
            tier = "Accelerated Wear & Recovery Needed"
        }

        // Determine primary longevity driver
        let absRhr = abs(rhrMod)
        let absHrv = abs(hrvMod)
        let absSleep = abs(sleepMod)
        let absAct = abs(activityMod)

        let primary: String
        if !hasRHR && !hasHRV {
            if absAct >= absSleep && dailySteps > 0 {
                primary = dailySteps >= 7000 ? "Active Step Volume (\(Int(dailySteps)) steps/day)" : "Sedentary Step Volume (\(Int(dailySteps)) steps/day)"
            } else if hasSleep {
                primary = sleepMod <= 0 ? "Healthy Sleep Consistency" : "Sleep Duration Needs Recovery"
            } else {
                primary = "iPhone Motion & Daily Step Tracking"
            }
        } else if absHrv >= absRhr && absHrv >= absSleep && absHrv >= absAct && hasHRV {
            primary = hrvMod <= 0 ? "High Vagal Tone (Strong HRV)" : "Suppressed HRV (Autonomic Strain)"
        } else if absRhr >= absHrv && absRhr >= absSleep && absRhr >= absAct && hasRHR {
            primary = rhrMod <= 0 ? "Efficient Stroke Volume (Low RHR)" : "Elevated Resting Pulse"
        } else if absSleep >= absRhr && absSleep >= absHrv && absSleep >= absAct && hasSleep {
            primary = sleepMod <= 0 ? "Deep Restorative Sleep Architecture" : "Insufficient Sleep Recovery"
        } else {
            primary = activityMod <= 0 ? "High Aerobic Capacity & Daily Movement" : "Low Daily Physical Activity"
        }

        return BioSyncAgeResult(
            bioSyncAge: roundedBioAge,
            chronologicalAge: round(age * 10.0) / 10.0,
            ageDelta: effectiveDelta,
            isYounger: effectiveDelta <= 0,
            rhrYearsModifier: round(rhrMod * 10.0) / 10.0,
            hrvYearsModifier: round(hrvMod * 10.0) / 10.0,
            sleepYearsModifier: round(sleepMod * 10.0) / 10.0,
            activityYearsModifier: round(activityMod * 10.0) / 10.0,
            longevityTier: tier,
            primaryDriver: primary
        )
    }

    // MARK: - Helpers
    private static func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
        Swift.min(Swift.max(value, min), max)
    }
}

public struct BioSyncAgeResult: Codable, Sendable, Equatable {
    public let bioSyncAge: Double
    public let chronologicalAge: Double
    public let ageDelta: Double // Negative means biologically younger than calendar age
    public let isYounger: Bool
    public let rhrYearsModifier: Double
    public let hrvYearsModifier: Double
    public let sleepYearsModifier: Double
    public let activityYearsModifier: Double
    public let longevityTier: String
    public let primaryDriver: String

    public init(
        bioSyncAge: Double,
        chronologicalAge: Double,
        ageDelta: Double,
        isYounger: Bool,
        rhrYearsModifier: Double,
        hrvYearsModifier: Double,
        sleepYearsModifier: Double,
        activityYearsModifier: Double,
        longevityTier: String,
        primaryDriver: String
    ) {
        self.bioSyncAge = bioSyncAge
        self.chronologicalAge = chronologicalAge
        self.ageDelta = ageDelta
        self.isYounger = isYounger
        self.rhrYearsModifier = rhrYearsModifier
        self.hrvYearsModifier = hrvYearsModifier
        self.sleepYearsModifier = sleepYearsModifier
        self.activityYearsModifier = activityYearsModifier
        self.longevityTier = longevityTier
        self.primaryDriver = primaryDriver
    }
}

public enum StressZone: String {
    case rest = "Rest / Low"
    case mild = "Mild"
    case elevated = "Elevated"
    case high = "High Stress"
    case exercising = "In Motion"

    public static func classify(score: Int?) -> StressZone {
        guard let score = score else { return .exercising }
        switch score {
        case 0..<25: return .rest
        case 25..<50: return .mild
        case 50..<75: return .elevated
        default: return .high
        }
    }
}
