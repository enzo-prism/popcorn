import Foundation
import SwiftData

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

    var genreNames: [String] {
        get { CodableStore.decode([String].self, from: genreNamesData, default: []) }
        set { genreNamesData = CodableStore.encode(newValue) }
    }

    var seenState: SeenState {
        get { SeenState(rawValue: seenStateRaw) ?? .unknown }
        set { seenStateRaw = newValue.rawValue }
    }

    var rubricRatings: RubricRatings? {
        get { CodableStore.decodeOptional(RubricRatings.self, from: rubricRatingsData) }
        set { rubricRatingsData = newValue.map { CodableStore.encode($0) } }
    }

    var details: MovieDetails? {
        get { CodableStore.decodeOptional(MovieDetails.self, from: detailsData) }
        set { detailsData = newValue.map { CodableStore.encode($0) } }
    }
}

enum SeenState: String, Codable, CaseIterable {
    case unknown
    case seen
    case notSeen
}

struct RubricRatings: Codable, Hashable {
    var story: Double
    var action: Double
    var visuals: Double
    var dialogue: Double
    var acting: Double
    var sound: Double

    static let empty = RubricRatings(story: 0, action: 0, visuals: 0, dialogue: 0, acting: 0, sound: 0)
}

struct MovieDetails: Codable, Hashable {
    var cast: [CastMember]
    var crew: [CrewMember]
    var keywords: [String]
    var lastUpdatedAt: Date
}

struct CastMember: Codable, Hashable {
    var id: Int
    var name: String
    var role: String
    var order: Int
}

struct CrewMember: Codable, Hashable {
    var id: Int
    var name: String
    var job: String
}

extension Movie: Identifiable {
    var id: Int { tmdbID }
}
