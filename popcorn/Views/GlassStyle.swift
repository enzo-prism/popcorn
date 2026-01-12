import SwiftUI

struct GlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: EdgeInsets?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let style: AnyShapeStyle = reduceTransparency
            ? AnyShapeStyle(Color(.systemBackground).opacity(0.9))
            : AnyShapeStyle(.ultraThinMaterial)
        let borderOpacity: Double = reduceTransparency ? 0.4 : 0.25
        let borderWidth: CGFloat = reduceTransparency ? 1.5 : 1

        return content
            .padding(padding ?? EdgeInsets())
            .background(style, in: shape)
            .overlay(shape.stroke(Color.white.opacity(borderOpacity), lineWidth: borderWidth))
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func glassSurface(cornerRadius: CGFloat = 20, padding: EdgeInsets? = nil) -> some View {
        modifier(GlassSurfaceModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

struct GlassButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 16
    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isProminent ? .primary : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassSurface(cornerRadius: cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isProminent ? Color.white.opacity(0.12) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
