import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Movie.eloRating, order: .reverse) private var movies: [Movie]
    @Query(sort: \ComparisonEvent.createdAt, order: .reverse) private var events: [ComparisonEvent]
    @Query private var tasteProfiles: [UserTasteProfile]

    @State private var showTop100 = false
    @State private var insightsCache: InsightsCache?
    @State private var isRefreshingInsights = false
    @State private var showPersonalityInfo = false

    var body: some View {
        List {
            Section {
                if movies.isEmpty {
                    Text("Pick a few movies to build your ranking.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(displayedMovies.enumerated()), id: \.element.id) { index, movie in
                        NavigationLink {
                            MovieDetailView(movie: movie, rank: index + 1)
                        } label: {
                            MovieRowView(rank: index + 1, movie: movie)
                        }
                    }

                    if movies.count > 10 {
                        Button {
                            showTop100.toggle()
                        } label: {
                            Label(showTop100 ? "Show Top 10" : "Show Top 100", systemImage: "list.number")
                        }
                        .foregroundStyle(.primary)
                    }
                }
            } header: {
                Label("Top Movies", systemImage: "film.stack")
            }

            Section {
                if isRefreshingInsights {
                    ProgressView("Updating insights…")
                }

                if let insightsCache {
                    insightBlock(title: "Favorite genres", systemImage: "theatermasks", items: insightsCache.favoriteGenres)
                    insightBlock(title: "Favorite actors", systemImage: "person.2.fill", items: insightsCache.favoriteActors)
                    insightBlock(title: "Favorite directors", systemImage: "video.fill", items: insightsCache.favoriteDirectors)
                    insightBlock(title: "Favorite themes", systemImage: "tag.fill", items: insightsCache.favoriteKeywords)

                    if !insightsCache.rubricInsights.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Rubric notes", systemImage: "slider.horizontal.3")
                                .font(.subheadline.weight(.semibold))
                            ForEach(insightsCache.rubricInsights, id: \.self) { insight in
                                Text("• \(insight)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text("Keep picking to unlock insights about your taste.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Insights", systemImage: "chart.bar.xaxis")
            }

            Section {
                if let personalitySnapshot {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(personalitySnapshot.isReady ? personalitySnapshot.title : "Developing Profile")
                                .font(.headline)

                            Spacer()

                            Button {
                                showPersonalityInfo = true
                            } label: {
                                Label("How this works", systemImage: "info.circle")
                            }
                            .font(.caption.weight(.semibold))
                        }

                        if personalitySnapshot.isReady, !personalitySnapshot.traits.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(personalitySnapshot.traits, id: \.self) { trait in
                                    Text(trait)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.thinMaterial)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        HStack {
                            Label("Confidence", systemImage: "gauge")
                                .font(.caption.weight(.semibold))
                            ProgressView(value: personalitySnapshot.confidence)
                                .tint(.primary)
                            Text("\(Int(personalitySnapshot.confidence * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if personalitySnapshot.isReady {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(personalitySnapshot.evidence, id: \.self) { line in
                                    Text("• \(line)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Text("\(personalitySnapshot.remainingComparisons) picks until profile stabilizes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .glassSurface(cornerRadius: 18, padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    .listRowBackground(Color.clear)
                } else {
                    Text("Your movie personality will appear after more picks.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Movie Personality", systemImage: "brain.head.profile")
            }
        }
        .navigationTitle("Dashboard")
        .scrollContentBackground(.hidden)
        .background(backgroundLayer)
        .task(id: events.first?.id) {
            await refreshInsightsIfNeeded()
        }
        .sheet(isPresented: $showPersonalityInfo) {
            TastePersonalityInfoSheet()
        }
    }

    private var displayedMovies: [Movie] {
        let limit = showTop100 ? min(100, movies.count) : min(10, movies.count)
        return Array(movies.prefix(limit))
    }

    @ViewBuilder
    private func insightBlock(title: String, systemImage: String, items: [NamedMetric]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                ForEach(items, id: \.name) { item in
                    Text("• \(item.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .glassSurface(cornerRadius: 16, padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
            .listRowBackground(Color.clear)
        }
    }

    private func refreshInsightsIfNeeded() async {
        guard !isRefreshingInsights else { return }
        isRefreshingInsights = true
        let engine = InsightsEngine(context: modelContext)
        insightsCache = await engine.refreshIfNeeded()
        isRefreshingInsights = false
    }

    private var personalitySnapshot: TastePersonalitySnapshot? {
        let presenter = PersonalityPresenter()
        return presenter.present(
            profile: tasteProfiles.first,
            favoriteGenres: insightsCache?.favoriteGenres ?? [],
            favoriteKeywords: insightsCache?.favoriteKeywords ?? [],
            favoriteDirectors: insightsCache?.favoriteDirectors ?? [],
            favoriteActors: insightsCache?.favoriteActors ?? []
        )
    }

    private var backgroundLayer: some View {
        let colors = colorScheme == .dark
            ? [Color(red: 0.10, green: 0.11, blue: 0.14), Color(red: 0.07, green: 0.09, blue: 0.11)]
            : [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.92, green: 0.94, blue: 0.90)]
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(PreviewStore.container)
}
