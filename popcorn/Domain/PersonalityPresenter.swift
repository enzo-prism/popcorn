import Foundation

struct TastePersonalitySnapshot: Hashable {
    let title: String
    let traits: [String]
    let evidence: [String]
    let summary: String
    let confidence: Double
    let isReady: Bool
    let progress: Double
    let remainingComparisons: Int
}

struct PersonalityPresenter {
    let minComparisons: Int
    let confidenceThreshold: Double

    init(minComparisons: Int = 20, confidenceThreshold: Double = 0.5) {
        self.minComparisons = minComparisons
        self.confidenceThreshold = confidenceThreshold
    }

    func present(
        profile: UserTasteProfile?,
        favoriteGenres: [NamedMetric],
        favoriteKeywords: [NamedMetric],
        favoriteDirectors: [NamedMetric],
        favoriteActors: [NamedMetric]
    ) -> TastePersonalitySnapshot {
        guard let profile else {
            return TastePersonalitySnapshot(
                title: "Developing Profile",
                traits: [],
                evidence: [],
                summary: "Keep comparing movies to build your taste profile.",
                confidence: 0,
                isReady: false,
                progress: 0,
                remainingComparisons: minComparisons
            )
        }

        let model = ForcedChoiceTasteModel(
            mu: profile.mu,
            sigma: profile.sigma,
            axisInfo: profile.axisInfo,
            comparisonsCount: profile.comparisonsCount
        )
        let confidence = model.confidence(sigmaScale: AppConfig.tasteSigmaScale)
        let comparisons = profile.comparisonsCount
        let progress = min(1, max(Double(comparisons) / Double(max(minComparisons, 1)), confidence))
        let remaining = max(0, minComparisons - comparisons)
        let isReady = comparisons >= minComparisons && confidence >= confidenceThreshold

        guard isReady else {
            return TastePersonalitySnapshot(
                title: "Developing Profile",
                traits: [],
                evidence: [],
                summary: "Your taste profile is still stabilizing.",
                confidence: confidence,
                isReady: false,
                progress: progress,
                remainingComparisons: remaining
            )
        }

        let axisSignals = dominantAxes(from: profile.mu, limit: 3)
        let traits = axisSignals.map { traitLabel(for: $0.axis, sign: $0.value) }
        let title = buildTitle(from: axisSignals)
        let evidence = buildEvidence(
            axes: axisSignals,
            favoriteGenres: favoriteGenres,
            favoriteKeywords: favoriteKeywords,
            favoriteDirectors: favoriteDirectors,
            favoriteActors: favoriteActors
        )
        let summary = evidence.first ?? "Based on your picks, your taste is taking shape."

        return TastePersonalitySnapshot(
            title: title,
            traits: traits,
            evidence: evidence,
            summary: summary,
            confidence: confidence,
            isReady: true,
            progress: progress,
            remainingComparisons: remaining
        )
    }

    private func dominantAxes(from mu: [Double], limit: Int) -> [AxisSignal] {
        let signals = TasteAxis.allCases.enumerated().map { index, axis in
            AxisSignal(axis: axis, value: index < mu.count ? mu[index] : 0)
        }
        let sorted = signals.sorted {
            let lhs = abs($0.value)
            let rhs = abs($1.value)
            if lhs == rhs { return $0.axis.rawValue < $1.axis.rawValue }
            return lhs > rhs
        }
        return Array(sorted.prefix(limit))
    }

    private func buildTitle(from axes: [AxisSignal]) -> String {
        guard let first = axes.first else { return "The Curator" }
        let second = axes.count > 1 ? axes[1] : nil
        let firstWord = titleWord(for: first.axis, sign: first.value)
        let secondWord = second.map { titleWord(for: $0.axis, sign: $0.value) } ?? "Curator"
        return "The \(firstWord) \(secondWord)"
    }

    private func titleWord(for axis: TasteAxis, sign: Double) -> String {
        switch axis {
        case .cerebralVisceral: return sign >= 0 ? "Cerebral" : "Visceral"
        case .darkComfort: return sign >= 0 ? "Midnight" : "Warm"
        case .auteurMainstream: return sign >= 0 ? "Auteur" : "Crowd"
        case .realismEscapism: return sign >= 0 ? "Realist" : "Dreamer"
        case .characterSpectacle: return sign >= 0 ? "Character" : "Spectacle"
        case .noveltyFamiliarity: return sign >= 0 ? "Explorer" : "Classic"
        }
    }

    private func traitLabel(for axis: TasteAxis, sign: Double) -> String {
        switch axis {
        case .cerebralVisceral: return sign >= 0 ? "cerebral" : "visceral"
        case .darkComfort: return sign >= 0 ? "dark-leaning" : "comfort-first"
        case .auteurMainstream: return sign >= 0 ? "auteur-leaning" : "mainstream-friendly"
        case .realismEscapism: return sign >= 0 ? "grounded realist" : "escapist"
        case .characterSpectacle: return sign >= 0 ? "character-first" : "spectacle-driven"
        case .noveltyFamiliarity: return sign >= 0 ? "novelty-seeking" : "familiarity-seeking"
        }
    }

    private func buildEvidence(
        axes: [AxisSignal],
        favoriteGenres: [NamedMetric],
        favoriteKeywords: [NamedMetric],
        favoriteDirectors: [NamedMetric],
        favoriteActors: [NamedMetric]
    ) -> [String] {
        var evidence: [String] = []
        var usedGenre = false
        var usedKeyword = false

        for signal in axes {
            var line = evidenceLine(for: signal.axis, sign: signal.value)
            if !usedGenre, let genre = favoriteGenres.first?.name {
                line += " Your top picks keep elevating \(genre)."
                usedGenre = true
            } else if !usedKeyword, let keyword = favoriteKeywords.first?.name {
                line += " Keywords like \(keyword.lowercased()) appear often."
                usedKeyword = true
            } else if let director = favoriteDirectors.first?.name, !line.contains(director) {
                line += " Directors like \(director) show up in your favorites."
            } else if let actor = favoriteActors.first?.name, !line.contains(actor) {
                line += " Actors like \(actor) keep appearing in your picks."
            }
            evidence.append(line)
        }

        if evidence.count < 3 {
            evidence.append("Your choices are sharpening this profile with every comparison.")
        }

        return Array(evidence.prefix(3))
    }

    private func evidenceLine(for axis: TasteAxis, sign: Double) -> String {
        switch axis {
        case .cerebralVisceral:
            return sign >= 0
                ? "You pick idea-driven stories over pure adrenaline."
                : "You favor visceral momentum over slow-burn puzzles."
        case .darkComfort:
            return sign >= 0
                ? "You often choose darker, intense films over lighter comfort picks."
                : "You lean toward lighter, comfort-first films."
        case .auteurMainstream:
            return sign >= 0
                ? "You gravitate toward auteur voices over mainstream crowd-pleasers."
                : "You gravitate toward crowd-pleasers over auteur signatures."
        case .realismEscapism:
            return sign >= 0
                ? "You lean toward grounded realism over pure escapism."
                : "You choose escapist worlds over strict realism."
        case .characterSpectacle:
            return sign >= 0
                ? "You favor character-first storytelling over spectacle."
                : "You chase spectacle and scale over character focus."
        case .noveltyFamiliarity:
            return sign >= 0
                ? "You seek novelty and surprise more than familiar formulas."
                : "You enjoy familiar formulas and comfort viewing."
        }
    }

    private struct AxisSignal {
        let axis: TasteAxis
        let value: Double
    }
}
