import SwiftUI
import SwiftData

struct PickView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var movies: [Movie]
    @Query(sort: \ComparisonEvent.createdAt, order: .reverse) private var events: [ComparisonEvent]
    @StateObject private var viewModel = PickViewModel()
    @AppStorage("lastRefreshMomentIndex") private var lastRefreshMomentIndex = 0

    @State private var showRefreshMoment = false
    @State private var refreshInsights: InsightsCache?
    @State private var refreshPersonality: TastePersonalitySnapshot?
    @State private var refreshTopMovies: [Movie] = []
    @State private var refreshPickCount = 0

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 16) {
                if AppConfig.isDemoMode {
                    DemoModeBanner()
                }

                Label("Pick the movie you prefer", systemImage: "hand.tap")
                    .font(.title2.bold())

                if let left = viewModel.leftMovie, let right = viewModel.rightMovie {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 8) {
                            MovieCardView(
                                movie: left,
                                isSelected: viewModel.selectedSide == .left,
                                isDimmed: viewModel.selectedSide == .right,
                                action: { viewModel.pick(side: .left) }
                            )
                            Button {
                                viewModel.markNotSeen(side: .left)
                            } label: {
                                Label("Haven't seen", systemImage: "eye.slash")
                            }
                            .buttonStyle(GlassButtonStyle(cornerRadius: 14))
                        }

                        VStack(spacing: 8) {
                            MovieCardView(
                                movie: right,
                                isSelected: viewModel.selectedSide == .right,
                                isDimmed: viewModel.selectedSide == .left,
                                action: { viewModel.pick(side: .right) }
                            )
                            Button {
                                viewModel.markNotSeen(side: .right)
                            } label: {
                                Label("Haven't seen", systemImage: "eye.slash")
                            }
                            .buttonStyle(GlassButtonStyle(cornerRadius: 14))
                        }
                    }
                    .allowsHitTesting(!viewModel.isProcessing)

                    Button {
                        viewModel.skipPair()
                    } label: {
                        Label("Skip this pair", systemImage: "forward.end")
                    }
                    .buttonStyle(GlassButtonStyle(cornerRadius: 20, isProminent: true))
                    .allowsHitTesting(!viewModel.isProcessing)
                } else {
                    ProgressView("Loading movies…")
                        .padding(.top, 32)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Pick")
        .task {
            viewModel.configure(context: modelContext)
        }
        .task(id: movies.count) {
            viewModel.updateMovies(movies)
        }
        .task(id: pickCount) {
            await evaluateRefreshMoment()
        }
        .sheet(isPresented: $showRefreshMoment) {
            RefreshMomentSheet(
                topMovies: refreshTopMovies,
                insights: refreshInsights,
                personality: refreshPersonality,
                pickCount: refreshPickCount,
                interval: AppConfig.refreshMomentInterval
            )
        }
    }

    private var pickCount: Int {
        events.filter { $0.selectedMovieID != nil }.count
    }

    private var sortedMovies: [Movie] {
        movies.sorted { $0.eloRating > $1.eloRating }
    }

    private var backgroundLayer: some View {
        let colors = colorScheme == .dark
            ? [Color(red: 0.09, green: 0.10, blue: 0.12), Color(red: 0.05, green: 0.08, blue: 0.12)]
            : [Color(red: 0.97, green: 0.95, blue: 0.92), Color(red: 0.90, green: 0.94, blue: 0.98)]
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func evaluateRefreshMoment() async {
        guard pickCount > 0 else { return }
        let interval = AppConfig.refreshMomentInterval
        guard interval > 0 else { return }
        let momentIndex = pickCount / interval
        guard momentIndex > 0, momentIndex > lastRefreshMomentIndex else { return }

        lastRefreshMomentIndex = momentIndex
        refreshTopMovies = Array(sortedMovies.prefix(10))
        refreshPickCount = pickCount

        let engine = InsightsEngine(context: modelContext)
        refreshInsights = await engine.refreshIfNeeded(force: true)
        let presenter = PersonalityPresenter()
        refreshPersonality = presenter.present(
            profile: TasteProfileStore(context: modelContext).fetchProfile(),
            favoriteGenres: refreshInsights?.favoriteGenres ?? [],
            favoriteKeywords: refreshInsights?.favoriteKeywords ?? [],
            favoriteDirectors: refreshInsights?.favoriteDirectors ?? [],
            favoriteActors: refreshInsights?.favoriteActors ?? []
        )
        showRefreshMoment = true
    }
}

#Preview {
    NavigationStack {
        PickView()
    }
    .modelContainer(PreviewStore.container)
}
