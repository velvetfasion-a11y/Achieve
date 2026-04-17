import SwiftUI

// MARK: - Zoom Level

private enum CalendarZoom: Int, CaseIterable {
    case month = 0
    case week  = 1
    case day   = 2

    var label: String {
        switch self {
        case .month: return "Month"
        case .week:  return "Week"
        case .day:   return "Day"
        }
    }
}

// MARK: - Design Tokens

private let calBg      = Color(hex: "#0D0D0D")
private let calGold    = Color(hex: "#C9A84C")
private let calCell    = Color(hex: "#1C1C1C")
private let calBorder  = Color(hex: "#2A2A2A")
private let calSecond  = Color(hex: "#888888")
private let calPressed = Color(hex: "#3A3A3A")

// MARK: - BossCalendarView

struct BossCalendarView: View {
    @EnvironmentObject private var store: AppStore

    @State private var zoom: CalendarZoom = .month
    @State private var displayDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showingNewEvent = false
    @State private var selectedDate: Date = Date()
    @State private var dragOffset: CGFloat = 0
    @State private var isFabRotated = false
    @State private var contentID = UUID()
    @State private var navDirection: Int = 0

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        return c
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            calBg.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                Rectangle()
                    .fill(calGold.opacity(0.25))
                    .frame(height: 0.5)

