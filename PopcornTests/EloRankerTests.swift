import XCTest
import UIKit
@testable import Popcorn

final class EloRankerTests: XCTestCase {
    func testUpdatedRatingsFromEqualScores() {
        let result = EloRanker.updatedRatings(winnerRating: 1500, loserRating: 1500, kFactor: 32)
        XCTAssertEqual(result.winner, 1516, accuracy: 0.0001)
        XCTAssertEqual(result.loser, 1484, accuracy: 0.0001)
    }
}

final class DesignContrastTests: XCTestCase {
    private let minimumPrimaryContrast: Double = 4.5
    private let minimumSecondaryContrast: Double = 3.0

    func testPrimaryContrastOnPickBackground() {
        assertContrastOnGradient(
            name: "Pick",
            start: color(0.97, 0.95, 0.92),
            end: color(0.90, 0.94, 0.98),
            foreground: resolved(.label),
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastOnPickBackground() {
        assertContrastOnGradient(
            name: "Pick",
            start: color(0.97, 0.95, 0.92),
            end: color(0.90, 0.94, 0.98),
            foreground: resolved(.secondaryLabel),
            minimum: minimumSecondaryContrast
        )
    }

    func testPrimaryContrastOnDashboardBackground() {
        assertContrastOnGradient(
            name: "Dashboard",
            start: color(0.95, 0.96, 0.98),
            end: color(0.92, 0.94, 0.90),
            foreground: resolved(.label),
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastOnDashboardBackground() {
        assertContrastOnGradient(
            name: "Dashboard",
            start: color(0.95, 0.96, 0.98),
            end: color(0.92, 0.94, 0.90),
            foreground: resolved(.secondaryLabel),
            minimum: minimumSecondaryContrast
        )
    }

    func testPrimaryContrastOnSettingsBackground() {
        assertContrastOnGradient(
            name: "Settings",
            start: color(0.95, 0.97, 0.98),
            end: color(0.93, 0.94, 0.90),
            foreground: resolved(.label),
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastOnSettingsBackground() {
        assertContrastOnGradient(
            name: "Settings",
            start: color(0.95, 0.97, 0.98),
            end: color(0.93, 0.94, 0.90),
            foreground: resolved(.secondaryLabel),
            minimum: minimumSecondaryContrast
        )
    }

    func testPrimaryContrastOnRefreshMomentBackground() {
        assertContrastOnGradient(
            name: "RefreshMoment",
            start: color(0.97, 0.96, 0.94),
            end: color(0.92, 0.94, 0.98),
            foreground: resolved(.label),
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastOnRefreshMomentBackground() {
        assertContrastOnGradient(
            name: "RefreshMoment",
            start: color(0.97, 0.96, 0.94),
            end: color(0.92, 0.94, 0.98),
            foreground: resolved(.secondaryLabel),
            minimum: minimumSecondaryContrast
        )
    }

    func testPrimaryContrastOnMovieDetailBackground() {
        assertContrastOnGradient(
            name: "MovieDetail",
            start: color(0.98, 0.96, 0.94),
            end: color(0.92, 0.94, 0.98),
            foreground: resolved(.label),
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastOnMovieDetailBackground() {
        assertContrastOnGradient(
            name: "MovieDetail",
            start: color(0.98, 0.96, 0.94),
            end: color(0.92, 0.94, 0.98),
            foreground: resolved(.secondaryLabel),
            minimum: minimumSecondaryContrast
        )
    }

    func testPrimaryContrastOnPersonalityInfoBackground() {
        assertContrastOnGradient(
            name: "PersonalityInfo",
            start: color(0.96, 0.95, 0.93),
            end: color(0.92, 0.95, 0.99),
            foreground: resolved(.label),
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastOnPersonalityInfoBackground() {
        assertContrastOnGradient(
            name: "PersonalityInfo",
            start: color(0.96, 0.95, 0.93),
            end: color(0.92, 0.95, 0.99),
            foreground: resolved(.secondaryLabel),
            minimum: minimumSecondaryContrast
        )
    }

    func testMovieCardScrimContrast() {
        let base = UIColor.white
        let scrim = blend(foreground: .black, background: base, alpha: 0.65)

        assertContrast(
            name: "MovieCard title",
            foreground: UIColor.white,
            background: scrim,
            minimum: minimumPrimaryContrast
        )
        assertContrast(
            name: "MovieCard subtitle",
            foreground: UIColor(white: 0.85, alpha: 1),
            background: scrim,
            minimum: minimumSecondaryContrast
        )
    }

    func testTMDbLogoPlaceholderContrast() {
        let lightStop = color(0.0, 0.45, 0.5)
        let darkStop = color(0.0, 0.25, 0.35)

        assertContrast(
            name: "TMDb logo light stop",
            foreground: UIColor.white,
            background: lightStop,
            minimum: minimumPrimaryContrast
        )
        assertContrast(
            name: "TMDb logo dark stop",
            foreground: UIColor.white,
            background: darkStop,
            minimum: minimumPrimaryContrast
        )
    }

    func testReducedTransparencyGlassSurfaceContrast() {
        let baseBackground = color(0.95, 0.96, 0.98)
        let material = blend(
            foreground: resolved(.systemBackground),
            background: baseBackground,
            alpha: 0.9
        )

        assertContrast(
            name: "Glass surface primary",
            foreground: resolved(.label),
            background: material,
            minimum: minimumPrimaryContrast
        )
        assertContrast(
            name: "Glass surface secondary",
            foreground: resolved(.secondaryLabel),
            background: material,
            minimum: minimumSecondaryContrast
        )
    }

    private func assertContrastOnGradient(
        name: String,
        start: UIColor,
        end: UIColor,
        foreground: UIColor,
        minimum: Double
    ) {
        let stops = [start, midpoint(start, end), end]
        for (index, stop) in stops.enumerated() {
            let ratio = contrastRatio(foreground: foreground, background: stop)
            XCTAssertGreaterThanOrEqual(
                ratio,
                minimum,
                "\(name) stop \(index) contrast \(ratio) is below \(minimum)."
            )
        }
    }

    private func assertContrast(name: String, foreground: UIColor, background: UIColor, minimum: Double) {
        let ratio = contrastRatio(foreground: foreground, background: background)
        XCTAssertGreaterThanOrEqual(ratio, minimum, "\(name) contrast \(ratio) is below \(minimum).")
    }

    private func contrastRatio(foreground: UIColor, background: UIColor) -> Double {
        let l1 = luminance(for: foreground)
        let l2 = luminance(for: background)
        let light = max(l1, l2)
        let dark = min(l1, l2)
        return (light + 0.05) / (dark + 0.05)
    }

    private func luminance(for color: UIColor) -> Double {
        let resolvedColor = resolved(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let r = linearize(Double(red))
        let g = linearize(Double(green))
        let b = linearize(Double(blue))
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private func linearize(_ component: Double) -> Double {
        if component <= 0.04045 {
            return component / 12.92
        }
        return pow((component + 0.055) / 1.055, 2.4)
    }

    private func midpoint(_ first: UIColor, _ second: UIColor) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        first.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)

        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        second.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(
            red: (r1 + r2) / 2,
            green: (g1 + g2) / 2,
            blue: (b1 + b2) / 2,
            alpha: (a1 + a2) / 2
        )
    }

    private func color(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private func blend(foreground: UIColor, background: UIColor, alpha: Double) -> UIColor {
        var fr: CGFloat = 0
        var fg: CGFloat = 0
        var fb: CGFloat = 0
        var fa: CGFloat = 0
        foreground.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)

        var br: CGFloat = 0
        var bg: CGFloat = 0
        var bb: CGFloat = 0
        var ba: CGFloat = 0
        background.getRed(&br, green: &bg, blue: &bb, alpha: &ba)

        let a = CGFloat(alpha)
        return UIColor(
            red: fr * a + br * (1 - a),
            green: fg * a + bg * (1 - a),
            blue: fb * a + bb * (1 - a),
            alpha: 1
        )
    }

    private func resolved(_ color: UIColor) -> UIColor {
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }
}
