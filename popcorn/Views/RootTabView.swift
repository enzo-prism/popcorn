import SwiftUI

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var didBootstrap = false

    var body: some View {
        TabView {
            NavigationStack {
                PickView()
            }
            .tabItem {
                Label("Pick", systemImage: "rectangle.split.2x1")
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)

            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "sparkles")
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            await MovieRepository(context: modelContext).bootstrapIfNeeded()
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewStore.container)
}
