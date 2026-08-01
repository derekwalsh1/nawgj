//
//  SessionDetailView.swift
//  NawgjExpenseTracker
//
//  Add/edit screen for a single `Session` within a `MeetDay`, pushed from
//  `MeetDayDetailView`'s sessions list. Reuses the same time/breaks editing
//  UI the old `MeetDayDetailView` used to host directly, plus (in edit mode)
//  a "Judges Working This Session" checklist mirroring the existing
//  `AddJudgesToMeetView` interaction pattern.
//
//  See .github/SESSIONS_FEATURE_PLAN.md for the full feature plan.
//

import SwiftUI

struct SessionDetailView: View {

    enum Mode {
        /// Adding a new session to `day`. Defaults to starting right after
        /// the day's last session (if any), otherwise a 7am-5pm default.
        case add
        /// Editing an existing session in place.
        case edit(Session)
    }

    let mode: Mode
    let meet: Meet
    let day: MeetDay
    let onFinish: () -> Void

    @State private var name: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var breaks: Int
    @State private var breakTimeInMins: Int

    @State private var showOverlapAlert = false
    @State private var overlapMessage = ""

    /// In `.add` mode, judges are auto-assigned to the new session by
    /// default (mirrors `Meet.addSession`'s behavior) - this tracks which
    /// ones the user has opted the new session *out* of via the checklist
    /// below, applied after the session/fees are created in `save()`.
    @State private var excludedJudgeIDs: Set<ObjectIdentifier> = []

    /// Bumped after any judge assignment change so the checklist section -
    /// which reads directly from `meet.judges`/`judge.fees` rather than
    /// local `@State` - redraws.
    @State private var refreshToken = UUID()

    init(mode: Mode, meet: Meet, day: MeetDay, onFinish: @escaping () -> Void) {
        self.mode = mode
        self.meet = meet
        self.day = day
        self.onFinish = onFinish

        switch mode {
        case .add:
            if let lastSession = day.sessions.max(by: { $0.endTime < $1.endTime }) {
                _name = State(initialValue: "Session \(day.sessions.count + 1)")
                _startTime = State(initialValue: lastSession.endTime)
                _endTime = State(initialValue: lastSession.endTime.addingTimeInterval(2 * 60 * 60))
            } else {
                let units: Set<Calendar.Component> = [.year, .month, .day]
                var components = Calendar.current.dateComponents(units, from: day.meetDate)
                components.hour = 7
                let start = Calendar.current.date(from: components) ?? day.meetDate
                components.hour = 17
                let end = Calendar.current.date(from: components) ?? day.meetDate
                _name = State(initialValue: Session.DEFAULT_NAME)
                _startTime = State(initialValue: start)
                _endTime = State(initialValue: end)
            }
            _breaks = State(initialValue: 0)
            _breakTimeInMins = State(initialValue: MeetDay.DEFAULT_BREAK_TIME_MINS)
        case .edit(let session):
            _name = State(initialValue: session.name)
            _startTime = State(initialValue: session.startTime)
            _endTime = State(initialValue: session.endTime)
            _breaks = State(initialValue: session.breaks)
            _breakTimeInMins = State(initialValue: session.breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS)
        }
    }

