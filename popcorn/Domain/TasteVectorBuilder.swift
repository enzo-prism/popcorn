import Foundation

struct TasteAxesConfig: Decodable {
    let version: Int
    let axes: [String]?
    let genreWeights: [String: [Double]]
    let keywordWeights: [String: [Double]]?
}

extension TasteAxesConfig {
    static func loadFromBundle() -> TasteAxesConfig {
        guard let url = Bundle.main.url(forResource: "TasteAxesConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(TasteAxesConfig.self, from: data) else {
            return TasteAxesConfig(version: 1, axes: nil, genreWeights: [:], keywordWeights: nil)
        }
        return config
    }
}

final class TasteVectorBuilder {
    private let config: TasteAxesConfig
    private let keywordWeightScale = 0.6

    init(config: TasteAxesConfig = TasteAxesConfig.loadFromBundle()) {
        self.config = config
    }

    var version: Int {
        config.version
    }

    func vector(for movie: Movie) -> TasteVector {
        var contributions: [[Double]] = []

        for genre in movie.genreNames {
            if let weights = weightForGenre(genre) {
                contributions.append(weights)
            }
        }

        if let keywords = movie.details?.keywords {
            for keyword in keywords {
                if let weights = weightForKeyword(keyword) {
                    contributions.append(weights.map { $0 * keywordWeightScale })
                }
            }
        }

        guard !contributions.isEmpty else { return .zero }

        let axisCount = TasteAxis.allCases.count
        var sum = Array(repeating: 0.0, count: axisCount)
        for weights in contributions {
            guard weights.count == axisCount else { continue }
            for index in 0..<axisCount {
                sum[index] += weights[index]
            }
        }

        let divisor = Double(contributions.count)
        let averaged = sum.map { clamp($0 / divisor, min: -1, max: 1) }
        return TasteVector(values: averaged)
    }

    private func weightForGenre(_ name: String) -> [Double]? {
        let key = normalize(name)
        return config.genreWeights[key] ?? config.genreWeights[name]
    }

    private func weightForKeyword(_ keyword: String) -> [Double]? {
        guard let keywordWeights = config.keywordWeights else { return nil }
        let key = normalize(keyword)
        return keywordWeights[key] ?? keywordWeights[keyword]
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
