//
//  MeetDetailView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven "Meet Overview" screen
//  (formerly MeetDetailViewController), used both when creating a brand new
//  meet and when editing an existing one - pushed from MeetTableViewController
//  for both the "AddItem" and "ShowDetail" flows. Hosted via
//  UIHostingController (see SwiftUIHosting.swift).
//
//  The "Meet Days" tiles below double as the meet's day navigation -
//  tapping one pushes `MeetDayDetailView` directly (there's no separate
//  "Meet Days" list screen anymore). "Judges" (MeetJudgeListView) still
//  pushes its own SwiftUI screen. "Meet Report" still instantiates the
//  storyboard-driven `PDFViewController` (it was given a
//  `storyboardIdentifier` for this purpose) and pushes it via the
//  `pushViewController` closure, since a SwiftUI view has no navigation
//  controller of its own to push onto.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI
import UIKit
import os.log

struct MeetDetailView: View {

    let meet: Meet

    /// Pushes a UIKit view controller onto the navigation stack this view is
    /// hosted in (used for "Meet Days", "Judges", and "Meet Report", which
    /// remain UIKit screens for now).
    let pushViewController: (UIViewController) -> Void

    /// Called when the user taps "Meet List" to go back. The caller is
    /// responsible for popping the screen and refreshing the meet list
    /// (mirrors the old `unwindToMeetListWithSender:` unwind action).
    let onFinish: () -> Void

    /// Pops the top view controller off the shared navigation stack. Used
    /// when pushing SwiftUI child screens (e.g. "Meet Days") that need to
    /// pop themselves back on completion.

    @State private var name: String
    @State private var startDate: Date
    @State private var location: String
    @State private var description: String

    @FocusState private var focusedField: Field?

    /// Bumped every time this view reappears (e.g. returning from "Meet
    /// Days"). `meet` is a plain reference, not `@ObservedObject`, so
    /// mutations made in pushed child screens (adding/editing a session,
    /// etc.) don't otherwise cause this view's body to re-render on their
    /// own - forcing a `@State` change here is what makes the "Day
    /// Summaries" grid and summary rows below pick up the latest data.
    @State private var refreshToken = UUID()

    private enum Field {
        case name, location, description
    }

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    private static var minimumMeetDate: Date {
        Calendar.current.date(from: DateComponents(year: 2016, month: 1, day: 1)) ?? Date.distantPast
    }

    let popViewController: () -> Void

    init(meet: Meet, pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void, onFinish: @escaping () -> Void) {
        self.meet = meet
        self.pushViewController = pushViewController
        self.popViewController = popViewController
        self.onFinish = onFinish

        // Mirrors the old screen's behavior of blanking the name field for a
        // brand new meet (`meet.name == "New Meet"`) so the user isn't stuck
        // typing over a default value.
        _name = State(initialValue: meet.name == "New Meet" ? "" : meet.name)
        _startDate = State(initialValue: meet.startDate)
        _location = State(initialValue: meet.location.trimmingCharacters(in: .whitespaces))
        _description = State(initialValue: meet.meetDescription.trimmingCharacters(in: .whitespaces))
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .focused($focusedField, equals: .name)
                    .onChange(of: name) { _ in persistFieldChanges() }

                DatePicker("Date", selection: $startDate, in: MeetDetailView.minimumMeetDate..., displayedComponents: .date)
                    .onChange(of: startDate) { _ in persistFieldChanges() }

                TextField("Location", text: $location)
                    .focused($focusedField, equals: .location)
                    .onChange(of: location) { _ in persistFieldChanges() }

                TextField("Description", text: $description)
                    .focused($focusedField, equals: .description)
                    .onChange(of: description) { _ in persistFieldChanges() }
            }

            Section {
                Button {
                    exportMeet()
                } label: {
                    Label("Export Meet", systemImage: "square.and.arrow.up")
                }
                Button {
                    generateReport()
                } label: {
                    Label("Generate Report", systemImage: "text.document")
                }
            }

            Section {
                summaryRow(title: "Judge Fees and Expenses", systemImage: "creditcard", detail: judgeDetailText) {
                    showJudges()
                }
            }

