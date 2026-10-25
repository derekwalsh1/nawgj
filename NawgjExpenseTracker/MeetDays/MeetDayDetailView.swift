//
//  MeetDayDetailView.swift
//  NawgjExpenceTracker
//
//  SwiftUI screen for a single Meet Day: the day's date, plus (in edit
//  mode) an always-visible list of that day's Sessions - the concurrent
//  judging areas that can run on the same calendar day (see
//  .github/SESSIONS_FEATURE_PLAN.md). Pushed directly from the "Day
//  Summaries" tiles on `MeetDetailView` (there's no separate "Meet Days"
//  list screen).
//
//  Formerly hosted the day's own start/end/breaks editor directly; that
//  editing now lives in `SessionDetailView`, pushed from this screen's
//  sessions list, since a day's billable time is the sum of its sessions.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI

struct MeetDayDetailView: View {

    enum Mode {
        /// Adding a new day to `Meet`. Defaults mirror the old screen's
        /// add-mode construction: reuse the last existing day's date+1 and
        /// its first session's start/end time if there is one, otherwise
        /// build a 7am-5pm default session from the meet's start date.
        case add(Meet)
        /// Editing an existing meet day in place.
        case edit(MeetDay)
    }

    let mode: Mode
    let meet: Meet
    let pushViewController: (UIViewController) -> Void
    let popViewController: () -> Void
    let onFinish: () -> Void

    @State private var meetDate: Date
    @State private var defaultSessionStart: Date
    @State private var defaultSessionEnd: Date
    @State private var sessions: [Session] = []

    @State private var showDuplicateDateAlert = false
    @State private var duplicateDateMessage = ""
    @State private var showLastSessionAlert = false

