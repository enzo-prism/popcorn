import Foundation

struct TasteCATSelector {
    let warmupComparisons: Int
    let warmupConfidenceThreshold: Double
    let warmupGainWeight: Double
    let warmupDiversityWeight: Double
    let steadyGainWeight: Double
    let steadyDiversityWeight: Double
    let axisWeight: Double
    let genreWeight: Double
    let randomesqueTopK: Int

    init(
        warmupComparisons: Int = 10,
        warmupConfidenceThreshold: Double = 0.2,
        warmupGainWeight: Double = 0.6,
        warmupDiversityWeight: Double = 0.4,
        steadyGainWeight: Double = 0.85,
        steadyDiversityWeight: Double = 0.15,
        axisWeight: Double = 0.7,
        genreWeight: Double = 0.3,
        randomesqueTopK: Int = 6
    ) {
        self.warmupComparisons = warmupComparisons
        self.warmupConfidenceThreshold = warmupConfidenceThreshold
        self.warmupGainWeight = warmupGainWeight
        self.warmupDiversityWeight = warmupDiversityWeight
        self.steadyGainWeight = steadyGainWeight
        self.steadyDiversityWeight = steadyDiversityWeight
        self.axisWeight = axisWeight
        self.genreWeight = genreWeight
        self.randomesqueTopK = randomesqueTopK
    }

    func isWarmup(profile: UserTasteProfile, sigmaScale: Double) -> Bool {
        let model = ForcedChoiceTasteModel(
            mu: profile.mu,
            sigma: profile.sigma,
            axisInfo: profile.axisInfo,
            comparisonsCount: profile.comparisonsCount
        )
        let confidence = model.confidence(sigmaScale: sigmaScale)
        return profile.comparisonsCount < warmupComparisons || confidence < warmupConfidenceThreshold
    }

    func traitScore(
        for pair: MoviePair,
        profile: UserTasteProfile?,
        vectors: [Int: [Double]],
        isWarmup: Bool
    ) -> Double {
        guard let profile else { return 0 }

        let leftVector = vectors[pair.left.tmdbID] ?? TasteVector.zero.values
        let rightVector = vectors[pair.right.tmdbID] ?? TasteVector.zero.values
        let delta = zip(leftVector, rightVector).map { $0 - $1 }

        let gain = traitGain(delta: delta, mu: profile.mu, sigma: profile.sigma)
        let normalizedGain = 1 - exp(-gain)
        let diversity = diversityBoost(
            delta: delta,
            axisInfo: profile.axisInfo,
            leftGenres: pair.left.genreNames,
            rightGenres: pair.right.genreNames
        )

        let gainWeight = isWarmup ? warmupGainWeight : steadyGainWeight
        let diversityWeight = isWarmup ? warmupDiversityWeight : steadyDiversityWeight
        return clamp(gainWeight * normalizedGain + diversityWeight * diversity, min: 0, max: 1)
    }

    func randomesquePick<R: RandomNumberGenerator>(
        from scored: [(pair: MoviePair, score: Double)],
        rng: inout R
    ) -> MoviePair? {
        guard !scored.isEmpty else { return nil }

        let sorted = scored.sorted {
            if $0.score == $1.score {
                return $0.pair.key < $1.pair.key
            }
            return $0.score > $1.score
        }

        let limit = min(randomesqueTopK, sorted.count)
        let top = Array(sorted.prefix(limit))
        let weights = top.map { max($0.score, 0.0001) }
        let total = weights.reduce(0, +)
        if total <= 0 {
            let index = Int.random(in: 0..<top.count, using: &rng)
            return top[index].pair
        }

        let roll = Double.random(in: 0..<total, using: &rng)
        var running = 0.0
        for (index, candidate) in top.enumerated() {
            running += weights[index]
            if roll <= running {
                return candidate.pair
            }
        }
        return top.last?.pair
    }

    private func traitGain(delta: [Double], mu: [Double], sigma: [[Double]]) -> Double {
        let p = sigmoid(dot(mu, delta))
        let alpha = p * (1 - p)
        let sigmaDelta = matVec(sigma, delta)
        let deltaSigmaDelta = max(0, dot(delta, sigmaDelta))
        return log(1 + alpha * deltaSigmaDelta)
    }

    private func diversityBoost(
        delta: [Double],
        axisInfo: [Double],
        leftGenres: [String],
        rightGenres: [String]
    ) -> Double {
        let axisCount = Double(TasteAxis.allCases.count)
        let weights = axisInfo.map { 1 / (1 + $0) }
        let axisSum = zip(delta.map(abs), weights).reduce(0.0) { $0 + $1.0 * $1.1 }
        let axisScore = axisSum / (axisCount * 2)

        let genres = Set(leftGenres + rightGenres)
        let genreDenom = max(1, leftGenres.count + rightGenres.count)
        let genreScore = Double(genres.count) / Double(genreDenom)

        return clamp(axisWeight * axisScore + genreWeight * genreScore, min: 0, max: 1)
    }

    private func sigmoid(_ value: Double) -> Double {
        1 / (1 + exp(-value))
    }

    private func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
        zip(lhs, rhs).reduce(0.0) { $0 + $1.0 * $1.1 }
    }

    private func matVec(_ matrix: [[Double]], _ vector: [Double]) -> [Double] {
        matrix.map { row in
            zip(row, vector).reduce(0.0) { $0 + $1.0 * $1.1 }
        }
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
