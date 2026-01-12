import Foundation
import SwiftData

@MainActor
final class TasteProfileStore {
    private let context: ModelContext
    private let modelVersion = 1
    private let sigmaScale: Double = AppConfig.tasteSigmaScale

    init(context: ModelContext) {
        self.context = context
    }

    func fetchProfile() -> UserTasteProfile {
        if let existing = fetchExistingProfile() {
            return existing
        }

        let profile = UserTasteProfile(modelVersion: modelVersion, comparisonsCount: 0, lastUpdatedAt: Date(), sigmaScale: sigmaScale)
        context.insert(profile)
        saveContext()
        return profile
    }

    func updateProfile(leftVector: [Double], rightVector: [Double], choseLeft: Bool) {
        let profile = fetchProfile()

        var model = ForcedChoiceTasteModel(
            mu: profile.mu,
            sigma: profile.sigma,
            axisInfo: profile.axisInfo,
            comparisonsCount: profile.comparisonsCount
        )

        let delta = zip(leftVector, rightVector).map { $0 - $1 }
        model.update(delta: delta, choseLeft: choseLeft)

        profile.mu = model.mu
        profile.sigma = model.sigma
        profile.axisInfo = model.axisInfo
        profile.comparisonsCount = model.comparisonsCount
        profile.lastUpdatedAt = Date()
        profile.modelVersion = modelVersion

        saveContext()
    }

    func confidence(for profile: UserTasteProfile) -> Double {
        let model = ForcedChoiceTasteModel(
            mu: profile.mu,
            sigma: profile.sigma,
            axisInfo: profile.axisInfo,
            comparisonsCount: profile.comparisonsCount
        )
        return model.confidence(sigmaScale: sigmaScale)
    }

    private func fetchExistingProfile() -> UserTasteProfile? {
        var descriptor = FetchDescriptor<UserTasteProfile>()
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save taste profile: \(error)")
        }
    }
}
