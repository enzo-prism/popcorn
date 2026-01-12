import XCTest
@testable import Popcorn

final class InsightsEvidenceTests: XCTestCase {
    func testBuildEvidenceSortsAndLimits() {
        let favorites = [
            NamedMetric(name: "Drama", score: 1.8, support: 1),
            NamedMetric(name: "Action", score: 1.2, support: 1)
        ]
        let contributions: [String: [Int: Double]] = [
            "Drama": [1: 0.4, 2: 0.9, 3: 0.2],
            "Action": [4: 0.5, 5: 0.1]
        ]

        let evidence = InsightsEngine.buildEvidence(
            favorites: favorites,
            contributions: contributions,
            movieLimit: 2
        )

        XCTAssertEqual(evidence.count, 2)
        XCTAssertEqual(evidence[0].name, "Drama")
        XCTAssertEqual(evidence[0].movieIDs, [2, 1])
        XCTAssertEqual(evidence[1].movieIDs, [4, 5])
    }
}
