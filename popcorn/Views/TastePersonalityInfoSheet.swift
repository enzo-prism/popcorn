import SwiftUI

struct TastePersonalityInfoSheet: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("How taste personality works")
                    .font(.title2.bold())

                Text("Popcorn learns a taste profile from your A vs B picks. It updates on-device and becomes more confident as you compare more movies.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What it means")
                        .font(.headline)
                    Text("The profile reflects movie taste axes like cerebral vs visceral or realism vs escapism. It is not a psychological assessment.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Why it changes")
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
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.95, blue: 0.93),
                Color(red: 0.92, green: 0.95, blue: 0.99)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    TastePersonalityInfoSheet()
}
