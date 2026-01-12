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
    private let glassMaterialAlpha: Double = 0.28
    private let reducedTransparencyAlpha: Double = 0.9

    private struct GradientSpec {
        let name: String
        let lightStart: UIColor
        let lightEnd: UIColor
        let darkStart: UIColor
        let darkEnd: UIColor

        func startEnd(for style: UIUserInterfaceStyle) -> (UIColor, UIColor) {
            if style == .dark {
                return (darkStart, darkEnd)
            }
            return (lightStart, lightEnd)
        }
    }

    private var gradientSpecs: [GradientSpec] {
        [
            GradientSpec(
                name: "Pick",
                lightStart: color(0.97, 0.95, 0.92),
                lightEnd: color(0.90, 0.94, 0.98),
                darkStart: color(0.09, 0.10, 0.12),
                darkEnd: color(0.05, 0.08, 0.12)
            ),
            GradientSpec(
                name: "Dashboard",
                lightStart: color(0.95, 0.96, 0.98),
                lightEnd: color(0.92, 0.94, 0.90),
                darkStart: color(0.10, 0.11, 0.14),
                darkEnd: color(0.07, 0.09, 0.11)
            ),
            GradientSpec(
                name: "Settings",
                lightStart: color(0.95, 0.97, 0.98),
                lightEnd: color(0.93, 0.94, 0.90),
                darkStart: color(0.09, 0.10, 0.12),
                darkEnd: color(0.06, 0.08, 0.10)
            ),
            GradientSpec(
                name: "RefreshMoment",
                lightStart: color(0.97, 0.96, 0.94),
                lightEnd: color(0.92, 0.94, 0.98),
                darkStart: color(0.10, 0.09, 0.12),
                darkEnd: color(0.06, 0.08, 0.12)
            ),
            GradientSpec(
                name: "MovieDetail",
                lightStart: color(0.98, 0.96, 0.94),
                lightEnd: color(0.92, 0.94, 0.98),
                darkStart: color(0.10, 0.09, 0.12),
                darkEnd: color(0.06, 0.08, 0.12)
            ),
            GradientSpec(
                name: "PersonalityInfo",
                lightStart: color(0.96, 0.95, 0.93),
                lightEnd: color(0.92, 0.95, 0.99),
                darkStart: color(0.10, 0.09, 0.12),
                darkEnd: color(0.06, 0.08, 0.12)
            )
        ]
    }

    func testPrimaryContrastAcrossLightModeBackgrounds() {
        assertContrastAcrossBackgrounds(
            style: .light,
            contrast: .normal,
            foreground: .label,
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastAcrossLightModeBackgrounds() {
        assertContrastAcrossBackgrounds(
            style: .light,
            contrast: .normal,
            foreground: .secondaryLabel,
            minimum: minimumSecondaryContrast
        )
    }

    func testPrimaryContrastAcrossDarkModeBackgrounds() {
        assertContrastAcrossBackgrounds(
            style: .dark,
            contrast: .normal,
            foreground: .label,
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastAcrossDarkModeBackgrounds() {
        assertContrastAcrossBackgrounds(
            style: .dark,
            contrast: .normal,
            foreground: .secondaryLabel,
            minimum: minimumSecondaryContrast
        )
    }

    func testPrimaryContrastAcrossLightModeHighContrastBackgrounds() {
        assertContrastAcrossBackgrounds(
            style: .light,
            contrast: .high,
            foreground: .label,
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastAcrossLightModeHighContrastBackgrounds() {
        assertContrastAcrossBackgrounds(
            style: .light,
            contrast: .high,
            foreground: .secondaryLabel,
            minimum: minimumSecondaryContrast
        )
    }

    func testPrimaryContrastAcrossDarkModeHighContrastBackgrounds() {
        assertContrastAcrossBackgrounds(
            style: .dark,
            contrast: .high,
            foreground: .label,
            minimum: minimumPrimaryContrast
        )
    }

    func testSecondaryContrastAcrossDarkModeHighContrastBackgrounds() {
        assertContrastAcrossBackgrounds(
            style: .dark,
            contrast: .high,
            foreground: .secondaryLabel,
            minimum: minimumSecondaryContrast
        )
    }

    func testGlassSurfaceContrastLightMode() {
        assertGlassSurfaceContrast(
            style: .light,
            contrast: .normal,
            alpha: glassMaterialAlpha
        )
    }

    func testGlassSurfaceContrastDarkMode() {
        assertGlassSurfaceContrast(
            style: .dark,
            contrast: .normal,
            alpha: glassMaterialAlpha
        )
    }

    func testGlassSurfaceContrastLightModeHighContrast() {
        assertGlassSurfaceContrast(
            style: .light,
            contrast: .high,
            alpha: glassMaterialAlpha
        )
    }

    func testGlassSurfaceContrastDarkModeHighContrast() {
        assertGlassSurfaceContrast(
            style: .dark,
            contrast: .high,
            alpha: glassMaterialAlpha
        )
    }

    func testReducedTransparencyGlassSurfaceContrastLightMode() {
        assertGlassSurfaceContrast(
            style: .light,
            contrast: .normal,
            alpha: reducedTransparencyAlpha
        )
    }

    func testReducedTransparencyGlassSurfaceContrastDarkMode() {
        assertGlassSurfaceContrast(
            style: .dark,
            contrast: .normal,
            alpha: reducedTransparencyAlpha
        )
    }

    func testMovieCardScrimContrastOnBrightPoster() {
        let base = UIColor.white
        let scrim = blend(foreground: .black, background: base, alpha: 0.65, style: .light, contrast: .normal)

        assertContrast(
            name: "MovieCard title",
            foreground: UIColor.white,
            background: scrim,
            style: .light,
            contrast: .normal,
            minimum: minimumPrimaryContrast
        )
        assertContrast(
            name: "MovieCard subtitle",
            foreground: UIColor(white: 0.85, alpha: 1),
            background: scrim,
            style: .light,
            contrast: .normal,
            minimum: minimumSecondaryContrast
        )
    }

    func testMovieCardScrimContrastOnMidPoster() {
        let base = UIColor(white: 0.7, alpha: 1)
        let scrim = blend(foreground: .black, background: base, alpha: 0.65, style: .light, contrast: .normal)

        assertContrast(
            name: "MovieCard title mid poster",
            foreground: UIColor.white,
            background: scrim,
            style: .light,
            contrast: .normal,
            minimum: minimumPrimaryContrast
        )
        assertContrast(
            name: "MovieCard subtitle mid poster",
            foreground: UIColor(white: 0.85, alpha: 1),
            background: scrim,
            style: .light,
            contrast: .normal,
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
            style: .light,
            contrast: .normal,
            minimum: minimumPrimaryContrast
        )
        assertContrast(
            name: "TMDb logo dark stop",
            foreground: UIColor.white,
            background: darkStop,
            style: .light,
            contrast: .normal,
            minimum: minimumPrimaryContrast
        )
    }

    private func assertContrastAcrossBackgrounds(
        style: UIUserInterfaceStyle,
        contrast: UIAccessibilityContrast,
        foreground: UIColor,
        minimum: Double
    ) {
        for spec in gradientSpecs {
            let (start, end) = spec.startEnd(for: style)
            assertContrastOnGradient(
                name: spec.name,
                start: start,
                end: end,
                foreground: foreground,
                style: style,
                contrast: contrast,
                minimum: minimum
            )
        }
    }

    private func assertGlassSurfaceContrast(
        style: UIUserInterfaceStyle,
        contrast: UIAccessibilityContrast,
        alpha: Double
    ) {
        for spec in gradientSpecs {
            let (start, end) = spec.startEnd(for: style)
            let stops = [start, midpoint(start, end), end]
            for (index, stop) in stops.enumerated() {
                let material = blend(
                    foreground: .systemBackground,
                    background: stop,
                    alpha: alpha,
                    style: style,
                    contrast: contrast
                )

                assertContrast(
                    name: "\(spec.name) glass primary stop \(index)",
                    foreground: .label,
                    background: material,
                    style: style,
                    contrast: contrast,
                    minimum: minimumPrimaryContrast
                )
                assertContrast(
                    name: "\(spec.name) glass secondary stop \(index)",
                    foreground: .secondaryLabel,
                    background: material,
                    style: style,
                    contrast: contrast,
                    minimum: minimumSecondaryContrast
                )
            }
        }
    }

    private func assertContrastOnGradient(
        name: String,
        start: UIColor,
        end: UIColor,
        foreground: UIColor,
        style: UIUserInterfaceStyle,
        contrast: UIAccessibilityContrast,
        minimum: Double
    ) {
        let stops = [start, midpoint(start, end), end]
        for (index, stop) in stops.enumerated() {
            let ratio = contrastRatio(
                foreground: foreground,
                background: stop,
                style: style,
                contrast: contrast
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                minimum,
                "\(name) stop \(index) contrast \(ratio) is below \(minimum)."
            )
        }
    }

    private func assertContrast(
        name: String,
        foreground: UIColor,
        background: UIColor,
        style: UIUserInterfaceStyle,
        contrast: UIAccessibilityContrast,
        minimum: Double
    ) {
        let ratio = contrastRatio(
            foreground: foreground,
            background: background,
            style: style,
            contrast: contrast
        )
        XCTAssertGreaterThanOrEqual(ratio, minimum, "\(name) contrast \(ratio) is below \(minimum).")
    }

    private func contrastRatio(
        foreground: UIColor,
        background: UIColor,
        style: UIUserInterfaceStyle,
        contrast: UIAccessibilityContrast
    ) -> Double {
        let l1 = luminance(for: foreground, style: style, contrast: contrast)
        let l2 = luminance(for: background, style: style, contrast: contrast)
        let light = max(l1, l2)
        let dark = min(l1, l2)
        return (light + 0.05) / (dark + 0.05)
    }

    private func luminance(
        for color: UIColor,
        style: UIUserInterfaceStyle,
        contrast: UIAccessibilityContrast
    ) -> Double {
        let resolvedColor = resolved(color, style: style, contrast: contrast)
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

    private func blend(
        foreground: UIColor,
        background: UIColor,
        alpha: Double,
        style: UIUserInterfaceStyle,
        contrast: UIAccessibilityContrast
    ) -> UIColor {
        let resolvedForeground = resolved(foreground, style: style, contrast: contrast)
        let resolvedBackground = resolved(background, style: style, contrast: contrast)
        var fr: CGFloat = 0
        var fg: CGFloat = 0
        var fb: CGFloat = 0
        var fa: CGFloat = 0
        resolvedForeground.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)

        var br: CGFloat = 0
        var bg: CGFloat = 0
        var bb: CGFloat = 0
        var ba: CGFloat = 0
        resolvedBackground.getRed(&br, green: &bg, blue: &bb, alpha: &ba)

        let a = CGFloat(alpha)
        return UIColor(
            red: fr * a + br * (1 - a),
            green: fg * a + bg * (1 - a),
            blue: fb * a + bb * (1 - a),
            alpha: 1
        )
    }

    private func resolved(
        _ color: UIColor,
        style: UIUserInterfaceStyle,
        contrast: UIAccessibilityContrast
    ) -> UIColor {
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: style),
            UITraitCollection(accessibilityContrast: contrast)
        ])
        return color.resolvedColor(with: traits)
    }
}
