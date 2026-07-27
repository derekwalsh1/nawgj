//
//  MeetDayListView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven "Days" screen
//  (formerly MeetDayTableViewController), reached from MeetDetailView's
//  "Meet Days and Times" row. Follows the same list/row/swipe-to-delete
//  conventions as MeetListView/JudgeListView.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI
import UIKit

struct MeetDayListView: View {

    let meet: Meet
    let pushViewController: (UIViewController) -> Void
    let popViewController: () -> Void

    init(meet: Meet, pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void) {
        self.meet = meet
        self.pushViewController = pushViewController
        self.popViewController = popViewController
    }

    @State private var days: [MeetDay] = []

    /// Bumped whenever this screen reappears, forcing the day rows below -
    /// which read hours directly from each `MeetDay`'s (mutable) sessions
    /// rather than diffable `@State` - to fully redraw.
    @State private var refreshToken = UUID()

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = MeetDay.DATE_FORMAT
        return formatter
    }()

    var body: some View {
        List {
            Section {
                ForEach(days) { day in
                    Button {
                        editDay(day)
                    } label: {
                        row(for: day)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            delete(day)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
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
        .listStyle(.plain)
        .id(refreshToken)
        .overlay {
            if days.isEmpty {
                emptyState
            }
        }
        .navigationTitle("Days")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addDay()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            refreshDays()
            refreshToken = UUID()
        }
    }

    // MARK: Row

    @ViewBuilder
    private func row(for day: MeetDay) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: day.meetDate))
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle(for: day))
                    .font(.subheadline)
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

    private func subtitle(for day: MeetDay) -> String {
        let hoursText = String(format: "%.2f Hours", day.totalBillableTimeInHours())
        guard day.sessions.count > 1 else { return hoursText }
        return "\(day.sessions.count) Sessions • \(hoursText)"
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No Meet Days Yet")
                .font(.headline)
            Text("Tap + to add the first day.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: Warnings
    //
    // Mirrors the old MeetDayTableViewController.checkForMeetDayWarnings().

    private var sortedDays: [MeetDay] {
        days.sorted(by: { $0.meetDate < $1.meetDate })
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

    // MARK: Data loading

    private func refreshDays() {
        days = meet.days
    }

    // MARK: Actions

    private func addDay() {
        let detailView = MeetDayDetailView(mode: .add(meet), meet: meet, pushViewController: pushViewController, popViewController: popViewController) {
            popViewController()
            refreshDays()
        }
        pushViewController(UIHostingController(rootView: detailView))
    }

    private func editDay(_ day: MeetDay) {
        guard let index = meet.days.firstIndex(where: { $0 === day }) else { return }
        MeetListManager.GetInstance().selectMeetDayAt(index: index)
        let detailView = MeetDayDetailView(mode: .edit(day), meet: meet, pushViewController: pushViewController, popViewController: popViewController) {
            popViewController()
            refreshDays()
        }
        pushViewController(UIHostingController(rootView: detailView))
    }

    private func delete(_ day: MeetDay) {
        guard let index = meet.days.firstIndex(where: { $0 === day }) else { return }
        MeetListManager.GetInstance().removeMeetDayAt(index: index)
        refreshDays()
    }
}

/// `MeetDay` is a plain `Codable` class with no natural stable identifier,
/// so give it one for SwiftUI `List`/`ForEach` purposes based on object
/// identity.
extension MeetDay: Identifiable {
    var id: ObjectIdentifier { ObjectIdentifier(self) }
}
