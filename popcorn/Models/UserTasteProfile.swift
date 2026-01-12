import Foundation
import SwiftData

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

    var mu: [Double] {
        get { [mu0, mu1, mu2, mu3, mu4, mu5] }
        set {
            mu0 = newValue.count > 0 ? newValue[0] : 0
            mu1 = newValue.count > 1 ? newValue[1] : 0
            mu2 = newValue.count > 2 ? newValue[2] : 0
            mu3 = newValue.count > 3 ? newValue[3] : 0
            mu4 = newValue.count > 4 ? newValue[4] : 0
            mu5 = newValue.count > 5 ? newValue[5] : 0
        }
    }

    var sigma: [[Double]] {
        get {
            [
                [sigma00, sigma01, sigma02, sigma03, sigma04, sigma05],
                [sigma10, sigma11, sigma12, sigma13, sigma14, sigma15],
                [sigma20, sigma21, sigma22, sigma23, sigma24, sigma25],
                [sigma30, sigma31, sigma32, sigma33, sigma34, sigma35],
                [sigma40, sigma41, sigma42, sigma43, sigma44, sigma45],
                [sigma50, sigma51, sigma52, sigma53, sigma54, sigma55]
            ]
        }
        set {
            let rows = newValue
            sigma00 = valueAt(rows, row: 0, col: 0)
            sigma01 = valueAt(rows, row: 0, col: 1)
            sigma02 = valueAt(rows, row: 0, col: 2)
            sigma03 = valueAt(rows, row: 0, col: 3)
            sigma04 = valueAt(rows, row: 0, col: 4)
            sigma05 = valueAt(rows, row: 0, col: 5)
            sigma10 = valueAt(rows, row: 1, col: 0)
            sigma11 = valueAt(rows, row: 1, col: 1)
            sigma12 = valueAt(rows, row: 1, col: 2)
            sigma13 = valueAt(rows, row: 1, col: 3)
            sigma14 = valueAt(rows, row: 1, col: 4)
            sigma15 = valueAt(rows, row: 1, col: 5)
            sigma20 = valueAt(rows, row: 2, col: 0)
            sigma21 = valueAt(rows, row: 2, col: 1)
            sigma22 = valueAt(rows, row: 2, col: 2)
            sigma23 = valueAt(rows, row: 2, col: 3)
            sigma24 = valueAt(rows, row: 2, col: 4)
            sigma25 = valueAt(rows, row: 2, col: 5)
            sigma30 = valueAt(rows, row: 3, col: 0)
            sigma31 = valueAt(rows, row: 3, col: 1)
            sigma32 = valueAt(rows, row: 3, col: 2)
            sigma33 = valueAt(rows, row: 3, col: 3)
            sigma34 = valueAt(rows, row: 3, col: 4)
            sigma35 = valueAt(rows, row: 3, col: 5)
            sigma40 = valueAt(rows, row: 4, col: 0)
            sigma41 = valueAt(rows, row: 4, col: 1)
            sigma42 = valueAt(rows, row: 4, col: 2)
            sigma43 = valueAt(rows, row: 4, col: 3)
            sigma44 = valueAt(rows, row: 4, col: 4)
            sigma45 = valueAt(rows, row: 4, col: 5)
            sigma50 = valueAt(rows, row: 5, col: 0)
            sigma51 = valueAt(rows, row: 5, col: 1)
            sigma52 = valueAt(rows, row: 5, col: 2)
            sigma53 = valueAt(rows, row: 5, col: 3)
            sigma54 = valueAt(rows, row: 5, col: 4)
            sigma55 = valueAt(rows, row: 5, col: 5)
        }
    }

    var axisInfo: [Double] {
        get { [axisInfo0, axisInfo1, axisInfo2, axisInfo3, axisInfo4, axisInfo5] }
        set {
            axisInfo0 = newValue.count > 0 ? newValue[0] : 0
            axisInfo1 = newValue.count > 1 ? newValue[1] : 0
            axisInfo2 = newValue.count > 2 ? newValue[2] : 0
            axisInfo3 = newValue.count > 3 ? newValue[3] : 0
            axisInfo4 = newValue.count > 4 ? newValue[4] : 0
            axisInfo5 = newValue.count > 5 ? newValue[5] : 0
        }
    }

    private func valueAt(_ rows: [[Double]], row: Int, col: Int) -> Double {
        guard row < rows.count, col < rows[row].count else { return 0 }
        return rows[row][col]
    }
}
