import Foundation

enum TasteAxis: Int, CaseIterable {
    case cerebralVisceral
    case darkComfort
    case auteurMainstream
    case realismEscapism
    case characterSpectacle
    case noveltyFamiliarity

    var positiveLabel: String {
        switch self {
        case .cerebralVisceral: return "Cerebral"
        case .darkComfort: return "Dark"
        case .auteurMainstream: return "Auteur"
        case .realismEscapism: return "Realism"
        case .characterSpectacle: return "Character-driven"
        case .noveltyFamiliarity: return "Novelty-seeking"
        }
    }

    var negativeLabel: String {
        switch self {
        case .cerebralVisceral: return "Visceral"
        case .darkComfort: return "Comfort"
        case .auteurMainstream: return "Mainstream"
        case .realismEscapism: return "Escapism"
        case .characterSpectacle: return "Spectacle-driven"
        case .noveltyFamiliarity: return "Familiarity-seeking"
        }
    }

    var axisLabel: String {
        "\(positiveLabel) \u{2194} \(negativeLabel)"
    }
}

struct TasteVector: Hashable {
    var values: [Double]

    static var zero: TasteVector {
        TasteVector(values: Array(repeating: 0, count: TasteAxis.allCases.count))
    }

    func normalized() -> TasteVector {
        let length = sqrt(values.map { $0 * $0 }.reduce(0, +))
        guard length > 0 else { return self }
        return TasteVector(values: values.map { $0 / length })
    }
}
