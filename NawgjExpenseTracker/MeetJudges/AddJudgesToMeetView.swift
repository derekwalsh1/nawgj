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

    /// When set, every judge added/created from this screen is also
    /// immediately assigned to this specific session, rather than just
    /// added to the meet's judge list - used when this screen is pushed
    /// from a session's "Add New Judge" action (`SessionDetailView`)
    /// instead of the meet-wide "Select Judges" flow.
    var assignmentTarget: (session: Session, day: MeetDay)? = nil

    init(meet: Meet, pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void, onFinish: @escaping () -> Void, assignmentTarget: (session: Session, day: MeetDay)? = nil) {
        self.meet = meet
        self.pushViewController = pushViewController
        self.popViewController = popViewController
        self.onFinish = onFinish
        self.assignmentTarget = assignmentTarget
    }

    @State private var judgeList: [JudgeInfo] = []
    @State private var selectedKeys: Set<String> = []
    @State private var overlapMessage = ""
    @State private var showOverlapAlert = false

    /// A judge is uniquely identified by name (case-insensitive) + level,
    /// matching `JudgeListManager.indexOfJudge(_:)`'s own de-dup rule - not
    /// by name alone. Two roster entries can share the same name with
    /// different levels (e.g. a judge who got re-certified at a new
    /// level), and treating name alone as the identity caused selecting
    /// one to also select/add the other.
    private func judgeKey(name: String, level: Judge.Level) -> String {
        "\(name.lowercased())|\(level.rawValue)"
    }

    private var meetJudgeKeys: Set<String> {
        Set(meet.judges.map { judgeKey(name: $0.name, level: $0.level) })
    }

    /// `judgeList` sorted so judges already added to this meet appear first
    /// (each group keeps the existing alphabetical order).
    private var sortedJudgeList: [JudgeInfo] {
        let keys = meetJudgeKeys
        return judgeList.enumerated().sorted { lhs, rhs in
            let lhsIncluded = keys.contains(judgeKey(name: lhs.element.name, level: lhs.element.level))
            let rhsIncluded = keys.contains(judgeKey(name: rhs.element.name, level: rhs.element.level))
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

            Text(assignmentTarget != nil ? "Select judges to add and assign to this session:" : "Select judges to add to meet:")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)

            List(sortedJudgeList) { judgeInfo in
                let alreadyIncluded = meetJudgeKeys.contains(judgeKey(name: judgeInfo.name, level: judgeInfo.level))
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
                        } else if selectedKeys.contains(judgeKey(name: judgeInfo.name, level: judgeInfo.level)) {
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
        .navigationTitle(assignmentTarget != nil ? "Add Judges" : "Select Judges")
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
        .alert(overlapMessage, isPresented: $showOverlapAlert) {
            Button("OK", role: .cancel) {}
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
        let key = judgeKey(name: judgeInfo.name, level: judgeInfo.level)
        if selectedKeys.contains(key) {
            selectedKeys.remove(key)
        } else {
            selectedKeys.insert(key)
        }
    }

    private func addSelectedJudges() {
        for judgeInfo in judgeList where selectedKeys.contains(judgeKey(name: judgeInfo.name, level: judgeInfo.level)) {
            addJudgeInfoToMeet(judgeInfo)
        }
    }

    private func addJudgeInfoToMeet(_ judgeInfo: JudgeInfo) {
        guard let newJudge = Judge(name: judgeInfo.name, level: judgeInfo.level, fees: Array<Fee>(), defaultExpenseDate: meet.startDate) else { return }
        // When assigning to one specific session, don't also auto-assign
        // (and bill) this judge for every other session in the meet.
        MeetListManager.GetInstance().addJudge(judge: newJudge, assignToAllSessions: assignmentTarget == nil)

        guard let target = assignmentTarget else { return }
        let result = MeetListManager.GetInstance().assignJudge(newJudge, to: target.session, in: target.day)
        if case .failure(let error) = result {
            switch error {
            case .overlappingSession(let conflict):
                overlapMessage = "\(newJudge.name) is already assigned to \"\(conflict.name)\", which overlaps this session's time."
                showOverlapAlert = true
            }
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
