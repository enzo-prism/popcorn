import Foundation
import SwiftData

enum PopcornSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            Movie.self,
            ComparisonEvent.self,
            InsightsCache.self,
            MovieTasteVector.self,
            TasteAxesConfigState.self,
            UserTasteProfile.self
        ]
    }

    @Model
    final class Movie {
        @Attribute(.unique) var tmdbID: Int
        var title: String
        var originalTitle: String?
        var overview: String
        var releaseDate: Date?
        var year: Int
        var posterPath: String?
        var backdropPath: String?
        var voteAverage: Double
        var voteCount: Int
        var genreNamesData: Data

        var eloRating: Double
        var comparisonsCount: Int
        var lastComparedAt: Date?
        var seenStateRaw: String
        var lastMarkedNotSeenAt: Date?

        var rubricRatingsData: Data?
        var detailsData: Data?
        var createdAt: Date
        var updatedAt: Date

        init(
            tmdbID: Int,
            title: String,
            originalTitle: String? = nil,
            overview: String,
            releaseDate: Date? = nil,
            year: Int,
            posterPath: String? = nil,
            backdropPath: String? = nil,
            voteAverage: Double,
            voteCount: Int,
            genreNames: [String]
        ) {
            self.tmdbID = tmdbID
            self.title = title
            self.originalTitle = originalTitle
            self.overview = overview
            self.releaseDate = releaseDate
            self.year = year
            self.posterPath = posterPath
            self.backdropPath = backdropPath
            self.voteAverage = voteAverage
            self.voteCount = voteCount
            self.genreNamesData = CodableStore.encode(genreNames)

            self.eloRating = 1500
            self.comparisonsCount = 0
            self.lastComparedAt = nil
            self.seenStateRaw = SeenState.unknown.rawValue
            self.lastMarkedNotSeenAt = nil

            self.rubricRatingsData = nil
            self.detailsData = nil
            self.createdAt = Date()
            self.updatedAt = Date()
        }
    }

    @Model
    final class ComparisonEvent {
        var id: UUID
        var createdAt: Date
        var leftMovieID: Int
        var rightMovieID: Int
        var selectedMovieID: Int?
        var outcomeRaw: String

        init(
            leftMovieID: Int,
            rightMovieID: Int,
            selectedMovieID: Int?,
            outcome: ComparisonOutcome,
            createdAt: Date = Date()
        ) {
            self.id = UUID()
            self.createdAt = createdAt
            self.leftMovieID = leftMovieID
            self.rightMovieID = rightMovieID
            self.selectedMovieID = selectedMovieID
            self.outcomeRaw = outcome.rawValue
        }
    }

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
    }

    @Model
    final class MovieTasteVector {
        @Attribute(.unique) var movieId: Int
        var version: Int
        var v0: Double
        var v1: Double
        var v2: Double
        var v3: Double
        var v4: Double
        var v5: Double
        var computedAt: Date

        init(movieId: Int, version: Int, values: [Double], computedAt: Date = Date()) {
            self.movieId = movieId
            self.version = version
            self.v0 = values.count > 0 ? values[0] : 0
            self.v1 = values.count > 1 ? values[1] : 0
            self.v2 = values.count > 2 ? values[2] : 0
            self.v3 = values.count > 3 ? values[3] : 0
            self.v4 = values.count > 4 ? values[4] : 0
            self.v5 = values.count > 5 ? values[5] : 0
            self.computedAt = computedAt
        }
    }

    @Model
    final class TasteAxesConfigState {
        var id: UUID
        var version: Int
        var lastAppliedAt: Date

        init(version: Int, lastAppliedAt: Date = Date()) {
            self.id = UUID()
            self.version = version
            self.lastAppliedAt = lastAppliedAt
        }
    }

    @Model
    final class UserTasteProfile {
        var id: UUID
        var modelVersion: Int
        var comparisonsCount: Int
        var lastUpdatedAt: Date

        var mu0: Double
        var mu1: Double
        var mu2: Double
        var mu3: Double
        var mu4: Double
        var mu5: Double

        var sigma00: Double
        var sigma01: Double
        var sigma02: Double
        var sigma03: Double
        var sigma04: Double
        var sigma05: Double
        var sigma10: Double
        var sigma11: Double
        var sigma12: Double
        var sigma13: Double
        var sigma14: Double
        var sigma15: Double
        var sigma20: Double
        var sigma21: Double
        var sigma22: Double
        var sigma23: Double
        var sigma24: Double
        var sigma25: Double
        var sigma30: Double
        var sigma31: Double
        var sigma32: Double
        var sigma33: Double
        var sigma34: Double
        var sigma35: Double
        var sigma40: Double
        var sigma41: Double
        var sigma42: Double
        var sigma43: Double
        var sigma44: Double
        var sigma45: Double
        var sigma50: Double
        var sigma51: Double
        var sigma52: Double
        var sigma53: Double
        var sigma54: Double
        var sigma55: Double

        var axisInfo0: Double
        var axisInfo1: Double
        var axisInfo2: Double
        var axisInfo3: Double
        var axisInfo4: Double
        var axisInfo5: Double

        init(modelVersion: Int = 1, comparisonsCount: Int = 0, lastUpdatedAt: Date = Date(), sigmaScale: Double = 1.0) {
            self.id = UUID()
            self.modelVersion = modelVersion
            self.comparisonsCount = comparisonsCount
            self.lastUpdatedAt = lastUpdatedAt

            self.mu0 = 0
            self.mu1 = 0
            self.mu2 = 0
            self.mu3 = 0
            self.mu4 = 0
            self.mu5 = 0

            self.sigma00 = sigmaScale
            self.sigma01 = 0
            self.sigma02 = 0
            self.sigma03 = 0
            self.sigma04 = 0
            self.sigma05 = 0
            self.sigma10 = 0
            self.sigma11 = sigmaScale
            self.sigma12 = 0
            self.sigma13 = 0
            self.sigma14 = 0
            self.sigma15 = 0
            self.sigma20 = 0
            self.sigma21 = 0
            self.sigma22 = sigmaScale
            self.sigma23 = 0
            self.sigma24 = 0
            self.sigma25 = 0
            self.sigma30 = 0
            self.sigma31 = 0
            self.sigma32 = 0
            self.sigma33 = sigmaScale
            self.sigma34 = 0
            self.sigma35 = 0
            self.sigma40 = 0
            self.sigma41 = 0
            self.sigma42 = 0
            self.sigma43 = 0
            self.sigma44 = sigmaScale
            self.sigma45 = 0
            self.sigma50 = 0
            self.sigma51 = 0
            self.sigma52 = 0
            self.sigma53 = 0
            self.sigma54 = 0
            self.sigma55 = sigmaScale

            self.axisInfo0 = 0
            self.axisInfo1 = 0
            self.axisInfo2 = 0
            self.axisInfo3 = 0
            self.axisInfo4 = 0
            self.axisInfo5 = 0
        }
    }
}

enum PopcornSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            Movie.self,
            ComparisonEvent.self,
            InsightsCache.self,
            MovieTasteVector.self,
            TasteAxesConfigState.self,
            UserTasteProfile.self
        ]
    }
}

enum PopcornMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PopcornSchemaV1.self, PopcornSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: PopcornSchemaV1.self, toVersion: PopcornSchemaV2.self)]
    }
}
