import XCTest
@testable import Popcorn

final class EloRankerTests: XCTestCase {
    func testUpdatedRatingsFromEqualScores() {
        let result = EloRanker.updatedRatings(winnerRating: 1500, loserRating: 1500, kFactor: 32)
        XCTAssertEqual(result.winner, 1516, accuracy: 0.0001)
        XCTAssertEqual(result.loser, 1484, accuracy: 0.0001)
    }
}
