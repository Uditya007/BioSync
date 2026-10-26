import WidgetKit
import SwiftUI

#if os(watchOS)

// MARK: - Timeline Entry
public struct BioSyncEntry: TimelineEntry {
    public let date: Date
    public let recoveryScore: Int
    public let stressScore: Int?
    public let sleepScore: Int
    public let stressZoneText: String

    public static var placeholder: BioSyncEntry {
        BioSyncEntry(
            date: Date(),
            recoveryScore: 82,
            stressScore: 28,
            sleepScore: 88,
            stressZoneText: "Low"
        )
    }
}

// MARK: - Timeline Provider
public struct BioSyncTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> BioSyncEntry {
        .placeholder
    }

    public func getSnapshot(in context: Context, completion: @escaping (BioSyncEntry) -> Void) {
        completion(.placeholder)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<BioSyncEntry>) -> Void) {
        let defaults = UserDefaults.standard
        let recovery = defaults.integer(forKey: "latest_recovery_score")
        let stress = defaults.object(forKey: "latest_stress_score") as? Int
        let sleep = defaults.integer(forKey: "latest_sleep_score")
        
        let entry = BioSyncEntry(
            date: Date(),
            recoveryScore: recovery > 0 ? recovery : 75,
            stressScore: stress,
            sleepScore: sleep > 0 ? sleep : 80,
            stressZoneText: StressZone.classify(score: stress).rawValue
        )

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Complication Entry View
public struct BioSyncComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    public var entry: BioSyncEntry

    public init(entry: BioSyncEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .accessoryCircular:
            CircularComplicationView(entry: entry)
        case .accessoryCorner:
            CornerComplicationView(entry: entry)
        case .accessoryRectangular:
            RectangularComplicationView(entry: entry)
        case .accessoryInline:
            InlineComplicationView(entry: entry)
        default:
            CircularComplicationView(entry: entry)
        }
    }
}

// MARK: - Circular Complication (Recovery Ring)
struct CircularComplicationView: View {
    let entry: BioSyncEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Gauge(value: Double(entry.recoveryScore), in: 0...100) {
                Text("REC")
                    .font(.system(size: 8, weight: .bold))
            } currentValueLabel: {
                Text("\(entry.recoveryScore)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(entry.recoveryScore >= 67 ? .green : (entry.recoveryScore >= 34 ? .yellow : .red))
        }
    }
}

// MARK: - Rectangular Complication (Dashboard Glance)
struct RectangularComplicationView: View {
    let entry: BioSyncEntry

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.heart.fill")
                        .foregroundStyle(entry.recoveryScore >= 67 ? .green : .orange)
                        .font(.system(size: 10))
                    Text("BioSync")
                        .font(.system(size: 11, weight: .bold))
                }
                Text("Recovery: \(entry.recoveryScore)%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Stress: \(entry.stressScore.map { "\($0) (\(entry.stressZoneText))" } ?? "Active")")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Corner Complication
struct CornerComplicationView: View {
    let entry: BioSyncEntry

    var body: some View {
        Text("\(entry.recoveryScore)%")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .widgetCurvesContent()
            .widgetLabel {
                Gauge(value: Double(entry.recoveryScore), in: 0...100) {
                    Text("REC")
                }
                .tint(entry.recoveryScore >= 67 ? .green : .orange)
            }
    }
}

// MARK: - Inline Complication
struct InlineComplicationView: View {
    let entry: BioSyncEntry

    var body: some View {
        Text("Rec: \(entry.recoveryScore)% • Stress: \(entry.stressZoneText)")
    }
}

// MARK: - Widget Configuration
// When building a standalone Widget Extension, uncomment @main below:
// @main
public struct BioSyncWidget: Widget {
    public let kind: String = "BioSyncComplications"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BioSyncTimelineProvider()) { entry in
            BioSyncComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("BioSync Readiness")
        .description("Glanceable Recovery, Stress, and Sleep scores on your watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}

#endif
