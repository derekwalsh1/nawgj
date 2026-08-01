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
//  model object. Edits save live as each field changes (see
//  `saveIfValid()`) rather than only on a Done button - there's no
//  Cancel/Done, just the standard back button.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI

struct LodgingExpenseDetailView: View {

    let expense: Expense

    @State private var totalText: String
    @State private var nights: Int
    @State private var date: Date
    @State private var notes: String

    @FocusState private var isTotalFocused: Bool

    init(expense: Expense) {
        self.expense = expense

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
                    .focused($isTotalFocused)
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
        .onChange(of: totalText) { _ in saveIfValid() }
        .onChange(of: nights) { _ in saveIfValid() }
        .onChange(of: date) { _ in saveIfValid() }
        .onChange(of: notes) { _ in saveIfValid() }
        .onChange(of: isTotalFocused) { focused in
            // Wipe the field's contents as soon as it's tapped into, rather
            // than leaving the existing value (e.g. "0") for new input to be
            // appended to.
            if focused {
                totalText = ""
            }
        }
    }

    private func saveIfValid() {
        guard let total = Self.numberFormatter.number(from: totalText) else { return }
        if nights > 0 {
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
