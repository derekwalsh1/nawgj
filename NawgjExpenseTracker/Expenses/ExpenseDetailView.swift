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
//  model object. Edits are staged in local @State and only committed back
//  to `expense` (and persisted via MeetListManager) when Done is tapped,
//  preserving the old screen's Cancel-discards-edits / Done-saves behavior.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI

struct ExpenseDetailView: View {

    let expense: Expense
    let popViewController: () -> Void

    @State private var amountText: String
    @State private var isCustomMileageRate: Bool
    @State private var mileageRateText: String
    @State private var date: Date
    @State private var notes: String

    init(expense: Expense, popViewController: @escaping () -> Void) {
        self.expense = expense
        self.popViewController = popViewController

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

    private var isAmountValid: Bool {
        Self.numberFormatter.number(from: amountText) != nil
    }

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
            }

            if isMileageExpense {
                Section("Mileage Rate") {
                    Toggle("Manual Mileage Rate", isOn: $isCustomMileageRate)
                        .onChange(of: isCustomMileageRate) { newValue in
                            if !newValue {
                                mileageRateText = Self.numberFormatter.string(from: NSNumber(value: Meet.getMileageRate(forDate: date))) ?? ""
                            }
                        }
                    TextField("Mileage Rate", text: $mileageRateText)
                        .keyboardType(.decimalPad)
                        .disabled(!isCustomMileageRate)
                }
            }

            Section("Date") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .onChange(of: date) { newValue in
                        if isMileageExpense && !isCustomMileageRate {
                            mileageRateText = Self.numberFormatter.string(from: NSNumber(value: Meet.getMileageRate(forDate: newValue))) ?? ""
                        }
                    }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle(expense.type.description)
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
                .disabled(!isAmountValid)
            }
        }
    }

    private func saveExpense() {
        if let amount = Self.numberFormatter.number(from: amountText) {
            expense.amount = amount.floatValue
        } else {
            expense.amount = 0
        }
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
