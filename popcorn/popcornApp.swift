import SwiftUI
import SwiftData

@main
struct PopcornApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema(versionedSchema: PopcornSchemaV2.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: PopcornMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            if let recovered = PopcornApp.recoverContainer(schema: schema, configuration: configuration, error: error) {
                container = recovered
            } else {
                fatalError("Failed to initialize SwiftData: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }

    private static func recoverContainer(
        schema: Schema,
        configuration: ModelConfiguration,
        error: Error
    ) -> ModelContainer? {
        print("SwiftData init failed: \(error). Attempting legacy store.")
        if let legacy = legacyContainer(configuration: configuration) {
            print("SwiftData legacy store loaded without migration.")
            return legacy
        }
        print("SwiftData legacy load failed. Resetting store.")
        removeStoreFiles(at: configuration.url)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: PopcornMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            print("SwiftData reset failed: \(error).")
            return nil
        }
    }

    private static func legacyContainer(configuration: ModelConfiguration) -> ModelContainer? {
        let legacySchema = Schema([
            Movie.self,
            ComparisonEvent.self,
            InsightsCache.self,
            MovieTasteVector.self,
            TasteAxesConfigState.self,
            UserTasteProfile.self
        ])
        let legacyConfiguration = ModelConfiguration("Legacy", schema: legacySchema, url: configuration.url)
        do {
            return try ModelContainer(for: legacySchema, configurations: [legacyConfiguration])
        } catch {
            print("SwiftData legacy init failed: \(error).")
            return nil
        }
    }

    private static func removeStoreFiles(at url: URL) {
        let fileManager = FileManager.default
        let directory = url.deletingLastPathComponent()
        let prefix = url.lastPathComponent
        if let items = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for item in items where item.lastPathComponent.hasPrefix(prefix) {
                try? fileManager.removeItem(at: item)
            }
        } else {
            try? fileManager.removeItem(at: url)
        }
    }
}
