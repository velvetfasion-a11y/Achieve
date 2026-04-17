import SwiftUI

struct NewEventSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var preselectedDate: Date = Date()

    @State private var title = ""
    @State private var date = Date()
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var duration: EventDuration = .oneHour
    @State private var category: EventCategory = .work
    @State private var isImportant = false
    @State private var isPinned = false
    @State private var appeared = false

    private let minutes = [0, 15, 30, 45]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D0D").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        titleField
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.spring(duration: 0.4).delay(0.05), value: appeared)

                        dateRow
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.spring(duration: 0.4).delay(0.1), value: appeared)

                        startTimePicker
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.spring(duration: 0.4).delay(0.15), value: appeared)

                        categoryRow
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.spring(duration: 0.4).delay(0.2), value: appeared)

                        durationRow
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.spring(duration: 0.4).delay(0.25), value: appeared)

                        flagsRow
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.spring(duration: 0.4).delay(0.3), value: appeared)

                        addButton
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(.spring(duration: 0.45).delay(0.35), value: appeared)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#888888"))
                }
            }
            .onAppear {
                date = Calendar.current.startOfDay(for: preselectedDate)
                withAnimation { appeared = true }
            }
        }
    }

    // MARK: - Subviews

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("EVENT TITLE")
            TextField("", text: $title, prompt: Text("What's happening...").foregroundStyle(Color(hex: "#555555")))
                .font(.title3.weight(.medium))
                .foregroundStyle(.white)
                .tint(Color(hex: "#C9A84C"))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var dateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("DATE")
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Color(hex: "#C9A84C"))
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(Color(hex: "#C9A84C"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var startTimePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("START TIME")
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("HOUR").font(.caption2).foregroundStyle(Color(hex: "#888888"))
                    Picker("", selection: $startHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d", h)).tag(h)
                                .foregroundStyle(.white)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
                }

                Text(":")
                    .font(.title2.bold())
                    .foregroundStyle(Color(hex: "#C9A84C"))
                    .padding(.horizontal, 4)
                    .padding(.top, 20)

                VStack(spacing: 2) {
                    Text("MIN").font(.caption2).foregroundStyle(Color(hex: "#888888"))
                    Picker("", selection: $startMinute) {
                        ForEach(minutes, id: \.self) { m in
                            Text(String(format: "%02d", m)).tag(m)
                                .foregroundStyle(.white)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
                }
            }
            .frame(height: 140)
            .padding(.horizontal, 12)
            .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("CATEGORY")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventCategory.allCases) { cat in
                        categoryChip(cat)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func categoryChip(_ cat: EventCategory) -> some View {
        let selected = category == cat
        return Button {
            withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                category = cat
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 5) {
                Text(cat.symbol)
                    .font(.system(size: 11))
                Text(cat.title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(selected ? Color(hex: "#0D0D0D") : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? Color(hex: "#C9A84C") : Color(hex: "#2A2A2A"))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(selected ? Color.clear : Color(hex: "#3A3A3A"), lineWidth: 1)
            )
            .scaleEffect(selected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var durationRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("DURATION")
            HStack(spacing: 8) {
                ForEach(EventDuration.allCases) { dur in
                    durationChip(dur)
                }
            }
        }
    }

    private func durationChip(_ dur: EventDuration) -> some View {
        let selected = duration == dur
        return Button {
            withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                duration = dur
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(dur.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color(hex: "#0D0D0D") : .white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? Color(hex: "#C9A84C") : Color(hex: "#2A2A2A"))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(selected ? Color.clear : Color(hex: "#3A3A3A"), lineWidth: 1)
                )
                .scaleEffect(selected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var flagsRow: some View {
        HStack(spacing: 12) {
            flagToggle(
                icon: "star.fill",
                label: "Important",
                isOn: $isImportant
            )
            flagToggle(
                icon: "pin.fill",
                label: "Pinned",
                isOn: $isPinned
            )
        }
    }

    private func flagToggle(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                isOn.wrappedValue.toggle()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(isOn.wrappedValue ? Color(hex: "#C9A84C") : Color(hex: "#555555"))
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isOn.wrappedValue ? .white : Color(hex: "#666666"))
                Spacer()
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isOn.wrappedValue ? Color(hex: "#C9A84C") : Color(hex: "#2A2A2A"))
                    .frame(width: 36, height: 20)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 14, height: 14)
                            .offset(x: isOn.wrappedValue ? 8 : -8)
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        let canAdd = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return PressScaleButton(disabled: !canAdd) {
            let event = CalendarEvent(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                startHour: startHour,
                startMinute: startMinute,
                duration: duration,
                category: category,
                isImportant: isImportant,
                isPinned: isPinned
            )
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            store.addEvent(event)
            dismiss()
        } label: {
            Text("Add Event")
                .font(.body.weight(.semibold))
                .foregroundStyle(canAdd ? Color(hex: "#0D0D0D") : Color(hex: "#555555"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(canAdd ? Color(hex: "#C9A84C") : Color(hex: "#2A2A2A"))
                )
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color(hex: "#888888"))
            .kerning(1.2)
    }
}

// MARK: - Press Scale Button

struct PressScaleButton<Label: View>: View {
    var disabled: Bool = false
    let action: () -> Void
    @ViewBuilder let label: Label
    @State private var isPressed = false

    var body: some View {
        label
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(duration: 0.2), value: isPressed)
            .onTapGesture {
                guard !disabled else { return }
                action()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !disabled { isPressed = true } }
                    .onEnded { _ in isPressed = false }
            )
            .opacity(disabled ? 0.5 : 1.0)
    }
}

#Preview {
    NewEventSheet()
        .environmentObject(AppStore.preview)
}
