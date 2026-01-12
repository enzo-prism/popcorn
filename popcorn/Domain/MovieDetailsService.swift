import Foundation
import SwiftData

@MainActor
final class MovieDetailsService {
    private let context: ModelContext
    private let client: TMDbClient?
    private let refreshInterval: TimeInterval = 60 * 60 * 24 * 30

    init(context: ModelContext, apiKey: String?) {
        self.context = context
        if let apiKey {
            self.client = TMDbClient(apiKey: apiKey)
        } else {
            self.client = nil
        }
    }

    func ensureDetails(for movie: Movie) async {
        guard let client else { return }

        if let details = movie.details {
            let age = Date().timeIntervalSince(details.lastUpdatedAt)
            if age < refreshInterval {
                return
            }
        }

        do {
            let details = try await client.fetchMovieDetails(movieID: movie.tmdbID)
            movie.details = details
            movie.updatedAt = Date()
            try context.save()
        } catch {
            return
        }
    }
}