                weekdayHeaderRow
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)

                Rectangle()
                    .fill(calBorder.opacity(0.5))
                    .frame(height: 0.3)

                contentArea
                    .id(contentID)
                    .transition(slideTransition)
            }

            fabButton
                .padding(.trailing, 20)
                .padding(.bottom, 32)
        }
        .sheet(isPresented: $showingNewEvent) {
            NewEventSheet(preselectedDate: selectedDate)
                .environmentObject(store)
        }
        .gesture(magnifyGesture)
        .gesture(swipeGesture)
        .onAppear { store.requestNotificationPermission() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 0) {
            Button {
                navigate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(calGold)
                    .frame(width: 36, height: 36)
                    .background(calCell, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 6) {
                Text(periodTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .id(periodTitle)
                    .animation(.easeInOut(duration: 0.2), value: periodTitle)

                zoomPillSelector
            }

            Spacer()

            Button {
                navigate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(calGold)
                    .frame(width: 36, height: 36)
                    .background(calCell, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var zoomPillSelector: some View {
        HStack(spacing: 4) {
            ForEach(CalendarZoom.allCases, id: \.rawValue) { level in
                Button {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                        zoom = level
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(level.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(zoom == level ? Color(hex: "#0D0D0D") : calSecond)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(zoom == level ? calGold : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(calCell, in: Capsule(style: .continuous))
    }

    // MARK: - Weekday Header

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(calSecond)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var weekdaySymbols: [String] {
        let symbols = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
        return symbols
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        switch zoom {
        case .month:
            MonthGridView(
                displayDate: displayDate,
                cal: cal,
                store: store,
                onDayTap: { date in
                    selectedDate = date
                    withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                        displayDate = date
                        zoom = .week
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                },
                onAddTap: { date in
                    selectedDate = date
                    showingNewEvent = true
                }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.97)))

        case .week:
            WeekColumnsView(
                displayDate: displayDate,
                cal: cal,
                store: store,
                onDayTap: { date in
                    selectedDate = date
                    withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                        displayDate = date
                        zoom = .day
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                },
                onAddTap: { date in
                    selectedDate = date
                    showingNewEvent = true
                }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.97)))

        case .day:
            DayTimelineView(
                displayDate: displayDate,
                cal: cal,
                store: store,
                onAddTap: {
                    selectedDate = displayDate
                    showingNewEvent = true
                }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
    }

    private var slideTransition: AnyTransition {
        let direction: Double = navDirection >= 0 ? 1 : -1
        return .asymmetric(
            insertion: .move(edge: direction >= 0 ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: direction >= 0 ? .leading : .trailing).combined(with: .opacity)
        )
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            selectedDate = displayDate
            isFabRotated.toggle()
            showingNewEvent = true
        } label: {
            Image(systemName: "plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(hex: "#0D0D0D"))
                .rotationEffect(.degrees(isFabRotated ? 45 : 0))
                .frame(width: 54, height: 54)
                .background(calGold, in: Circle())
                .shadow(color: calGold.opacity(0.4), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3, bounce: 0.3), value: isFabRotated)
        .onChange(of: showingNewEvent) { _, newVal in
            if !newVal { isFabRotated = false }
        }
    }

    // MARK: - Gestures

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onEnded { value in
                withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                    if value < 0.75 {
                        let next = min(zoom.rawValue + 1, 2)
                        zoom = CalendarZoom(rawValue: next) ?? zoom
                    } else if value > 1.3 {
                        let prev = max(zoom.rawValue - 1, 0)
                        zoom = CalendarZoom(rawValue: prev) ?? zoom
                    }
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) else { return }
                if horizontal < -40 { navigate(by: 1) }
                else if horizontal > 40 { navigate(by: -1) }
            }
    }

    // MARK: - Navigation

    private func navigate(by value: Int) {
        navDirection = value
        withAnimation(.easeInOut(duration: 0.25)) {
            contentID = UUID()
            displayDate = offsetDate(by: value)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func offsetDate(by value: Int) -> Date {
        switch zoom {
        case .month: return cal.date(byAdding: .month, value: value, to: displayDate) ?? displayDate
        case .week:  return cal.date(byAdding: .weekOfYear, value: value, to: displayDate) ?? displayDate
        case .day:   return cal.date(byAdding: .day, value: value, to: displayDate) ?? displayDate
        }
    }

    private var periodTitle: String {
        let formatter = DateFormatter()
        switch zoom {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: displayDate)
        case .week:
            let days = weekDays(for: displayDate)
            let start = days.first ?? displayDate
            let end = days.last ?? displayDate
            let sf = DateFormatter()
            sf.dateFormat = "MMM d"
            let ef = DateFormatter()
            ef.dateFormat = "d, yyyy"
            return "\(sf.string(from: start)) – \(ef.string(from: end))"
        case .day:
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: displayDate)
        }
    }

    // MARK: - Calendar Utilities

    private func weekDays(for date: Date) -> [Date] {
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let start = cal.date(from: comps) ?? date
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
}

// MARK: - Month Grid View

private struct MonthGridView: View {
    let displayDate: Date
    let cal: Calendar
    let store: AppStore
    let onDayTap: (Date) -> Void
    let onAddTap: (Date) -> Void

    @State private var appeared = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)

    var body: some View {
        let days = daysInMonth(for: displayDate)
        let rows = stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0+7, days.count)]) }

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 1) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 1) {
                        ForEach(Array(row.enumerated()), id: \.offset) { colIndex, optDate in
                            Group {
                                if let date = optDate {
                                    MonthDayCell(
                                        date: date,
                                        events: store.eventsFor(date: date),
                                        cal: cal,
                                        onTap: { onDayTap(date) },
                                        onLongPress: { onAddTap(date) }
                                    )
                                } else {
                                    Color(hex: "#0D0D0D")
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(
                                .spring(duration: 0.4).delay(Double(rowIndex) * 0.05 + Double(colIndex) * 0.01),
                                value: appeared
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .onAppear { withAnimation { appeared = true } }
        .onDisappear { appeared = false }
    }

    private func daysInMonth(for date: Date) -> [Date?] {
        guard let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: date)) else { return [] }
        let weekday = cal.component(.weekday, from: firstOfMonth)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        let dayCount = cal.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30

        var days: [Date?] = Array(repeating: nil, count: offset)
        for d in 0..<dayCount {
            days.append(cal.date(byAdding: .day, value: d, to: firstOfMonth))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

// MARK: - Month Day Cell

private struct MonthDayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let cal: Calendar
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false

    private var isToday: Bool { cal.isDateInToday(date) }
    private var dayNum: String {
        let comps = cal.dateComponents([.day], from: date)
        return "\(comps.day ?? 0)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .center, spacing: 3) {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(calGold)
                            .frame(width: 22, height: 22)
                            .shadow(color: calGold.opacity(0.5), radius: 6)
                            .overlay(TodayHaloPulse())
                    }
                    Text(dayNum)
                        .font(.caption.weight(isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? Color(hex: "#0D0D0D") : .white)
                        .frame(width: 22, height: 22)
                }
                Spacer()
                if events.count > 2 {
                    Text("+\(events.count - 2)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(calGold)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(calGold.opacity(0.15), in: Capsule())
                }
            }
            .padding(.horizontal, 5)
            .padding(.top, 5)

            ForEach(events.prefix(2)) { event in
                EventPill(event: event, compact: true)
                    .padding(.horizontal, 3)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isToday ? calGold.opacity(0.08) : calCell.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isToday ? calGold.opacity(0.5) : calBorder.opacity(0.4), lineWidth: isToday ? 1 : 0.5)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(duration: 0.2), value: isPressed)
        .onTapGesture { onTap() }
        .onLongPressGesture(minimumDuration: 0.4) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onLongPress()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Today Halo Pulse

private struct TodayHaloPulse: View {
    @State private var scale: CGFloat = 1.0
    var body: some View {
        Circle()
            .stroke(calGold.opacity(0.35), lineWidth: 1)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    scale = 1.35
                }
            }
    }
}

// MARK: - Event Pill

struct EventPill: View {
    let event: CalendarEvent
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 2 : 4) {
            Text(event.category.symbol)
                .font(.system(size: compact ? 7 : 9))
                .foregroundStyle(calGold)

            Text(event.title)
                .font(.system(size: compact ? 8 : 10, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)

            if event.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: compact ? 6 : 7))
                    .foregroundStyle(calGold.opacity(0.8))
            }
        }
        .padding(.horizontal, compact ? 4 : 6)
        .padding(.vertical, compact ? 2 : 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: "#252525"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(calGold.opacity(event.isImportant ? 0.5 : 0.12), lineWidth: 0.5)
        )
        .overlay(alignment: .topTrailing) {
            if event.isImportant {
                SparkleOverlay()
                    .offset(x: 2, y: -2)
            }
        }
    }
}

