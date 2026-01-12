import XCTest
@testable import Popcorn

final class PairSelectorTests: XCTestCase {
    func testDeterministicPairsWithSeededRng() {
        let movies = makeMovies(count: 8)
        var selectorA = PairSelector(bufferSize: 5)
        var selectorB = PairSelector(bufferSize: 5)
        var rngA = SeededRandomNumberGenerator(seed: 42)
        var rngB = SeededRandomNumberGenerator(seed: 42)

        let pairsA = (0..<6).compactMap { _ in
            selectorA.nextPair(from: movies, tasteProfile: nil, tasteVectors: [:], rng: &rngA)?.key
        }
        let pairsB = (0..<6).compactMap { _ in
            selectorB.nextPair(from: movies, tasteProfile: nil, tasteVectors: [:], rng: &rngB)?.key
        }

        XCTAssertEqual(pairsA, pairsB)
    }

    func testNoRepeatPairsWithinBuffer() {
        let movies = makeMovies(count: 10)
        var selector = PairSelector(bufferSize: 5)
        var rng = SeededRandomNumberGenerator(seed: 7)
        var recent: [String] = []

        for _ in 0..<12 {
            guard let pair = selector.nextPair(from: movies, tasteProfile: nil, tasteVectors: [:], rng: &rng) else {
                XCTFail("Expected a pair")
                return
            }
            let key = pair.key
            XCTAssertFalse(recent.contains(key))
            recent.append(key)
            if recent.count > 5 {
                recent.removeFirst(recent.count - 5)
            }
        }
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
}
