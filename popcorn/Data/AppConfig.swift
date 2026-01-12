import Foundation

enum AppConfig {
    static let minimumVoteCount = 2000
    static let topMovieTargetCount = 1000
    static let refreshMomentInterval = 10
    static let eloKFactor: Double = 32
    static let recentPairBufferSize = 50
    static let tasteSigmaScale: Double = 1.0

    static var tmdbApiKey: String? {
        let plistValue = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String
        let envValue = ProcessInfo.processInfo.environment["TMDB_API_KEY"]
        let candidates = [plistValue, envValue]
        return candidates
            .compactMap { sanitizeApiKey($0) }
            .first
    }

    static var isDemoMode: Bool {
        tmdbApiKey == nil
    }

    private static func sanitizeApiKey(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains("$(") || trimmed == "TMDB_API_KEY" {
            return nil
        }
        return trimmed
    }
}
