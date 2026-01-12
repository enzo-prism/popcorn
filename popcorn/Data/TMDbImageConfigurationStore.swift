import Foundation

struct TMDbImageConfiguration: Codable, Equatable {
    let secureBaseURL: URL
    let posterSizes: [String]
    let fetchedAt: Date

    static let fallbackBaseURL = URL(string: "https://image.tmdb.org/t/p/")!
    static let fallbackPosterSizes = ["w500"]
}

@MainActor
final class TMDbImageConfigurationStore {
    static let shared = TMDbImageConfigurationStore()

    private let cacheURL: URL
    private let ttl: TimeInterval = 60 * 60 * 24 * 7
    private var cachedConfiguration: TMDbImageConfiguration?
    private var isRefreshing = false
    private var didLogFallback = false

    private init(fileManager: FileManager = .default) {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        cacheURL = (cachesDirectory ?? fileManager.temporaryDirectory)
            .appendingPathComponent("tmdb-image-config.json")
        cachedConfiguration = loadFromDisk()
    }

    func currentConfiguration() -> TMDbImageConfiguration? {
        cachedConfiguration
    }

    func refreshIfNeeded(apiKey: String?) async {
        guard let apiKey, !apiKey.isEmpty else { return }
        if let cachedConfiguration, isFresh(cachedConfiguration) {
            return
        }
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let client = TMDbClient(apiKey: apiKey)
            let response = try await client.fetchImageConfiguration()
            let baseURLString = response.secureBaseURL ?? response.baseURL
            guard let baseURLString,
                  let baseURL = URL(string: baseURLString) else {
                logFallbackOnce(reason: "configuration missing base URL")
                return
            }
            let configuration = TMDbImageConfiguration(
                secureBaseURL: baseURL,
                posterSizes: response.posterSizes,
                fetchedAt: Date()
            )
            cachedConfiguration = configuration
            saveToDisk(configuration)
        } catch {
            logFallbackOnce(reason: "configuration fetch failed: \(error)")
        }
    }

    func logFallbackOnce(reason: String) {
#if DEBUG
        guard !didLogFallback else { return }
        didLogFallback = true
        print("TMDb image configuration fallback: \(reason)")
#endif
    }

    private func isFresh(_ configuration: TMDbImageConfiguration) -> Bool {
        Date().timeIntervalSince(configuration.fetchedAt) < ttl
    }

    private func loadFromDisk() -> TMDbImageConfiguration? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(TMDbImageConfiguration.self, from: data)
    }

    private func saveToDisk(_ configuration: TMDbImageConfiguration) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(configuration) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
