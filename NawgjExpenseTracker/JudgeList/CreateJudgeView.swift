//
//  CreateJudgeView.swift
//  NawgjExpenseTracker
//
//  SwiftUI replacement for two old storyboard-driven screens that both
//  edited judge name/level: the "Create Judge" screen (formerly
//  CreateJudgeViewController, pushed from AddJudgesToMeetViewController)
//  and the "Judge Info" add/edit screen (formerly
//  JudgeInfoDetailsTableViewController, pushed from
//  JudgeListTableViewController for both "Add New" and tapping an existing
//  judge). Hosted via UIHostingController (see SwiftUIHosting.swift).
//
//  This is the Phase 3 pilot screen for the incremental SwiftUI migration -
//  see .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI

struct CreateJudgeView: View {

    enum Mode {
        /// Creating a brand new judge. Duplicate name+level combinations
        /// (matching an existing judge) are blocked.
        case create
        /// Editing an existing judge's name/level in place. Matches the old
        /// `JudgeInfoDetailsTableViewController` behavior: only a non-empty
        /// name is required (no duplicate check), since the judge being
        /// edited is expected to already exist in the list.
        case edit(JudgeInfo)
    }

    let mode: Mode

    /// Called when the user taps Cancel or Save (after the judge, if any,
    /// has already been added/updated). The caller is responsible for
    /// popping the screen and refreshing its judge list.
    let onFinish: () -> Void

    @State private var name: String
    @State private var selectedLevel: Judge.Level
    @FocusState private var nameFieldFocused: Bool

    init(mode: Mode, onFinish: @escaping () -> Void) {
        self.mode = mode
        self.onFinish = onFinish
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _selectedLevel = State(initialValue: CreateJudgeView.defaultLevel())
        case .edit(let existingJudge):
            _name = State(initialValue: existingJudge.name)
            _selectedLevel = State(initialValue: existingJudge.level)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            if let duplicateWarning {
                Text(duplicateWarning)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
            }

            Form {
                Section("Judge Name") {
                    TextField("Full name", text: $name)
                        .focused($nameFieldFocused)
                        .textInputAutocapitalization(.words)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { nameFieldFocused = false }
                }

                Section {
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(Judge.Level.selectableCases, id: \.self) { level in
                            Text(level.description).tag(level)
                        }
                    }
                    .pickerStyle(.wheel)
                } header: {
                    Text("Level")
                } footer: {
                    Text(selectedLevel.fullDescription)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveIfPossible()
                    onFinish()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            nameFieldFocused = true
        }
    }

    // MARK: Validation / save logic
    //
    // When creating, Save is disabled unless the name is non-empty and not
    // already a duplicate judge at the same level (mirrors the old
    // CreateJudgeViewController/JudgeInfoDetailsTableViewController "add"
    // behavior). When editing, only a non-empty name is required (mirrors
    // JudgeInfoDetailsTableViewController's "edit" behavior, which never
    // checked for duplicates). Leading/trailing whitespace in the name is
    // trimmed before checking for duplicates or saving, and a specific
    // reason is shown inline instead of just silently disabling Save.

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "Create Judge"
        case .edit:
            return trimmedName.isEmpty ? "Edit Judge" : trimmedName
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicateJudge: Bool {
        guard !isEditing, !trimmedName.isEmpty else { return false }
        let info = JudgeInfo(name: trimmedName, level: selectedLevel)
        return JudgeListManager.GetInstance().indexOfJudge(info) != -1
    }

    private var duplicateWarning: String? {
        guard isDuplicateJudge else { return nil }
        return "A judge named \"\(trimmedName)\" already exists at this level."
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && !isDuplicateJudge
    }

    private func saveIfPossible() {
        guard canSave else { return }
        let judgeInfo = JudgeInfo(name: trimmedName, level: selectedLevel)
        switch mode {
        case .create:
            _ = JudgeListManager.GetInstance().addJudge(judgeInfo)
        case .edit:
            JudgeListManager.GetInstance().updateSelectedJudgeWith(judgeInfo)
        }
    }

    private static func defaultLevel() -> Judge.Level {
        let cases = Judge.Level.selectableCases
        let defaultIndex = cases.count > 1 ? cases.count - 2 : 0
        return cases[defaultIndex]
    }
}

