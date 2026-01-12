import XCTest
import UIKit
@testable import Popcorn

@MainActor
final class TMDbImageURLBuilderTests: XCTestCase {
    func testPosterURLSelectsBestSize() {
        let configuration = TMDbImageConfiguration(
            secureBaseURL: URL(string: "https://image.tmdb.org/t/p/")!,
            posterSizes: ["w92", "w154", "w342", "w500", "original"],
            fetchedAt: Date()
        )

        let url = TMDbImageURLBuilder.posterURL(
            posterPath: "/abc.jpg",
            targetPointWidth: 180,
            screenScale: 2,
            configuration: configuration
        )

        XCTAssertEqual(url?.absoluteString, "https://image.tmdb.org/t/p/w500/abc.jpg")
    }

    func testPosterURLFallsBackToLargestSize() {
        let configuration = TMDbImageConfiguration(
            secureBaseURL: URL(string: "https://image.tmdb.org/t/p/")!,
            posterSizes: ["w92", "w154", "w342", "w500", "original"],
            fetchedAt: Date()
        )

        let url = TMDbImageURLBuilder.posterURL(
            posterPath: "abc.jpg",
            targetPointWidth: 1200,
            screenScale: 2,
            configuration: configuration
        )

        XCTAssertEqual(url?.absoluteString, "https://image.tmdb.org/t/p/original/abc.jpg")
    }

    func testPosterURLUsesSmallestThatFits() {
        let configuration = TMDbImageConfiguration(
            secureBaseURL: URL(string: "https://image.tmdb.org/t/p/")!,
            posterSizes: ["w92", "w154", "w342", "w500"],
            fetchedAt: Date()
        )

        let url = TMDbImageURLBuilder.posterURL(
            posterPath: "/abc.jpg",
            targetPointWidth: 100,
            screenScale: 2,
            configuration: configuration
        )

        XCTAssertEqual(url?.absoluteString, "https://image.tmdb.org/t/p/w342/abc.jpg")
    }
}
