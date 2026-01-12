import Foundation

struct PairSelector {
    private(set) var recentPairs: [String] = []
    let bufferSize: Int

    private let informativeWeight = 0.7
    private let challengeWeight = 0.2
    private let candidatePoolSize = 60
    private let informativeSampleSize = 30
    private let challengeNeighborRange = 4
    private let challengePickLimit = 3
    private let maxFallbackAttempts = 12

    private let rankWeight = 0.55
    private let traitWeight = 0.35
    private let exploreWeight = 0.10
    private let challengeBoost = 0.15

    private let tasteSelector = TasteCATSelector()

    init(bufferSize: Int) {
        self.bufferSize = bufferSize
    }

    mutating func nextPair<R: RandomNumberGenerator>(
        from movies: [Movie],
        tasteProfile: UserTasteProfile?,
        tasteVectors: [Int: [Double]],
        rng: inout R
    ) -> MoviePair? {
        let visibleCandidates = movies.filter { $0.seenState != .notSeen }
        let pool = visibleCandidates.count >= 2 ? visibleCandidates : movies
        guard pool.count >= 2 else { return nil }

        let ranked = pool.sorted {
            if $0.eloRating == $1.eloRating {
                return $0.tmdbID < $1.tmdbID
            }
            return $0.eloRating > $1.eloRating
        }

        var rankIndexById: [Int: Int] = [:]
        for (index, movie) in ranked.enumerated() {
            rankIndexById[movie.tmdbID] = index
        }

        let candidates = candidatePairs(from: pool, ranked: ranked, rng: &rng)
        let isWarmup = tasteProfile.map { tasteSelector.isWarmup(profile: $0, sigmaScale: AppConfig.tasteSigmaScale) } ?? false
        var scoredByKey: [String: (pair: MoviePair, score: Double)] = [:]

        for pair in candidates {
            if recentPairs.contains(pair.key) {
                continue
            }
            let rankScore = rankScore(for: pair, rankIndexById: rankIndexById)
            let traitScore = tasteSelector.traitScore(
                for: pair,
                profile: tasteProfile,
                vectors: tasteVectors,
                isWarmup: isWarmup
            )
            let noveltyScore = noveltyScore(for: pair)
            let totalScore = rankWeight * rankScore + traitWeight * traitScore + exploreWeight * noveltyScore

            if let existing = scoredByKey[pair.key], existing.score >= totalScore {
                continue
            }
            scoredByKey[pair.key] = (pair, totalScore)
        }

        if let picked = tasteSelector.randomesquePick(from: Array(scoredByKey.values), rng: &rng) {
            record(picked.key)
            return picked
        }

        if let fallback = fallbackPair(from: pool, rng: &rng) {
            record(fallback.key)
            return fallback
        }

        return nil
    }

    private func candidatePairs<R: RandomNumberGenerator>(
        from pool: [Movie],
        ranked: [Movie],
        rng: inout R
    ) -> [MoviePair] {
        var candidates: [MoviePair] = []
        for _ in 0..<candidatePoolSize {
            let mode = pickMode(using: &rng)
            if let pair = candidatePair(mode: mode, from: pool, ranked: ranked, rng: &rng) {
                candidates.append(pair)
            }
        }
        return candidates
    }

    private func candidatePair<R: RandomNumberGenerator>(
        mode: PairSelectionMode,
        from pool: [Movie],
        ranked: [Movie],
        rng: inout R
    ) -> MoviePair? {
        switch mode {
        case .informative:
            return informativePair(from: pool, rng: &rng)
        case .challenge:
            return challengePair(from: pool, ranked: ranked, rng: &rng)
        case .random:
            return randomPair(from: pool, rng: &rng)
        }
    }

    private func informativePair<R: RandomNumberGenerator>(from pool: [Movie], rng: inout R) -> MoviePair? {
        let sampleCount = min(informativeSampleSize, pool.count * 2)
        var best: (pair: MoviePair, score: Double)?

        for _ in 0..<sampleCount {
            guard let pair = randomPair(from: pool, rng: &rng) else { continue }
            let expected = EloRanker.expectedScore(rating: pair.left.eloRating, against: pair.right.eloRating)
            let closeness = abs(0.5 - expected)
            if best == nil || closeness < best!.score {
                best = (pair, closeness)
            }
        }

        return best?.pair
    }

