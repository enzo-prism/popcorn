import SwiftUI

struct DemoModeBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text("Demo mode (no TMDb key)")
                .font(.subheadline.weight(.semibold))
        }
        .glassSurface(cornerRadius: 18, padding: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        .clipShape(Capsule())
    }
}

#Preview {
    DemoModeBanner()
        .padding()
}
