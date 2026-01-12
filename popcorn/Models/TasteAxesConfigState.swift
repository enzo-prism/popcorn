import Foundation
import SwiftData

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
