import SwiftUI
import UIKit

struct MovieCardView: View {
    let movie: Movie
    let isSelected: Bool
    let isDimmed: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    private let scrimOpacity = 0.65

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                if let posterURL {
                    RemoteImageView(url: posterURL)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.08))
                }

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(scrimOpacity)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Spacer()
                    titleText
                    Text(detailLine)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .topLeading) {
                if posterURL == nil {
                    Image(systemName: "film")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .aspectRatio(0.7, contentMode: .fit)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .opacity(isDimmed ? 0.6 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.7) : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(reduceTransparency ? 0 : 0.35)
                .blendMode(.screen)
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.25 : 0.1), radius: isSelected ? 16 : 8, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .animation(.easeInOut(duration: 0.18), value: isDimmed)
    }

    private var detailLine: String {
        let yearText = movie.year > 0 ? String(movie.year) : "—"
        let genres = movie.genreNames.prefix(2).joined(separator: ", ")
        if genres.isEmpty {
            return yearText
        }
        return "\(yearText) • \(genres)"
    }

    private var titleText: some View {
        ViewThatFits(in: .vertical) {
            MovieTitleLabel(
                text: movie.title,
                font: titleUIFont(style: .headline, weight: .semibold),
                textColor: .white
            )
            MovieTitleLabel(
                text: movie.title,
                font: titleUIFont(style: .subheadline, weight: .semibold),
                textColor: .white
            )
            MovieTitleLabel(
                text: movie.title,
                font: titleUIFont(style: .footnote, weight: .semibold),
                textColor: .white
            )
        }
    }

    private func titleUIFont(style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: style)
        let descriptor = base.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: 0)
    }

    private var posterURL: URL? {
        guard let path = movie.posterPath else { return nil }
        return TMDbImageURL.posterURL(path: path)
    }
}

#Preview {
    MovieCardView(
        movie: Movie(
            tmdbID: 1,
            title: "Sample Movie",
            overview: "",
            releaseDate: nil,
            year: 2020,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 8.2,
            voteCount: 2000,
            genreNames: ["Drama", "Thriller"]
        ),
        isSelected: true,
        isDimmed: false,
        action: {}
    )
    .padding()
    .background(Color.black.opacity(0.05))
}
