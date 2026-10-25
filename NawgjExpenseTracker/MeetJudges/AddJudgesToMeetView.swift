//
//  AddJudgesToMeetView.swift
//  NawgjExpenseTracker
//
//  SwiftUI replacement for the old storyboard-driven "Select Judges" screen
//  (formerly AddJudgesToMeetViewController), pushed from
//  MeetJudgeListView's "+" toolbar button. Lets the user pick one or more
//  judges from the master roster (JudgeListManager) to add to the current
//  meet, or create a brand new judge via CreateJudgeView.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI

struct AddJudgesToMeetView: View {

    let meet: Meet
    let pushViewController: (UIViewController) -> Void
    let popViewController: () -> Void

    /// Called when the user taps Cancel or Done (after any selected judges
    /// have already been added to the meet). The caller is responsible for
    /// popping this screen and refreshing its judge list.
    let onFinish: () -> Void

    init(meet: Meet, pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void, onFinish: @escaping () -> Void) {
        self.meet = meet
        self.pushViewController = pushViewController
        self.popViewController = popViewController
        self.onFinish = onFinish
    }

    @State private var judgeList: [JudgeInfo] = []
    @State private var selectedNames: Set<String> = []

    private var meetJudgeNames: Set<String> {
        Set(meet.judges.map { $0.name })
    }

    /// `judgeList` sorted so judges already added to this meet appear first
    /// (each group keeps the existing alphabetical order).
    private var sortedJudgeList: [JudgeInfo] {
        let names = meetJudgeNames
        return judgeList.enumerated().sorted { lhs, rhs in
            let lhsIncluded = names.contains(lhs.element.name)
            let rhsIncluded = names.contains(rhs.element.name)
            if lhsIncluded != rhsIncluded {
                return lhsIncluded
            }
            return lhs.offset < rhs.offset
        }.map { $0.element }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                createNewJudge()
            } label: {
                Text("Create New Judge")
                    .frame(maxWidth: .infinity)
            }
            .padding()

            Text("Select judges to add to meet:")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)

            List(sortedJudgeList) { judgeInfo in
                let alreadyIncluded = meetJudgeNames.contains(judgeInfo.name)
                Button {
                    toggleSelection(judgeInfo)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alreadyIncluded ? "\(judgeInfo.name) (Already Included)" : judgeInfo.name)
                            Text(judgeInfo.level.fullDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if alreadyIncluded {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        } else if selectedNames.contains(judgeInfo.name) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .foregroundColor(alreadyIncluded ? .secondary : .primary)
                }
                .disabled(alreadyIncluded)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Select Judges")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    onFinish()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    addSelectedJudges()
                    onFinish()
                }
            }
        }
        .onAppear {
            loadJudgeList()
        }
    }

    // MARK: Data

    private func loadJudgeList() {
        // Only reload from disk the first time this session touches the
        // roster (judges == nil). Reloading from disk on every appearance
        // of this screen, unconditionally, could race ahead of a very
        // recent pending save made elsewhere (a delete/edit on the All
        // Judges screen, an import, etc. all save asynchronously) and read
        // back stale data, silently reverting that change - and then
        // re-save that stale snapshot, making the revert permanent. Once
        // the roster is loaded in memory, just re-sort it instead.
        if JudgeListManager.GetInstance().judges == nil {
            JudgeListManager.GetInstance().loadAndSortJudges()
        } else {
            JudgeListManager.GetInstance().sortJudges()
        }
        judgeList = JudgeListManager.GetInstance().judges ?? []
    }

    /// Re-sorts the already up-to-date in-memory judge list instead of
    /// reloading from disk. Use this right after `CreateJudgeView` adds a
    /// new judge: `JudgeListManager.addJudge` already updated the in-memory
    /// list and queued its own async save, so reloading from disk
    /// immediately afterward (as `loadJudgeList()` does) could race ahead
    /// of that pending write and silently discard the judge that was just
    /// created.
    private func refreshJudgeList() {
        JudgeListManager.GetInstance().sortJudges()
        judgeList = JudgeListManager.GetInstance().judges ?? []
    }

    private func toggleSelection(_ judgeInfo: JudgeInfo) {
        if selectedNames.contains(judgeInfo.name) {
            selectedNames.remove(judgeInfo.name)
        } else {
            selectedNames.insert(judgeInfo.name)
        }
    }

    private func addSelectedJudges() {
        for judgeInfo in judgeList where selectedNames.contains(judgeInfo.name) {
            addJudgeInfoToMeet(judgeInfo)
        }
    }

    private func addJudgeInfoToMeet(_ judgeInfo: JudgeInfo) {
        if let newJudge = Judge(name: judgeInfo.name, level: judgeInfo.level, fees: Array<Fee>(), defaultExpenseDate: meet.startDate) {
            MeetListManager.GetInstance().addJudge(judge: newJudge)
        }
    }

    // MARK: Actions

    private func createNewJudge() {
        let createJudgeView = CreateJudgeView(mode: .create) { newJudgeInfo in
            // Creating a judge from this screen implies the intent is to
            // add them to this meet, so do that automatically instead of
            // requiring the user to also find and select them afterward.
            addJudgeInfoToMeet(newJudgeInfo)
            popViewController()
            refreshJudgeList()
        }
        pushViewController(UIHostingController(rootView: createJudgeView))
    }
}
