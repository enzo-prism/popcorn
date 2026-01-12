import Foundation
import SwiftData
import UIKit

@MainActor
final class PickViewModel: ObservableObject {
    @Published private(set) var leftMovie: Movie?
    @Published private(set) var rightMovie: Movie?
    @Published var selectedSide: PickSide?
    @Published var isProcessing = false

    private var movies: [Movie] = []
    private var context: ModelContext?
    private var tasteVectorMap: [Int: [Double]] = [:]
    private var tasteProfile: UserTasteProfile?
    private let feedback = UIImpactFeedbackGenerator(style: .medium)
    private var rng = SystemRandomNumberGenerator()
    private var pairSelector = PairSelector(bufferSize: AppConfig.recentPairBufferSize)

    func configure(context: ModelContext) {
        self.context = context
        feedback.prepare()
        tasteProfile = TasteProfileStore(context: context).fetchProfile()
        if !movies.isEmpty {
            tasteVectorMap = TasteVectorStore(context: context).vectorMap(for: movies)
        }
    }

    func updateMovies(_ movies: [Movie]) {
        self.movies = movies
        if let context {
            tasteVectorMap = TasteVectorStore(context: context).vectorMap(for: movies)
            if tasteProfile == nil {
                tasteProfile = TasteProfileStore(context: context).fetchProfile()
            }
        }
        if leftMovie == nil || rightMovie == nil {
            selectNextPair()
        }
    }

    func pick(side: PickSide) {
        guard !isProcessing else { return }
        guard let context, let left = leftMovie, let right = rightMovie else { return }

        isProcessing = true
        selectedSide = side
        feedback.impactOccurred()
        feedback.prepare()

        let now = Date()
        let winner = side == .left ? left : right
        let loser = side == .left ? right : left

        applyElo(winner: winner, loser: loser, at: now)
        updateTasteProfile(left: left, right: right, choseLeft: side == .left)

        let outcome: ComparisonOutcome = side == .left ? .left : .right
        let event = ComparisonEvent(
            leftMovieID: left.tmdbID,
            rightMovieID: right.tmdbID,
            selectedMovieID: winner.tmdbID,
            outcome: outcome
        )
        context.insert(event)
        saveContext(context)

        advancePair(after: 0.2)
    }

    func markNotSeen(side: PickSide) {
        guard !isProcessing else { return }
        guard let context, let left = leftMovie, let right = rightMovie else { return }

        isProcessing = true
        let now = Date()
        if side == .left {
            markNotSeen(movie: left, at: now)
        } else {
            markNotSeen(movie: right, at: now)
        }

        let outcome: ComparisonOutcome = side == .left ? .leftNotSeen : .rightNotSeen
        let event = ComparisonEvent(
            leftMovieID: left.tmdbID,
            rightMovieID: right.tmdbID,
            selectedMovieID: nil,
            outcome: outcome
        )
        context.insert(event)
        saveContext(context)

        advancePair(after: 0.1)
    }

    func skipPair() {
        guard !isProcessing else { return }
        guard let context, let left = leftMovie, let right = rightMovie else { return }

        isProcessing = true
        let event = ComparisonEvent(
            leftMovieID: left.tmdbID,
            rightMovieID: right.tmdbID,
            selectedMovieID: nil,
            outcome: .skip
        )
        context.insert(event)
        saveContext(context)

        advancePair(after: 0.05)
    }

    private func advancePair(after seconds: Double) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            await MainActor.run {
                self?.selectedSide = nil
                self?.selectNextPair()
                self?.isProcessing = false
            }
        }
    }

    private func selectNextPair() {
        guard let pair = pairSelector.nextPair(
            from: movies,
            tasteProfile: tasteProfile,
            tasteVectors: tasteVectorMap,
            rng: &rng
        ) else {
            leftMovie = nil
            rightMovie = nil
            return
        }
        leftMovie = pair.left
        rightMovie = pair.right
    }

    private func applyElo(winner: Movie, loser: Movie, at date: Date) {
        let updated = EloRanker.updatedRatings(
            winnerRating: winner.eloRating,
            loserRating: loser.eloRating,
            kFactor: AppConfig.eloKFactor
        )
        winner.eloRating = updated.winner
        loser.eloRating = updated.loser

        winner.comparisonsCount += 1
        loser.comparisonsCount += 1
        winner.lastComparedAt = date
        loser.lastComparedAt = date
        winner.seenState = .seen
        loser.seenState = .seen
        winner.updatedAt = date
        loser.updatedAt = date
    }

    private func markNotSeen(movie: Movie, at date: Date) {
        movie.seenState = .notSeen
        movie.lastMarkedNotSeenAt = date
        movie.updatedAt = date
    }

    private func saveContext(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save changes: \(error)")
        }
    }

    private func updateTasteProfile(left: Movie, right: Movie, choseLeft: Bool) {
        guard let context else { return }
        let leftVector = tasteVectorMap[left.tmdbID] ?? TasteVector.zero.values
        let rightVector = tasteVectorMap[right.tmdbID] ?? TasteVector.zero.values
        TasteProfileStore(context: context).updateProfile(leftVector: leftVector, rightVector: rightVector, choseLeft: choseLeft)
        tasteProfile = TasteProfileStore(context: context).fetchProfile()
    }
}

enum PickSide {
    case left
    case right
}