    var body: some View {
        Group {
            if case .add = mode {
                // Add mode: no Cancel - the standard back button discards
                // without saving, and "Add" saves and goes back.
                formContent
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                save()
                                onFinish()
                            }
                        }
                    }
            } else {
                // Edit mode: changes save live as fields change (see
                // saveLiveIfEditing()), so there's no Cancel/Done - the
                // standard back button is all that's needed.
                formContent
            }
        }
    }

    private var formContent: some View {
        Form {
            Section("Name") {
                TextField("Session Name", text: $name)
            }

            Section("Time") {
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $endTime, in: startTime..., displayedComponents: .hourAndMinute)
            }

            Section("Breaks") {
                Picker("Number of Breaks", selection: $breaks) {
                    ForEach(0..<6) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Break Time")
                        Spacer()
                        Text("\(breakTimeInMins) mins")
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(breakTimeInMins) },
                            set: { breakTimeInMins = Int($0) }
                        ),
                        in: 0...60,
                        step: 1
                    )
                }
            }

            Section("Summary") {
                summaryRow(title: "Total Time", hours: workingSession.totalTimeInHours())
                summaryRow(title: "Break Time", hours: workingSession.breakTimeInHours())
                summaryRow(title: "Billable Time", hours: workingSession.totalBillableTimeInHours())
            }

            if case .edit(let session) = mode {
                Section("Judges Working This Session") {
                    ForEach(meet.judges) { judge in
                        Button {
                            toggleJudge(judge, session: session)
                        } label: {
                            HStack {
                                Text(judge.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if isAssigned(judge, to: session) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                .id(refreshToken)
            } else if !meet.judges.isEmpty {
                Section {
                    ForEach(meet.judges) { judge in
                        Button {
                            toggleNewSessionJudge(judge)
                        } label: {
                            HStack {
                                Text(judge.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if !excludedJudgeIDs.contains(ObjectIdentifier(judge)) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Judges Working This Session")
                } footer: {
                    Text("Every judge is included by default. Uncheck anyone who isn't working this session.")
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: name) { _ in saveLiveIfEditing() }
        .onChange(of: startTime) { newValue in
            if newValue >= endTime {
                endTime = newValue.addingTimeInterval(15 * 60)
            }
            saveLiveIfEditing()
        }
        .onChange(of: endTime) { _ in saveLiveIfEditing() }
        .onChange(of: breaks) { _ in saveLiveIfEditing() }
        .onChange(of: breakTimeInMins) { _ in saveLiveIfEditing() }
        .alert(overlapMessage, isPresented: $showOverlapAlert) {
            Button("OK", role: .cancel) {}
        }
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
        case .add: return "Add Session"
        case .edit: return "Session Details"
        }
    }

    /// A throwaway `Session` built from the current in-progress field
    /// values, used only to read the shared billing calculations.
    private var workingSession: Session {
        Session(name: name, startTime: startTime, endTime: endTime, breaks: breaks, breakTimeInMins: breakTimeInMins)
    }

    // MARK: Judge checklist

    private func isAssigned(_ judge: Judge, to session: Session) -> Bool {
        judge.fees.contains(where: { $0.getSessionUUID() == session.getUUID() })
    }

    private func toggleJudge(_ judge: Judge, session: Session) {
        if isAssigned(judge, to: session) {
            MeetListManager.GetInstance().unassignJudge(judge, from: session)
        } else {
            let result = MeetListManager.GetInstance().assignJudge(judge, to: session, in: day)
            if case .failure(let error) = result {
                switch error {
                case .overlappingSession(let conflict):
                    overlapMessage = "\(judge.name) is already assigned to \"\(conflict.name)\", which overlaps this session's time."
                    showOverlapAlert = true
                }
            }
        }
        refreshToken = UUID()
    }

    /// Toggles a judge's inclusion in a brand-new (not-yet-created) session.
    private func toggleNewSessionJudge(_ judge: Judge) {
        let id = ObjectIdentifier(judge)
        if excludedJudgeIDs.contains(id) {
            excludedJudgeIDs.remove(id)
        } else {
            excludedJudgeIDs.insert(id)
        }
    }

    // MARK: Save

    private func save() {
        guard case .add = mode else { return }
        let sessionName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Session.DEFAULT_NAME : name
        let newSession = Session(name: sessionName, startTime: startTime, endTime: endTime, breaks: breaks, breakTimeInMins: breakTimeInMins)
        MeetListManager.GetInstance().addSession(session: newSession, to: day)
        for judge in meet.judges where excludedJudgeIDs.contains(ObjectIdentifier(judge)) {
            MeetListManager.GetInstance().unassignJudge(judge, from: newSession)
        }
    }

    /// Saves field edits immediately as they change (edit mode only) -
    /// mirrors `MeetDayDetailView`'s `checkForDateCollision` live-save
    /// pattern, since there's no Done button in edit mode anymore.
    private func saveLiveIfEditing() {
        guard case .edit(let session) = mode else { return }
        let sessionName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Session.DEFAULT_NAME : name
        session.name = sessionName
        session.startTime = startTime
        session.endTime = endTime
        session.breaks = breaks
        session.breakTimeInMins = breakTimeInMins
        MeetListManager.GetInstance().sessionChanged(session, in: day)
    }
}
