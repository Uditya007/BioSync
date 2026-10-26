import Foundation
import HealthKit
import Combine

/// Advanced HealthKit Manager for Apple Watch SE 2.
/// Features live optical sensor streaming (green LEDs), 30-day baseline calibration,
/// and comprehensive sleep stage analytics.
@MainActor
public final class HealthKitManager: NSObject, ObservableObject {
    public static let shared = HealthKitManager()

    // Preview-safe lazy initialization
    public private(set) lazy var healthStore: HKHealthStore? = {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1",
              HKHealthStore.isHealthDataAvailable() else {
            return nil
        }
        return HKHealthStore()
    }()

    // MARK: - Published Live Telemetry
    @Published public var currentHeartRate: Double = 0.0
    @Published public var latestHRV_SDNN: Double = 0.0
    @Published public var baselineHRV: Double = 0.0
    @Published public var restingHeartRate: Double = 0.0
    @Published public var baselineRestingHeartRate: Double = 0.0
    @Published public var todaySteps: Double = 0.0
    @Published public var recentSteps: Double = 0.0
    @Published public var todayDistanceKm: Double = 0.0
    @Published public var todayActiveCalories: Double = 0.0
    @Published public var todayFlightsClimbed: Double = 0.0
    @Published public var walkingHeartRateAverage: Double = 0.0
    @Published public var sleepData: SleepSessionSummary?
    @Published public var chronologicalAge: Double = 25.0
    @Published public var isAgeFromHealthProfile: Bool = false
    @Published public var biologicalSexString: String = "Not Set"
    @Published public var vo2Max: Double? = nil
    @Published public var isAuthorized: Bool = false
    @Published public var isSensorScanning: Bool = false
    @Published public var authorizationStatusMessage: String = "Checking..."
    @Published public var hasHeartRateData: Bool = false
    @Published public var hasHRVData: Bool = false
    @Published public var hasRestingHRData: Bool = false
    @Published public var hasSleepData: Bool = false

    // MARK: - Published Past Week (7-Day) Analytics
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

    // MARK: - Published Today Statistical Extremes
    @Published public var minHeartRateToday: Double = 0.0
    @Published public var maxHeartRateToday: Double = 0.0
    @Published public var avgHeartRateToday: Double = 0.0

    #if os(watchOS)
    // Live Sensor Workout Session (lights up green PPG LEDs on Apple Watch)
    private var workoutSession: HKWorkoutSession?
    private var liveBuilder: HKLiveWorkoutBuilder?
    #endif

    private override init() {
        super.init()
    }

