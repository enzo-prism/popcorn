import Foundation
import SwiftData

@Model
final class InsightsCache {
    var id: UUID
    var updatedAt: Date
    var favoriteGenresData: Data
    var favoriteActorsData: Data
    var favoriteDirectorsData: Data
    var favoriteKeywordsData: Data
    var rubricInsightsData: Data

    var personalityTitle: String
    var personalityTraitsData: Data
    var personalitySummary: String
    var personalityConfidence: Double

    init(
        updatedAt: Date = Date(),
        favoriteGenres: [NamedMetric] = [],
        favoriteActors: [NamedMetric] = [],
        favoriteDirectors: [NamedMetric] = [],
        favoriteKeywords: [NamedMetric] = [],
        rubricInsights: [String] = [],
        personalityTitle: String = "",
        personalityTraits: [String] = [],
        personalitySummary: String = "",
        personalityConfidence: Double = 0
    ) {
        self.id = UUID()
        self.updatedAt = updatedAt
        self.favoriteGenresData = CodableStore.encode(favoriteGenres)
        self.favoriteActorsData = CodableStore.encode(favoriteActors)
        self.favoriteDirectorsData = CodableStore.encode(favoriteDirectors)
        self.favoriteKeywordsData = CodableStore.encode(favoriteKeywords)
        self.rubricInsightsData = CodableStore.encode(rubricInsights)
        self.personalityTitle = personalityTitle
        self.personalityTraitsData = CodableStore.encode(personalityTraits)
        self.personalitySummary = personalitySummary
        self.personalityConfidence = personalityConfidence
    }

    var favoriteGenres: [NamedMetric] {
        get { CodableStore.decode([NamedMetric].self, from: favoriteGenresData, default: []) }
        set { favoriteGenresData = CodableStore.encode(newValue) }
    }

    var favoriteActors: [NamedMetric] {
        get { CodableStore.decode([NamedMetric].self, from: favoriteActorsData, default: []) }
        set { favoriteActorsData = CodableStore.encode(newValue) }
    }

    var favoriteDirectors: [NamedMetric] {
        get { CodableStore.decode([NamedMetric].self, from: favoriteDirectorsData, default: []) }
        set { favoriteDirectorsData = CodableStore.encode(newValue) }
    }

    var favoriteKeywords: [NamedMetric] {
        get { CodableStore.decode([NamedMetric].self, from: favoriteKeywordsData, default: []) }
        set { favoriteKeywordsData = CodableStore.encode(newValue) }
    }

    var rubricInsights: [String] {
        get { CodableStore.decode([String].self, from: rubricInsightsData, default: []) }
        set { rubricInsightsData = CodableStore.encode(newValue) }
    }

    var personalityTraits: [String] {
        get { CodableStore.decode([String].self, from: personalityTraitsData, default: []) }
        set { personalityTraitsData = CodableStore.encode(newValue) }
    }
}

struct NamedMetric: Codable, Hashable {
    var name: String
    var score: Double
}
