import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()

    var body: some View {
        TabView {
            NavigationStack {
                AchieveView()
            }
            .tabItem {
                Label("Achieve", systemImage: "target")
            }

            NavigationStack {
                AICoachView()
            }
            .tabItem {
                Label("AI Coach", systemImage: "sparkles")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
        .environmentObject(store)
        .tint(store.accentColor)
    }
}

#Preview {
    ContentView()
}