    // MARK: - Permissions
    public func requestAuthorization() async throws {
        guard let store = healthStore, HKHealthStore.isHealthDataAvailable() else {
            self.authorizationStatusMessage = "HealthKit Unavailable"
            throw HealthKitError.notAvailableOnDevice
        }

        var readTypes: Set<HKObjectType> = []
        let identifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .heartRateVariabilitySDNN,
            .restingHeartRate,
            .walkingHeartRateAverage,
            .stepCount,
            .distanceWalkingRunning,
            .flightsClimbed,
            .activeEnergyBurned
        ]
        for id in identifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                readTypes.insert(type)
            }
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            readTypes.insert(sleep)
        }

        if let vo2Type = HKQuantityType.quantityType(forIdentifier: .vo2Max) {
            readTypes.insert(vo2Type)
        }
        if let dobType = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth) {
            readTypes.insert(dobType)
        }
        if let sexType = HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex) {
            readTypes.insert(sexType)
        }

        #if os(watchOS)
        let shareTypes: Set<HKSampleType> = [
            HKQuantityType.workoutType()
        ]
        #else
        let shareTypes: Set<HKSampleType> = []
        #endif

        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
        self.isAuthorized = true
        self.authorizationStatusMessage = "Sensors Connected"

        // Fetch real historical baselines & latest biometrics
        await calculateHistoricalBaselines()
        await calculatePastWeekAnalytics()
        await fetchLatestBiometrics()
        try await enableBackgroundObservers()
    }

    // MARK: - 30-Day Real Historical Baseline Calculation
    public func calculateHistoricalBaselines() async {
        guard let store = healthStore else { return }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: thirtyDaysAgo, end: Date(), options: .strictStartDate)

        // 1. Calculate Real 30-Day Average HRV
        if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            let avgHRV = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, _ in
                    let val = stats?.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli))
                    continuation.resume(returning: val)
                }
                store.execute(query)
            }
            if let avgHRV, avgHRV > 10 {
                self.baselineHRV = avgHRV
            }
        }

        // 2. Calculate Real 30-Day Average Resting Heart Rate
        if let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            let avgRHR = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: rhrType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, _ in
                    let val = stats?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
                    continuation.resume(returning: val)
                }
                store.execute(query)
            }
            if let avgRHR, avgRHR > 35 {
                self.baselineRestingHeartRate = avgRHR
            }
        }
    }

    // MARK: - Past Week (7-Day) Biological Age Analytics
    /// Extracts aggregated biometrics across the past 7 days from Apple Health
    /// to provide a stable, longitudinal assessment of biological fitness age.
    public func calculatePastWeekAnalytics() async {
        guard let store = healthStore else { return }

        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) ?? now
        let weekPredicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)

        // 1. Past 7-Day Average, Min & Max Resting Heart Rate
        if let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            let rhrStats = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: rhrType, quantitySamplePredicate: weekPredicate, options: [.discreteAverage, .discreteMin, .discreteMax]) { _, stats, _ in
                    continuation.resume(returning: stats)
                }
                store.execute(query)
            }
            if let stats = rhrStats {
                if let avg = stats.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")), avg > 35 {
                    self.pastWeekAverageRHR = round(avg * 10.0) / 10.0
                }
                if let min = stats.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/min")), min > 30 {
                    self.pastWeekMinRHR = round(min * 10.0) / 10.0
                }
                if let max = stats.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/min")), max > 30 {
                    self.pastWeekMaxRHR = round(max * 10.0) / 10.0
                }
            }
        }

        // 2. Past 7-Day Average, Min & Max HRV SDNN
        if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            let hrvStats = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: weekPredicate, options: [.discreteAverage, .discreteMin, .discreteMax]) { _, stats, _ in
                    continuation.resume(returning: stats)
                }
                store.execute(query)
            }
            if let stats = hrvStats {
                if let avg = stats.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli)), avg > 5 {
                    self.pastWeekAverageHRV = round(avg * 10.0) / 10.0
                }
                if let min = stats.minimumQuantity()?.doubleValue(for: .secondUnit(with: .milli)), min > 5 {
                    self.pastWeekMinHRV = round(min * 10.0) / 10.0
                }
                if let max = stats.maximumQuantity()?.doubleValue(for: .secondUnit(with: .milli)), max > 5 {
                    self.pastWeekMaxHRV = round(max * 10.0) / 10.0
                }
            }
        }

        // 3. Past 7-Day Cumulative Step Volume & Daily Average
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let totalWeekSteps = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: weekPredicate, options: .cumulativeSum) { _, stats, _ in
                    let sum = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    continuation.resume(returning: sum)
                }
                store.execute(query)
            }
            self.pastWeekTotalSteps = round(totalWeekSteps)
            if totalWeekSteps > 0 {
                self.pastWeekAverageDailySteps = round(totalWeekSteps / 7.0)
            }
        }

        // 4. Past 7-Day Cumulative Distance (km)
        if let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let totalDist = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: distType, quantitySamplePredicate: weekPredicate, options: .cumulativeSum) { _, stats, _ in
                    let sum = stats?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
                    continuation.resume(returning: sum)
                }
                store.execute(query)
            }
            self.pastWeekTotalDistanceKm = round(totalDist * 10.0) / 10.0
        }

        // 5. Past 7-Day Cumulative Active Calories (kcal)
        if let calsType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let totalCals = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: calsType, quantitySamplePredicate: weekPredicate, options: .cumulativeSum) { _, stats, _ in
                    let sum = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    continuation.resume(returning: sum)
                }
                store.execute(query)
            }
            self.pastWeekTotalActiveCalories = round(totalCals)
        }

        // 6. Past 7-Day Cumulative Flights Climbed
        if let flightType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            let totalFlights = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: flightType, quantitySamplePredicate: weekPredicate, options: .cumulativeSum) { _, stats, _ in
                    let sum = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    continuation.resume(returning: sum)
                }
                store.execute(query)
            }
            self.pastWeekTotalFlightsClimbed = round(totalFlights)
        }

        // 7. Past 7-Day Average Sleep Architecture & Stage Breakdown
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let sleepSamples = await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: sleepType, predicate: weekPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
                store.execute(query)
            }

            if !sleepSamples.isEmpty {
                var dailySessions: [Date: [HKCategorySample]] = [:]
                for sample in sleepSamples {
                    let dayKey = calendar.startOfDay(for: sample.endDate)
                    dailySessions[dayKey, default: []].append(sample)
                }

                var totalSleepSecondsAllDays: TimeInterval = 0
                var totalDeepSecondsAllDays: TimeInterval = 0
                var totalRemSecondsAllDays: TimeInterval = 0
                var totalCoreSecondsAllDays: TimeInterval = 0
                var totalAwakeSecondsAllDays: TimeInterval = 0
                var totalScoreAllDays: Double = 0
                var validDaysCount: Double = 0

                for (_, daySamples) in dailySessions {
                    var deep: TimeInterval = 0
                    var rem: TimeInterval = 0
                    var core: TimeInterval = 0
                    var awake: TimeInterval = 0

                    for s in daySamples {
                        let duration = s.endDate.timeIntervalSince(s.startDate)
                        switch s.value {
                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                            deep += duration
                        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            rem += duration
                        case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                             HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                            core += duration
                        case HKCategoryValueSleepAnalysis.awake.rawValue:
                            awake += duration
                        default:
                            break
                        }
                    }

                    let totalSleep = deep + rem + core
                    if totalSleep >= 1800 { // at least 30 mins
                        let summary = SleepSessionSummary(
                            totalSleepSeconds: totalSleep,
                            deepSeconds: deep,
                            remSeconds: rem,
                            coreSeconds: core,
                            awakeSeconds: awake,
                            sessionDate: daySamples.first?.endDate ?? now
                        )
                        let dayScore = Double(BiometricEngine.calculateSleepScore(summary: summary))
                        totalScoreAllDays += dayScore
                        totalSleepSecondsAllDays += totalSleep
                        totalDeepSecondsAllDays += deep
                        totalRemSecondsAllDays += rem
                        totalCoreSecondsAllDays += core
                        totalAwakeSecondsAllDays += awake
                        validDaysCount += 1.0
                    }
                }

                if validDaysCount > 0 {
                    self.pastWeekAverageSleepScore = round(totalScoreAllDays / validDaysCount)
                    self.pastWeekAverageSleepHours = round((totalSleepSecondsAllDays / (validDaysCount * 3600.0)) * 10.0) / 10.0
                    self.pastWeekAverageDeepHours = round((totalDeepSecondsAllDays / (validDaysCount * 3600.0)) * 10.0) / 10.0
                    self.pastWeekAverageRemHours = round((totalRemSecondsAllDays / (validDaysCount * 3600.0)) * 10.0) / 10.0
                    self.pastWeekAverageCoreHours = round((totalCoreSecondsAllDays / (validDaysCount * 3600.0)) * 10.0) / 10.0
                    self.pastWeekAverageAwakeHours = round((totalAwakeSecondsAllDays / (validDaysCount * 3600.0)) * 10.0) / 10.0
                    if totalSleepSecondsAllDays > 0 {
                        self.pastWeekDeepPercentage = Int(round((totalDeepSecondsAllDays / totalSleepSecondsAllDays) * 100))
                        self.pastWeekRemPercentage = Int(round((totalRemSecondsAllDays / totalSleepSecondsAllDays) * 100))
                        self.pastWeekCorePercentage = Int(round((totalCoreSecondsAllDays / totalSleepSecondsAllDays) * 100))
                        let timeInBed = totalSleepSecondsAllDays + totalAwakeSecondsAllDays
                        if timeInBed > 0 {
                            self.pastWeekSleepEfficiency = Int(round((totalSleepSecondsAllDays / timeInBed) * 100))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Live Sensor Scan (Fires the Green LEDs on Apple Watch)
    public func toggleLiveSensorScan() {
        if isSensorScanning {
            stopLiveSensorScan()
        } else {
            startLiveSensorScan()
        }
    }

    public func startLiveSensorScan() {
        #if os(watchOS)
        guard let store = healthStore, !isSensorScanning else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: store, configuration: configuration)
            liveBuilder = workoutSession?.associatedWorkoutBuilder()
            liveBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)

            workoutSession?.delegate = self
            liveBuilder?.delegate = self

            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            liveBuilder?.beginCollection(withStart: startDate) { success, error in
                if success {
                    Task { @MainActor in
                        self.isSensorScanning = true
                    }
                }
            }
        } catch {
            print("Failed to start optical sensor session: \(error.localizedDescription)")
        }
        #endif
    }

    public func stopLiveSensorScan() {
        #if os(watchOS)
        guard isSensorScanning, let session = workoutSession, let builder = liveBuilder else { return }
        session.end()
        builder.endCollection(withEnd: Date()) { success, _ in
            builder.finishWorkout { _, _ in
                Task { @MainActor in
                    self.isSensorScanning = false
                    await self.fetchLatestBiometrics()
                }
            }
        }
        #endif
    }

    // MARK: - Background Delivery
    private func enableBackgroundObservers() async throws {
        guard let store = healthStore else { return }

        let typesToObserve: [HKQuantityTypeIdentifier] = [.heartRate, .heartRateVariabilitySDNN, .restingHeartRate]
        for identifier in typesToObserve {
            guard let sampleType = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            try await store.enableBackgroundDelivery(for: sampleType, frequency: .hourly)

            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, completionHandler, error in
                guard error == nil else { completionHandler(); return }
                Task { @MainActor [weak self] in
                    guard let self = self else { completionHandler(); return }
                    await self.fetchLatestBiometrics()
                    await BackgroundManager.shared.handleHealthKitBackgroundUpdate()
                    completionHandler()
                }
            }
            store.execute(query)
        }
    }

    // MARK: - Fetch Latest Biometrics
    public func fetchLatestBiometrics() async {
        guard let store = healthStore else { return }

        // 1. Query Real Date of Birth for Biological Age
        var foundAgeFromHealth: Bool = false
        do {
            let dobComponents = try store.dateOfBirthComponents()
            if let birthDate = dobComponents.date {
                let ageSeconds = Date().timeIntervalSince(birthDate)
                let years = ageSeconds / (365.2425 * 86400.0)
                if years >= 12.0 && years <= 115.0 {
                    self.chronologicalAge = round(years * 10.0) / 10.0
                    self.isAgeFromHealthProfile = true
                    foundAgeFromHealth = true
                }
            }
        } catch {
            // DOB not entered in Apple Health
        }

        if !foundAgeFromHealth {
            let savedAge = UserDefaults.standard.double(forKey: "user_custom_age")
            if savedAge >= 12.0 && savedAge <= 115.0 {
                self.chronologicalAge = savedAge
                self.isAgeFromHealthProfile = false
            } else {
                self.chronologicalAge = 25.0
                self.isAgeFromHealthProfile = false
            }
        }

        // 2. Query Real Biological Sex
        if let sex = try? store.biologicalSex().biologicalSex {
            switch sex {
            case .female: self.biologicalSexString = "Female"
            case .male: self.biologicalSexString = "Male"
            case .other: self.biologicalSexString = "Other"
            default: self.biologicalSexString = "Not Set in Health"
            }
        }

        // 3. Parallel Queries for Vitals & Activity
        async let hr = fetchLatestQuantitySample(for: .heartRate, unit: HKUnit(from: "count/min"))
        async let hrv = fetchLatestQuantitySample(for: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let rhr = fetchLatestQuantitySample(for: .restingHeartRate, unit: HKUnit(from: "count/min"))
        async let walkingHR = fetchLatestQuantitySample(for: .walkingHeartRateAverage, unit: HKUnit(from: "count/min"))
        async let vo2 = fetchLatestQuantitySample(for: .vo2Max, unit: HKUnit(from: "ml/kg*min"))
        async let steps = fetchTodaySteps()
        async let dist = fetchTodayCumulativeQuantity(for: .distanceWalkingRunning, unit: .meterUnit(with: .kilo))
        async let cals = fetchTodayCumulativeQuantity(for: .activeEnergyBurned, unit: .kilocalorie())
        async let flights = fetchTodayCumulativeQuantity(for: .flightsClimbed, unit: .count())
        async let recent = fetchRecentSteps(minutes: 15)
        async let sleep = fetchLatestSleepData()

        let (newHR, newHRV, newRHR, newWalkingHR, newVO2, newSteps, newDist, newCals, newFlights, newRecentSteps, newSleep) =
            await (hr, hrv, rhr, walkingHR, vo2, steps, dist, cals, flights, recent, sleep)

        // Heart Rate
        if let newHR, newHR > 0 {
            self.currentHeartRate = newHR
            self.hasHeartRateData = true
        } else {
            self.currentHeartRate = 0.0
            self.hasHeartRateData = false
        }

        // Today's Heart Rate Discrete Extremes (Min, Max, Avg)
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let todayPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
            let hrStats = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: hrType, quantitySamplePredicate: todayPredicate, options: [.discreteMin, .discreteMax, .discreteAverage]) { _, stats, _ in
                    continuation.resume(returning: stats)
                }
                store.execute(query)
            }
            if let stats = hrStats {
                if let minQ = stats.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/min")), minQ > 0 {
                    self.minHeartRateToday = round(minQ)
                }
                if let maxQ = stats.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/min")), maxQ > 0 {
                    self.maxHeartRateToday = round(maxQ)
                }
                if let avgQ = stats.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")), avgQ > 0 {
                    self.avgHeartRateToday = round(avgQ)
                }
            }
        }

        // HRV
        if let newHRV, newHRV > 0 {
            self.latestHRV_SDNN = newHRV
            self.hasHRVData = true
        } else {
            self.latestHRV_SDNN = 0.0
            self.hasHRVData = false
        }

        // Resting Heart Rate
        if let newRHR, newRHR > 0 {
            self.restingHeartRate = newRHR
            self.hasRestingHRData = true
        } else if let newWalkingHR, newWalkingHR > 0 {
            self.restingHeartRate = max(45.0, newWalkingHR - 15.0)
            self.walkingHeartRateAverage = newWalkingHR
            self.hasRestingHRData = true
        } else {
            self.restingHeartRate = 0.0
            self.hasRestingHRData = false
        }

        if let newVO2, newVO2 > 0 { self.vo2Max = newVO2 }
        self.todaySteps = newSteps
        self.todayDistanceKm = round(newDist * 10.0) / 10.0
        self.todayActiveCalories = round(newCals)
        self.todayFlightsClimbed = round(newFlights)
        self.recentSteps = newRecentSteps

        if let newSleep {
            self.sleepData = newSleep
            self.hasSleepData = true
        } else {
            self.hasSleepData = false
        }
    }

    public func fetchTodayCumulativeQuantity(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let store = healthStore,
              let sampleType = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: sampleType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let sum = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: sum)
            }
            store.execute(query)
        }
    }

    private func fetchLatestQuantitySample(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let store = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    public func fetchTodaySteps() async -> Double {
        guard let store = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let sum = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: sum)
            }
            store.execute(query)
        }
    }

    /// Fetches steps taken in the past `minutes` (default: 15 min) to filter out physical motion from autonomic stress.
    public func fetchRecentSteps(minutes: Int = 15) async -> Double {
        guard let store = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let startDate = Calendar.current.date(byAdding: .minute, value: -minutes, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let sum = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: sum)
            }
            store.execute(query)
        }
    }

    // Comprehensive 48-hour sleep extraction
    public func fetchLatestSleepData() async -> SleepSessionSummary? {
        guard let store = healthStore,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let startDate = Calendar.current.date(byAdding: .hour, value: -48, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Filter to the most recent continuous sleep window (past 20 hours)
                let cutoff = Calendar.current.date(byAdding: .hour, value: -20, to: Date()) ?? Date()
                let recentSamples = sleepSamples.filter { $0.endDate >= cutoff }

                var deepDuration: TimeInterval = 0
                var remDuration: TimeInterval = 0
                var coreDuration: TimeInterval = 0
                var awakeDuration: TimeInterval = 0

                for sample in recentSamples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepDuration += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remDuration += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                         HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        coreDuration += duration
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        awakeDuration += duration
                    default:
                        break
                    }
                }

                let totalSleepDuration = deepDuration + remDuration + coreDuration
                guard totalSleepDuration > 1200 else { // 20 min threshold
                    continuation.resume(returning: nil)
                    return
                }

                let summary = SleepSessionSummary(
                    totalSleepSeconds: totalSleepDuration,
                    deepSeconds: deepDuration,
                    remSeconds: remDuration,
                    coreSeconds: coreDuration,
                    awakeSeconds: awakeDuration,
                    sessionDate: recentSamples.first?.endDate ?? Date()
                )
                continuation.resume(returning: summary)
            }
            store.execute(query)
        }
    }
}

