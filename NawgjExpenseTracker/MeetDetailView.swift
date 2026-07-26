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
//  Navigation to "Meet Days" (MeetDayListView) and "Judges"
//  (MeetJudgeListView) pushes SwiftUI screens directly. "Meet Report" still
//  instantiates the storyboard-driven `PDFViewController` (it was given a
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

    @State private var shareItems: [Any] = []
    @State private var isShareSheetPresented = false

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
                summaryRow(title: "Meet Days and Times", systemImage: "calendar", detail: meetDaysDetailText) {
                    showMeetDays()
                }
            }

            Section {
                summaryRow(title: "Judge Fees and Expenses", systemImage: "creditcard", detail: judgeDetailText) {
                    showJudges()
                }
            }

            if !meet.days.isEmpty {
                Section("Day Summaries") {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Array(meet.days.enumerated()), id: \.offset) { dayIndex, day in
                            dayCard(dayIndex: dayIndex, day: day)
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                }
            }
        }
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
        .sheet(isPresented: $isShareSheetPresented) {
            ActivitySheet(items: shareItems)
        }
        .onAppear {
            focusInitialField()
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
                Label("\(meet.judges.count)", systemImage: "person.2")
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

    // MARK: Derived display text

    private var meetDaysDetailText: String {
        let meetDayText = meet.days.count == 1 ? "Day" : "Days"
        return "\(meet.days.count) \(meetDayText) - \(meet.billableMeetHours()) Hours"
    }

    private var judgeDetailText: String {
        let judgeText = meet.judges.count == 1 ? "Judge" : "Judges"
        return "\(meet.judges.count) \(judgeText) - \(currencyString(meet.totalJudgeFeesAndExpenses()))"
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

    private func showMeetDays() {
        let meetDayListView = MeetDayListView(meet: meet, pushViewController: pushViewController, popViewController: popViewController)
        pushViewController(UIHostingController(rootView: meetDayListView))
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
        shareItems = [url]
        isShareSheetPresented = true
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

/// Thin wrapper so `UIActivityViewController` (used for the "Export Meet"
/// share sheet) can be presented via a SwiftUI `.sheet`. Shared by other
/// SwiftUI screens that need a share sheet (e.g. JudgeListView).
struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
