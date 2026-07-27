//
//  MeetJudgeDetailView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven "Judge Details" screen
//  (formerly JudgeDetailViewController + JudgeSummaryTableViewDelegate),
//  pushed from MeetJudgeListView.
//
//  Pushes the SwiftUI "Adjust Fees" (FeeListView), "Manage Expenses"
//  (ExpensesListView), and "Invoice" (JudgeInvoiceView) screens directly -
//  all sub-screens are now SwiftUI.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI
import UIKit

struct MeetJudgeDetailView: View {

    let meet: Meet
    let judge: Judge
    let pushViewController: (UIViewController) -> Void
    let popViewController: () -> Void

    @State private var name: String
    @State private var notes: String
    @State private var level: Judge.Level
    @State private var isPaid: Bool
    @State private var isMeetRef: Bool
    @State private var meetRefereeFeeText: String
    @State private var isW9Received: Bool
    @State private var isReceiptsReceived: Bool

    /// Bumped whenever this screen reappears (e.g. after returning from
    /// "Adjust Fees"/"Manage Expenses") to force the fee/expense summary
    /// sections - which read directly from `judge.fees`/`judge.expenses`
    /// rather than local `@State` - to redraw with any changes made there.
    @State private var refreshToken = UUID()

    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    private var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    init(meet: Meet, judge: Judge, pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void) {
        self.meet = meet
        self.judge = judge
        self.pushViewController = pushViewController
        self.popViewController = popViewController

        _name = State(initialValue: judge.name)
        _notes = State(initialValue: judge.getNotes())
        _level = State(initialValue: judge.level)
        _isPaid = State(initialValue: judge.isPaid())
        _isMeetRef = State(initialValue: judge.isMeetRef())
        let decimalFormatter = NumberFormatter()
        decimalFormatter.numberStyle = .decimal
        _meetRefereeFeeText = State(initialValue: decimalFormatter.string(from: NSNumber(value: judge.getMeetRefereeFee())) ?? "")
        _isW9Received = State(initialValue: judge.isW9Received())
        _isReceiptsReceived = State(initialValue: judge.isReceiptsReceived())
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .onChange(of: name) { _ in persistChanges() }

                Picker("Level", selection: $level) {
                    ForEach(Judge.Level.selectableCases, id: \.self) { level in
                        Text(level.description).tag(level)
                    }
                }
                .onChange(of: level) { newLevel in
                    judge.changeLevel(level: newLevel)
                    persistChanges()
                }

                TextField("Notes", text: $notes)
                    .onChange(of: notes) { _ in persistChanges() }
            }

            Section {
                Toggle("Paid", isOn: $isPaid)
                    .onChange(of: isPaid) { _ in persistChanges() }

                Toggle("Meet Referee", isOn: $isMeetRef)
                    .onChange(of: isMeetRef) { _ in persistChanges() }

                if isMeetRef {
                    HStack {
                        Text("Referee Fee ($)")
                        Spacer()
                        TextField("0", text: $meetRefereeFeeText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: meetRefereeFeeText) { _ in persistChanges() }
                    }
                }

                Toggle("W9 Received", isOn: $isW9Received)
                    .onChange(of: isW9Received) { _ in persistChanges() }

                Toggle("Receipts Received", isOn: $isReceiptsReceived)
                    .onChange(of: isReceiptsReceived) { _ in persistChanges() }
            }

            Section {
                summaryRow(title: "Manage Expenses", detail: "Total: \(currencyString(judge.totalExpenses()))") {
                    showExpenses()
                }
            }

            Section {
                summaryRow(title: "Adjust Fees", detail: "Total: \(currencyString(judge.totalFees()))") {
                    showFees()
                }
            }

            Section("Judge Fees") {
                ForEach(Array(judge.fees.enumerated()), id: \.offset) { _, fee in
                    HStack {
                        Text(dateFormatter.string(from: fee.date))
                        Spacer()
                        Text(currencyString(fee.getFeeTotal()))
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Text("Total Fees").fontWeight(.bold)
                    Spacer()
                    Text(currencyString(judge.totalFees())).fontWeight(.bold)
                }
            }

            Section("Judge Expenses") {
                ForEach(Array(judge.expenses.enumerated()), id: \.offset) { _, expense in
                    HStack {
                        Text(expense.type.description)
                        Spacer()
                        Text(currencyString(expense.getExpenseTotal()))
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Text("Total Expenses").fontWeight(.bold)
                    Spacer()
                    Text(currencyString(judge.totalExpenses())).fontWeight(.bold)
                }
                HStack {
                    Text("Total Fees & Expenses").fontWeight(.bold)
                    Spacer()
                    Text(currencyString(judge.totalExpenses() + judge.totalFees())).fontWeight(.bold)
                }
            }
        }
        .id(refreshToken)
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Judge List") {
                    persistChanges()
                    popViewController()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Invoice") {
                    showInvoice()
                }
            }
        }
        .onAppear {
            refreshToken = UUID()
        }
    }

    @ViewBuilder
    private func summaryRow(title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
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

    private func currencyString(_ value: Float) -> String {
        numberFormatter.string(from: value as NSNumber) ?? ""
    }

    // MARK: Persistence
    //
    // Edits are written straight into `judge` (a reference type shared with
    // `MeetListManager`) and saved on every change, mirroring the pattern
    // established in `MeetDetailView.persistFieldChanges()`.

    private func persistChanges() {
        judge.name = name.isEmpty ? "Unknown Judge" : name
        judge.setNotes(notes)
        judge.setPaid(isPaid)
        judge.setMeetRef(isMeetRef)
        judge.setW9Received(isW9Received)
        judge.setReceiptsReceived(isReceiptsReceived)
        if let amount = decimalFormatter.number(from: meetRefereeFeeText) {
            judge.setMeetRefereeFee(Float(truncating: amount))
        }
        MeetListManager.GetInstance().updateSelectedJudgeWith(judge: judge)
    }

    // MARK: Actions

    private func showExpenses() {
        persistChanges()
        let view = ExpensesListView(meet: meet, judge: judge, pushViewController: pushViewController, popViewController: popViewController)
        pushViewController(UIHostingController(rootView: view))
    }

    private func showFees() {
        persistChanges()
        let view = FeeListView(meet: meet, judge: judge, pushViewController: pushViewController, popViewController: popViewController)
        pushViewController(UIHostingController(rootView: view))
    }

    private func showInvoice() {
        persistChanges()
        let view = JudgeInvoiceView(judge: judge, meet: meet)
        pushViewController(UIHostingController(rootView: view))
    }
}
