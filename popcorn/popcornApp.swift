import SwiftUI
import SwiftData

@main
struct PopcornApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema([
            Movie.self,
            ComparisonEvent.self,
            InsightsCache.self,
            MovieTasteVector.self,
            TasteAxesConfigState.self,
            UserTasteProfile.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
