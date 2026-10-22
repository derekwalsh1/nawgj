//
//  ExpenseDetailView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for ExpenseDetailsViewController, covering the 7
//  non-Lodging expense types (Mileage, Meals, Tolls, Airfare,
//  Transportation, Parking, Other). Lodging has its own dedicated screen,
//  LodgingExpenseDetailView, matching the old app's split between
//  ExpenseDetailsViewController and LodgingExpenseDetailsViewController.
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

struct ExpenseDetailView: View {

    let expense: Expense

    @State private var amountText: String
    @State private var isCustomMileageRate: Bool
    @State private var mileageRateText: String
    @State private var date: Date
    @State private var notes: String

    private enum Field: Hashable {
        case amount
        case mileageRate
    }
    @FocusState private var focusedField: Field?

    init(expense: Expense) {
        self.expense = expense

        let initialDate = expense.date ?? Date()
        _date = State(initialValue: initialDate)
        _amountText = State(initialValue: Self.numberFormatter.string(from: NSNumber(value: expense.amount)) ?? "")
        _notes = State(initialValue: expense.notes)
        _isCustomMileageRate = State(initialValue: expense.isCustomMileageRate ?? false)

        var rate = expense.mileageRate
        if rate == 0 {
            rate = Meet.getMileageRate(forDate: initialDate)
        }
        _mileageRateText = State(initialValue: Self.numberFormatter.string(from: NSNumber(value: rate)) ?? "")
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private var isMileageExpense: Bool { expense.type == .Mileage }

    private var iconName: String {
        switch expense.type {
        case .Mileage: return "fuelpump.fill"
        case .Meals: return "fork.knife"
        case .Toll: return "road.lanes"
        case .Airfare: return "airplane"
        case .Transportation: return "car.fill"
        case .Parking: return "parkingsign"
        case .Lodging: return "bed.double.fill"
        case .Other: return "ellipsis.circle.fill"
        }
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Image(systemName: iconName)
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section(isMileageExpense ? "Miles" : "Amount($)") {
                TextField(isMileageExpense ? "Miles" : "Amount($)", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
            }

            if isMileageExpense {
                Section("Mileage Rate") {
                    Toggle("Manual Mileage Rate", isOn: $isCustomMileageRate)
                        .onChange(of: isCustomMileageRate) { newValue in
                            if !newValue {
                                mileageRateText = Self.numberFormatter.string(from: NSNumber(value: Meet.getMileageRate(forDate: date))) ?? ""
                            }
                            saveIfValid()
                        }
                    TextField("Mileage Rate", text: $mileageRateText)
                        .keyboardType(.decimalPad)
                        .disabled(!isCustomMileageRate)
                        .focused($focusedField, equals: .mileageRate)
                }
            }

            Section("Date") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .onChange(of: date) { newValue in
                        if isMileageExpense && !isCustomMileageRate {
                            mileageRateText = Self.numberFormatter.string(from: NSNumber(value: Meet.getMileageRate(forDate: newValue))) ?? ""
                        }
                        saveIfValid()
                    }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle(expense.type.description)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: amountText) { _ in saveIfValid() }
        .onChange(of: mileageRateText) { _ in saveIfValid() }
        .onChange(of: notes) { _ in saveIfValid() }
        .onChange(of: focusedField) { newValue in
            // Wipe the field's contents as soon as it's tapped into, rather
            // than leaving the existing value (e.g. "0") for new input to be
            // appended to.
            switch newValue {
            case .amount: amountText = ""
            case .mileageRate: mileageRateText = ""
            case nil: break
            }
        }
    }

    private func saveIfValid() {
        guard let amount = Self.numberFormatter.number(from: amountText) else { return }
        expense.amount = amount.floatValue
        expense.notes = notes
        expense.date = date

        if isMileageExpense {
            expense.isCustomMileageRate = isCustomMileageRate
            if let rate = Self.numberFormatter.number(from: mileageRateText) {
                expense.mileageRate = rate.floatValue
            }
        }

        MeetListManager.GetInstance().updateSelectedExpenseWith(expense: expense)
    }
}