            Section {
                if meet.days.isEmpty {
                    emptyDaysState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Array(meet.days.enumerated()), id: \.offset) { dayIndex, day in
                            Button {
                                editDay(day)
                            } label: {
                                dayCard(dayIndex: dayIndex, day: day)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    delete(day)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                }
            } header: {
                HStack {
                    Text("Meet Days")
                    Spacer()
                    Button {
                        addDay()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            } footer: {
                if !meet.days.isEmpty {
                    Text(meetDaysDetailText)
                }
            }

            if isIncorrectFirstDayDetected || areNonSequentialDaysDetected {
                Section("We noticed some things...") {
                    if isIncorrectFirstDayDetected {
                        warningRow(title: "Date Mismatch", detail: "Meet start date doesn't match earliest meet day")
                    }
                    if areNonSequentialDaysDetected {
                        warningRow(title: "Non-Consecutive Days", detail: "A gap was detected between one or more meet days")
                    }
                }
            }
        }
        .id(refreshToken)
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Meet List") {
                    onFinish()
                }
            }
        }
        .onAppear {
            focusInitialField()
            // Force a redraw so the "Meet Days" cards and summary rows
            // (which read straight from `meet`, a plain reference) reflect
            // any changes made in the pushed day/session detail screens.
            refreshToken = UUID()
        }
    }

    @ViewBuilder
    private func summaryRow(title: String, systemImage: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                VStack(alignment: .leading) {
                    Text(title)
                    Text(detail)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }

    @ViewBuilder
    private func dayCard(dayIndex: Int, day: MeetDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateFormatter.string(from: day.meetDate))
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(timeRangeText(for: day))
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer(minLength: 4)

            Text(currencyString(meet.totalJudgesFeeForDay(dayIndex: dayIndex)))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)

            HStack(spacing: 12) {
                Label(String(format: "%0.1f hrs", day.totalBillableTimeInHours()), systemImage: "clock")
                Label("\(meet.assignedJudgeCountForDay(dayIndex: dayIndex))", systemImage: "person.2")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private var emptyDaysState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No days yet - tap + above to add one.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func warningRow(title: String, detail: String) -> some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: Derived display text

    private var meetDaysDetailText: String {
        let meetDayText = meet.days.count == 1 ? "Day" : "Days"
        return "\(meet.days.count) \(meetDayText) - \(meet.billableMeetHours()) Hours"
    }

    private var judgeDetailText: String {
        let judgeText = meet.judges.count == 1 ? "Judge" : "Judges"
        return "\(meet.judges.count) \(judgeText) - \(currencyString(meet.totalJudgeFeesAndExpenses()))"
    }

    // MARK: Day warnings
    //
    // Mirrors the old MeetDayTableViewController/MeetDayListView's
    // checkForMeetDayWarnings().

    private var sortedDays: [MeetDay] {
        meet.days.sorted(by: { $0.meetDate < $1.meetDate })
    }

    private var isIncorrectFirstDayDetected: Bool {
        guard let firstDay = sortedDays.first else { return false }
        return !Calendar.current.isDate(meet.startDate, inSameDayAs: firstDay.meetDate)
    }

    private var areNonSequentialDaysDetected: Bool {
        let sorted = sortedDays
        guard sorted.count > 1 else { return false }
        for i in 1..<sorted.count {
            let previousDay = Calendar.current.startOfDay(for: sorted[i - 1].meetDate)
            let expectedNextDay = Calendar.current.date(byAdding: .day, value: 1, to: previousDay)
            let currentDay = Calendar.current.startOfDay(for: sorted[i].meetDate)
            if expectedNextDay != currentDay {
                return true
            }
        }
        return false
    }

    private func timeRangeText(for day: MeetDay) -> String {
        "\(timeFormatter.string(from: day.startTime)) – \(timeFormatter.string(from: day.endTime))"
    }

    private func currencyString(_ value: Float) -> String {
        numberFormatter.string(from: value as NSNumber) ?? ""
    }

    private func focusInitialField() {
        if name.isEmpty {
            focusedField = .name
        } else if location.isEmpty {
            focusedField = .location
        } else if description.isEmpty {
            focusedField = .description
        }
    }

    // MARK: Persistence
    //
    // Edits are written straight into `meet` (a reference type shared with
    // `MeetListManager`) and saved on every change, instead of only on
    // `viewWillDisappear` like the old screen - there's no risk of losing
    // edits made right before navigating away, and the async save chain
    // added in Phase 5 makes this cheap.

    private func persistFieldChanges() {
        meet.name = name
        meet.startDate = startDate
        meet.location = location
        meet.meetDescription = description
        MeetListManager.GetInstance().updateSelectedMeetWith(meet: meet)
    }

    // MARK: Actions

    private func addDay() {
        let detailView = MeetDayDetailView(mode: .add(meet), meet: meet, pushViewController: pushViewController, popViewController: popViewController) {
            popViewController()
            refreshToken = UUID()
        }
        pushViewController(UIHostingController(rootView: detailView))
    }

    private func editDay(_ day: MeetDay) {
        guard let index = meet.days.firstIndex(where: { $0 === day }) else { return }
        MeetListManager.GetInstance().selectMeetDayAt(index: index)
        let detailView = MeetDayDetailView(mode: .edit(day), meet: meet, pushViewController: pushViewController, popViewController: popViewController) {
            popViewController()
            refreshToken = UUID()
        }
        pushViewController(UIHostingController(rootView: detailView))
    }

    private func delete(_ day: MeetDay) {
        guard let index = meet.days.firstIndex(where: { $0 === day }) else { return }
        MeetListManager.GetInstance().removeMeetDayAt(index: index)
        refreshToken = UUID()
    }

    private func showJudges() {
        let judgeListView = MeetJudgeListView(meet: meet, pushViewController: pushViewController, popViewController: popViewController)
        pushViewController(UIHostingController(rootView: judgeListView))
    }

    private func generateReport() {
        guard let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MeetReport") as? PDFViewController else {
            os_log("Failed to instantiate PDFViewController", log: OSLog.default, type: .error)
            return
        }
        pushViewController(controller)
    }

    private func exportMeet() {
        guard let url = dataToFile(fileName: "ExportedMeet.JSON") else { return }
        presentShareSheet(items: [url])
    }

    private func dataToFile(fileName: String) -> URL? {
        do {
            let newURL = JudgeListManager.DocumentsDirectory.appendingPathComponent(fileName)
            var encodedData = try JSONEncoder().encode(meet)
            let meetFromData = try JSONDecoder().decode(Meet.self, from: encodedData) as Meet
            encodedData = try JSONEncoder().encode(meetFromData)
            try encodedData.write(to: newURL)
            return newURL
        } catch {
            os_log("Failed to convert meet to JSON format", log: OSLog.default, type: .error)
            return nil
        }
    }
}

