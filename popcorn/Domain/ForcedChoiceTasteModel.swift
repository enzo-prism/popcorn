import Foundation

struct ForcedChoiceTasteModel {
    var mu: [Double]
    var sigma: [[Double]]
    var axisInfo: [Double]
    var comparisonsCount: Int

    init(mu: [Double], sigma: [[Double]], axisInfo: [Double], comparisonsCount: Int) {
        self.mu = mu
        self.sigma = sigma
        self.axisInfo = axisInfo
        self.comparisonsCount = comparisonsCount
    }

    mutating func update(delta: [Double], choseLeft: Bool) {
        let y = choseLeft ? 1.0 : 0.0
        let p = sigmoid(dot(mu, delta))
        let alpha = p * (1 - p)

        let sigmaDelta = matVec(sigma, delta)
        let deltaSigmaDelta = dot(delta, sigmaDelta)
        let denom = 1 + alpha * deltaSigmaDelta
        let scale = alpha / denom

        let sigmaUpdate = outer(sigmaDelta, sigmaDelta).map { row in
            row.map { $0 * scale }
        }
        sigma = subtractMatrices(sigma, sigmaUpdate)

        let adjustment = (y - p)
        let scaledDelta = delta.map { $0 * adjustment }
        let muUpdate = matVec(sigma, scaledDelta)
        mu = addVectors(mu, muUpdate)

        for index in 0..<axisInfo.count {
            axisInfo[index] += alpha * delta[index] * delta[index]
        }
        comparisonsCount += 1
    }

    func confidence(sigmaScale: Double) -> Double {
        let trace = sigma.enumerated().reduce(0.0) { partial, pair in
            let index = pair.offset
            return partial + pair.element[index]
        }
        let baseline = sigmaScale * Double(TasteAxis.allCases.count)
        if baseline == 0 { return 0 }
        return clamp(1 - (trace / baseline), min: 0, max: 1)
    }

    private func sigmoid(_ value: Double) -> Double {
        1 / (1 + exp(-value))
    }

    private func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
        zip(lhs, rhs).reduce(0.0) { $0 + $1.0 * $1.1 }
    }

    private func matVec(_ matrix: [[Double]], _ vector: [Double]) -> [Double] {
        matrix.map { row in
            zip(row, vector).reduce(0.0) { $0 + $1.0 * $1.1 }
        }
    }

    private func outer(_ vector: [Double], _ vector2: [Double]) -> [[Double]] {
        vector.map { v in
            vector2.map { v * $0 }
        }
    }

    private func addVectors(_ lhs: [Double], _ rhs: [Double]) -> [Double] {
        zip(lhs, rhs).map(+)
    }

    private func subtractMatrices(_ lhs: [[Double]], _ rhs: [[Double]]) -> [[Double]] {
        zip(lhs, rhs).map { rowPair in
            zip(rowPair.0, rowPair.1).map { $0 - $1 }
        }
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
