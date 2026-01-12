import SwiftUI

struct MovieRowView: View {
    let rank: Int
    let movie: Movie

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Elo \(Int(movie.eloRating))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }

    private var detailLine: String {
        let yearText = movie.year > 0 ? String(movie.year) : "—"
        let genres = movie.genreNames.prefix(2).joined(separator: ", ")
        if genres.isEmpty {
            return yearText
        }
        return "\(yearText) • \(genres)"
    }
}

#Preview {
    MovieRowView(
        rank: 1,
        movie: Movie(
            tmdbID: 1,
            title: "Sample Movie",
            overview: "",
            releaseDate: nil,
            year: 2020,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 8.1,
            voteCount: 2000,
            genreNames: ["Drama", "Thriller"]
        )
    )
    .padding()
}