/// Presents a `UIActivityViewController` directly via UIKit's
/// `present(_:animated:)`, instead of through a SwiftUI `.sheet`. This app's
/// screens are SwiftUI views hosted in `UIHostingController`s pushed onto a
/// plain UIKit `UINavigationController` (see SceneDelegate.swift) rather
/// than a native SwiftUI `NavigationStack` - in that hybrid setup, `.sheet`
/// presentation state (a `@State` Bool) could silently fail to trigger a
/// presentation on the very first attempt after a screen appeared, even
/// with the state flip deferred to the next run loop tick. Presenting
/// directly on the topmost UIKit view controller sidesteps SwiftUI's sheet
/// state syncing altogether. Shared by MeetDetailView and JudgeListView.
func presentShareSheet(items: [Any]) {
    guard let presenter = topMostViewController() else {
        os_log("Failed to find a view controller to present the share sheet from", log: OSLog.default, type: .error)
        return
    }
    let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
    if let popover = activityViewController.popoverPresentationController {
        // Required on iPad, where UIActivityViewController presents as a
        // popover rather than a sheet.
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
    }
    presenter.present(activityViewController, animated: true)
}

private func topMostViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
        let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
        return nil
    }
    var top = root
    while let presented = top.presentedViewController {
        top = presented
    }
    if let nav = top as? UINavigationController, let visible = nav.visibleViewController {
        top = visible
    }
    return top
}
