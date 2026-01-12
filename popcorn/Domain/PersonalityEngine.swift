import Foundation

struct PersonalityProfile: Hashable {
    let title: String
    let traits: [String]
    let summary: String
    let confidence: Double
    let progress: Double
    let isReady: Bool
}

final class PersonalityEngine {
    private let minComparisons: Int
    private let maxComparisonConfidence: Double = 50

    init(minComparisons: Int = AppConfig.refreshMomentInterval) {
        self.minComparisons = max(minComparisons, 1)
    }

    func buildProfile(
        comparisonCount: Int,
        ratingSpread: Double,
        topGenres: [NamedMetric],
        topKeywords: [NamedMetric],
        topDirectors: [NamedMetric],
        topActors: [NamedMetric]
    ) -> PersonalityProfile {
        let progress = min(1, Double(comparisonCount) / Double(minComparisons))
        let pickFactor = min(1, Double(comparisonCount) / maxComparisonConfidence)
        let spreadFactor = min(1, ratingSpread / 200)
        let confidence = min(1, 0.2 + 0.8 * (0.7 * pickFactor + 0.3 * spreadFactor))
        let ready = comparisonCount >= minComparisons

        guard ready else {
            return PersonalityProfile(
                title: "",
                traits: [],
                summary: "",
                confidence: confidence,
                progress: progress,
                isReady: false
            )
        }

        let genreName = topGenres.first?.name
        let keywordName = topKeywords.first?.name
        let directorName = topDirectors.first?.name
        let actorName = topActors.first?.name

        let styleWord = styleDescriptor(for: genreName)
        let mindWord = mindsetDescriptor(for: keywordName, directorName: directorName, actorName: actorName)
        let title = "The \(styleWord) \(mindWord)"

        var traits: [String] = []
        if let genreTrait = traitForGenre(genreName) {
            traits.append(genreTrait)
        }
        if let keywordTrait = traitForKeyword(keywordName) {
            traits.append(keywordTrait)
        }
        traits.append(traitForSignal(comparisonCount: comparisonCount, ratingSpread: ratingSpread))
        if traits.count < 3 {
            traits.append("curiosity-forward")
        }
        let trimmedTraits = Array(traits.prefix(3))

        let summary = summaryText(
            genreName: genreName,
            keywordName: keywordName,
            traits: trimmedTraits
        )

        return PersonalityProfile(
            title: title,
            traits: trimmedTraits,
            summary: summary,
            confidence: confidence,
            progress: progress,
            isReady: true
        )
    }

    private func styleDescriptor(for genre: String?) -> String {
        guard let genre else { return "Cinematic" }
        switch genre {
        case "Sci-Fi": return "Neon"
        case "Drama": return "Tender"
        case "Comedy": return "Bright"
        case "Thriller": return "Edge"
        case "Horror": return "Midnight"
        case "Animation": return "Whimsical"
        case "Fantasy": return "Mythic"
        case "Action": return "Blazing"
        case "Adventure": return "Wandering"
        case "Crime": return "Noir"
        case "Romance": return "Heart"
        case "Mystery": return "Cipher"
        case "History": return "Golden"
        case "War": return "Steel"
        case "Western": return "Dust"
        case "Documentary": return "Lens"
        case "Music": return "Pulse"
        case "Family": return "Warm"
        default: return "Cinematic"
        }
    }

    private func mindsetDescriptor(for keyword: String?, directorName: String?, actorName: String?) -> String {
        guard let keyword = keyword?.lowercased() else {
            if directorName != nil { return "Auteur" }
            if actorName != nil { return "Star" }
            return "Curator"
        }

        if keyword.contains("dream") { return "Dreamer" }
        if keyword.contains("redemption") { return "Philosopher" }
        if keyword.contains("revenge") { return "Avenger" }
        if keyword.contains("love") { return "Romantic" }
        if keyword.contains("friend") { return "Connector" }
        if keyword.contains("survival") { return "Survivor" }
        if keyword.contains("time") { return "Timekeeper" }
        if keyword.contains("space") { return "Cosmic" }
        if keyword.contains("heist") { return "Schemer" }
        if keyword.contains("war") { return "Strategist" }
        if keyword.contains("coming of age") { return "Seeker" }
        if keyword.contains("mystery") { return "Investigator" }
        return "Curator"
    }

    private func traitForGenre(_ genre: String?) -> String? {
        guard let genre else { return nil }
        switch genre {
        case "Sci-Fi": return "future-minded"
        case "Drama": return "character-driven"
        case "Comedy": return "joy-seeking"
        case "Thriller": return "tension-tuned"
        case "Horror": return "midnight brave"
        case "Animation": return "whimsy lover"
        case "Fantasy": return "mythic dreamer"
        case "Action": return "adrenaline-forward"
        case "Adventure": return "wanderlust"
        case "Crime": return "noir-leaning"
        case "Romance": return "heart-first"
        case "Mystery": return "curiosity-driven"
        case "Documentary": return "truth-seeking"
        case "History": return "time-traveling"
        case "War": return "battle-hardened"
        case "Western": return "dust trail"
        case "Music": return "rhythm-led"
        case "Family": return "warm-hearted"
        default: return "genre-fluid"
        }
    }

    private func traitForKeyword(_ keyword: String?) -> String? {
        guard let keyword = keyword?.lowercased() else { return nil }
        if keyword.contains("redemption") { return "introspective" }
        if keyword.contains("friend") { return "connection-driven" }
        if keyword.contains("love") { return "romance-forward" }
        if keyword.contains("revenge") { return "justice-seeking" }
        if keyword.contains("heist") { return "clever-minded" }
        if keyword.contains("space") { return "cosmic-curious" }
        if keyword.contains("time") { return "time-bending" }
        if keyword.contains("survival") { return "resilient" }
        if keyword.contains("dream") { return "imaginative" }
        if keyword.contains("coming of age") { return "growth-focused" }
        return nil
    }

    private func traitForSignal(comparisonCount: Int, ratingSpread: Double) -> String {
        if comparisonCount >= minComparisons * 3 && ratingSpread >= 120 {
            return "decisive"
        }
        if ratingSpread >= 120 {
            return "conviction-driven"
        }
        if comparisonCount >= minComparisons * 3 {
            return "data-confident"
        }
        return "still exploring"
    }

    private func summaryText(genreName: String?, keywordName: String?, traits: [String]) -> String {
        var parts: [String] = []
        if let genreName {
            parts.append("You gravitate toward \(genreName) stories")
        } else {
            parts.append("You gravitate toward bold, modern stories")
        }
        if let keywordName {
            parts.append("with a taste for \(keywordName.lowercased()) themes")
        }
        if traits.count >= 2 {
            parts.append("Your picks feel \(traits[0]) and \(traits[1])")
        }
        return parts.joined(separator: ". ") + "."
    }
}
