//
//  MeetJudgeListView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven per-meet "Judges" list
//  screen (formerly JudgeTableViewController), pushed from MeetDetailView's
//  "Judge Fees and Expenses" row. Not to be confused with the "All Judges"
//  `JudgeListView` (NawgjExpenseTracker/JudgeList/JudgeListView.swift), which
//  manages the master judge roster independent of any meet.
//
//  Presents judges as a grid of tiles (rather than a plain list) with a
//  search field to filter by name. Since swipe-to-delete doesn't apply to a
//  grid, deleting a judge is now done via a tile's context menu (long-press)
//  instead.
//
//  Pushes the SwiftUI AddJudgesToMeetView (formerly the storyboard-driven
//  "Select Judges" screen / AddJudgesToMeetViewController) to add existing
//  judges to the meet.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI
import UIKit

struct MeetJudgeListView: View {

    let meet: Meet
    let pushViewController: (UIViewController) -> Void
    let popViewController: () -> Void

    init(meet: Meet, pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void) {
        self.meet = meet
        self.pushViewController = pushViewController
        self.popViewController = popViewController
    }

    @State private var judges: [Judge] = []
    @State private var searchText = ""

    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    private let gridColumns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    private var filteredJudges: [Judge] {
        guard !searchText.isEmpty else { return judges }
        return judges.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            if filteredJudges.isEmpty {
                emptyState
                    .padding(.top, 60)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(filteredJudges) { judge in
                        Button {
                            editJudge(judge)
                        } label: {
                            tile(for: judge)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(judge)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Judges")
        .searchable(text: $searchText, prompt: "Search Judges")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addJudges()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            refreshJudges()
        }
    }

    // MARK: Tile

    @ViewBuilder
    private func tile(for judge: Judge) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                Spacer()
                if judge.isPaid() {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            }
            Text(judge.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(judge.level.description)
                .font(.caption)
                .foregroundColor(.secondary)
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Label(currencyString(judge.totalFees()), systemImage: "dollarsign.circle")
                Label(currencyString(judge.totalExpenses()), systemImage: "cart")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(judge.isPaid() ? Color.green.opacity(0.15) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "No Judges Yet" : "No Judges Found")
                .font(.headline)
            Text(searchText.isEmpty ? "Tap + to add judges to this meet." : "Try a different search.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func currencyString(_ value: Float) -> String {
        numberFormatter.string(from: value as NSNumber) ?? ""
    }

    // MARK: Data

    private func refreshJudges() {
        // Mirrors the old JudgeTableViewController.viewDidLoad(), which
        // re-sorted the meet's judges alphabetically by name every time the
        // list appeared.
        meet.judges = meet.judges.sorted(by: { $0.name < $1.name })
        judges = meet.judges
    }

    // MARK: Actions

    private func addJudges() {
        let addJudgesView = AddJudgesToMeetView(meet: meet, pushViewController: pushViewController, popViewController: popViewController) {
            popViewController()
            refreshJudges()
        }
        pushViewController(UIHostingController(rootView: addJudgesView))
    }

    private func editJudge(_ judge: Judge) {
        guard let index = meet.judges.firstIndex(where: { $0 === judge }) else { return }
        MeetListManager.GetInstance().selectJudgeAt(index: index)
        let detailView = MeetJudgeDetailView(meet: meet, judge: judge, pushViewController: pushViewController, popViewController: popViewController)
        pushViewController(UIHostingController(rootView: detailView))
    }

    private func delete(_ judge: Judge) {
        guard let index = meet.judges.firstIndex(where: { $0 === judge }) else { return }
        MeetListManager.GetInstance().removeJudgeAt(index: index)
        judges = meet.judges
    }
}

/// `Judge` is a plain `Codable` class with no natural stable identifier, so
/// give it one for SwiftUI `List`/`ForEach` purposes based on object identity.
extension Judge: Identifiable {
    var id: ObjectIdentifier { ObjectIdentifier(self) }
}
