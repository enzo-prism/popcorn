import XCTest
@testable import Popcorn

final class ImageCacheKeyTests: XCTestCase {
    func testFileNameIsStableForSameURL() {
        let url = URL(string: "https://image.tmdb.org/t/p/w500/abc.jpg")!
        let first = ImageCacheKey.fileName(for: url)
        let second = ImageCacheKey.fileName(for: url)

        XCTAssertEqual(first, second)
        XCTAssertTrue(first.hasSuffix(".img"))
    }

    func testFileNameDiffersForDifferentURLs() {
        let firstURL = URL(string: "https://image.tmdb.org/t/p/w500/abc.jpg")!
        let secondURL = URL(string: "https://image.tmdb.org/t/p/w500/xyz.jpg")!

        let first = ImageCacheKey.fileName(for: firstURL)
        let second = ImageCacheKey.fileName(for: secondURL)

        XCTAssertNotEqual(first, second)
    }
}
