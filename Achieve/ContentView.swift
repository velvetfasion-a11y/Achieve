import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView {
            AchieveView()
                .tabItem {
                    Label("Achieve", systemImage: "checkmark.circle")
                }

            AICoachView()
                .tabItem {
                    Label("AI Coach", systemImage: "sparkles")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(store.accentColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore.preview)
}
