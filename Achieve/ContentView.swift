import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()
    @State private var selectedSection: AppSection = .habits
    @State private var showingProfile = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Group {
                    switch selectedSection {
                    case .habits:
                        AchieveView()
                    case .coach:
                        AICoachView()
                    case .journal:
                        JournalView()
                    }
                }

                FloatingNavigationBubble(selectedSection: $selectedSection, accent: store.accentColor)
                    .padding(.bottom, 8)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Text("🙂")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                NavigationStack {
                    ProfileView()
                        .environmentObject(store)
                }
            }
        }
        .environmentObject(store)
        .tint(store.accentColor)
    }
}

private struct FloatingNavigationBubble: View {
    @Binding var selectedSection: AppSection
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppSection.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: section.icon)
                            .font(.subheadline.weight(.semibold))
                        Text(section.title)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(selectedSection == section ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(selectedSection == section ? accent : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
}
