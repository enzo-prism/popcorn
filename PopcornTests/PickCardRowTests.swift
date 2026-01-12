import XCTest
import SwiftUI
import UIKit
@testable import Popcorn

@MainActor
final class PickCardRowTests: XCTestCase {
    func testCardsStayBalancedWithLongTitles() {
        let longTitle = "The Lord of the Rings: The Return of the King Extended Collector's Edition"
        let leftMovie = Movie(
            tmdbID: 10,
            title: "John Wick",
            overview: "",
            releaseDate: nil,
            year: 2014,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 7.4,
            voteCount: 1000,
            genreNames: ["Action"]
        )
        let rightMovie = Movie(
            tmdbID: 20,
            title: longTitle,
            overview: "",
            releaseDate: nil,
            year: 2003,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 9.0,
            voteCount: 2000,
            genreNames: ["Adventure", "Fantasy"]
        )

        let containerWidth: CGFloat = 360
        let containerHeight: CGFloat = 700
        let expectation = expectation(description: "layout")
        var captured: PickCardLayout?

        let view = PickCardRow(
            left: leftMovie,
            right: rightMovie,
            selectedSide: nil,
            isProcessing: false,
            onPickLeft: {},
            onPickRight: {},
            onNotSeenLeft: {},
            onNotSeenRight: {},
            onLayout: { layout in
                guard captured == nil else { return }
                captured = layout
                expectation.fulfill()
            }
        )
        .frame(width: containerWidth, height: containerHeight)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: containerWidth, height: containerHeight))
        let controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        wait(for: [expectation], timeout: 1.0)

        guard let captured else {
            XCTFail("Expected layout capture")
            return
        }

        let expectedWidth = (containerWidth - 12) / 2
        XCTAssertEqual(captured.leftWidth, captured.rightWidth, accuracy: 1.0)
        XCTAssertEqual(captured.leftWidth, expectedWidth, accuracy: 1.0)

        guard let rightTitleLabel = controller.view.findLabel(containingText: longTitle) else {
            XCTFail("Expected to find title label")
            return
        }
        XCTAssertLessThanOrEqual(rightTitleLabel.bounds.width, captured.rightWidth + 1)
    }

    func testPosterTitleAndNotSeenStackVertically() {
        let longTitle = "The Lord of the Rings: The Return of the King Extended Collector's Edition"
        let leftMovie = Movie(
            tmdbID: 10,
            title: "John Wick",
            overview: "",
            releaseDate: nil,
            year: 2014,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 7.4,
            voteCount: 1000,
            genreNames: ["Action"]
        )
        let rightMovie = Movie(
            tmdbID: 20,
            title: longTitle,
            overview: "",
            releaseDate: nil,
            year: 2003,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 9.0,
            voteCount: 2000,
            genreNames: ["Adventure", "Fantasy"]
        )

        let containerWidth: CGFloat = 360
        let containerHeight: CGFloat = 760
        let expectation = expectation(description: "layout")

        let view = PickCardRow(
            left: leftMovie,
            right: rightMovie,
            selectedSide: nil,
            isProcessing: false,
            onPickLeft: {},
            onPickRight: {},
            onNotSeenLeft: {},
            onNotSeenRight: {},
            onLayout: { _ in
                expectation.fulfill()
            }
        )
        .frame(width: containerWidth, height: containerHeight)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: containerWidth, height: containerHeight))
        let controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        wait(for: [expectation], timeout: 1.0)

        guard let posterView = controller.view.findView(withIdentifier: "pick-card-right-poster"),
              let titleLabel = controller.view.findLabel(withIdentifier: "pick-card-right-title")
                ?? controller.view.findLabel(containingText: longTitle),
              let notSeenView = controller.view.findView(withIdentifier: "pick-card-right-not-seen") else {
            XCTFail("Expected to find poster, title, and not-seen views")
            return
        }

        let rootView = controller.view!
        let posterFrame = posterView.convert(posterView.bounds, to: rootView)
        let titleFrame = titleLabel.convert(titleLabel.bounds, to: rootView)
        let notSeenFrame = notSeenView.convert(notSeenView.bounds, to: rootView)

        XCTAssertGreaterThan(titleFrame.minY, posterFrame.maxY - 1)
        XCTAssertGreaterThan(notSeenFrame.minY, titleFrame.maxY - 1)
    }
}

private extension UIView {
    func findView(withIdentifier identifier: String) -> UIView? {
        if accessibilityIdentifier == identifier {
            return self
        }
        for subview in subviews {
            if let match = subview.findView(withIdentifier: identifier) {
                return match
            }
        }
        return nil
    }

    func findLabel(withIdentifier identifier: String) -> UILabel? {
        if let label = self as? UILabel, label.accessibilityIdentifier == identifier {
            return label
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

}
