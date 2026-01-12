import SwiftUI

struct PickCardRow: View {
    let left: Movie
    let right: Movie
    let selectedSide: PickSide?
    let isProcessing: Bool
    let onPickLeft: () -> Void
    let onPickRight: () -> Void
    let onNotSeenLeft: () -> Void
    let onNotSeenRight: () -> Void
    let onLayout: ((PickCardLayout) -> Void)?
    private let spacing: CGFloat = 12

    init(
        left: Movie,
        right: Movie,
        selectedSide: PickSide?,
        isProcessing: Bool,
        onPickLeft: @escaping () -> Void,
        onPickRight: @escaping () -> Void,
        onNotSeenLeft: @escaping () -> Void,
        onNotSeenRight: @escaping () -> Void,
        onLayout: ((PickCardLayout) -> Void)? = nil
    ) {
        self.left = left
        self.right = right
        self.selectedSide = selectedSide
        self.isProcessing = isProcessing
        self.onPickLeft = onPickLeft
        self.onPickRight = onPickRight
        self.onNotSeenLeft = onNotSeenLeft
        self.onNotSeenRight = onNotSeenRight
        self.onLayout = onLayout
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 0) {
            PickCardColumn(
                movie: left,
                isSelected: selectedSide == .left,
                isDimmed: selectedSide == .right,
                side: .left,
                accessibilityID: "pick-card-left",
                action: onPickLeft,
                notSeenAction: onNotSeenLeft
            )

            PickCardColumn(
                movie: right,
                isSelected: selectedSide == .right,
                isDimmed: selectedSide == .left,
                side: .right,
                accessibilityID: "pick-card-right",
                action: onPickRight,
                notSeenAction: onNotSeenRight
            )
        }
        .allowsHitTesting(!isProcessing)
        .onPreferenceChange(CardWidthPreferenceKey.self) { widths in
            guard let onLayout,
                  let leftWidth = widths[.left],
                  let rightWidth = widths[.right] else {
                return
            }
            onLayout(PickCardLayout(leftWidth: leftWidth, rightWidth: rightWidth))
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }
}

struct PickCardLayout: Equatable {
    let leftWidth: CGFloat
    let rightWidth: CGFloat
}

private enum PickCardSide {
    case left
    case right
}

private struct PickCardColumn: View {
    let movie: Movie
    let isSelected: Bool
    let isDimmed: Bool
    let side: PickCardSide
    let accessibilityID: String
    let action: () -> Void
    let notSeenAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            MovieCardView(
                movie: movie,
                isSelected: isSelected,
                isDimmed: isDimmed,
                action: action
            )
            .accessibilityIdentifier(accessibilityID)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: CardWidthPreferenceKey.self, value: [side: proxy.size.width])
                }
            )
            .frame(maxWidth: .infinity)

            Button {
                notSeenAction()
            } label: {
                Label("Haven't seen", systemImage: "eye.slash")
            }
            .buttonStyle(GlassButtonStyle(cornerRadius: 14))
        }
    }
}

private struct CardWidthPreferenceKey: PreferenceKey {
    static var defaultValue: [PickCardSide: CGFloat] = [:]

    static func reduce(value: inout [PickCardSide: CGFloat], nextValue: () -> [PickCardSide: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
