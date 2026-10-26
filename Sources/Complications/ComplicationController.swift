#if os(watchOS)
import ClockKit
import SwiftUI

/// ComplicationController powers watch face complications across all Apple Watch faces.
/// Displays BioSync Biological Age, Stress, and Recovery.
public class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Complication Descriptors
    public func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "com.uditya.BioSync.vitality",
                displayName: "BioSync Vitality & Age",
                supportedFamilies: [
                    .graphicRectangular,
                    .modularLarge,
                    .graphicCircular,
                    .graphicCorner,
                    .graphicBezel,
                    .utilitarianLarge,
                    .modularSmall,
                    .circularSmall,
                    .graphicExtraLarge
                ]
            )
        ]
        handler(descriptors)
    }

    public func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {}

    // MARK: - Timeline Configuration
    public func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date().addingTimeInterval(24 * 3600))
    }

    public func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    // MARK: - Current Timeline Entry
    public func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let defaults = UserDefaults.standard
        let recovery = defaults.integer(forKey: "latest_recovery_score")
        let recoveryScore = recovery > 0 ? recovery : 82
        let stress = defaults.object(forKey: "latest_stress_score") as? Int ?? 22
        let bioAge = defaults.double(forKey: "latest_biosync_age")
        let bioSyncAge = bioAge > 0 ? bioAge : 23.4
        let delta = defaults.double(forKey: "latest_biosync_delta")

        if let template = createTemplate(for: complication, recovery: recoveryScore, stress: stress, bioAge: bioSyncAge, delta: delta) {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil)
        }
    }

    // MARK: - Sample Template (Displayed in Watch Face Gallery)
    public func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = createTemplate(for: complication, recovery: 85, stress: 24, bioAge: 23.5, delta: -1.5)
        handler(template)
    }

    // MARK: - Template Construction
    private func createTemplate(
        for complication: CLKComplication,
        recovery: Int,
        stress: Int,
        bioAge: Double,
        delta: Double
    ) -> CLKComplicationTemplate? {
        let recoveryColor = UIColor(red: 0.98, green: 0.82, blue: 0.22, alpha: 1.0) // Yellow
        let stressColor = UIColor(red: 0.25, green: 0.85, blue: 0.45, alpha: 1.0) // Green
        let deltaSign = delta <= 0 ? "" : "+"
        let deltaStr = String(format: "%@%.1fy", deltaSign, delta)
        let recoveryStatus = recovery >= 67 ? "PRIMED" : (recovery >= 34 ? "BALANCED" : "STRAINED")
        let stressZone = stress < 25 ? "REST" : (stress < 50 ? "CALM" : (stress < 75 ? "MODERATE" : "HIGH"))

        switch complication.family {
        case .graphicRectangular:
            let template = CLKComplicationTemplateGraphicRectangularStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "BIOSYNC AGE: \(String(format: "%.1f", bioAge))y (\(deltaStr))")
            let recText = CLKSimpleTextProvider(text: "Recovery: \(recovery)% • \(recoveryStatus)")
            recText.tintColor = recoveryColor
            template.body1TextProvider = recText
            let stressText = CLKSimpleTextProvider(text: "Stress: \(stress)/100 • \(stressZone)")
            stressText.tintColor = stressColor
            template.body2TextProvider = stressText
            return template

        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "BioSync Age \(String(format: "%.1f", bioAge))y")
            let recText = CLKSimpleTextProvider(text: "Recovery: \(recovery)% (\(recoveryStatus))")
            recText.tintColor = recoveryColor
            template.body1TextProvider = recText
            let stressText = CLKSimpleTextProvider(text: "Stress: \(stress) (\(stressZone))")
            stressText.tintColor = stressColor
            template.body2TextProvider = stressText
            return template

        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
            let gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColors: [recoveryColor],
                gaugeColorLocations: nil,
                fillFraction: Float(recovery) / 100.0
            )
            template.gaugeProvider = gaugeProvider
            template.centerTextProvider = CLKSimpleTextProvider(text: "\(recovery)%")
            template.bottomTextProvider = CLKSimpleTextProvider(text: "\(String(format: "%.0f", bioAge))y")
            return template

        case .graphicCorner:
            let template = CLKComplicationTemplateGraphicCornerGaugeText()
            template.gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColors: [recoveryColor],
                gaugeColorLocations: nil,
                fillFraction: Float(recovery) / 100.0
            )
            template.outerTextProvider = CLKSimpleTextProvider(text: "Bio \(String(format: "%.1f", bioAge))y • Str \(stress)")
            template.leadingTextProvider = CLKSimpleTextProvider(text: "\(recovery)%")
            return template

        case .graphicBezel:
            let circularTemplate = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
            circularTemplate.gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColors: [recoveryColor],
                gaugeColorLocations: nil,
                fillFraction: Float(recovery) / 100.0
            )
            circularTemplate.centerTextProvider = CLKSimpleTextProvider(text: "\(recovery)%")
            circularTemplate.bottomTextProvider = CLKSimpleTextProvider(text: "\(stress)")

            let template = CLKComplicationTemplateGraphicBezelCircularText()
            template.circularTemplate = circularTemplate
            template.textProvider = CLKSimpleTextProvider(text: "BioSync Age \(String(format: "%.1f", bioAge))y (\(deltaStr)) • Stress \(stress)")
            return template

        case .utilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "Bio: \(String(format: "%.1f", bioAge))y • Rec: \(recovery)% • Str: \(stress)")
            return template

        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText()
            let recText = CLKSimpleTextProvider(text: "\(recovery)%")
            recText.tintColor = recoveryColor
            template.line1TextProvider = recText
            template.line2TextProvider = CLKSimpleTextProvider(text: "\(String(format: "%.0f", bioAge))y")
            return template

        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleText()
            let recText = CLKSimpleTextProvider(text: "\(recovery)%")
            recText.tintColor = recoveryColor
            template.textProvider = recText
            return template

        case .graphicExtraLarge:
            let template = CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText()
            template.gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColors: [recoveryColor],
                gaugeColorLocations: nil,
                fillFraction: Float(recovery) / 100.0
            )
            template.centerTextProvider = CLKSimpleTextProvider(text: "\(recovery)%")
            template.bottomTextProvider = CLKSimpleTextProvider(text: "\(String(format: "%.1f", bioAge))y")
            return template

        default:
            return nil
        }
    }
}
#endif
