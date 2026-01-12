import SwiftUI
import UIKit

struct PickMovieCardView: View {
    let movie: Movie
    let isSelected: Bool
    let isDimmed: Bool
    let accessibilityID: String
    let action: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let cornerRadius: CGFloat = 20
    private let textCornerRadius: CGFloat = 16
    private let posterAspectRatio: CGFloat = 0.7

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                posterView
                    .aspectRatio(posterAspectRatio, contentMode: .fit)
                    .overlay(AccessibilityMarkerView(identifier: "\(accessibilityID)-poster"))

                textBlock
                    .accessibilityIdentifier("\(accessibilityID)-text")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(reduceTransparency ? 0.08 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.7) : Color.white.opacity(0.18), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(isSelected ? 0.25 : 0.12), radius: isSelected ? 14 : 8, x: 0, y: 6)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .opacity(isDimmed ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .animation(.easeInOut(duration: 0.18), value: isDimmed)
    }

    private var posterView: some View {
        GeometryReader { proxy in
            let targetWidth = max(proxy.size.width, 1)
            let url = TMDbImageURLBuilder.posterURL(
                posterPath: movie.posterPath,
                targetPointWidth: targetWidth,
                screenScale: UIScreen.main.scale
            )
            RemoteImageView(url: url) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.08))
                    .overlay(
                        Image(systemName: "film")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            titleText
            Text(detailLine)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(textBackground)
        .clipShape(RoundedRectangle(cornerRadius: textCornerRadius, style: .continuous))
    }

    private var textBackground: some View {
        let shape = RoundedRectangle(cornerRadius: textCornerRadius, style: .continuous)
        let style: AnyShapeStyle = reduceTransparency
            ? AnyShapeStyle(Color(.systemBackground).opacity(0.9))
            : AnyShapeStyle(.ultraThinMaterial)
        let borderOpacity: Double = reduceTransparency ? 0.35 : 0.2

        return shape
            .fill(style)
            .overlay(shape.stroke(Color.white.opacity(borderOpacity), lineWidth: 1))
    }

    private var titleText: some View {
        ViewThatFits(in: .vertical) {
            MovieTitleLabel(
                text: movie.title,
                font: titleUIFont(style: .headline, weight: .semibold),
                textColor: .label,
                accessibilityIdentifier: "\(accessibilityID)-title"
            )
            MovieTitleLabel(
                text: movie.title,
                font: titleUIFont(style: .subheadline, weight: .semibold),
                textColor: .label,
                accessibilityIdentifier: "\(accessibilityID)-title"
            )
            MovieTitleLabel(
                text: movie.title,
                font: titleUIFont(style: .footnote, weight: .semibold),
                textColor: .label,
                accessibilityIdentifier: "\(accessibilityID)-title"
            )
        }
    }

    private var detailLine: String {
        let yearText = movie.year > 0 ? String(movie.year) : "—"
        let genres = movie.genreNames.prefix(2).joined(separator: ", ")
        if genres.isEmpty {
            return yearText
        }
        return "\(yearText) • \(genres)"
    }

    private func titleUIFont(style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: style)
        let descriptor = base.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: 0)
    }

}

#Preview {
    PickMovieCardView(
        movie: Movie(
            tmdbID: 1,
            title: "Sample Movie With a Longer Title to Preview Wrapping",
            overview: "",
            releaseDate: nil,
            year: 2020,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 8.2,
            voteCount: 2000,
            genreNames: ["Drama", "Thriller"]
        ),
        isSelected: false,
        isDimmed: false,
        accessibilityID: "pick-card-preview",
        action: {}
    )
    .padding()
    .background(Color.black.opacity(0.05))
}
