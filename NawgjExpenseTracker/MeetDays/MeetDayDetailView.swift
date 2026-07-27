//
//  MeetDayDetailView.swift
//  NawgjExpenceTracker
//
//  SwiftUI screen for a single Meet Day: the day's date, plus (in edit
//  mode) an always-visible list of that day's Sessions - the concurrent
//  judging areas that can run on the same calendar day (see
//  .github/SESSIONS_FEATURE_PLAN.md). Pushed from MeetDayListView.
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
                Section("Sessions") {
                    ForEach(sessions) { session in
                        Button {
                            editSession(session)
                        } label: {
                            sessionRow(for: session)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }

                Section("Summary") {
                    summaryRow(title: "Total Time", hours: dayTotalTime)
                    summaryRow(title: "Billable Time", hours: dayBillableTime)
                }
            }
        }
        .id(refreshToken)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { onFinish() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if case .edit = mode {
                    Button {
                        addSession()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(saveButtonTitle) {
                    save()
                    onFinish()
                }
            }
        }
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

    private var saveButtonTitle: String {
        switch mode {
        case .add: return "Add"
        case .edit: return "Done"
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

    private var dayBillableTime: Float {
        guard case .edit(let day) = mode else { return 0 }
        return day.totalBillableTimeInHours()
    }

    // MARK: Validation
    //
    // Mirrors the old screen's date-change handler: reverts the date and
    // shows an alert if it collides with another existing day in the meet
    // (same-day comparison, excluding the day being edited).

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
        }
    }

    // MARK: Data

    private func refreshSessions() {
        guard case .edit(let day) = mode else { return }
        sessions = day.sessions
        refreshToken = UUID()
    }

    // MARK: Actions

    private func addSession() {
        guard case .edit(let day) = mode else { return }
        let detailView = SessionDetailView(mode: .add, meet: meet, day: day) {
            popViewController()
            refreshSessions()
        }
        pushViewController(UIHostingController(rootView: detailView))
    }

    private func editSession(_ session: Session) {
        guard case .edit(let day) = mode else { return }
        let detailView = SessionDetailView(mode: .edit(session), meet: meet, day: day) {
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

    private func save() {
        switch mode {
        case .add:
            let newDay = MeetDay(meetDate: meetDate, startTime: defaultSessionStart, endTime: defaultSessionEnd, breaks: 0, breakTime: MeetDay.DEFAULT_BREAK_TIME_MINS, id: UUID().uuidString)
            MeetListManager.GetInstance().addMeetDay(meetDay: newDay)
        case .edit(let existingDay):
            existingDay.meetDate = meetDate
            MeetListManager.GetInstance().updateSelectedMeetDayWith(meetDay: existingDay)
        }
    }
}
