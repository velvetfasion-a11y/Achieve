import SwiftUI

struct AchieveView: View {
    @EnvironmentObject private var store: AppStore
    @State private var newHabit = ""

    private let background = Color(hex: "#F8F4EB")
    private let suggestionColumns = [GridItem(.adaptive(minimum: 130), spacing: 8)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    RadialProgressView(percentage: store.completionRate, accent: store.accentColor)
                        .padding(.top, 8)

                    Text("Achieve")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(store.accentColor)

                    if store.habits.isEmpty {
                        VStack(spacing: 8) {
                            Text("Add your first habit")
                                .font(.system(size: 27, weight: .bold, design: .rounded))
                            Text("This is where your high frequency lives")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.habits) { habit in
                                Button {
                                    store.toggleHabit(habit)
                                } label: {
                                    HStack(spacing: 14) {
                                        Circle()
                                            .fill(habit.completed ? store.accentColor : Color.gray.opacity(0.3))
                                            .frame(width: 28, height: 28)

                                        Text(habit.title)
                                            .font(.body)
                                            .strikethrough(habit.completed)
                                            .foregroundStyle(.primary)

                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        TextField("New habit...", text: $newHabit)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                            .submitLabel(.done)
                            .onSubmit {
                                store.addHabit(newHabit)
                                newHabit = ""
                            }

                        Button {
                            store.addHabit(newHabit)
                            newHabit = ""
                        } label: {
                            Text("+")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(store.accentColor, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)

                    LazyVGrid(columns: suggestionColumns, alignment: .leading, spacing: 8) {
                        ForEach(store.habitSuggestions, id: \.self) { suggestion in
                            Button {
                                store.addHabit(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.callout)
                                    .foregroundStyle(store.accentColor)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .frame(maxWidth: .infinity)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(store.accentColor, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(background.ignoresSafeArea())
            .navigationTitle("Today's Frequency")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AchieveView()
        .environmentObject(AppStore.preview)
}
