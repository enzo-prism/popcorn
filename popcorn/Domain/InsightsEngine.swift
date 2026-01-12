import Foundation
import SwiftData

@MainActor
final class InsightsEngine {
    private let context: ModelContext
    private let detailsService: MovieDetailsService
    private let personalityPresenter = PersonalityPresenter()
    private let refreshInterval: TimeInterval = 60 * 60 * 12
    private let refreshPickDelta = 5
    private let topLimit = 40
    private let recentLimit = 40
    private let comparedLimit = 200
    private let detailsFetchLimit = 60

    private let minGenreSupport = 0.6
    private let minPeopleSupport = 0.4
    private let minKeywordSupport = 0.35
    private let minTagScore = 0.02
    private let keywordWeight = 0.6

    private let keywordStoplist: Set<String> = [
        "based on novel or book",
        "based on true story",
        "duringcreditsstinger",
        "aftercreditsstinger",
        "sequel",
        "prequel",
        "remake",
        "reboot",
        "based on comic",
        "based on comic book",
        "based on manga",
        "based on graphic novel"
    ]

    init(context: ModelContext) {
        self.context = context
        self.detailsService = MovieDetailsService(context: context, apiKey: AppConfig.tmdbApiKey)
    }

    func refreshIfNeeded(force: Bool = false) async -> InsightsCache? {
        let cache = fetchCache()
        if let cache, !force {
            let age = Date().timeIntervalSince(cache.updatedAt)
            if age < refreshInterval {
                let currentPickCount = fetchComparisonEvents().count
                if currentPickCount - cache.sourcePickCount < refreshPickDelta {
                    return cache
                }
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
        target.sourceMovieCount = snapshot.sourceMovieCount
        target.sourcePickCount = snapshot.sourcePickCount
        target.detailsCoverage = snapshot.detailsCoverage
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
        let comparedMovies = fetchComparedMovies(limit: comparedLimit)
        let fallback = dedupe(fetchTopMovies(limit: topLimit) + fetchRecentMovies(limit: recentLimit))
        let candidateMovies = comparedMovies.isEmpty ? fallback : comparedMovies

        let events = fetchComparisonEvents()
        let comparisonStats = buildComparisonStats(from: events)

        let profileStore = TasteProfileStore(context: context)
        let profile = profileStore.fetchProfile()
        let tasteSnapshot = TasteProfileSnapshot(mu: profile.mu, confidence: profileStore.confidence(for: profile))

        if events.isEmpty {
            let personality = personalityPresenter.present(
                profile: profile,
                favoriteGenres: [],
                favoriteKeywords: [],
                favoriteDirectors: [],
                favoriteActors: []
            )
            return InsightsSnapshot(
                favoriteGenres: [],
                favoriteActors: [],
                favoriteDirectors: [],
                favoriteKeywords: [],
                rubricInsights: [],
                personality: personality,
                sourceMovieCount: 0,
                sourcePickCount: 0,
                detailsCoverage: 0
            )
        }

        let vectorMap = TasteVectorStore(context: context).vectorMap(for: candidateMovies)
        let scorer = InsightsScorer(
            now: Date(),
            tasteProfile: tasteSnapshot,
            vectors: vectorMap,
            comparisonStats: comparisonStats
        )
        let signalsById = scorer.signals(for: candidateMovies)

        let detailTargets = candidateMovies
            .compactMap { movie -> (Movie, Double)? in
                guard let signal = signalsById[movie.tmdbID], signal.score > 0 else { return nil }
                return (movie, signal.score * signal.weight)
            }
            .sorted { $0.1 > $1.1 }

        let detailSelection = detailTargets.isEmpty
            ? candidateMovies.map { ($0, 0.0) }
            : detailTargets
        for (movie, _) in detailSelection.prefix(detailsFetchLimit) {
            await detailsService.ensureDetails(for: movie)
        }

        let detailsCoverage = candidateMovies.isEmpty
            ? 0
            : Double(candidateMovies.filter { $0.details != nil }.count) / Double(candidateMovies.count)

        var genreStats: [String: TagStats] = [:]
        var actorStats: [String: TagStats] = [:]
        var directorStats: [String: TagStats] = [:]
        var keywordStats: [String: TagStats] = [:]

        var genreGlobals: [String: Double] = [:]
        var actorGlobals: [String: Double] = [:]
        var directorGlobals: [String: Double] = [:]
        var keywordGlobals: [String: Double] = [:]

        var genreNames: [String: String] = [:]
        var actorNames: [String: String] = [:]
        var directorNames: [String: String] = [:]
        var keywordNames: [String: String] = [:]

        for movie in candidateMovies {
            guard let signal = signalsById[movie.tmdbID] else { continue }
            let genres = movie.genreNames
            let genreWeight = 1.0 / Double(max(1, genres.count))
            for genre in genres {
                InsightsScorer.addTag(
                    key: genre,
                    displayName: genre,
                    weight: genreWeight,
                    signal: signal,
                    stats: &genreStats,
                    displayNames: &genreNames
                )
            }

            if let details = movie.details {
                for castMember in details.cast.sorted(by: { $0.order < $1.order }).prefix(5) {
                    let weight = 1.0 / Double(max(1, castMember.order + 1))
                    InsightsScorer.addTag(
                        key: castMember.name,
                        displayName: castMember.name,
                        weight: weight,
                        signal: signal,
                        stats: &actorStats,
                        displayNames: &actorNames
                    )
                }
                for crewMember in details.crew where crewMember.job == "Director" {
                    InsightsScorer.addTag(
                        key: crewMember.name,
                        displayName: crewMember.name,
                        weight: 1.0,
                        signal: signal,
                        stats: &directorStats,
                        displayNames: &directorNames
                    )
                }
                for keyword in details.keywords {
                    guard let normalized = normalizedKeyword(keyword) else { continue }
                    InsightsScorer.addTag(
                        key: normalized,
                        displayName: displayKeyword(normalized),
                        weight: keywordWeight,
                        signal: signal,
                        stats: &keywordStats,
                        displayNames: &keywordNames
                    )
                }
            }
        }

        let allMovies = fetchAllMovies()
        for movie in allMovies {
            let genres = movie.genreNames
            let genreWeight = 1.0 / Double(max(1, genres.count))
            for genre in genres {
                InsightsScorer.addGlobalTag(
                    key: genre,
                    displayName: genre,
                    weight: genreWeight,
                    global: &genreGlobals,
                    displayNames: &genreNames
                )
            }
        }

        let detailPool = allMovies.filter { $0.details != nil }
        for movie in detailPool {
            guard let details = movie.details else { continue }
            for castMember in details.cast.sorted(by: { $0.order < $1.order }).prefix(5) {
                let weight = 1.0 / Double(max(1, castMember.order + 1))
                InsightsScorer.addGlobalTag(
                    key: castMember.name,
                    displayName: castMember.name,
                    weight: weight,
                    global: &actorGlobals,
                    displayNames: &actorNames
                )
            }
            for crewMember in details.crew where crewMember.job == "Director" {
                InsightsScorer.addGlobalTag(
                    key: crewMember.name,
                    displayName: crewMember.name,
                    weight: 1.0,
                    global: &directorGlobals,
                    displayNames: &directorNames
                )
            }
            for keyword in details.keywords {
                guard let normalized = normalizedKeyword(keyword) else { continue }
                InsightsScorer.addGlobalTag(
                    key: normalized,
                    displayName: displayKeyword(normalized),
                    weight: keywordWeight,
                    global: &keywordGlobals,
                    displayNames: &keywordNames
                )
            }
        }

        let favoriteGenres = InsightsScorer.rankMetrics(
            stats: genreStats,
            global: genreGlobals,
            displayNames: genreNames,
            limit: 5,
            minSupport: minGenreSupport,
            minScore: minTagScore
        )
        let favoriteActors = InsightsScorer.rankMetrics(
            stats: actorStats,
            global: actorGlobals,
            displayNames: actorNames,
            limit: 5,
            minSupport: minPeopleSupport,
            minScore: minTagScore
        )
        let favoriteDirectors = InsightsScorer.rankMetrics(
            stats: directorStats,
            global: directorGlobals,
            displayNames: directorNames,
            limit: 5,
            minSupport: minPeopleSupport,
            minScore: minTagScore
        )
        let favoriteKeywords = InsightsScorer.rankMetrics(
            stats: keywordStats,
            global: keywordGlobals,
            displayNames: keywordNames,
            limit: 5,
            minSupport: minKeywordSupport,
            minScore: minTagScore
        )

        let rubricInsights = computeRubricInsights(from: candidateMovies, signalsById: signalsById)
        let personality = personalityPresenter.present(
            profile: profile,
            favoriteGenres: favoriteGenres,
            favoriteKeywords: favoriteKeywords,
            favoriteDirectors: favoriteDirectors,
            favoriteActors: favoriteActors
        )

        return InsightsSnapshot(
            favoriteGenres: favoriteGenres,
            favoriteActors: favoriteActors,
            favoriteDirectors: favoriteDirectors,
            favoriteKeywords: favoriteKeywords,
            rubricInsights: rubricInsights,
            personality: personality,
            sourceMovieCount: candidateMovies.count,
            sourcePickCount: events.count,
            detailsCoverage: detailsCoverage
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

    private func fetchComparedMovies(limit: Int) -> [Movie] {
        var descriptor = FetchDescriptor<Movie>(
            predicate: #Predicate { $0.comparisonsCount > 0 },
            sortBy: [SortDescriptor(\.comparisonsCount, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    private func fetchAllMovies() -> [Movie] {
        let descriptor = FetchDescriptor<Movie>()
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    private func fetchComparisonEvents() -> [ComparisonEvent] {
        var descriptor = FetchDescriptor<ComparisonEvent>(
            predicate: #Predicate { $0.selectedMovieID != nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
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

    private func computeRubricInsights(
        from movies: [Movie],
        signalsById: [Int: MoviePreferenceSignal]
    ) -> [String] {
        let weightedRatings: [(RubricRatings, Double)] = movies.compactMap { movie in
            guard let ratings = movie.rubricRatings else { return nil }
            guard let signal = signalsById[movie.tmdbID] else { return nil }
            let weight = max(0, signal.score) * signal.weight
            guard weight > 0 else { return nil }
            return (ratings, weight)
        }
        guard weightedRatings.count >= 5 else { return [] }

        let averages = RubricAverages(from: weightedRatings)
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

    private func buildComparisonStats(from events: [ComparisonEvent]) -> [Int: MovieComparisonStats] {
        var stats: [Int: MovieComparisonStats] = [:]
        for event in events {
            guard let selected = event.selectedMovieID else { continue }
            let left = event.leftMovieID
            let right = event.rightMovieID
            let winner = selected
            let loser = selected == left ? right : left
            let timestamp = event.createdAt

            var winnerStats = stats[winner] ?? MovieComparisonStats()
            winnerStats.wins += 1
            winnerStats.lastComparedAt = maxDate(winnerStats.lastComparedAt, timestamp)
            stats[winner] = winnerStats

            var loserStats = stats[loser] ?? MovieComparisonStats()
            loserStats.losses += 1
            loserStats.lastComparedAt = maxDate(loserStats.lastComparedAt, timestamp)
            stats[loser] = loserStats
        }
        return stats
    }

    private func normalizedKeyword(_ keyword: String) -> String? {
        let normalized = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return nil }
        guard normalized.count >= 3 else { return nil }
        guard normalized.rangeOfCharacter(from: .letters) != nil else { return nil }
        guard !keywordStoplist.contains(normalized) else { return nil }
        return normalized
    }

    private func displayKeyword(_ normalized: String) -> String {
        normalized.capitalized
    }

    private func maxDate(_ lhs: Date?, _ rhs: Date) -> Date {
        guard let lhs else { return rhs }
        return max(lhs, rhs)
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
        let sourceMovieCount: Int
        let sourcePickCount: Int
        let detailsCoverage: Double
    }

    private struct RubricAverages {
        let story: Double
        let action: Double
        let visuals: Double
        let dialogue: Double
        let acting: Double
        let sound: Double

        init(from ratings: [(RubricRatings, Double)]) {
            let totalWeight = ratings.map(\.1).reduce(0, +)
            guard totalWeight > 0 else {
                story = 0
                action = 0
                visuals = 0
                dialogue = 0
                acting = 0
                sound = 0
                return
            }

            story = ratings.reduce(0) { $0 + $1.0.story * $1.1 } / totalWeight
            action = ratings.reduce(0) { $0 + $1.0.action * $1.1 } / totalWeight
            visuals = ratings.reduce(0) { $0 + $1.0.visuals * $1.1 } / totalWeight
            dialogue = ratings.reduce(0) { $0 + $1.0.dialogue * $1.1 } / totalWeight
            acting = ratings.reduce(0) { $0 + $1.0.acting * $1.1 } / totalWeight
            sound = ratings.reduce(0) { $0 + $1.0.sound * $1.1 } / totalWeight
        }
    }

}
