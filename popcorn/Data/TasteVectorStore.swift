import Foundation
import SwiftData

@MainActor
final class TasteVectorStore {
    private let context: ModelContext
    private let builder: TasteVectorBuilder

    init(context: ModelContext, builder: TasteVectorBuilder = TasteVectorBuilder()) {
        self.context = context
        self.builder = builder
    }

    @discardableResult
    func ensureVectors(for movies: [Movie]) -> [Int: MovieTasteVector] {
        let shouldRecomputeAll = ensureConfigState()
        let existingVectors = fetchAllVectors()
        var vectorByMovieId: [Int: MovieTasteVector] = [:]

        for vector in existingVectors {
            vectorByMovieId[vector.movieId] = vector
        }

        for movie in movies {
            let vector = vectorByMovieId[movie.tmdbID]
            let refreshForDetails = vector.map { needsRefresh(movie: movie, vector: $0) } ?? false
            if shouldRecomputeAll || vector == nil || vector?.version != builder.version || refreshForDetails {
                let values = builder.vector(for: movie).values
                if let vector {
                    vector.values = values
                    vector.version = builder.version
                    vector.computedAt = Date()
                } else {
                    let newVector = MovieTasteVector(movieId: movie.tmdbID, version: builder.version, values: values)
                    context.insert(newVector)
                    vectorByMovieId[movie.tmdbID] = newVector
                }
            }
        }

        saveContext()
        return vectorByMovieId
    }

    func vectorMap(for movies: [Movie]) -> [Int: [Double]] {
        let vectors = ensureVectors(for: movies)
        var map: [Int: [Double]] = [:]
        for movie in movies {
            if let vector = vectors[movie.tmdbID] {
                map[movie.tmdbID] = vector.values
            }
        }
        return map
    }

    private func ensureConfigState() -> Bool {
        let currentVersion = builder.version
        let state = fetchConfigState()
        if let state, state.version == currentVersion {
            return false
        }

        if let state {
            state.version = currentVersion
            state.lastAppliedAt = Date()
        } else {
            context.insert(TasteAxesConfigState(version: currentVersion))
        }
        saveContext()
        return true
    }

    private func fetchAllVectors() -> [MovieTasteVector] {
        let descriptor = FetchDescriptor<MovieTasteVector>()
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchConfigState() -> TasteAxesConfigState? {
        var descriptor = FetchDescriptor<TasteAxesConfigState>()
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func needsRefresh(movie: Movie, vector: MovieTasteVector) -> Bool {
        guard let details = movie.details else { return false }
        return details.lastUpdatedAt > vector.computedAt
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save taste vectors: \(error)")
        }
    }
}
