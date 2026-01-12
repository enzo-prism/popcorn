import Foundation
import SwiftData

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

    var outcome: ComparisonOutcome {
        get { ComparisonOutcome(rawValue: outcomeRaw) ?? .skip }
        set { outcomeRaw = newValue.rawValue }
    }
}

enum ComparisonOutcome: String, Codable, CaseIterable {
    case left
    case right
    case skip
    case leftNotSeen
    case rightNotSeen
}
