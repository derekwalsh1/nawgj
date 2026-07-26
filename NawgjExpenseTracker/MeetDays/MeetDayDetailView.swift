//
//  MeetDayDetailView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven "Meet Day Details" /
//  "Add Meet Day" screen (formerly MeetDayDetailViewController), pushed
//  from MeetDayListView. Uses a Mode enum (add/edit) following the same
//  convention as CreateJudgeView, and plain native SwiftUI DatePicker/
//  Picker/Slider controls instead of the old expand/collapse-row pickers.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI

struct MeetDayDetailView: View {

    enum Mode {
        /// Adding a new day to `Meet`. Defaults mirror the old screen's
        /// add-mode construction (see MODERNIZATION_BACKLOG.md research
        /// notes): reuse the last existing day's date+1/start/end time if
        /// there is one, otherwise build a 7am-5pm day from the meet's
        /// start date.
        case add(Meet)
        /// Editing an existing meet day in place.
        case edit(MeetDay)
    }

    let mode: Mode
    let meet: Meet
    let onFinish: () -> Void

    @State private var meetDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var breaks: Int
    @State private var breakTimeInMins: Int

    @State private var showDuplicateDateAlert = false
    @State private var duplicateDateMessage = ""

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter
    }()

    init(mode: Mode, meet: Meet, onFinish: @escaping () -> Void) {
        self.mode = mode
        self.meet = meet
        self.onFinish = onFinish

        switch mode {
        case .add(let meet):
            if let lastDay = meet.days.last {
                _meetDate = State(initialValue: lastDay.meetDate.addingTimeInterval(24 * 60 * 60))
                _startTime = State(initialValue: lastDay.startTime)
                _endTime = State(initialValue: lastDay.endTime)
            } else {
                let units: Set<Calendar.Component> = [.year, .month, .day, .hour]
                var components = Calendar.current.dateComponents(units, from: Date())
                components.hour = 7
                let start = Calendar.current.date(from: components) ?? Date()
                components.hour = 17
                let end = Calendar.current.date(from: components) ?? Date()
                _meetDate = State(initialValue: meet.startDate)
                _startTime = State(initialValue: start)
                _endTime = State(initialValue: end)
            }
            _breaks = State(initialValue: 0)
            _breakTimeInMins = State(initialValue: MeetDay.DEFAULT_BREAK_TIME_MINS)
        case .edit(let existingDay):
            _meetDate = State(initialValue: existingDay.meetDate)
            _startTime = State(initialValue: existingDay.startTime)
            _endTime = State(initialValue: existingDay.endTime)
            _breaks = State(initialValue: existingDay.breaks)
            _breakTimeInMins = State(initialValue: existingDay.breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS)
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
                summaryRow(title: "Total Time", hours: workingMeetDay.totalTimeInHours())
                summaryRow(title: "Break Time", hours: workingMeetDay.breakTimeInHours())
                summaryRow(title: "Billable Time", hours: workingMeetDay.totalBillableTimeInHours())
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onFinish() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(saveButtonTitle) {
                    save()
                    onFinish()
                }
            }
        }
        .onChange(of: startTime) { newValue in
            if newValue >= endTime {
                endTime = newValue.addingTimeInterval(15 * 60)
            }
        }
        .onChange(of: meetDate) { newValue in
            checkForDateCollision(newValue)
        }
        .alert(duplicateDateMessage, isPresented: $showDuplicateDateAlert) {
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
            return "You are editing an existing meet day in the \"\(meet.name)\" meet"
        }
    }

    private var meetDateRange: PartialRangeFrom<Date> {
        if case .edit = mode {
            return meet.startDate...
        }
        return Date.distantPast...
    }

    /// A throwaway `MeetDay` built from the current in-progress field values,
    /// used only to read the shared billing calculations (`MeetDay`'s
    /// hours/break-time methods don't depend on anything but these fields).
    private var workingMeetDay: MeetDay {
        MeetDay(meetDate: meetDate, startTime: startTime, endTime: endTime, breaks: breaks, breakTime: breakTimeInMins, id: "")
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

    // MARK: Save

    private func save() {
        switch mode {
        case .add:
            let newDay = MeetDay(meetDate: meetDate, startTime: startTime, endTime: endTime, breaks: breaks, breakTime: breakTimeInMins, id: UUID().uuidString)
            MeetListManager.GetInstance().addMeetDay(meetDay: newDay)
        case .edit(let existingDay):
            existingDay.meetDate = meetDate
            existingDay.startTime = startTime
            existingDay.endTime = endTime
            existingDay.breaks = breaks
            existingDay.breakTimeInMins = breakTimeInMins
            MeetListManager.GetInstance().updateSelectedMeetDayWith(meetDay: existingDay)
        }
    }
}
