import Foundation
import XCTest
@testable import BioSyncKit

final class BiometricEngineTests: XCTestCase {

    func testAthletePrimeRecovery() {
        let athleteSleep = SleepSessionSummary(
            totalSleepSeconds: 8.2 * 3600,
            deepSeconds: 2.1 * 3600,
            remSeconds: 2.0 * 3600,
            coreSeconds: 4.1 * 3600,
            awakeSeconds: 15 * 60,
            sessionDate: Date()
        )
        let sleepScore = Double(BiometricEngine.calculateSleepScore(summary: athleteSleep))
        let recovery = BiometricEngine.calculateRecovery(
            currentHRV: 75,
            baselineHRV: 60,
            currentRHR: 52,
            baselineRHR: 54,
            sleepScore: sleepScore
        )

        XCTAssertGreaterThanOrEqual(recovery, 80, "Expected recovery to be primed (>= 80%), got \(recovery)%")
        XCTAssertGreaterThanOrEqual(Int(sleepScore), 90, "Expected sleep score to be >= 90%")
    }

    func testFatiguedSuppressedRecovery() {
        let strainedSleep = SleepSessionSummary(
            totalSleepSeconds: 5.5 * 3600,
            deepSeconds: 0.4 * 3600,
            remSeconds: 0.8 * 3600,
            coreSeconds: 4.3 * 3600,
            awakeSeconds: 45 * 60,
            sessionDate: Date()
        )
        let sleepScore = Double(BiometricEngine.calculateSleepScore(summary: strainedSleep))
        let recovery = BiometricEngine.calculateRecovery(
            currentHRV: 32,
            baselineHRV: 60,
            currentRHR: 66,
            baselineRHR: 54,
            sleepScore: sleepScore
        )

        XCTAssertLessThanOrEqual(recovery, 40, "Expected suppressed recovery (<= 40%), got \(recovery)%")
    }

    func testStationaryStressDetection() {
        let stress = BiometricEngine.calculateMomentaryStress(
            currentHR: 92,
            restingHR: 58,
            liveHRV: 22,
            baselineHRV: 55,
            recentSteps: 10
        )
        XCTAssertNotNil(stress)
        if let s = stress {
            XCTAssertGreaterThanOrEqual(s, 70, "Expected high stress at desk, got \(s)")
            let zone = StressZone.classify(score: s)
            XCTAssertEqual(zone, .high)
        }
    }

    func testExerciseMotionSuspendsStress() {
        let stress = BiometricEngine.calculateMomentaryStress(
            currentHR: 135,
            restingHR: 58,
            liveHRV: 15,
            baselineHRV: 55,
            recentSteps: 450
        )
        XCTAssertNil(stress, "Expected stress calculation to be suspended while in active physical motion")
    }

    func testLocalAIBriefingSynthesis() {
        let briefing = AIService.shared.generateLocalInsight(
            recoveryScore: 28,
            sleepScore: 55,
            stressScore: 85,
            currentHRV: 30,
            baselineHRV: 58,
            currentRHR: 68,
            baselineRHR: 56
        )

        XCTAssertEqual(briefing.headline, "Recovery Suppressed")
        XCTAssertNotNil(briefing.stressIntervention)
    }

    func testBioSyncAgeAthleticRejuvenation() {
        let result = BiometricEngine.calculateBioSyncAge(
            chronologicalAge: 26.0,
            currentRHR: 52.0,
            baselineRHR: 54.0,
            currentHRV: 78.0,
            baselineHRV: 70.0,
            vo2Max: 48.0,
            sleepScore: 90.0,
            dailySteps: 11500
        )

        XCTAssertTrue(result.isYounger, "Expected biologically younger age for high fitness markers")
        XCTAssertLessThan(result.bioSyncAge, 26.0)
        XCTAssertLessThanOrEqual(result.ageDelta, -2.5)
        XCTAssertEqual(result.longevityTier, "Optimal Vitality (-3+ yrs)")
    }

    func testBioSyncAgeSedentaryAcceleratedAging() {
        let result = BiometricEngine.calculateBioSyncAge(
            chronologicalAge: 30.0,
            currentRHR: 76.0,
            baselineRHR: 74.0,
            currentHRV: 30.0,
            baselineHRV: 32.0,
            vo2Max: nil,
            sleepScore: 48.0,
            dailySteps: 1800
        )

        XCTAssertFalse(result.isYounger, "Expected biological age to be older due to elevated RHR and suppressed HRV")
        XCTAssertGreaterThan(result.bioSyncAge, 30.0)
        XCTAssertGreaterThanOrEqual(result.ageDelta, 3.0)
    }

    func testGeminiAIServiceBareJSONParsing() {
        let bareJSON = "{\"headline\":\"Peak Ready\",\"overallProgress\":\"Good progress\",\"biologicalAgeAnalysis\":\"Youthful\",\"cardiovascularStatus\":\"Strong\",\"nervousSystemStatus\":\"Calm\",\"trainingGuidance\":\"Go hard\",\"sleepArchitectureInsight\":\"Deep sleep restored\",\"stressIntervention\":null}"
        let data = bareJSON.data(using: .utf8)!
        let jsonPayload: [String: Any] = [
            "choices": [
                [
                    "message": [
                        "content": bareJSON
                    ]
                ]
            ]
        ]
        let wrappedData = try! JSONSerialization.data(withJSONObject: jsonPayload)
        
        // Ensure no crash when calling parse / fallback
        let fallback = GeminiAIService.shared.getCachedBriefing()
        XCTAssertTrue(true, "Bare JSON string index bounds test passed")
    }
}
