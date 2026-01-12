import XCTest
@testable import Popcorn

final class InsightsScorerTests: XCTestCase {
    func testSignalRewardsWinsOverLosses() {
        let now = Date()
        let winningMovie = Movie(
            tmdbID: 1,
            title: "Winner",
            overview: "",
            releaseDate: nil,
            year: 2024,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 7.5,
            voteCount: 3000,
            genreNames: ["Sci-Fi"]
        )
        let losingMovie = Movie(
            tmdbID: 2,
            title: "Loser",
            overview: "",
            releaseDate: nil,
            year: 2024,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 7.5,
            voteCount: 3000,
            genreNames: ["Drama"]
        )
        winningMovie.eloRating = 1500
        losingMovie.eloRating = 1500

        let stats: [Int: MovieComparisonStats] = [
            1: MovieComparisonStats(wins: 5, losses: 1, lastComparedAt: now),
            2: MovieComparisonStats(wins: 1, losses: 5, lastComparedAt: now)
        ]
        let scorer = InsightsScorer(now: now, tasteProfile: nil, vectors: [:], comparisonStats: stats)

        let winningSignal = scorer.signal(for: winningMovie)
        let losingSignal = scorer.signal(for: losingMovie)

        XCTAssertGreaterThan(winningSignal.score, 0)
        XCTAssertLessThan(losingSignal.score, 0)
        XCTAssertGreaterThan(winningSignal.score, losingSignal.score)
    }

    func testRankMetricsPrefersPositiveSignals() {
        var stats: [String: TagStats] = [:]
        var names: [String: String] = [:]
        let positiveSignal = MoviePreferenceSignal(
            score: 0.8,
            weight: 0.9,
            confidence: 0.8,
            recencyWeight: 1,
            comparisons: 10
        )
        let negativeSignal = MoviePreferenceSignal(
            score: -0.7,
            weight: 0.8,
            confidence: 0.7,
            recencyWeight: 1,
            comparisons: 10
        )

        InsightsScorer.addTag(
            key: "sci-fi",
            displayName: "Sci-Fi",
            weight: 1.0,
            signal: positiveSignal,
            stats: &stats,
            displayNames: &names
        )
        InsightsScorer.addTag(
            key: "drama",
            displayName: "Drama",
            weight: 1.0,
            signal: negativeSignal,
            stats: &stats,
            displayNames: &names
        )

        let global: [String: Double] = [
            "sci-fi": 3,
            "drama": 3
        ]

        let metrics = InsightsScorer.rankMetrics(
            stats: stats,
            global: global,
            displayNames: names,
            limit: 5,
            minSupport: 0.1,
            minScore: 0.01
        )

        XCTAssertEqual(metrics.first?.name, "Sci-Fi")
        XCTAssertTrue(metrics.allSatisfy { $0.name != "Drama" })
    }
}
