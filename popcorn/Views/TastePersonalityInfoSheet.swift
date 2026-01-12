import SwiftUI

struct TastePersonalityInfoSheet: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label("How taste personality works", systemImage: "brain.head.profile")
                    .font(.title2.bold())

                Text("Popcorn learns a taste profile from your A vs B picks. It updates on-device and becomes more confident as you compare more movies.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("What it means", systemImage: "info.circle")
                        .font(.headline)
                    Text("The profile reflects movie taste axes like cerebral vs visceral or realism vs escapism. It is not a psychological assessment.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Why it changes", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                    Text("As you keep picking, Popcorn chooses more informative pairings and tightens confidence around your preferences.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .presentationDetents([.medium, .large])
        .background(backgroundLayer)
    }

    private var backgroundLayer: some View {
        let colors = colorScheme == .dark
            ? [Color(red: 0.10, green: 0.09, blue: 0.12), Color(red: 0.06, green: 0.08, blue: 0.12)]
            : [Color(red: 0.96, green: 0.95, blue: 0.93), Color(red: 0.92, green: 0.95, blue: 0.99)]
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    TastePersonalityInfoSheet()
}
