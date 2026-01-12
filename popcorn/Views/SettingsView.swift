import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            if AppConfig.isDemoMode {
                Section {
                    Label("Demo mode (no TMDb key)", systemImage: "sparkles")
                }
            }
            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About Popcorn", systemImage: "info.circle")
                }
            } header: {
                Label("About", systemImage: "film.stack")
            }
            Section {
                TMDbAttributionView()
            } header: {
                Label("Credits", systemImage: "seal")
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(SettingsBackground())
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Label("Popcorn", systemImage: "film.stack")
                    .font(.title.bold())

                TMDbLogoPlaceholder()
                    .frame(width: 160, height: 48)

                Text("This product uses the TMDb API but is not endorsed or certified by TMDb.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding()
        }
        .background(SettingsBackground())
        .navigationTitle("About")
    }
}

private struct TMDbAttributionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TMDbLogoPlaceholder()
                .frame(width: 120, height: 36)
            Text("This product uses the TMDb API but is not endorsed or certified by TMDb.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .glassSurface(cornerRadius: 16, padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
        .listRowBackground(Color.clear)
    }
}

private struct TMDbLogoPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.45, blue: 0.5),
                        Color(red: 0.0, green: 0.25, blue: 0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text("TMDb")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            )
    }
}

private struct SettingsBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = colorScheme == .dark
            ? [Color(red: 0.09, green: 0.10, blue: 0.12), Color(red: 0.06, green: 0.08, blue: 0.10)]
            : [Color(red: 0.95, green: 0.97, blue: 0.98), Color(red: 0.93, green: 0.94, blue: 0.90)]

        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
