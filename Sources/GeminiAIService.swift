import Foundation

/// Unified Multi-Provider AI Service supporting OpenRouter, Google Gemini, and on-device offline intelligence.
/// Automatically handles rate-limits, model failovers, and formats rich clinical longevity and strain insights.
public final class GeminiAIService {
    public static let shared = GeminiAIService()

    // Configurable keys for dual-provider redundancy (retrieved securely from Environment or user settings)
    public var openRouterKey: String? = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? UserDefaults.standard.string(forKey: "biosync_openrouter_api_key")
    public var geminiKey: String? = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? UserDefaults.standard.string(forKey: "biosync_gemini_api_key")

    public var apiKey: String? {
        get { geminiKey ?? openRouterKey }
        set {
            if let val = newValue, !val.isEmpty {
                if val.hasPrefix("sk-or-v1-") {
                    openRouterKey = val
                    UserDefaults.standard.set(val, forKey: "biosync_openrouter_api_key")
                } else {
                    geminiKey = val
                    UserDefaults.standard.set(val, forKey: "biosync_gemini_api_key")
                }
            } else {
                openRouterKey = nil
                geminiKey = nil
                UserDefaults.standard.removeObject(forKey: "biosync_openrouter_api_key")
                UserDefaults.standard.removeObject(forKey: "biosync_gemini_api_key")
            }
        }
    }

    private let cacheKey = "biosync_cached_ai_briefing"

    private init() {}

    // MARK: - Comprehensive Structured Response Schema
    public struct AIDetailedBriefing: Codable, Sendable {
        public let headline: String
        public let overallProgress: String
        public let biologicalAgeAnalysis: String
        public let cardiovascularStatus: String
        public let nervousSystemStatus: String
        public let trainingGuidance: String
        public let sleepArchitectureInsight: String
        public let stressIntervention: String?
        public let generatedAt: Date

        // Backward compatibility
        public var biometricDiagnosis: String {
            "\(biologicalAgeAnalysis) \(overallProgress)"
        }
        public var strainRecommendation: String {
            trainingGuidance
        }
    }

    // MARK: - Fetch AI Coaching
    public func fetchAIBriefing(
        recoveryScore: Int,
        sleepScore: Int,
        stressScore: Int?,
        currentHRV: Double,
        baselineHRV: Double,
        currentRHR: Double,
        baselineRHR: Double,
        sleepSummary: SleepSessionSummary?,
        bioSyncAge: BioSyncAgeResult? = nil
    ) async -> AIDetailedBriefing {
        let prompt = AIService.shared.generateAIPrompt(
            recoveryScore: recoveryScore,
            sleepScore: sleepScore,
            stressScore: stressScore,
            currentHRV: currentHRV,
            baselineHRV: baselineHRV,
            currentRHR: currentRHR,
            baselineRHR: baselineRHR,
            sleepSummary: sleepSummary,
            bioSyncAge: bioSyncAge
        )

        // 1. Try OpenRouter first if key is present
        if let orKey = openRouterKey, !orKey.isEmpty {
            if let briefing = await queryOpenRouter(prompt: prompt, apiKey: orKey) {
                saveToCache(briefing)
                return briefing
            }
        }

        // 2. Fall back to Google Gemini API
        if let gKey = geminiKey, !gKey.isEmpty {
            if let briefing = await queryGemini(prompt: prompt, apiKey: gKey) {
                saveToCache(briefing)
                return briefing
            }
        }

        // 3. Fallback to cached or local sports-science heuristic
        return getFallbackOrLocalBriefing(
            recovery: recoveryScore,
            sleep: sleepScore,
            stress: stressScore,
            currentHRV: currentHRV,
            baselineHRV: baselineHRV,
            currentRHR: currentRHR,
            baselineRHR: baselineRHR,
            bioSyncAge: bioSyncAge
        )
    }

    // MARK: - OpenRouter Provider Call
    private func queryOpenRouter(prompt: String, apiKey: String) async -> AIDetailedBriefing? {
        let models = [
            "nvidia/nemotron-3.5-lightning:free",
            "liquid/lfm-2.5-2.6b:free",
            "google/gemma-4-31b-it:free"
        ]

        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else { return nil }

        for model in models {
            let requestBody: [String: Any] = [
                "model": model,
                "messages": [
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.2
            ]

            guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else { continue }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("https://biosync.app", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("BioSync Apple Watch", forHTTPHeaderField: "X-Title")
            request.httpBody = httpBody
            request.timeoutInterval = 6.0

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continue
                }

                if let briefing = parseOpenRouterResponse(data) {
                    return briefing
                }
            } catch {
                continue
            }
        }
        return nil
    }

