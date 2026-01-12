import XCTest
import SwiftData
@testable import Popcorn

final class SwiftDataMigrationTests: XCTestCase {
    func testInsightsCacheMigrationAddsDefaults() throws {
        let storeURL = temporaryStoreURL()
        defer {
            try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent())
        }

        let v1Schema = Schema(versionedSchema: PopcornSchemaV1.self)
        let v1Config = ModelConfiguration("PopcornV1", schema: v1Schema, url: storeURL)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Config])
        let v1Context = ModelContext(v1Container)

        let v1Cache = PopcornSchemaV1.InsightsCache(
            favoriteGenres: [NamedMetric(name: "Drama", score: 1)],
            favoriteActors: [],
            favoriteDirectors: [],
            favoriteKeywords: [],
            rubricInsights: ["You love Story"],
            personalityTitle: "The Curator",
            personalityTraits: ["curiosity-forward"],
            personalitySummary: "Summary",
            personalityConfidence: 0.3
        )
        v1Context.insert(v1Cache)
        try v1Context.save()

        let v2Schema = Schema(versionedSchema: PopcornSchemaV2.self)
        let v2Config = ModelConfiguration("PopcornV2", schema: v2Schema, url: storeURL)
        let v2Container = try ModelContainer(
            for: v2Schema,
            migrationPlan: PopcornMigrationPlan.self,
            configurations: [v2Config]
        )
        let v2Context = ModelContext(v2Container)
        let caches = try v2Context.fetch(FetchDescriptor<InsightsCache>())

        XCTAssertEqual(caches.count, 1)
        let migrated = caches[0]
        XCTAssertEqual(migrated.sourceMovieCount ?? 0, 0)
        XCTAssertEqual(migrated.sourcePickCount ?? 0, 0)
        XCTAssertEqual(migrated.detailsCoverage ?? 0, 0)
        XCTAssertEqual(migrated.favoriteGenres.first?.name, "Drama")
    }

    private func temporaryStoreURL() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("Popcorn.store")
    }
}
