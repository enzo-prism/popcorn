import Foundation
import UIKit

@MainActor
enum TMDbImageURLBuilder {
    private static var didLogMissingPosterPath = false

    static func posterURL(
        posterPath: String?,
        targetPointWidth: CGFloat,
        screenScale: CGFloat,
        configuration: TMDbImageConfiguration? = nil
    ) -> URL? {
        guard let rawPath = posterPath?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawPath.isEmpty else {
#if DEBUG
            if !didLogMissingPosterPath {
                didLogMissingPosterPath = true
                print("TMDb posterPath missing for movie.")
            }
#endif
            return nil
        }

        let normalizedPath = rawPath.hasPrefix("/") ? String(rawPath.dropFirst()) : rawPath
        let config = configuration ?? TMDbImageConfigurationStore.shared.currentConfiguration()
        let baseURL = config?.secureBaseURL ?? TMDbImageConfiguration.fallbackBaseURL
        let sizes = config?.posterSizes ?? TMDbImageConfiguration.fallbackPosterSizes

        if config == nil {
            TMDbImageConfigurationStore.shared.logFallbackOnce(reason: "no cached configuration")
        }

        let targetPixels = max(targetPointWidth * screenScale, 1)
        let bestSize = selectBestSize(from: sizes, targetPixels: targetPixels)

        return baseURL
            .appendingPathComponent(bestSize)
            .appendingPathComponent(normalizedPath)
    }

    private static func selectBestSize(from sizes: [String], targetPixels: CGFloat) -> String {
        let candidates = sizes.compactMap { size -> (size: String, width: CGFloat)? in
            if size == "original" {
                return (size, .greatestFiniteMagnitude)
            }
            guard size.hasPrefix("w"),
                  let width = Double(size.dropFirst()) else {
                return nil
            }
            return (size, CGFloat(width))
        }

        if let match = candidates.sorted(by: { $0.width < $1.width })
            .first(where: { $0.width >= targetPixels }) {
            return match.size
        }

        return candidates.sorted(by: { $0.width < $1.width }).last?.size
            ?? TMDbImageConfiguration.fallbackPosterSizes.first
            ?? "w500"
    }
}
