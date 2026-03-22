import SwiftUI

struct AchieveView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedDay = Calendar.current.startOfDay(for: Date())
    @State private var editingHabit: Habit?
    @State private var editingTitle = ""
    @State private var showingAddHabit = false
    @State private var newHabitTitle = ""
    @State private var editMode: EditMode = .inactive

    private var weekDays: [Date] {
        store.weekDays(reference: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Achieve")
                    .font(.custom("AvenirNext-Bold", size: 34))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)

                RadialProgressView(percentage: store.progress(for: selectedDay), accent: store.accentColor, size: 130)

                Text("Goals for \(dayTitle(for: selectedDay)): \(Int((store.progress(for: selectedDay) * 100).rounded()))%")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(store.accentColor)
                    .multilineTextAlignment(.center)

                weekdayProgressStrip

                VStack(spacing: 10) {
                    HStack(alignment: .bottom) {
                        Text("Dream ✨")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        dayActionHeader
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(editMode == .active ? "Done" : "Reorder") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                editMode = editMode == .active ? .inactive : .active
                            }
                        }
                        .font(.footnote.weight(.semibold))
                    }

                    List {
                        ForEach(store.habits) { habit in
                            HStack(spacing: 8) {
                                Button {
                                    editingHabit = habit
                                    editingTitle = habit.title
                                } label: {
                                    HStack {
                                        Text(habit.title)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Button {
                                    store.toggleHabit(habit, on: selectedDay)
                                } label: {
                                    HStack {
                                        Image(systemName: store.isHabitCompleted(habit, on: selectedDay) ? "checkmark.circle.fill" : "circle")
                                        Text(store.isHabitCompleted(habit, on: selectedDay) ? "Done" : "Tap")
                                        Spacer()
                                    }
                                    .foregroundStyle(store.isHabitCompleted(habit, on: selectedDay) ? store.accentColor : .secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .onMove(perform: store.moveHabits)

                        HStack {
                            Button {
                                showingAddHabit = true
                            } label: {
                                Text("Add Habit")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(store.accentColor)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(store.accentColor.opacity(0.75), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(minHeight: CGFloat(max(300, store.habits.count * 62)))
                    .listStyle(.plain)
                    .scrollDisabled(true)
                    .environment(\.editMode, $editMode)
                }
            }
            .padding()
            .padding(.bottom, 120)
        }
        .onAppear {
            selectedDay = Calendar.current.startOfDay(for: Date())
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $editingHabit) { habit in
            NavigationStack {
                Form {
                    Section("Edit Habit") {
                        TextField("Habit title", text: $editingTitle)
                    }
                }
                .navigationTitle("Edit")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            editingHabit = nil
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            store.updateHabitTitle(id: habit.id, title: editingTitle)
                            editingHabit = nil
                        }
                    }
                }
            }
        }
        .alert("Add Habit", isPresented: $showingAddHabit) {
            TextField("Habit name", text: $newHabitTitle)
            Button("Cancel", role: .cancel) {
                newHabitTitle = ""
            }
            Button("Add") {
                store.addHabit(newHabitTitle)
                newHabitTitle = ""
            }
        } message: {
            Text("Create your next Dream habit.")
        }
    }

    private var weekdayProgressStrip: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(weekDays, id: \.self) { day in
                Button {
                    selectedDay = Calendar.current.startOfDay(for: day)
                } label: {
                    VStack(spacing: 7) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.18))
                            .frame(width: 18, height: 56)
                            .overlay(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(store.accentColor)
                                    .frame(width: 18, height: 56 * store.progress(for: day))
                            }

                        Text(shortDayName(for: day))
                            .font(dayFont(for: day))
                            .foregroundStyle(dayColor(for: day))
                            .underline(isSelectedDay(day))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dayActionHeader: some View {
        let title = dayTitle(for: selectedDay)
        return Button {
            let today = Calendar.current.startOfDay(for: Date())
            if !Calendar.current.isDate(selectedDay, inSameDayAs: today) {
                selectedDay = today
            }
        } label: {
            Text("🗓️ \(title)")
                .font(.headline)
                .foregroundStyle(store.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func shortDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func dayTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func isSelectedDay(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDay)
    }

    private func dayColor(for date: Date) -> Color {
        if Calendar.current.isDateInToday(date) {
            return store.accentColor
        }
        return isSelectedDay(date) ? .primary : .gray
    }

    private func dayFont(for date: Date) -> Font {
        isSelectedDay(date) ? .subheadline.bold() : .subheadline
    }
}

private struct AchieveHeaderPreviewWrapper: View {
    var body: some View {
        NavigationStack {
            AchieveView()
                .environmentObject(AppStore.preview)
        }
    }
}

#Preview {
    AchieveHeaderPreviewWrapper()
}
