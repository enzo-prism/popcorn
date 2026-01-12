import XCTest
import SwiftUI
import UIKit
@testable import Popcorn

@MainActor
final class MovieCardViewTests: XCTestCase {
    func testLongTitleRendersWithoutTruncation() {
        let title = "The Extremely Long and Winding Title of a Movie That Refuses to Be Short or Easily Forgotten"
        let movie = Movie(
            tmdbID: 999,
            title: title,
            overview: "",
            releaseDate: nil,
            year: 2024,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 8.1,
            voteCount: 5000,
            genreNames: ["Drama", "Adventure"]
        )

        let width: CGFloat = 180
        let height: CGFloat = width / 0.7
        let view = MovieCardView(movie: movie, isSelected: false, isDimmed: false, action: {})
            .frame(width: width, height: height)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        guard let label = controller.view.findLabel(containingText: title)
            ?? controller.view.findLabel(withIdentifier: "movie-card-title") else {
            XCTFail("Expected to find a title label")
            return
        }

        XCTAssertEqual(label.numberOfLines, 0)
        let targetSize = CGSize(width: label.bounds.width, height: .greatestFiniteMagnitude)
        let requiredHeight = label.sizeThatFits(targetSize).height
        XCTAssertGreaterThanOrEqual(label.bounds.height + 1, requiredHeight)
    }
}

private extension UIView {
    func findLabel(withIdentifier identifier: String) -> UILabel? {
        if let label = self as? UILabel, label.accessibilityIdentifier == identifier {
            return label
        }
        if accessibilityIdentifier == identifier {
            return findFirstLabel()
        }
        for subview in subviews {
            if let match = subview.findLabel(withIdentifier: identifier) {
                return match
            }
        }
        return nil
    }

    func findLabel(containingText text: String) -> UILabel? {
        if let label = self as? UILabel, label.text?.contains(text) == true {
            return label
        }
        for subview in subviews {
            if let match = subview.findLabel(containingText: text) {
                return match
            }
        }
        return nil
    }

    private func findFirstLabel() -> UILabel? {
        if let label = self as? UILabel {
            return label
        }
        for subview in subviews {
            if let match = subview.findFirstLabel() {
                return match
            }
        }
        return nil
    }
}