    // MARK: - Google Gemini Provider Call
    private func queryGemini(prompt: String, apiKey: String) async -> AIDetailedBriefing? {
        let models = [
            "gemini-3.5-flash-lite",
            "gemini-3.5-flash",
            "gemini-2.5-flash"
        ]

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.2
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else { return nil }

        for model in models {
            let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
            guard let url = URL(string: endpoint) else { continue }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = httpBody
            request.timeoutInterval = 6.0

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continue
                }

                if let briefing = parseGeminiResponse(data) {
                    return briefing
                }
            } catch {
                continue
            }
        }
        return nil
    }

    // MARK: - Response Parsing
    private func parseOpenRouterResponse(_ data: Data) -> AIDetailedBriefing? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return nil
        }
        return decodePayload(from: content)
    }

    private func parseGeminiResponse(_ data: Data) -> AIDetailedBriefing? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return nil
        }
        return decodePayload(from: text)
    }

    private func decodePayload(from rawText: String) -> AIDetailedBriefing? {
        let cleaned = extractJSONText(from: rawText)
        guard let textData = cleaned.data(using: .utf8) else { return nil }

        struct LLMPayload: Decodable {
            let headline: String?
            let overallProgress: String?
            let biologicalAgeAnalysis: String?
            let cardiovascularStatus: String?
            let nervousSystemStatus: String?
            let trainingGuidance: String?
            let sleepArchitectureInsight: String?
            let stressIntervention: String?
        }

        guard let payload = try? JSONDecoder().decode(LLMPayload.self, from: textData) else {
            return nil
        }

        return AIDetailedBriefing(
            headline: payload.headline ?? "Optimal Physiology",
            overallProgress: payload.overallProgress ?? "Biometric trends are aligning with physiological baselines.",
            biologicalAgeAnalysis: payload.biologicalAgeAnalysis ?? "BioSync biological age is well-maintained.",
            cardiovascularStatus: payload.cardiovascularStatus ?? "Resting heart rate reflects healthy stroke volume.",
            nervousSystemStatus: payload.nervousSystemStatus ?? "Autonomic nervous system is balanced.",
            trainingGuidance: payload.trainingGuidance ?? "Maintain structured activity and hydration.",
            sleepArchitectureInsight: payload.sleepArchitectureInsight ?? "Sleep provided essential restorative repair.",
            stressIntervention: payload.stressIntervention,
            generatedAt: Date()
        )
    }

    private func extractJSONText(from raw: String) -> String {
        // 1. Check for markdown code blocks ```json ... ``` or ``` ... ```
        if let codeBlockStart = raw.range(of: "```json") {
            let searchSubrange = codeBlockStart.upperBound..<raw.endIndex
            if let codeBlockEnd = raw.range(of: "```", range: searchSubrange),
               codeBlockStart.upperBound <= codeBlockEnd.lowerBound {
                let inner = String(raw[codeBlockStart.upperBound..<codeBlockEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !inner.isEmpty {
                    return inner
                }
            }
        } else if let codeBlockStart = raw.range(of: "```") {
            let searchSubrange = codeBlockStart.upperBound..<raw.endIndex
            if let codeBlockEnd = raw.range(of: "```", range: searchSubrange),
               codeBlockStart.upperBound <= codeBlockEnd.lowerBound {
                let inner = String(raw[codeBlockStart.upperBound..<codeBlockEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !inner.isEmpty {
                    return inner
                }
            }
        }

        // 2. Locate outermost JSON object { ... }
        if let openBrace = raw.firstIndex(of: "{"),
           let closeBrace = raw.lastIndex(of: "}"),
           openBrace <= closeBrace {
            // Using a closed range between the actual character indices [openBrace...closeBrace]
            // safely includes the closing '}' without ever referencing raw.endIndex (which causes an out-of-bounds crash).
            return String(raw[openBrace...closeBrace]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Cache & Local Fallbacks
    private func saveToCache(_ briefing: AIDetailedBriefing) {
        if let encoded = try? JSONEncoder().encode(briefing) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }

    public func getCachedBriefing() -> AIDetailedBriefing? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let briefing = try? JSONDecoder().decode(AIDetailedBriefing.self, from: data) else {
            return nil
        }
        return briefing
    }

    private func getFallbackOrLocalBriefing(
        recovery: Int,
        sleep: Int,
        stress: Int?,
        currentHRV: Double,
        baselineHRV: Double,
        currentRHR: Double,
        baselineRHR: Double,
        bioSyncAge: BioSyncAgeResult? = nil
    ) -> AIDetailedBriefing {
        if let cached = getCachedBriefing(), Date().timeIntervalSince(cached.generatedAt) < 14400 {
            return cached
        }

        let local = AIService.shared.generateLocalInsight(
            recoveryScore: recovery,
            sleepScore: sleep,
            stressScore: stress,
            currentHRV: currentHRV,
            baselineHRV: baselineHRV,
            currentRHR: currentRHR,
            baselineRHR: baselineRHR,
            bioSyncAge: bioSyncAge
        )

        return AIDetailedBriefing(
            headline: local.headline,
            overallProgress: local.overallProgress,
            biologicalAgeAnalysis: local.biologicalAgeAnalysis,
            cardiovascularStatus: local.cardiovascularStatus,
            nervousSystemStatus: local.nervousSystemStatus,
            trainingGuidance: local.trainingGuidance,
            sleepArchitectureInsight: local.sleepArchitectureInsight,
            stressIntervention: local.stressIntervention,
            generatedAt: Date()
        )
    }
}
