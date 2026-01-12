import Foundation
import SwiftData

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

    var values: [Double] {
        get { [v0, v1, v2, v3, v4, v5] }
        set {
            v0 = newValue.count > 0 ? newValue[0] : 0
            v1 = newValue.count > 1 ? newValue[1] : 0
            v2 = newValue.count > 2 ? newValue[2] : 0
            v3 = newValue.count > 3 ? newValue[3] : 0
            v4 = newValue.count > 4 ? newValue[4] : 0
            v5 = newValue.count > 5 ? newValue[5] : 0
        }
    }
}
