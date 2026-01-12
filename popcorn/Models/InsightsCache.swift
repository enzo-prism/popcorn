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
    var favoriteGenreEvidenceData: Data?
    var favoriteActorEvidenceData: Data?
    var favoriteDirectorEvidenceData: Data?
    var favoriteKeywordEvidenceData: Data?

    var personalityTitle: String
    var personalityTraitsData: Data
    var personalitySummary: String
    var personalityConfidence: Double
    var sourceMovieCount: Int?
    var sourcePickCount: Int?
    var detailsCoverage: Double?

    init(
        updatedAt: Date = Date(),
        favoriteGenres: [NamedMetric] = [],
        favoriteActors: [NamedMetric] = [],
        favoriteDirectors: [NamedMetric] = [],
        favoriteKeywords: [NamedMetric] = [],
        rubricInsights: [String] = [],
        favoriteGenreEvidence: [InsightEvidence] = [],
        favoriteActorEvidence: [InsightEvidence] = [],
        favoriteDirectorEvidence: [InsightEvidence] = [],
        favoriteKeywordEvidence: [InsightEvidence] = [],
        personalityTitle: String = "",
        personalityTraits: [String] = [],
        personalitySummary: String = "",
        personalityConfidence: Double = 0,
        sourceMovieCount: Int = 0,
        sourcePickCount: Int = 0,
        detailsCoverage: Double = 0
    ) {
        self.id = UUID()
        self.updatedAt = updatedAt
        self.favoriteGenresData = CodableStore.encode(favoriteGenres)
        self.favoriteActorsData = CodableStore.encode(favoriteActors)
        self.favoriteDirectorsData = CodableStore.encode(favoriteDirectors)
        self.favoriteKeywordsData = CodableStore.encode(favoriteKeywords)
        self.rubricInsightsData = CodableStore.encode(rubricInsights)
        self.favoriteGenreEvidenceData = CodableStore.encode(favoriteGenreEvidence)
        self.favoriteActorEvidenceData = CodableStore.encode(favoriteActorEvidence)
        self.favoriteDirectorEvidenceData = CodableStore.encode(favoriteDirectorEvidence)
        self.favoriteKeywordEvidenceData = CodableStore.encode(favoriteKeywordEvidence)
        self.personalityTitle = personalityTitle
        self.personalityTraitsData = CodableStore.encode(personalityTraits)
        self.personalitySummary = personalitySummary
        self.personalityConfidence = personalityConfidence
        self.sourceMovieCount = sourceMovieCount
        self.sourcePickCount = sourcePickCount
        self.detailsCoverage = detailsCoverage
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

    var favoriteGenreEvidence: [InsightEvidence] {
        get { CodableStore.decodeOptional([InsightEvidence].self, from: favoriteGenreEvidenceData) ?? [] }
        set { favoriteGenreEvidenceData = CodableStore.encode(newValue) }
    }

    var favoriteActorEvidence: [InsightEvidence] {
        get { CodableStore.decodeOptional([InsightEvidence].self, from: favoriteActorEvidenceData) ?? [] }
        set { favoriteActorEvidenceData = CodableStore.encode(newValue) }
    }

    var favoriteDirectorEvidence: [InsightEvidence] {
        get { CodableStore.decodeOptional([InsightEvidence].self, from: favoriteDirectorEvidenceData) ?? [] }
        set { favoriteDirectorEvidenceData = CodableStore.encode(newValue) }
    }

    var favoriteKeywordEvidence: [InsightEvidence] {
        get { CodableStore.decodeOptional([InsightEvidence].self, from: favoriteKeywordEvidenceData) ?? [] }
        set { favoriteKeywordEvidenceData = CodableStore.encode(newValue) }
    }

    var personalityTraits: [String] {
        get { CodableStore.decode([String].self, from: personalityTraitsData, default: []) }
        set { personalityTraitsData = CodableStore.encode(newValue) }
    }
}

struct NamedMetric: Codable, Hashable {
    var name: String
    var score: Double
    var support: Double

    init(name: String, score: Double, support: Double = 0) {
        self.name = name
        self.score = score
        self.support = support
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case score
        case support
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        score = try container.decode(Double.self, forKey: .score)
        support = try container.decodeIfPresent(Double.self, forKey: .support) ?? 0
    }
}

struct InsightEvidence: Codable, Hashable {
    var name: String
    var movieIDs: [Int]
}
