import XCTest
@testable import Popcorn

final class TasteCATSelectorDeterminismTests: XCTestCase {
    func testRandomesqueSelectionIsDeterministicWithSeededRng() {
        let selector = TasteCATSelector(randomesqueTopK: 3)
        let profile = UserTasteProfile()
        profile.mu = [0.2, -0.1, 0.05, 0, 0, 0]
        profile.sigma = identityMatrix(size: 6, scale: 1.0)
        profile.axisInfo = Array(repeating: 0.2, count: 6)
        profile.comparisonsCount = 30

        let movies = makeMovies(count: 4)
        let vectors: [Int: [Double]] = [
            1: [0.8, -0.2, 0.1, 0.3, 0, 0],
            2: [-0.4, 0.5, -0.1, 0.2, 0, 0],
            3: [0.2, 0.1, -0.4, -0.1, 0.3, 0],
            4: [-0.2, -0.3, 0.6, 0.2, -0.1, 0.1]
        ]

        let pairs = [
            MoviePair(left: movies[0], right: movies[1]),
            MoviePair(left: movies[0], right: movies[2]),
            MoviePair(left: movies[1], right: movies[3]),
            MoviePair(left: movies[2], right: movies[3])
        ]

        let scored = pairs.map { pair in
            let score = selector.traitScore(for: pair, profile: profile, vectors: vectors, isWarmup: false)
            return (pair: pair, score: score)
        }

        var rngA = SeededRandomNumberGenerator(seed: 7)
        var rngB = SeededRandomNumberGenerator(seed: 7)

        let pickA = selector.randomesquePick(from: scored, rng: &rngA)?.key
        let pickB = selector.randomesquePick(from: scored, rng: &rngB)?.key

        XCTAssertEqual(pickA, pickB)
    }

    private func makeMovies(count: Int) -> [Movie] {
        (1...count).map { index in
            Movie(
                tmdbID: index,
                title: "Movie \(index)",
                overview: "",
                releaseDate: nil,
                year: 2000 + index,
                posterPath: nil,
                backdropPath: nil,
                voteAverage: 7.0,
                voteCount: 2000,
                genreNames: ["Drama"]
            )
        }
    }

    private func identityMatrix(size: Int, scale: Double) -> [[Double]] {
        (0..<size).map { row in
            (0..<size).map { col in
                row == col ? scale : 0
            }
        }
    }
}
