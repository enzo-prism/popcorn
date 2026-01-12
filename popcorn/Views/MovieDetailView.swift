import SwiftUI
import SwiftData

struct MovieDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var movie: Movie
    let rank: Int

    @State private var ratings: RubricRatings = .empty
    @State private var didLoadRatings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                posterView

                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title)
                        .font(.title.bold())
                    Text(detailLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    badge(text: "Rank #\(rank)", systemImage: "trophy.fill")
                    badge(text: "Elo \(Int(movie.eloRating))", systemImage: "chart.line.uptrend.xyaxis")
                }

                if !movie.overview.isEmpty {
                    Text(movie.overview)
                        .font(.body)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Your Rubric", systemImage: "slider.horizontal.3")
                        .font(.headline)

                    RubricSlider(title: "Story", value: $ratings.story)
                    RubricSlider(title: "Action", value: $ratings.action)
                    RubricSlider(title: "Visuals", value: $ratings.visuals)
                    RubricSlider(title: "Dialogue", value: $ratings.dialogue)
                    RubricSlider(title: "Acting", value: $ratings.acting)
                    RubricSlider(title: "Sound", value: $ratings.sound)
                }
            }
            .padding()
        }
        .background(backgroundLayer)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoadRatings else { return }
            didLoadRatings = true
            ratings = movie.rubricRatings ?? .empty
        }
        .onChange(of: ratings) {
            movie.rubricRatings = ratings
            movie.updatedAt = Date()
            saveChanges()
        }
    }

    private var posterView: some View {
        Group {
            if let posterURL {
                RemoteImageView(url: posterURL)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 320)
                    .overlay(
                        Image(systemName: "film")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }

    private var detailLine: String {
        let yearText = movie.year > 0 ? String(movie.year) : "—"
        let genres = movie.genreNames.joined(separator: ", ")
        if genres.isEmpty {
            return yearText
        }
        return "\(yearText) • \(genres)"
    }

    private var posterURL: URL? {
        guard let path = movie.posterPath else { return nil }
        return TMDbImageURL.posterURL(path: path)
    }

    private func badge(text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .glassSurface(cornerRadius: 16, padding: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            .clipShape(Capsule())
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save rubric ratings: \(error)")
        }
    }

    private var backgroundLayer: some View {
        let colors = colorScheme == .dark
            ? [Color(red: 0.10, green: 0.09, blue: 0.12), Color(red: 0.06, green: 0.08, blue: 0.12)]
            : [Color(red: 0.98, green: 0.96, blue: 0.94), Color(red: 0.92, green: 0.94, blue: 0.98)]
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct RubricSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(value))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: 0...10, step: 1)
        }
    }
}

#Preview {
    NavigationStack {
        MovieDetailView(
            movie: Movie(
                tmdbID: 1,
                title: "Sample Movie",
                overview: "A quick overview of the story.",
                releaseDate: nil,
                year: 2020,
                posterPath: nil,
                backdropPath: nil,
                voteAverage: 8.1,
                voteCount: 2000,
                genreNames: ["Drama", "Thriller"]
            ),
            rank: 1
        )
    }
    .modelContainer(PreviewStore.container)
}
