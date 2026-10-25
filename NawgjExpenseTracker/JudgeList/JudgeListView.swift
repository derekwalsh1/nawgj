//
//  JudgeListView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven "All Judges" screen
//  (JudgeListTableViewController / JudgeManagementCell), continuing the
//  same redesign approach used for the Meet List root screen: compact rows,
//  swipe-to-delete (plus an explicit multi-select "Delete" mode) instead of
//  Edit-mode, and Add/Import/Export consolidated into a single toolbar menu.
//
//  One of the app's three tab roots (Meets / Judges / Settings - see
//  SceneDelegate.swift), hosted in its own UINavigationController. Itself
//  pushes the existing SwiftUI CreateJudgeView for both "Add New" and
//  tapping an existing judge, using the same push/pop closure bridging
//  pattern used elsewhere.
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
    @State private var isSelecting = false
    @State private var selectedJudgeIDs: Set<ObjectIdentifier> = []
    @State private var showDeleteSelectedConfirmation = false

    var body: some View {
        List {
            ForEach(judges) { judgeInfo in
                rowContainer(for: judgeInfo)
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
            // Keep a fixed set of ToolbarItems (conditional ToolbarContent
            // needs iOS 16+); vary the view inside each item instead.
            ToolbarItem(placement: .navigationBarLeading) {
                if isSelecting {
                    Button("Cancel") {
                        isSelecting = false
                        selectedJudgeIDs.removeAll()
                    }
                } else {
                    Button("Select") {
                        isSelecting = true
                    }
                    .disabled(judges.isEmpty)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSelecting {
                    Button(role: .destructive) {
                        showDeleteSelectedConfirmation = true
                    } label: {
                        Text("Delete (\(selectedJudgeIDs.count))")
                    }
                    .disabled(selectedJudgeIDs.isEmpty)
                } else {
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
        .confirmationDialog(
            "Delete \(selectedJudgeIDs.count) judge\(selectedJudgeIDs.count == 1 ? "" : "s")? This cannot be undone.",
            isPresented: $showDeleteSelectedConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedJudges()
            }
            Button("Cancel", role: .cancel) {}
        }
        .task {
            await loadJudges()
        }
    }

    // MARK: Row

    @ViewBuilder
    private func rowContainer(for judgeInfo: JudgeInfo) -> some View {
        if isSelecting {
            Button {
                toggleSelection(judgeInfo)
            } label: {
                HStack {
                    Image(systemName: selectedJudgeIDs.contains(ObjectIdentifier(judgeInfo)) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedJudgeIDs.contains(ObjectIdentifier(judgeInfo)) ? .accentColor : Color(.tertiaryLabel))
                    row(for: judgeInfo)
                }
            }
            .buttonStyle(.plain)
        } else {
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
        // Re-sort the already up-to-date in-memory list (editing a name can
        // change its alphabetical position) instead of reloading from disk:
        // `addJudge`/`updateSelectedJudgeWith` already updated `judges` in
        // memory and queued their own async save, so reloading from disk
        // immediately afterward could race ahead of that pending write and
        // silently discard the change that was just made.
        JudgeListManager.GetInstance().sortJudges()
        judges = JudgeListManager.GetInstance().judges ?? []
    }

    // MARK: Actions

    private func addJudge() {
        let createJudgeView = CreateJudgeView(mode: .create) { _ in
            popViewController()
            refreshJudges()
        }
        pushViewController(UIHostingController(rootView: createJudgeView))
    }

    private func editJudge(_ judgeInfo: JudgeInfo) {
        guard let index = JudgeListManager.GetInstance().judges?.firstIndex(where: { $0 === judgeInfo }) else { return }
        JudgeListManager.GetInstance().selectJudgeInfoAt(index)
        let createJudgeView = CreateJudgeView(mode: .edit(judgeInfo)) { _ in
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

    private func toggleSelection(_ judgeInfo: JudgeInfo) {
        let id = ObjectIdentifier(judgeInfo)
        if selectedJudgeIDs.contains(id) {
            selectedJudgeIDs.remove(id)
        } else {
            selectedJudgeIDs.insert(id)
        }
    }

    private func deleteSelectedJudges() {
        let judgesToDelete = judges.filter { selectedJudgeIDs.contains(ObjectIdentifier($0)) }
        JudgeListManager.GetInstance().removeJudges(judgesToDelete)
        judges = JudgeListManager.GetInstance().judges ?? []
        isSelecting = false
        selectedJudgeIDs.removeAll()
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
