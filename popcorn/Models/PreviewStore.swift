import SwiftData

enum PreviewStore {
    static let container: ModelContainer = {
        let schema = Schema([
            Movie.self,
            ComparisonEvent.self,
            InsightsCache.self,
            MovieTasteVector.self,
            TasteAxesConfigState.self,
            UserTasteProfile.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
}
