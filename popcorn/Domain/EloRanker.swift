import Foundation

enum EloRanker {
    static func expectedScore(rating: Double, against opponentRating: Double) -> Double {
        1.0 / (1.0 + pow(10, (opponentRating - rating) / 400.0))
    }

    static func updatedRatings(
        winnerRating: Double,
        loserRating: Double,
        kFactor: Double
    ) -> (winner: Double, loser: Double) {
        let expectedWinner = expectedScore(rating: winnerRating, against: loserRating)
        let expectedLoser = 1.0 - expectedWinner
        let winnerUpdated = winnerRating + kFactor * (1.0 - expectedWinner)
        let loserUpdated = loserRating + kFactor * (0.0 - expectedLoser)
        return (winnerUpdated, loserUpdated)
    }
}