// MARK: - Sparkle Overlay

struct SparkleOverlay: View {
    @State private var opacity: Double = 0.3
    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 8))
            .foregroundStyle(calGold)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    opacity = 1.0
                }
            }
    }
}

// MARK: - Week Columns View

private struct WeekColumnsView: View {
    let displayDate: Date
    let cal: Calendar
    let store: AppStore
    let onDayTap: (Date) -> Void
    let onAddTap: (Date) -> Void

    @State private var appeared = false

    private var days: [Date] {
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: displayDate)
        let start = cal.date(from: comps) ?? displayDate
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                WeekDayColumn(
                    date: day,
                    events: store.eventsFor(date: day),
                    cal: cal,
                    onTap: { onDayTap(day) },
                    onAddTap: { onAddTap(day) }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(duration: 0.4).delay(Double(idx) * 0.04), value: appeared)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear { withAnimation { appeared = true } }
        .onDisappear { appeared = false }
    }
}

private struct WeekDayColumn: View {
    let date: Date
    let events: [CalendarEvent]
    let cal: Calendar
    let onTap: () -> Void
    let onAddTap: () -> Void

    @State private var isPressed = false

    private var isToday: Bool { cal.isDateInToday(date) }

    private var dayNumber: String {
        let comps = cal.dateComponents([.day], from: date)
        return "\(comps.day ?? 0)"
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(calGold)
                        .frame(width: 28, height: 28)
                        .shadow(color: calGold.opacity(0.4), radius: 4)
                }
                Text(dayNumber)
                    .font(.callout.weight(isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? Color(hex: "#0D0D0D") : .white)
            }

            Rectangle()
                .fill(isToday ? calGold.opacity(0.3) : calBorder)
                .frame(height: 0.5)
                .padding(.vertical, 2)

