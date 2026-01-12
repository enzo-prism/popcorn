import Foundation

enum TMDbImageURL {
    private static let baseURL = URL(string: "https://image.tmdb.org/t/p/")!

    static func posterURL(path: String, size: String = "w500") -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        return baseURL.appendingPathComponent(size).appendingPathComponent(normalized)
    }
}
