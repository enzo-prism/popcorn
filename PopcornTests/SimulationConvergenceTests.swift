import XCTest
@testable import Popcorn

final class SimulationConvergenceTests: XCTestCase {
    func testCatConvergesFasterThanRandom() {
        let movieCount = 40
        let pickCount = 80
        var rng = SeededRandomNumberGenerator(seed: 123)
        let (movies, vectors) = makeMovies(count: movieCount, rng: &rng)
        let trueTheta = normalized(randomVector(count: 6, rng: &rng))

        let randomRmse = runSimulation(
            strategy: .random,
            movies: movies,
            vectors: vectors,
            trueTheta: trueTheta,
            picks: pickCount,
            seed: 77
        )

        let catRmse = runSimulation(
            strategy: .cat,
            movies: movies,
            vectors: vectors,
            trueTheta: trueTheta,
            picks: pickCount,
            seed: 77
        )

        XCTAssertLessThan(catRmse, randomRmse * 0.9)
    }

    private func runSimulation(
        strategy: Strategy,
        movies: [Movie],
        vectors: [Int: [Double]],
        trueTheta: [Double],
        picks: Int,
        seed: UInt64
    ) -> Double {
        var pairingRng = SeededRandomNumberGenerator(seed: seed)
        var choiceRng = SeededRandomNumberGenerator(seed: seed + 1)
        let selector = TasteCATSelector(randomesqueTopK: 6)

        var model = ForcedChoiceTasteModel(
            mu: Array(repeating: 0, count: 6),
            sigma: identityMatrix(size: 6, scale: 1.0),
            axisInfo: Array(repeating: 0, count: 6),
            comparisonsCount: 0
        )

        let profile = UserTasteProfile()

        for _ in 0..<picks {
            let pair: MoviePair
            switch strategy {
            case .random:
                pair = randomPair(from: movies, rng: &pairingRng)
            case .cat:
                profile.mu = model.mu
                profile.sigma = model.sigma
                profile.axisInfo = model.axisInfo
                profile.comparisonsCount = model.comparisonsCount
                let candidates = candidatePairs(from: movies, rng: &pairingRng, count: 40)
                let isWarmup = selector.isWarmup(profile: profile, sigmaScale: AppConfig.tasteSigmaScale)
                let scored = candidates.map { pair in
                    let score = selector.traitScore(for: pair, profile: profile, vectors: vectors, isWarmup: isWarmup)
                    return (pair: pair, score: score)
                }
                pair = selector.randomesquePick(from: scored, rng: &pairingRng) ?? candidates[0]
            }

            let leftVector = vectors[pair.left.tmdbID] ?? TasteVector.zero.values
            let rightVector = vectors[pair.right.tmdbID] ?? TasteVector.zero.values
            let delta = zip(leftVector, rightVector).map { $0 - $1 }
            let p = sigmoid(dot(trueTheta, delta))
            let roll = Double.random(in: 0..<1, using: &choiceRng)
            let choseLeft = roll < p
            model.update(delta: delta, choseLeft: choseLeft)
        }

        return rmse(model.mu, trueTheta)
    }

    private func candidatePairs<R: RandomNumberGenerator>(
        from movies: [Movie],
        rng: inout R,
        count: Int
    ) -> [MoviePair] {
        var pairs: [MoviePair] = []
        for _ in 0..<count {
            pairs.append(randomPair(from: movies, rng: &rng))
        }
        return pairs
    }

    private func randomPair<R: RandomNumberGenerator>(from movies: [Movie], rng: inout R) -> MoviePair {
        let count = movies.count
        let firstIndex = Int.random(in: 0..<count, using: &rng)
        var secondIndex = Int.random(in: 0..<(count - 1), using: &rng)
        if secondIndex >= firstIndex {
            secondIndex += 1
        }
        return MoviePair(left: movies[firstIndex], right: movies[secondIndex])
    }

    private func makeMovies<R: RandomNumberGenerator>(
        count: Int,
        rng: inout R
    ) -> ([Movie], [Int: [Double]]) {
        var movies: [Movie] = []
        var vectors: [Int: [Double]] = [:]
        for index in 1...count {
            let vector = randomVector(count: 6, rng: &rng)
            vectors[index] = vector
            movies.append(
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
            )
        }
        return (movies, vectors)
    }

    private func randomVector<R: RandomNumberGenerator>(count: Int, rng: inout R) -> [Double] {
        (0..<count).map { _ in Double.random(in: -1...1, using: &rng) }
    }

    private func normalized(_ vector: [Double]) -> [Double] {
        let length = sqrt(vector.map { $0 * $0 }.reduce(0, +))
        guard length > 0 else { return vector }
        return vector.map { $0 / length }
    }

    private func rmse(_ lhs: [Double], _ rhs: [Double]) -> Double {
        let count = Double(min(lhs.count, rhs.count))
        guard count > 0 else { return 0 }
        let sum = zip(lhs, rhs).reduce(0.0) { partial, pair in
            let diff = pair.0 - pair.1
            return partial + diff * diff
        }
        return sqrt(sum / count)
    }

    private func sigmoid(_ value: Double) -> Double {
        1 / (1 + exp(-value))
    }

    private func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
        zip(lhs, rhs).reduce(0.0) { $0 + $1.0 * $1.1 }
    }

    private func identityMatrix(size: Int, scale: Double) -> [[Double]] {
        (0..<size).map { row in
            (0..<size).map { col in
                row == col ? scale : 0
            }
        }
    }

    private enum Strategy {
        case random
        case cat
    }
}
