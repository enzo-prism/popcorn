import SwiftUI

struct RefreshMomentSheet: View {
    let topMovies: [Movie]
    let insights: InsightsCache?
    let personality: TastePersonalitySnapshot?
    let pickCount: Int
    let interval: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                    .glassSurface(cornerRadius: 18, padding: EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))

                if !topMovies.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Top 10 right now", systemImage: "list.number")
                            .font(.headline)
                        ForEach(Array(topMovies.prefix(10).enumerated()), id: \.element.id) { index, movie in
                            MovieRowView(rank: index + 1, movie: movie)
                        }
                    }
                    .glassSurface(cornerRadius: 18, padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("New insight", systemImage: "lightbulb")
                        .font(.headline)
                    Text(insightSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .glassSurface(cornerRadius: 18, padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Label("Movie personality", systemImage: "brain.head.profile")
                        .font(.headline)
                    if let personality {
                        Text(personality.isReady ? personality.title : "Developing Profile")
                            .font(.subheadline.weight(.semibold))
                        ProgressView(value: personality.confidence)
                            .tint(.primary)
                        if personality.isReady, let first = personality.evidence.first {
                            Text(first)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(personality.remainingComparisons) picks until profile stabilizes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Keep picking to unlock your personality card.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ProgressView(value: progressValue)
                            .tint(.primary)
                        Text("\(remainingCount) picks to the next update")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .glassSurface(cornerRadius: 18, padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(backgroundLayer)
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Fresh signals", systemImage: "sparkles")
                .font(.title2.bold())
            Text("Based on your latest \(pickCount) picks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var insightSummary: String {
        if let insights {
            if let genre = insights.favoriteGenres.first?.name {
                return "You keep elevating \(genre) films based on your top-ranked picks."
            }
            if let actor = insights.favoriteActors.first?.name {
                return "\(actor) keeps showing up in your favorites."
            }
            if let director = insights.favoriteDirectors.first?.name {
                return "\(director) is leading your director list."
            }
            if let keyword = insights.favoriteKeywords.first?.name {
                return "Themes around \(keyword.lowercased()) are resonating."
            }
        }
        return "Keep picking to unlock deeper insights about your taste."
    }

    private var remainingCount: Int {
        let remainder = pickCount % interval
        return remainder == 0 ? interval : (interval - remainder)
    }

    private var progressValue: Double {
        let remainder = pickCount % interval
        return Double(remainder) / Double(interval)
    }

    private var backgroundLayer: some View {
        let colors = colorScheme == .dark
            ? [Color(red: 0.10, green: 0.09, blue: 0.12), Color(red: 0.06, green: 0.08, blue: 0.12)]
            : [Color(red: 0.97, green: 0.96, blue: 0.94), Color(red: 0.92, green: 0.94, blue: 0.98)]
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    RefreshMomentSheet(
        topMovies: [
            Movie(
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
        ],
        insights: nil,
        personality: nil,
        pickCount: 12,
        interval: 10
    )
    .modelContainer(PreviewStore.container)
}
