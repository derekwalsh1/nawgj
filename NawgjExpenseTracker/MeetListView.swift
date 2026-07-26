//
//  MeetListView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven "NAWGJ Meet Manager"
//  root screen (formerly MeetTableViewController / MeetTableViewCell /
//  MeetTableImportExportCell), redesigned to be more useful and flow
//  better:
//   - Compact rows (name, date, location, cost) with a status badge that
//     surfaces what needs attention (unpaid judges) or otherwise whether
//     the meet is upcoming or past.
//   - Meets are sorted by date (most recent first) instead of manual
//     drag-to-reorder.
//   - A search field to filter by name/location.
//   - "New Meet" and "Import Meet" combined into a single toolbar menu
//     instead of Import always occupying its own row.
//   - Swipe-to-delete instead of a separate Edit-mode toggle.
//
//  This is the app's root screen, so unlike other SwiftUI screens it isn't
//  pushed from a UIKit view controller - it's hosted directly in a
//  UINavigationController by SceneDelegate, which supplies the
//  `pushViewController`/`popViewController` closures used to bridge to the
//  remaining UIKit/storyboard screens (same pattern as MeetDetailView).
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import os.log

struct MeetListView: View {

    let pushViewController: (UIViewController) -> Void
    let popViewController: () -> Void

    init(pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void) {
        self.pushViewController = pushViewController
        self.popViewController = popViewController
    }

    @State private var meets: [Meet] = []
    @State private var searchText = ""
    @State private var isImportingDocument = false
    @State private var importErrorMessage: String?

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    private var filteredMeets: [Meet] {
        let sorted = meets.sorted { $0.startDate > $1.startDate }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredMeets) { meet in
                Button {
                    showMeetDetail(meet)
                } label: {
                    row(for: meet)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button(role: .destructive) {
                        delete(meet)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if meets.isEmpty {
                emptyState
            } else if filteredMeets.isEmpty {
                noResultsState
            }
        }
        .searchable(text: $searchText, prompt: "Search meets")
        .navigationTitle("NAWGJ Meet Manager")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("NAWGJLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
                    .accessibilityLabel("NAWGJ Meet Manager")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showJudgeList()
                } label: {
                    Label("Judges", systemImage: "person.2")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        addMeet()
                    } label: {
                        Label("New Meet", systemImage: "plus")
                    }
                    Button {
                        isImportingDocument = true
                    } label: {
                        Label("Import Meet…", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fileImporter(isPresented: $isImportingDocument, allowedContentTypes: [.json]) { result in
            handleImportResult(result)
        }
        .alert("Import Failed", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("OK") { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
        .task {
            await loadInitialData()
        }
    }

    // MARK: Row

    @ViewBuilder
    private func row(for meet: Meet) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meet.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(dateFormatter.string(from: meet.startDate)) • \(meet.location.trimmingCharacters(in: .whitespaces))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(currencyString(meet.totalCostOfMeet()))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                statusBadge(for: meet)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func statusBadge(for meet: Meet) -> some View {
        let unpaidCount = meet.judges.filter { !$0.isPaid() }.count
        if unpaidCount > 0 {
            badge("\(unpaidCount) unpaid", color: .red)
        } else if meet.startDate >= Calendar.current.startOfDay(for: Date()) {
            badge("Upcoming", color: .blue)
        } else {
            badge("Past", color: .secondary)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No Meets Yet")
                .font(.headline)
            Text("Tap + to create your first meet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No Matching Meets")
                .font(.headline)
        }
    }

    private func currencyString(_ value: Float) -> String {
        numberFormatter.string(from: value as NSNumber) ?? ""
    }

    // MARK: Data loading

    private func loadInitialData() async {
        let loadedMeets = await MeetListManager.GetInstance().loadMeetsAsync()
        MeetListManager.GetInstance().meets = loadedMeets
        let loadedJudges = await JudgeListManager.GetInstance().loadJudgesAsync()
        JudgeListManager.GetInstance().judges = loadedJudges

        synchronizeJudgeList()
        refreshMeets()
    }

    private func refreshMeets() {
        meets = MeetListManager.GetInstance().meets ?? []
    }

    // In case someone has used an older version of the app, go through the
    // list of meets and add any existing judges. If a judge appears in a
    // meet that is not in the judge list, then add the judge and save the
    // list. (Mirrors the old MeetTableViewController.synchronizeJudgeList().)
    private func synchronizeJudgeList() {
        guard let meets = MeetListManager.GetInstance().meets else { return }
        for meet in meets {
            for meetJudge in meet.judges {
                let judgeInfo = JudgeInfo(name: meetJudge.name, level: meetJudge.level)
                if JudgeListManager.GetInstance().addJudge(judgeInfo) {
                    os_log("Added Judge %@", log: OSLog.default, type: .debug, judgeInfo.name)
                } else {
                    os_log("Judge %@ not added because they already exist in the Judge List", log: OSLog.default, type: .debug, judgeInfo.name)
                }
            }
        }
    }

    // MARK: Actions

    private func addMeet() {
        guard let newMeet = Meet(name: "New Meet", startDate: Date()) else { return }
        MeetListManager.GetInstance().addMeet(meet: newMeet)
        if let index = MeetListManager.GetInstance().meets?.firstIndex(where: { $0 === newMeet }) {
            MeetListManager.GetInstance().selectMeetAt(index: index)
        }
        refreshMeets()
        showMeetDetail(newMeet)
    }

    private func delete(_ meet: Meet) {
        guard let index = MeetListManager.GetInstance().meets?.firstIndex(where: { $0 === meet }) else { return }
        MeetListManager.GetInstance().removeMeetAt(index: index)
        refreshMeets()
    }

    private func showMeetDetail(_ meet: Meet) {
        if let index = MeetListManager.GetInstance().meets?.firstIndex(where: { $0 === meet }) {
            MeetListManager.GetInstance().selectMeetAt(index: index)
        }
        let detailView = MeetDetailView(meet: meet, pushViewController: pushViewController, popViewController: popViewController, onFinish: {
            popViewController()
            refreshMeets()
        })
        pushViewController(UIHostingController(rootView: detailView))
    }

    private func showJudgeList() {
        let judgeListView = JudgeListView(pushViewController: pushViewController, popViewController: popViewController)
        pushViewController(UIHostingController(rootView: judgeListView))
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importErrorMessage = "Couldn't access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            MeetListManager.GetInstance().importMeet(fromFile: url)
            refreshMeets()
        case .failure(let error):
            os_log("Failed to import meet: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
            importErrorMessage = error.localizedDescription
        }
    }
}

/// `Meet` is a plain `Codable` class with no natural stable identifier, so
/// give it one for SwiftUI `List`/`ForEach` purposes based on object identity.
extension Meet: Identifiable {
    var id: ObjectIdentifier { ObjectIdentifier(self) }
}