    /// Bumped whenever session data changes (added/edited/deleted) or this
    /// screen reappears, forcing the Sessions/Summary sections below - which
    /// read directly from `day.sessions` rather than diffable `@State` - to
    /// fully redraw. Plain array reassignment in `refreshSessions()` isn't
    /// always enough since the underlying `Session` objects are mutated in
    /// place (same references, same ids) by `SessionDetailView`.
    @State private var refreshToken = UUID()

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter
    }()

    private var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    init(mode: Mode, meet: Meet, pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void, onFinish: @escaping () -> Void) {
        self.mode = mode
        self.meet = meet
        self.pushViewController = pushViewController
        self.popViewController = popViewController
        self.onFinish = onFinish

        switch mode {
        case .add(let meet):
            if let lastDay = meet.days.last, let lastSession = lastDay.sessions.first {
                _meetDate = State(initialValue: lastDay.meetDate.addingTimeInterval(24 * 60 * 60))
                _defaultSessionStart = State(initialValue: lastSession.startTime)
                _defaultSessionEnd = State(initialValue: lastSession.endTime)
            } else {
                let units: Set<Calendar.Component> = [.year, .month, .day, .hour]
                var components = Calendar.current.dateComponents(units, from: Date())
                components.hour = 7
                let start = Calendar.current.date(from: components) ?? Date()
                components.hour = 17
                let end = Calendar.current.date(from: components) ?? Date()
                _meetDate = State(initialValue: meet.startDate)
                _defaultSessionStart = State(initialValue: start)
                _defaultSessionEnd = State(initialValue: end)
            }
        case .edit(let existingDay):
            _meetDate = State(initialValue: existingDay.meetDate)
            _defaultSessionStart = State(initialValue: existingDay.meetDate)
            _defaultSessionEnd = State(initialValue: existingDay.meetDate)
        }
    }

    var body: some View {
        Group {
            if case .add = mode {
                formContent
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Add") {
                                save()
                                onFinish()
                            }
                        }
                    }
            } else {
                // Edit mode: changes save live as fields change (see
                // checkForDateCollision), so there's no Cancel/Done - the
                // standard back button is all that's needed. An Edit
                // button is still needed to reveal the Sessions list's
                // drag-to-reorder handles.
                formContent
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                    }
            }
        }
    }

    private var formContent: some View {
        Form {
            Section {
                Text(promptText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section("Date") {
                DatePicker("Date", selection: $meetDate, in: meetDateRange, displayedComponents: .date)
            }

            if case .edit = mode {
                if sessions.count > 1 {
                    Section("Session Timeline") {
                        DayTimelineView(sessions: sessions, colorFor: sessionColor(for:), onSelect: editSession)
                            .padding(.vertical, 4)
                            .listRowBackground(Color(.systemBackground))
                    }
                }

                Section("Sessions") {
                    ForEach(sessions) { session in
                        Button {
                            editSession(session)
                        } label: {
                            sessionRow(for: session)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(sessions.count > 1 ? sessionColor(for: session) : Color(.secondarySystemGroupedBackground))
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove(perform: moveSession)

                    Button {
                        addSession()
                    } label: {
                        Label("Add Session", systemImage: "plus.circle.fill")
                    }
                }

                Section("Summary") {
                    summaryRow(title: "Total Time", hours: dayTotalTime)
                }

                // A single day-wide "Billable Time" isn't meaningful once a
                // day has more than one session, since the per-judge,
                // per-day minimum billing rule means two judges on the same
                // day can bill different totals. Show each assigned judge's
                // actual billable total for this day instead.
                if !judgeBillableBreakdown.isEmpty {
                    Section {
                        ForEach(judgeBillableBreakdown) { entry in
                            summaryRow(title: entry.name, hours: entry.hours)
                        }
                    } header: {
                        Text("Billable Time by Judge")
                    } footer: {
                        Text("Billable hours can differ from judge to judge based on which sessions they worked and the 3-hour daily minimum.")
                    }
                }
            }
        }
        .id(refreshToken)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: meetDate) { newValue in
            checkForDateCollision(newValue)
        }
        .alert(duplicateDateMessage, isPresented: $showDuplicateDateAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("A meet day must have at least one session.", isPresented: $showLastSessionAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            refreshSessions()
            refreshToken = UUID()
        }
    }

    // MARK: Rows

    /// Light pastel colors assigned to sessions by their order in `sessions`
    /// (not by lane/start time, so a session keeps its color as others are
    /// added/removed/reordered). Shared by the timeline bars and the
    /// matching Sessions list row backgrounds so the two can be visually
    /// correlated at a glance.
    private static let sessionColors: [Color] = [
        Color(red: 0.80, green: 0.88, blue: 1.00),
        Color(red: 0.80, green: 0.95, blue: 0.80),
        Color(red: 1.00, green: 0.90, blue: 0.75),
        Color(red: 0.90, green: 0.83, blue: 1.00),
        Color(red: 0.78, green: 0.93, blue: 0.93),
        Color(red: 1.00, green: 0.85, blue: 0.90),
    ]

    private func sessionColor(for session: Session) -> Color {
        let index = sessions.firstIndex(where: { $0.id == session.id }) ?? 0
        return Self.sessionColors[index % Self.sessionColors.count]
    }

    @ViewBuilder
    private func sessionRow(for session: Session) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(timeFormatter.string(from: session.startTime)) – \(timeFormatter.string(from: session.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(judgeCountText(for: session))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.2f Billable Hours", session.totalBillableTimeInHours()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func judgeCountText(for session: Session) -> String {
        let judgeCount = meet.judges.filter { judge in
            judge.fees.contains(where: { $0.getSessionUUID() == session.getUUID() })
        }.count
        return judgeCount == 1 ? "1 Judge Assigned" : "\(judgeCount) Judges Assigned"
    }

    @ViewBuilder
    private func summaryRow(title: String, hours: Float) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(String(format: "%.2f hours", hours))
                .foregroundColor(.secondary)
        }
    }

    // MARK: Derived display text

    private var navigationTitle: String {
        switch mode {
        case .add: return "Add Meet Day"
        case .edit: return "Meet Day Details"
        }
    }

    private var promptText: String {
        switch mode {
        case .add:
            return "You are adding a new day to the \"\(meet.name)\" meet"
        case .edit:
            return "Manage this day's sessions below - each is billed separately per judge assigned to it."
        }
    }

    private var meetDateRange: PartialRangeFrom<Date> {
        if case .edit = mode {
            return meet.startDate...
        }
        return Date.distantPast...
    }

    private var dayTotalTime: Float {
        guard case .edit(let day) = mode else { return 0 }
        return day.totalTimeInHours()
    }

    private struct JudgeDayBillable: Identifiable {
        let id: ObjectIdentifier
        let name: String
        let hours: Float
    }

    /// Each judge assigned to this day, with their own billable total for
    /// it (summed across whichever of the day's sessions they worked,
    /// already topped up to the per-judge daily minimum by
    /// `Meet.recomputeBillableHours`). Judges with no non-excluded fee on
    /// this day are omitted.
    private var judgeBillableBreakdown: [JudgeDayBillable] {
        guard case .edit(let day) = mode else { return [] }
        let dayUUID = day.getUUID()
        return meet.judges.compactMap { judge -> JudgeDayBillable? in
            let dayFees = judge.fees.filter { $0.getMeetDayUUID() == dayUUID && !($0.exclude ?? false) }
            guard !dayFees.isEmpty else { return nil }
            let total = dayFees.reduce(Float(0)) { $0 + $1.hours }
            return JudgeDayBillable(id: ObjectIdentifier(judge), name: judge.name, hours: total)
        }.sorted { $0.name < $1.name }
    }

    // MARK: Validation
    //
    // Mirrors the old screen's date-change handler: reverts the date and
    // shows an alert if it collides with another existing day in the meet
    // (same-day comparison, excluding the day being edited). In edit mode,
    // a non-colliding change is saved immediately (live editing - see the
    // Cancel/Done removal note on `body`).

    private func checkForDateCollision(_ newDate: Date) {
        let editingDay: MeetDay? = { if case .edit(let day) = mode { return day }; return nil }()
        let collides = meet.days.contains { candidate in
            if let editingDay, candidate === editingDay { return false }
            return Calendar.current.isDate(candidate.meetDate, inSameDayAs: newDate)
        }

        if collides {
            duplicateDateMessage = "\(dateFormatter.string(from: newDate)) is already in use"
            showDuplicateDateAlert = true
            meetDate = editingDay?.meetDate ?? meet.startDate
            return
        }

        if let editingDay {
            editingDay.meetDate = newDate
            MeetListManager.GetInstance().updateSelectedMeetDayWith(meetDay: editingDay)
        }
    }

    // MARK: Data

    private func refreshSessions() {
        guard case .edit(let day) = mode else { return }
        sessions = day.sessions
        refreshToken = UUID()
    }

    private func moveSession(from source: IndexSet, to destination: Int) {
        guard case .edit(let day) = mode else { return }
        sessions.move(fromOffsets: source, toOffset: destination)
        day.sessions = sessions
        MeetListManager.GetInstance().updateSelectedMeetDayWith(meetDay: day)
        refreshToken = UUID()
    }

    // MARK: Actions

    private func addSession() {
        guard case .edit(let day) = mode else { return }
        let detailView = SessionDetailView(mode: .add, meet: meet, day: day, pushViewController: pushViewController, popViewController: popViewController) {
            popViewController()
            refreshSessions()
        }
        pushViewController(UIHostingController(rootView: detailView))
    }

    private func editSession(_ session: Session) {
        guard case .edit(let day) = mode else { return }
        let detailView = SessionDetailView(mode: .edit(session), meet: meet, day: day, pushViewController: pushViewController, popViewController: popViewController) {
            popViewController()
            refreshSessions()
        }
        pushViewController(UIHostingController(rootView: detailView))
    }

    private func deleteSession(_ session: Session) {
        guard case .edit(let day) = mode else { return }
        if MeetListManager.GetInstance().removeSession(session, from: day) {
            refreshSessions()
        } else {
            showLastSessionAlert = true
        }
    }

    // MARK: Save
    //
    // Only reachable in `.add` mode - `.edit` mode saves live via
    // `checkForDateCollision`/`SessionDetailView`.

    private func save() {
        guard case .add = mode else { return }
        let newDay = MeetDay(meetDate: meetDate, startTime: defaultSessionStart, endTime: defaultSessionEnd, breaks: 0, breakTime: MeetDay.DEFAULT_BREAK_TIME_MINS, id: UUID().uuidString)
        MeetListManager.GetInstance().addMeetDay(meetDay: newDay)
    }
}

// MARK: - DayTimelineView

/// Each of a day's sessions as its own row - name on the left, then a
/// compact bar showing where it falls across the full day (proportionally
/// scaled - exact times are shown in the Sessions list below instead).
/// Drawn in the same pastel color as its row in the Sessions list below
/// (via `colorFor`) so the two can be visually matched up. Tapping a row
/// opens that session (via `onSelect`).
private struct DayTimelineView: View {
    let sessions: [Session]
    let colorFor: (Session) -> Color
    let onSelect: (Session) -> Void

    private static let laneHeight: CGFloat = 44
    private static let laneSpacing: CGFloat = 6
    private static let labelWidth: CGFloat = 90

    private var dayStart: Date {
        sessions.map { $0.startTime }.min() ?? Date()
    }

    private var dayEnd: Date {
        sessions.map { $0.endTime }.max() ?? Date()
    }

    private var totalSeconds: TimeInterval {
        max(dayEnd.timeIntervalSince(dayStart), 1)
    }

    private func fraction(for date: Date) -> CGFloat {
        CGFloat(date.timeIntervalSince(dayStart) / totalSeconds)
    }

    /// Each session in chronological order, one per row.
    private var orderedSessions: [Session] {
        sessions.sorted(by: { $0.startTime < $1.startTime })
    }

    var body: some View {
        if sessions.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: Self.laneSpacing) {
                ForEach(orderedSessions) { session in
                    HStack(spacing: 8) {
                        Text(session.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(width: Self.labelWidth, alignment: .leading)

                        GeometryReader { geo in
                            let width = geo.size.width
                            let startX = fraction(for: session.startTime) * width
                            let endX = fraction(for: session.endTime) * width
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorFor(session))
                                .frame(width: max(endX - startX, 3), height: Self.laneHeight)
                                .offset(x: startX)
                        }
                        .frame(height: Self.laneHeight)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(session)
                    }
                }
            }
        }
    }
}



