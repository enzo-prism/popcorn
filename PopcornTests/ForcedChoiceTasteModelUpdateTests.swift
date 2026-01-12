import XCTest
@testable import Popcorn

final class ForcedChoiceTasteModelUpdateTests: XCTestCase {
    func testUpdateMatchesExpectedValues() {
        var model = ForcedChoiceTasteModel(
            mu: Array(repeating: 0, count: 6),
            sigma: identityMatrix(size: 6, scale: 1.0),
            axisInfo: Array(repeating: 0, count: 6),
            comparisonsCount: 0
        )

        let delta = [1.0, 0, 0, 0, 0, 0]
        model.update(delta: delta, choseLeft: true)

        XCTAssertEqual(model.mu[0], 0.4, accuracy: 0.0001)
        XCTAssertEqual(model.sigma[0][0], 0.8, accuracy: 0.0001)
        XCTAssertEqual(model.comparisonsCount, 1)
    }

    func testUpdateMovesMuInExpectedDirection() {
        var model = ForcedChoiceTasteModel(
            mu: Array(repeating: 0, count: 6),
            sigma: identityMatrix(size: 6, scale: 1.0),
            axisInfo: Array(repeating: 0, count: 6),
            comparisonsCount: 0
        )

        let delta = [1.0, 0, 0, 0, 0, 0]
        model.update(delta: delta, choseLeft: false)

        XCTAssertLessThan(model.mu[0], 0)
    }

    func testSigmaTraceDecreasesForInformativeDelta() {
        var model = ForcedChoiceTasteModel(
            mu: Array(repeating: 0, count: 6),
            sigma: identityMatrix(size: 6, scale: 1.0),
            axisInfo: Array(repeating: 0, count: 6),
            comparisonsCount: 0
        )

        let initialTrace = model.sigma.enumerated().reduce(0.0) { partial, pair in
            partial + pair.element[pair.offset]
        }

        let delta = [1.0, 0.5, -0.2, 0, 0, 0]
        model.update(delta: delta, choseLeft: true)

        let updatedTrace = model.sigma.enumerated().reduce(0.0) { partial, pair in
            partial + pair.element[pair.offset]
        }

        XCTAssertLessThan(updatedTrace, initialTrace)
    }

    private func identityMatrix(size: Int, scale: Double) -> [[Double]] {
        (0..<size).map { row in
            (0..<size).map { col in
                row == col ? scale : 0
            }
        }
    }
}
