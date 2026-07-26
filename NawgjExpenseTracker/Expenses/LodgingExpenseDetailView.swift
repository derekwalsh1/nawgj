//
//  LodgingExpenseDetailView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for LodgingExpenseDetailsViewController. Shows a
//  single editable "Total($)" field representing amountPerNight *
//  totalNights, back-computing amountPerNight from the entered total and
//  number of nights - matching the old screen's UX.
//
//  Pushed from ExpensesListView after MeetListManager.selectExpenseAt(index:)
//  has already been called, so `expense` is the live, already-selected
//  model object. Edits are staged in local @State and only committed back
//  to `expense` (and persisted via MeetListManager) when Done is tapped.
//  Unlike the old imperative screen (which mutated `expense.amountPerNight`
//  live on every keystroke, so Cancel didn't actually discard that one
//  field), this SwiftUI version discards ALL edits on Cancel, since that's
//  the behavior a Cancel button implies.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI

struct LodgingExpenseDetailView: View {

    let expense: Expense
    let popViewController: () -> Void

    @State private var totalText: String
    @State private var nights: Int
    @State private var date: Date
    @State private var notes: String

    init(expense: Expense, popViewController: @escaping () -> Void) {
        self.expense = expense
        self.popViewController = popViewController

        let nightsValue = expense.totalNights ?? 1
        _nights = State(initialValue: nightsValue)
        let total = (expense.amountPerNight ?? 0) * Float(nightsValue)
        _totalText = State(initialValue: Self.numberFormatter.string(from: NSNumber(value: total)) ?? "")
        _date = State(initialValue: expense.date ?? Date())
        _notes = State(initialValue: expense.notes)
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private var isTotalValid: Bool {
        Self.numberFormatter.number(from: totalText) != nil
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Total($)") {
                TextField("Total($)", text: $totalText)
                    .keyboardType(.decimalPad)
            }

            Section {
                Stepper("Nights: \(nights)", value: $nights, in: 0...365)
            }

            Section("Date") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("Lodging")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    popViewController()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveExpense()
                    popViewController()
                }
                .disabled(!isTotalValid)
            }
        }
    }

    private func saveExpense() {
        if let total = Self.numberFormatter.number(from: totalText), nights > 0 {
            expense.amountPerNight = total.floatValue / Float(nights)
        } else {
            expense.amountPerNight = 0
        }
        expense.notes = notes
        expense.date = date
        expense.totalNights = nights

        MeetListManager.GetInstance().updateSelectedExpenseWith(expense: expense)
    }
}