#if os(watchOS)
// MARK: - HKWorkoutSessionDelegate & Live Builder
extension HealthKitManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}

    nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) else { continue }

            let statistics = workoutBuilder.statistics(for: quantityType)
            if let latestHeartRateQuantity = statistics?.mostRecentQuantity() {
                let bpm = latestHeartRateQuantity.doubleValue(for: HKUnit(from: "count/min"))
                Task { @MainActor in
                    self.currentHeartRate = bpm
                }
            }
        }
    }
}
#endif

public struct SleepSessionSummary: Sendable {
    public let totalSleepSeconds: TimeInterval
    public let deepSeconds: TimeInterval
    public let remSeconds: TimeInterval
    public let coreSeconds: TimeInterval
    public let awakeSeconds: TimeInterval
    public let sessionDate: Date

    public init(totalSleepSeconds: TimeInterval, deepSeconds: TimeInterval, remSeconds: TimeInterval, coreSeconds: TimeInterval, awakeSeconds: TimeInterval, sessionDate: Date) {
        self.totalSleepSeconds = totalSleepSeconds
        self.deepSeconds = deepSeconds
        self.remSeconds = remSeconds
        self.coreSeconds = coreSeconds
        self.awakeSeconds = awakeSeconds
        self.sessionDate = sessionDate
    }

    public var totalHours: Double { totalSleepSeconds / 3600.0 }
    public var deepHours: Double { deepSeconds / 3600.0 }
    public var remHours: Double { remSeconds / 3600.0 }
    public var coreHours: Double { coreSeconds / 3600.0 }
    public var awakeHours: Double { awakeSeconds / 3600.0 }

    public var deepPercentage: Int {
        guard totalSleepSeconds > 0 else { return 0 }
        return Int(round((deepSeconds / totalSleepSeconds) * 100))
    }

    public var remPercentage: Int {
        guard totalSleepSeconds > 0 else { return 0 }
        return Int(round((remSeconds / totalSleepSeconds) * 100))
    }

    public var corePercentage: Int {
        guard totalSleepSeconds > 0 else { return 0 }
        return Int(round((coreSeconds / totalSleepSeconds) * 100))
    }
}

public enum HealthKitError: Error {
    case notAvailableOnDevice
    case queryFailed
}
