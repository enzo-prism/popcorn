import Foundation
import SwiftData

@MainActor
final class MovieRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func bootstrapIfNeeded() async {
        let descriptor = FetchDescriptor<Movie>()
        let existingMovies = (try? context.fetch(descriptor)) ?? []
        if !existingMovies.isEmpty {
            TasteVectorStore(context: context).ensureVectors(for: existingMovies)
            return
        }

        if let apiKey = AppConfig.tmdbApiKey {
            do {
                try await fetchAndStoreTMDbMovies(apiKey: apiKey)
                return
            } catch {
                loadSampleMovies()
            }
        } else {
            loadSampleMovies()
        }
    }

    private func fetchAndStoreTMDbMovies(apiKey: String) async throws {
        let client = TMDbClient(apiKey: apiKey)
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .year, value: -30, to: endDate) else {
            loadSampleMovies()
            return
        }

        let dtos = try await client.fetchTopMovies(
            limit: AppConfig.topMovieTargetCount,
            minVoteCount: AppConfig.minimumVoteCount,
            from: startDate,
            to: endDate
        )

        let movies = dtos.compactMap { mapTMDbMovie($0) }
        insertMovies(movies)
    }

    private func loadSampleMovies() {
        let movies = SampleMoviesLoader.loadMovies()
        insertMovies(movies)
    }

    private func insertMovies(_ movies: [Movie]) {
        movies.forEach { context.insert($0) }
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save movies: \(error)")
        }
        TasteVectorStore(context: context).ensureVectors(for: movies)
    }

    private func mapTMDbMovie(_ dto: TMDbMovieDTO) -> Movie? {
        guard let releaseDate = TMDbDateFormatter.parse(dto.releaseDate) else { return nil }
        let year = Calendar.current.component(.year, from: releaseDate)
        let genreNames = dto.genreIDs.compactMap { TMDbGenres.namesByID[$0] }

        return Movie(
            tmdbID: dto.id,
            title: dto.title,
            originalTitle: dto.originalTitle,
            overview: dto.overview ?? "",
            releaseDate: releaseDate,
            year: year,
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            voteAverage: dto.voteAverage ?? 0,
            voteCount: dto.voteCount ?? 0,
            genreNames: genreNames
        )
    }
}