            VStack(spacing: 3) {
                ForEach(events) { event in
                    EventPill(event: event, compact: true)
                }
                if events.isEmpty {
                    Text("—")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#333333"))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isToday ? calGold.opacity(0.07) : calCell.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isToday ? calGold.opacity(0.4) : calBorder.opacity(0.3), lineWidth: isToday ? 1 : 0.5)
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(duration: 0.2), value: isPressed)
        .onTapGesture { onTap() }
        .onLongPressGesture(minimumDuration: 0.4) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onAddTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Day Timeline View

private struct DayTimelineView: View {
    let displayDate: Date
    let cal: Calendar
    let store: AppStore
    let onAddTap: () -> Void

    @State private var appeared = false

    private let hourHeight: CGFloat = 64
    private let labelWidth: CGFloat = 46

    private var events: [CalendarEvent] { store.eventsFor(date: displayDate) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    hourGrid

                    ForEach(Array(events.enumerated()), id: \.element.id) { idx, event in
                        if event.duration != .allDay {
                            DayEventBlock(event: event, hourHeight: hourHeight, labelWidth: labelWidth)
                                .opacity(appeared ? 1 : 0)
                                .scaleEffect(appeared ? 1 : 0.9, anchor: .top)
                                .animation(.spring(duration: 0.4).delay(Double(idx) * 0.06), value: appeared)
                        }
                    }

                    allDayBar
                }
                .padding(.bottom, 40)
                .id("timeline")
            }
            .onAppear {
                withAnimation { appeared = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo("hour-8", anchor: .top)
                    }
                }
            }
            .onDisappear { appeared = false }
        }
    }

    @ViewBuilder
    private var allDayBar: some View {
        let allDayEvents = events.filter { $0.duration == .allDay }
        if !allDayEvents.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text("ALL DAY")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(calSecond)
                    .kerning(1)
                ForEach(allDayEvents) { event in
                    HStack(spacing: 4) {
                        Text(event.category.symbol).font(.caption2).foregroundStyle(calGold)
                        Text(event.title).font(.caption.weight(.medium)).foregroundStyle(.white).lineLimit(1)
                        if event.isImportant { SparkleOverlay() }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(calGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(calGold.opacity(0.3), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, labelWidth + 8)
            .padding(.vertical, 6)
            .background(Color(hex: "#111111"), in: Rectangle())
            .offset(y: 0)
        }
    }

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text(hourLabel(hour))
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(calSecond)
                        .frame(width: labelWidth, alignment: .trailing)
                        .padding(.top, -6)

                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(calBorder.opacity(0.4))
                            .frame(height: 0.5)
                        Spacer()
                    }
                }
                .frame(height: hourHeight)
                .id("hour-\(hour)")
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 8)
    }

    private func hourLabel(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }
}

private struct DayEventBlock: View {
    let event: CalendarEvent
    let hourHeight: CGFloat
    let labelWidth: CGFloat

    @State private var isPressed = false

    private var yOffset: CGFloat {
        CGFloat(event.startHour) * hourHeight + CGFloat(event.startMinute) / 60.0 * hourHeight + 8
    }
    private var blockHeight: CGFloat {
        max(CGFloat(event.duration.minutes) / 60.0 * hourHeight, 28)
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(calGold)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(event.category.symbol)
                        .font(.system(size: 9))
                        .foregroundStyle(calGold)
                    Text(event.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    if event.isImportant { SparkleOverlay() }
                    if event.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(calGold.opacity(0.7))
                    }
                }
                if blockHeight > 44 {
                    Text(timeLabel)
                        .font(.system(size: 9))
                        .foregroundStyle(calSecond)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(height: blockHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#1E1E1E"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(calGold.opacity(0.2), lineWidth: 0.5)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(duration: 0.15), value: isPressed)
        .padding(.leading, labelWidth + 16)
        .padding(.trailing, 8)
        .offset(y: yOffset)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }

    private var timeLabel: String {
        let endMinute = event.startMinute + event.duration.minutes
        let endHour = event.startHour + endMinute / 60
        let remMin = endMinute % 60
        return String(format: "%02d:%02d – %02d:%02d", event.startHour, event.startMinute, endHour, remMin)
    }
}

#Preview {
    BossCalendarView()
        .environmentObject(AppStore.preview)
}
