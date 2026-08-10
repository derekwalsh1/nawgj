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
    @State private var assignedJudgeIDs: Set<ObjectIdentifier> = []
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
                    HStack {
                        Button("Add All") {
                            assignAllJudges(to: session)
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                        Button("Remove All", role: .destructive) {
                            unassignAllJudges(from: session)
                        }
                        .buttonStyle(.borderless)
                    }

                    ForEach(meet.judges) { judge in
                        Button {
                            toggleJudge(judge, session: session)
                        } label: {
                            HStack {
                                Text(judge.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if assignedJudgeIDs.contains(ObjectIdentifier(judge)) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                .id(refreshToken)
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
        .onAppear {
            syncAssignedJudgeIDs()
            refreshToken = UUID()
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

    private var navigationTitle: String {
        switch mode {
        case .add: return "Add Session"
        case .edit: return "Session Details"
        }
    }

    private var workingSession: Session {
        Session(name: name, startTime: startTime, endTime: endTime, breaks: breaks, breakTimeInMins: breakTimeInMins)
    }

    private func isAssigned(_ judge: Judge, to session: Session) -> Bool {
        judge.fees.contains(where: { $0.getSessionUUID() == session.getUUID() })
    }

    private func syncAssignedJudgeIDs() {
        guard case .edit(let session) = mode else {
            assignedJudgeIDs = []
            return
        }

        assignedJudgeIDs = Set(
            meet.judges.compactMap { judge in
                isAssigned(judge, to: session) ? ObjectIdentifier(judge) : nil
            }
        )
    }

    private func toggleJudge(_ judge: Judge, session: Session) {
        if isAssigned(judge, to: session) {
            MeetListManager.GetInstance().unassignJudge(judge, from: session)
            assignedJudgeIDs.remove(ObjectIdentifier(judge))
        } else {
            let result = MeetListManager.GetInstance().assignJudge(judge, to: session, in: day)
            if case .failure(let error) = result {
                switch error {
                case .overlappingSession(let conflict):
                    overlapMessage = "\(judge.name) is already assigned to \"\(conflict.name)\", which overlaps this session's time."
                    showOverlapAlert = true
                }
            } else {
                assignedJudgeIDs.insert(ObjectIdentifier(judge))
            }
        }
        refreshToken = UUID()
    }

    private func assignAllJudges(to session: Session) {
        var conflicts: [String] = []

        for judge in meet.judges where !isAssigned(judge, to: session) {
            let result = MeetListManager.GetInstance().assignJudge(judge, to: session, in: day)
            if case .failure(let error) = result {
                switch error {
                case .overlappingSession(let conflict):
                    conflicts.append("\(judge.name) with \"\(conflict.name)\"")
                }
            } else {
                assignedJudgeIDs.insert(ObjectIdentifier(judge))
            }
        }

        if !conflicts.isEmpty {
            overlapMessage = "Could not assign:\n" + conflicts.joined(separator: "\n")
            showOverlapAlert = true
        }

        refreshToken = UUID()
    }

    private func unassignAllJudges(from session: Session) {
        for judge in meet.judges where isAssigned(judge, to: session) {
            MeetListManager.GetInstance().unassignJudge(judge, from: session)
            assignedJudgeIDs.remove(ObjectIdentifier(judge))
        }
        refreshToken = UUID()
    }

    private func save() {
        guard case .add = mode else { return }
        let sessionName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Session.DEFAULT_NAME : name
        let newSession = Session(name: sessionName, startTime: startTime, endTime: endTime, breaks: breaks, breakTimeInMins: breakTimeInMins)
        MeetListManager.GetInstance().addSession(session: newSession, to: day)
    }

    private func saveLiveIfEditing() {
        guard case .edit(let session) = mode else { return }
        let sessionName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Session.DEFAULT_NAME : name

        let candidate = Session(
            name: sessionName,
            startTime: startTime,
            endTime: endTime,
            breaks: breaks,
            breakTimeInMins: breakTimeInMins,
            uuid: session.getUUID()
        )

        let validation = MeetListManager.GetInstance().validateSessionChange(candidate, in: day)
        if case .failure(let error) = validation {
            name = session.name
            startTime = session.startTime
            endTime = session.endTime
            breaks = session.breaks
            breakTimeInMins = session.breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS

            switch error {
            case .overlappingAssignments(let conflicts):
                let lines = conflicts.map { conflict in
                    "\(conflict.judgeName) with \"\(conflict.conflictingSessionName)\""
                }
                overlapMessage = "This change would double-book:\n" + lines.joined(separator: "\n")
            }
            showOverlapAlert = true
            return
        }

        session.name = sessionName
        session.startTime = startTime
        session.endTime = endTime
        session.breaks = breaks
        session.breakTimeInMins = breakTimeInMins
        MeetListManager.GetInstance().sessionChanged(session, in: day)
    }
}
