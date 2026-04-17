import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()
    @State private var selectedSection: AppSection = .habits
    @State private var dragOffset: CGFloat = 0

    private let sections = AppSection.allCases

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#0D0D0D").ignoresSafeArea()

            pageContent
                .offset(x: dragOffset)
                .animation(.interactiveSpring(duration: 0.12), value: dragOffset)

            FloatingNavBubble(selected: $selectedSection)
                .padding(.bottom, 12)
        }
        .gesture(pageSwipeGesture)
        .environmentObject(store)
        .tint(store.accentColor)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch selectedSection {
        case .habits:   AchieveView()
        case .coach:    AICoachView()
        case .journal:  JournalView()
        case .calendar: BossCalendarView()
        case .profile:  UserProfilePage()
        }
    }

    private var pageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy) else { return }
                dragOffset = dx * 0.15
            }
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy), abs(dx) > 50 else {
                    withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                    return
                }
                withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                navigatePage(by: dx < 0 ? 1 : -1)
            }
    }

    private func navigatePage(by offset: Int) {
        guard let idx = sections.firstIndex(of: selectedSection) else { return }
        let next = idx + offset
        guard next >= 0, next < sections.count else { return }
        withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
            selectedSection = sections[next]
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Floating Navigation Bubble

private struct FloatingNavBubble: View {
    @Binding var selected: AppSection

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppSection.allCases) { section in
                NavBubbleItem(section: section, isSelected: selected == section) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                        selected = section
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 6)
    }
}

private struct NavBubbleItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: sectionSymbol)
                    .font(.system(size: 15, weight: .semibold))
                Text(section.title)
                    .font(.system(size: 8, weight: .semibold))
                    .kerning(0.3)
            }
            .foregroundStyle(isSelected ? Color(hex: "#0D0D0D") : Color(hex: "#888888"))
            .frame(width: 52, height: 44)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color(hex: "#C9A84C") : Color.clear)
            )
            .scaleEffect(isPressed ? 0.92 : (isSelected ? 1.04 : 1.0))
            .animation(.spring(duration: 0.2, bounce: 0.3), value: isSelected)
            .animation(.spring(duration: 0.15), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }

    private var sectionSymbol: String {
        switch section {
        case .habits:   return "bolt.fill"
        case .coach:    return "sparkles"
        case .journal:  return "book.closed.fill"
        case .calendar: return "calendar"
        case .profile:  return "person.fill"
        }
    }
}

#Preview {
    ContentView()
}
