import SwiftUI

struct AchieveView: View {
    @EnvironmentObject private var store: AppStore
    @State private var newHabit = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RadialProgressView(percentage: store.todayFrequency, accent: store.accentColor)
                    .padding(.top, 8)

                Text("Today's Frequency")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(store.accentColor)

                if store.habits.isEmpty {
                    VStack(spacing: 8) {
                        Text("Add your first habit")
                            .font(.title2.weight(.bold))
                        Text("Completely empty on day one. Make it 100% yours.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 24)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(store.habits) { habit in
                            habitRow(habit)
                        }
                    }
                }

                HStack(spacing: 12) {
                    TextField("New habit...", text: $newHabit)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit(addHabit)

                    Button(action: addHabit) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(store.accentColor, in: Circle())
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested")
                        .font(.headline)

                    FlexibleTagView(
                        tags: store.suggestedHabits,
                        accent: store.accentColor
                    ) { title in
                        store.addHabit(title)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Achieve")
    }

    private func habitRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            Button {
                store.toggleHabit(habit)
            } label: {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(habit.isCompleted ? store.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            Text(habit.title)
                .font(.body)
                .strikethrough(habit.isCompleted)

            Spacer()

            Button(role: .destructive) {
                store.removeHabit(habit)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func addHabit() {
        store.addHabit(newHabit)
        newHabit = ""
    }
}

private struct FlexibleTagView: View {
    let tags: [String]
    let accent: Color
    var action: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Button(tag) {
                    action(tag)
                }
                .font(.subheadline.weight(.medium))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .foregroundStyle(accent)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        AchieveView()
            .environmentObject(AppStore.preview)
    }
}
