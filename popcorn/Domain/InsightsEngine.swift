import Foundation
import SwiftData

@MainActor
final class InsightsEngine {
    private let context: ModelContext
    private let detailsService: MovieDetailsService
    private let personalityPresenter = PersonalityPresenter()
    private let refreshInterval: TimeInterval = 60 * 60 * 12
    private let topLimit = 20
    private let recentLimit = 20
    private let detailsFetchLimit = 20

    init(context: ModelContext) {
        self.context = context
        self.detailsService = MovieDetailsService(context: context, apiKey: AppConfig.tmdbApiKey)
    }

    func refreshIfNeeded(force: Bool = false) async -> InsightsCache? {
        let cache = fetchCache()
        if let cache, !force {
            let age = Date().timeIntervalSince(cache.updatedAt)
            if age < refreshInterval {
                return cache
            }
        }

        let snapshot = await computeInsights()
        let target = cache ?? InsightsCache()
        target.favoriteGenres = snapshot.favoriteGenres
        target.favoriteActors = snapshot.favoriteActors
        target.favoriteDirectors = snapshot.favoriteDirectors
        target.favoriteKeywords = snapshot.favoriteKeywords
        target.rubricInsights = snapshot.rubricInsights
        target.personalityTitle = snapshot.personality.title
        target.personalityTraits = snapshot.personality.traits
        target.personalitySummary = snapshot.personality.summary
        target.personalityConfidence = snapshot.personality.confidence
        target.updatedAt = Date()

        if cache == nil {
            context.insert(target)
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save insights: \(error)")
        }

        return target
    }

    private func computeInsights() async -> InsightsSnapshot {
        let topMovies = fetchTopMovies(limit: topLimit)
        let recentMovies = fetchRecentMovies(limit: recentLimit)
        let combined = dedupe(topMovies + recentMovies)

        for movie in combined.prefix(detailsFetchLimit) {
            await detailsService.ensureDetails(for: movie)
        }

        var genreCounts: [String: Double] = [:]
        var actorCounts: [String: Double] = [:]
        var directorCounts: [String: Double] = [:]
        var keywordCounts: [String: Double] = [:]

        for movie in combined {
            for genre in movie.genreNames {
                genreCounts[genre, default: 0] += 1
            }

            if let details = movie.details {
                for castMember in details.cast.sorted(by: { $0.order < $1.order }).prefix(3) {
                    actorCounts[castMember.name, default: 0] += 1
                }
                for crewMember in details.crew where crewMember.job == "Director" {
                    directorCounts[crewMember.name, default: 0] += 1
                }
                for keyword in details.keywords {
                    keywordCounts[keyword, default: 0] += 1
                }
            }
        }

        let rubricInsights = computeRubricInsights(from: combined)
        let personality = personalityPresenter.present(
            profile: TasteProfileStore(context: context).fetchProfile(),
            favoriteGenres: topMetrics(from: genreCounts),
            favoriteKeywords: topMetrics(from: keywordCounts),
            favoriteDirectors: topMetrics(from: directorCounts),
            favoriteActors: topMetrics(from: actorCounts)
        )

        return InsightsSnapshot(
            favoriteGenres: topMetrics(from: genreCounts),
            favoriteActors: topMetrics(from: actorCounts),
            favoriteDirectors: topMetrics(from: directorCounts),
            favoriteKeywords: topMetrics(from: keywordCounts),
            rubricInsights: rubricInsights,
            personality: personality
        )
    }

    private func fetchTopMovies(limit: Int) -> [Movie] {
        var descriptor = FetchDescriptor<Movie>(sortBy: [SortDescriptor(\.eloRating, order: .reverse)])
        descriptor.fetchLimit = limit
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    private func fetchRecentMovies(limit: Int) -> [Movie] {
        var descriptor = FetchDescriptor<Movie>(
            predicate: #Predicate { $0.lastComparedAt != nil },
            sortBy: [SortDescriptor(\.lastComparedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    private func dedupe(_ movies: [Movie]) -> [Movie] {
        var seen = Set<Int>()
        var result: [Movie] = []
        for movie in movies {
            if seen.insert(movie.tmdbID).inserted {
                result.append(movie)
            }
        }
        return result
    }

    private func topMetrics(from counts: [String: Double]) -> [NamedMetric] {
        let metrics = counts.map { NamedMetric(name: $0.key, score: $0.value) }
        let sorted = metrics.sorted { $0.score == $1.score ? $0.name < $1.name : $0.score > $1.score }
        return Array(sorted.prefix(5))
    }

    private func computeRubricInsights(from movies: [Movie]) -> [String] {
        let ratings = movies.compactMap { $0.rubricRatings }
        guard ratings.count >= 5 else { return [] }

        let averages = RubricAverages(from: ratings)
        var insights: [String] = []

        if let insight = rubricInsight(label: "Story", average: averages.story) {
            insights.append(insight)
        }
        if let insight = rubricInsight(label: "Action", average: averages.action) {
            insights.append(insight)
        }
        if let insight = rubricInsight(label: "Visuals", average: averages.visuals) {
            insights.append(insight)
        }
        if let insight = rubricInsight(label: "Dialogue", average: averages.dialogue) {
            insights.append(insight)
        }
        if let insight = rubricInsight(label: "Acting", average: averages.acting) {
            insights.append(insight)
        }
        if let insight = rubricInsight(label: "Sound", average: averages.sound) {
            insights.append(insight)
        }

        return Array(insights.prefix(3))
    }

    private func rubricInsight(label: String, average: Double) -> String? {
        if average <= 4 {
            return "You rate \(label) harshly"
        }
        if average >= 7 {
            return "You love \(label)"
        }
        return nil
    }

    private func fetchCache() -> InsightsCache? {
        var descriptor = FetchDescriptor<InsightsCache>()
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    private struct InsightsSnapshot {
        let favoriteGenres: [NamedMetric]
        let favoriteActors: [NamedMetric]
        let favoriteDirectors: [NamedMetric]
        let favoriteKeywords: [NamedMetric]
        let rubricInsights: [String]
        let personality: TastePersonalitySnapshot
    }

    private struct RubricAverages {
        let story: Double
        let action: Double
        let visuals: Double
        let dialogue: Double
        let acting: Double
        let sound: Double

        init(from ratings: [RubricRatings]) {
            let count = Double(ratings.count)
            story = ratings.map(\.story).reduce(0, +) / count
            action = ratings.map(\.action).reduce(0, +) / count
            visuals = ratings.map(\.visuals).reduce(0, +) / count
            dialogue = ratings.map(\.dialogue).reduce(0, +) / count
            acting = ratings.map(\.acting).reduce(0, +) / count
            sound = ratings.map(\.sound).reduce(0, +) / count
        }
    }

}