    private func challengePair<R: RandomNumberGenerator>(
        from pool: [Movie],
        ranked: [Movie],
        rng: inout R
    ) -> MoviePair? {
        let topCount = min(10, ranked.count)
        guard topCount >= 1 else { return nil }
        let topIndex = Int.random(in: 0..<topCount, using: &rng)
        let topMovie = ranked[topIndex]

        guard let topPosition = ranked.firstIndex(where: { $0.tmdbID == topMovie.tmdbID }) else {
            return nil
        }

        let start = max(0, topPosition - challengeNeighborRange)
        let end = min(ranked.count - 1, topPosition + challengeNeighborRange)
        var neighbors = ranked[start...end].filter { $0.tmdbID != topMovie.tmdbID }
        if neighbors.isEmpty {
            return randomPair(from: pool, rng: &rng)
        }

        neighbors.sort {
            if $0.comparisonsCount == $1.comparisonsCount {
                return $0.tmdbID < $1.tmdbID
            }
            return $0.comparisonsCount < $1.comparisonsCount
        }

        let pickCount = min(challengePickLimit, neighbors.count)
        let opponentIndex = Int.random(in: 0..<pickCount, using: &rng)
        let opponent = neighbors[opponentIndex]

        if Bool.random(using: &rng) {
            return MoviePair(left: topMovie, right: opponent)
        }
        return MoviePair(left: opponent, right: topMovie)
    }

    private func randomPair<R: RandomNumberGenerator>(from pool: [Movie], rng: inout R) -> MoviePair? {
        guard pool.count >= 2 else { return nil }
        let firstIndex = Int.random(in: 0..<pool.count, using: &rng)
        var secondIndex = Int.random(in: 0..<(pool.count - 1), using: &rng)
        if secondIndex >= firstIndex {
            secondIndex += 1
        }
        return MoviePair(left: pool[firstIndex], right: pool[secondIndex])
    }

    private func rankScore(for pair: MoviePair, rankIndexById: [Int: Int]) -> Double {
        let expected = EloRanker.expectedScore(rating: pair.left.eloRating, against: pair.right.eloRating)
        let closeness = 1 - (abs(0.5 - expected) / 0.5)
        let challengeBonus = isChallengePair(pair, rankIndexById: rankIndexById) ? challengeBoost : 0
        return clamp(closeness + challengeBonus, min: 0, max: 1)
    }

    private func isChallengePair(_ pair: MoviePair, rankIndexById: [Int: Int]) -> Bool {
        guard let leftIndex = rankIndexById[pair.left.tmdbID],
              let rightIndex = rankIndexById[pair.right.tmdbID] else {
            return false
        }
        let topLimit = 10
        if leftIndex < topLimit {
            return abs(leftIndex - rightIndex) <= challengeNeighborRange
        }
        if rightIndex < topLimit {
            return abs(leftIndex - rightIndex) <= challengeNeighborRange
        }
        return false
    }

    private func noveltyScore(for pair: MoviePair) -> Double {
        let minComparisons = min(pair.left.comparisonsCount, pair.right.comparisonsCount)
        let score = 1 / (1 + Double(minComparisons))
        return clamp(score, min: 0, max: 1)
    }

    private func fallbackPair<R: RandomNumberGenerator>(from pool: [Movie], rng: inout R) -> MoviePair? {
        for _ in 0..<maxFallbackAttempts {
            guard let pair = randomPair(from: pool, rng: &rng) else { continue }
            if !recentPairs.contains(pair.key) {
                return pair
            }
        }
        return firstAvailablePair(from: pool)
    }

    private func firstAvailablePair(from pool: [Movie]) -> MoviePair? {
        let sorted = pool.sorted { $0.tmdbID < $1.tmdbID }
        for i in 0..<sorted.count {
            for j in (i + 1)..<sorted.count {
                let pair = MoviePair(left: sorted[i], right: sorted[j])
                if !recentPairs.contains(pair.key) {
                    return pair
                }
            }
        }
        return nil
    }

    private mutating func record(_ key: String) {
        recentPairs.append(key)
        if recentPairs.count > bufferSize {
            recentPairs.removeFirst(recentPairs.count - bufferSize)
        }
    }

    private func pickMode<R: RandomNumberGenerator>(using rng: inout R) -> PairSelectionMode {
        let roll = Double.random(in: 0..<1, using: &rng)
        if roll < informativeWeight {
            return .informative
        }
        if roll < informativeWeight + challengeWeight {
            return .challenge
        }
        return .random
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }

    private enum PairSelectionMode {
        case informative
        case challenge
        case random
    }
}
