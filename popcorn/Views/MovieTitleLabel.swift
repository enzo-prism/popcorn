import SwiftUI
import UIKit

struct MovieTitleLabel: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let accessibilityIdentifier: String

    init(
        text: String,
        font: UIFont,
        textColor: UIColor = .label,
        accessibilityIdentifier: String = "movie-card-title"
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.accessibilityIdentifier = accessibilityIdentifier
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.text = text
        uiView.font = font
        uiView.textColor = textColor
        uiView.accessibilityIdentifier = accessibilityIdentifier
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize {
        let targetWidth = proposal.width ?? uiView.bounds.width
        let width = targetWidth > 0 ? targetWidth : 0
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width == 0 ? size.width : width, height: size.height)
    }
}
