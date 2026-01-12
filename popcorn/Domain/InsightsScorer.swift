import Foundation

struct TasteProfileSnapshot {
    let mu: [Double]
    let confidence: Double
}

struct MovieComparisonStats {
    var wins: Int = 0
    var losses: Int = 0
    var lastComparedAt: Date?

    var comparisons: Int {
        wins + losses
    }
}

struct MoviePreferenceSignal: Hashable {
    let score: Double
    let weight: Double
    let confidence: Double
    let recencyWeight: Double
    let comparisons: Int
}

struct TagStats: Hashable {
    var positive: Double = 0
    var negative: Double = 0
    var support: Double = 0
}

struct InsightsScorer {
    let now: Date
    let tasteProfile: TasteProfileSnapshot?
    let vectors: [Int: [Double]]
    let comparisonStats: [Int: MovieComparisonStats]

    private let winPrior = 6.0
    private let eloCenter = 1500.0
    private let eloScale = 320.0
    private let recencyHalfLifeDays = 120.0

    func signal(for movie: Movie) -> MoviePreferenceSignal {
        let stats = comparisonStats[movie.tmdbID]
        let comparisons = stats?.comparisons ?? movie.comparisonsCount
        let wins = stats?.wins ?? 0
        let losses = stats?.losses ?? 0

        let eloComponent = tanh((movie.eloRating - eloCenter) / eloScale)
        let winComponent = winRateComponent(wins: wins, losses: losses)
        let tasteComponent = tasteSimilarity(for: movie) * (tasteProfile?.confidence ?? 0)
        let score = clamp(0.45 * winComponent + 0.35 * eloComponent + 0.20 * tasteComponent, min: -1, max: 1)

        let winConfidence = winConfidenceScore(comparisons: comparisons)
        let eloConfidence = min(1, Double(comparisons) / 10.0)
        let tasteConfidence = tasteProfile?.confidence ?? 0
        let confidence = clamp(0.5 * winConfidence + 0.3 * eloConfidence + 0.2 * tasteConfidence, min: 0, max: 1)

        let recencyWeight = recencyScore(for: stats?.lastComparedAt ?? movie.lastComparedAt)
        let weight = confidence * recencyWeight

        return MoviePreferenceSignal(
            score: score,
            weight: weight,
            confidence: confidence,
            recencyWeight: recencyWeight,
            comparisons: comparisons
        )
    }

    func signals(for movies: [Movie]) -> [Int: MoviePreferenceSignal] {
        var result: [Int: MoviePreferenceSignal] = [:]
        for movie in movies {
            result[movie.tmdbID] = signal(for: movie)
        }
        return result
    }

    static func addTag(
        key: String,
        displayName: String,
        weight: Double,
        signal: MoviePreferenceSignal,
        stats: inout [String: TagStats],
        displayNames: inout [String: String]
    ) {
        let contribution = signal.score * signal.weight * weight
        guard contribution != 0 else { return }

        var entry = stats[key] ?? TagStats()
        if contribution > 0 {
            entry.positive += contribution
        } else {
            entry.negative += abs(contribution)
        }
        entry.support += signal.confidence * weight
        stats[key] = entry

        if displayNames[key] == nil {
            displayNames[key] = displayName
        }
    }

    static func addGlobalTag(
        key: String,
        displayName: String,
        weight: Double,
        global: inout [String: Double],
        displayNames: inout [String: String]
    ) {
        global[key, default: 0] += weight
        if displayNames[key] == nil {
            displayNames[key] = displayName
        }
    }

    static func rankMetrics(
        stats: [String: TagStats],
        global: [String: Double],
        displayNames: [String: String],
        limit: Int,
        minSupport: Double,
        minScore: Double,
        negativeWeight: Double = 0.6
    ) -> [NamedMetric] {
        let totalGlobal = max(1, global.values.reduce(0, +))
        var metrics: [NamedMetric] = []

        for (key, stat) in stats {
            let globalCount = global[key] ?? 0
            let idf = log(1 + totalGlobal / (globalCount + 1))
            let net = stat.positive - stat.negative * negativeWeight
            let score = net * idf
            guard score > minScore, stat.support >= minSupport else { continue }
            let name = displayNames[key] ?? key
            metrics.append(NamedMetric(name: name, score: score, support: stat.support))
        }

        metrics.sort {
            if $0.score == $1.score {
                return $0.name < $1.name
            }
            return $0.score > $1.score
        }
        return Array(metrics.prefix(limit))
    }

    private func winRateComponent(wins: Int, losses: Int) -> Double {
        let comparisons = wins + losses
        guard comparisons > 0 else { return 0 }
        let winRate = Double(wins - losses) / Double(comparisons)
        let shrink = Double(comparisons) / Double(comparisons + Int(winPrior))
        return winRate * shrink
    }

    private func winConfidenceScore(comparisons: Int) -> Double {
        Double(comparisons) / Double(comparisons + Int(winPrior))
    }

    private func tasteSimilarity(for movie: Movie) -> Double {
        guard let profile = tasteProfile else { return 0 }
        guard let vector = vectors[movie.tmdbID], vector.count == profile.mu.count else { return 0 }
        let mu = profile.mu
        let dot = zip(mu, vector).reduce(0.0) { $0 + $1.0 * $1.1 }
        let muNorm = sqrt(mu.map { $0 * $0 }.reduce(0, +))
        let vectorNorm = sqrt(vector.map { $0 * $0 }.reduce(0, +))
        guard muNorm > 0, vectorNorm > 0 else { return 0 }
        return clamp(dot / (muNorm * vectorNorm), min: -1, max: 1)
    }

    private func recencyScore(for date: Date?) -> Double {
        guard let date else { return 0.5 }
        let days = max(0, now.timeIntervalSince(date) / 86_400)
        let decay = exp(-days / recencyHalfLifeDays)
        return 0.4 + 0.6 * decay
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
