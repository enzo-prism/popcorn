import Foundation

@MainActor
enum TMDbImageURL {
    static func posterURL(path: String, size: String = "w500") -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        let config = TMDbImageConfigurationStore.shared.currentConfiguration()
        if config == nil {
            TMDbImageConfigurationStore.shared.logFallbackOnce(reason: "no cached configuration")
        }
        let baseURL = config?.secureBaseURL ?? TMDbImageConfiguration.fallbackBaseURL
        return baseURL.appendingPathComponent(size).appendingPathComponent(normalized)
    }
}
