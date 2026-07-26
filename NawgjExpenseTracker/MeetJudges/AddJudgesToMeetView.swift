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

            List(judgeList) { judgeInfo in
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
                        if selectedNames.contains(judgeInfo.name) {
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
        JudgeListManager.GetInstance().loadAndSortJudges()
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
            if let newJudge = Judge(name: judgeInfo.name, level: judgeInfo.level, fees: Array<Fee>()) {
                MeetListManager.GetInstance().addJudge(judge: newJudge)
            }
        }
    }

    // MARK: Actions

    private func createNewJudge() {
        let createJudgeView = CreateJudgeView(mode: .create) {
            // Mirrors the old createNewJudgeButtonTapped, which popped back
            // to this screen and refreshed the judge list every time,
            // regardless of whether a judge was actually created.
            popViewController()
            loadJudgeList()
        }
        pushViewController(UIHostingController(rootView: createJudgeView))
    }
}
