//
//  JudgeListView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven "All Judges" screen
//  (JudgeListTableViewController / JudgeManagementCell), continuing the
//  same redesign approach used for the Meet List root screen: compact rows,
//  swipe-to-delete instead of Edit-mode, and Add/Import/Export consolidated
//  into a single toolbar menu.
//
//  Pushed from MeetListView via its pushViewController closure (see
//  MeetListView.swift), and itself pushes the existing SwiftUI
//  CreateJudgeView for both "Add New" and tapping an existing judge, using
//  the same push/pop closure bridging pattern.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import os.log

struct JudgeListView: View {

    let pushViewController: (UIViewController) -> Void
    let popViewController: () -> Void

    init(pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void) {
        self.pushViewController = pushViewController
        self.popViewController = popViewController
    }

    @State private var judges: [JudgeInfo] = []
    @State private var isImportingDocument = false
    @State private var showRemoveAllConfirmation = false

    var body: some View {
        List {
            ForEach(judges) { judgeInfo in
                Button {
                    editJudge(judgeInfo)
                } label: {
                    row(for: judgeInfo)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button(role: .destructive) {
                        delete(judgeInfo)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if judges.isEmpty {
                emptyState
            }
        }
        .navigationTitle("All Judges")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        addJudge()
                    } label: {
                        Label("New Judge", systemImage: "plus")
                    }
                    Button {
                        isImportingDocument = true
                    } label: {
                        Label("Import Judges…", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        exportJudges()
                    } label: {
                        Label("Export Judges…", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showRemoveAllConfirmation = true
                    } label: {
                        Label("Remove All Judges…", systemImage: "trash")
                    }
                    .disabled(judges.isEmpty)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fileImporter(isPresented: $isImportingDocument, allowedContentTypes: [.json]) { result in
            handleImportResult(result)
        }
        .confirmationDialog(
            "Remove all \(judges.count) judges? This cannot be undone.",
            isPresented: $showRemoveAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) {
                removeAllJudges()
            }
            Button("Cancel", role: .cancel) {}
        }
        .task {
            await loadJudges()
        }
    }

    // MARK: Row

    @ViewBuilder
    private func row(for judgeInfo: JudgeInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(judgeInfo.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(judgeInfo.level.fullDescription)
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No Judges Yet")
                .font(.headline)
            Text("Tap + to add your first judge.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: Data loading

    private func loadJudges() async {
        judges = await JudgeListManager.GetInstance().loadAndSortJudgesAsync()
    }

    private func refreshJudges() {
        // Mirrors the old JudgeListTableViewController.finishJudgeEditing(),
        // which reloaded and re-sorted from disk after add/edit since
        // editing a name can change its alphabetical position.
        JudgeListManager.GetInstance().loadAndSortJudges()
        judges = JudgeListManager.GetInstance().judges ?? []
    }

    // MARK: Actions

    private func addJudge() {
        let createJudgeView = CreateJudgeView(mode: .create) {
            popViewController()
            refreshJudges()
        }
        pushViewController(UIHostingController(rootView: createJudgeView))
    }

    private func editJudge(_ judgeInfo: JudgeInfo) {
        guard let index = JudgeListManager.GetInstance().judges?.firstIndex(where: { $0 === judgeInfo }) else { return }
        JudgeListManager.GetInstance().selectJudgeInfoAt(index)
        let createJudgeView = CreateJudgeView(mode: .edit(judgeInfo)) {
            popViewController()
            refreshJudges()
        }
        pushViewController(UIHostingController(rootView: createJudgeView))
    }

    private func delete(_ judgeInfo: JudgeInfo) {
        guard let index = JudgeListManager.GetInstance().judges?.firstIndex(where: { $0 === judgeInfo }) else { return }
        JudgeListManager.GetInstance().removeJudgeAt(index)
        judges = JudgeListManager.GetInstance().judges ?? []
    }

    private func removeAllJudges() {
        JudgeListManager.GetInstance().removeAllJudges()
        judges = JudgeListManager.GetInstance().judges ?? []
    }

    private func exportJudges() {
        guard let url = dataToFile(fileName: "JudgeList.JSON") else { return }
        presentShareSheet(items: [url])
    }

    private func dataToFile(fileName: String) -> URL? {
        do {
            let newURL = JudgeListManager.DocumentsDirectory.appendingPathComponent(fileName)
            let encodedData = try JSONEncoder().encode(JudgeListManager.GetInstance().judges)
            try encodedData.write(to: newURL)
            return newURL
        } catch {
            os_log("Failed to convert judges list to JSON format", log: OSLog.default, type: .error)
            return nil
        }
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // JudgeListManager.importJudges(fromFile:) already handles
            // security-scoped resource access internally.
            JudgeListManager.GetInstance().importJudges(fromFile: url)
            judges = JudgeListManager.GetInstance().judges ?? []
        case .failure(let error):
            os_log("Failed to import judges: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
        }
    }
}

/// `JudgeInfo` is a plain `Codable` class with no natural stable identifier,
/// so give it one for SwiftUI `List`/`ForEach` purposes based on object
/// identity.
extension JudgeInfo: Identifiable {
    var id: ObjectIdentifier { ObjectIdentifier(self) }
}
