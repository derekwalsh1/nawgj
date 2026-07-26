//
//  ExpensesListView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven "Expenses" list screen
//  (formerly ExpensesTableViewController), pushed from MeetJudgeDetailView's
//  "Manage Expenses" row. Shows one row per expense category with its
//  current total; tapping a row pushes the SwiftUI `ExpenseDetailView` (or,
//  for Lodging, `LodgingExpenseDetailView`).
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI
import UIKit

struct ExpensesListView: View {

    let meet: Meet
    let judge: Judge
    let pushViewController: (UIViewController) -> Void
    let popViewController: () -> Void

    init(meet: Meet, judge: Judge, pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void) {
        self.meet = meet
        self.judge = judge
        self.pushViewController = pushViewController
        self.popViewController = popViewController
    }

    /// Bumped whenever this screen (re)appears so the category totals -
    /// which read directly from `judge.expenses` rather than local
    /// `@State` - redraw with any changes made in the detail screens.
    @State private var refreshToken = UUID()

    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    /// Category order and icons mirror the old storyboard cell order
    /// exactly (Mileage, Meals, Tolls, Airfare, Transportation, Parking,
    /// Lodging, Other), swapping the old bitmap icons for SF Symbols per
    /// the convention established in `MeetDetailView`.
    private let categories: [(type: Expense.ExpenseType, title: String, systemImage: String)] = [
        (.Mileage, "Mileage", "fuelpump.fill"),
        (.Meals, "Meals/Per Diem", "fork.knife"),
        (.Toll, "Tolls", "road.lanes"),
        (.Airfare, "Airfare", "airplane"),
        (.Transportation, "Transportation/Auto Rental", "car.fill"),
        (.Parking, "Parking", "parkingsign"),
        (.Lodging, "Lodging", "bed.double.fill"),
        (.Other, "Other Expenses", "ellipsis.circle.fill"),
    ]

    var body: some View {
        List(categories, id: \.type) { category in
            Button {
                rowTapped(category.type)
            } label: {
                row(for: category)
            }
            .buttonStyle(.plain)
        }
        .id(refreshToken)
        .listStyle(.plain)
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(judge.name) {
                    popViewController()
                }
            }
        }
        .onAppear {
            refreshToken = UUID()
        }
    }

    @ViewBuilder
    private func row(for category: (type: Expense.ExpenseType, title: String, systemImage: String)) -> some View {
        HStack(spacing: 16) {
            Image(systemName: category.systemImage)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .foregroundColor(.primary)
                Text(currencyString(total(for: category.type)))
                    .font(.footnote)
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

    private func total(for type: Expense.ExpenseType) -> Float {
        judge.expenses.first(where: { $0.type == type })?.getExpenseTotal() ?? 0
    }

    private func currencyString(_ value: Float) -> String {
        numberFormatter.string(from: value as NSNumber) ?? ""
    }

    // MARK: Navigation

    private func rowTapped(_ type: Expense.ExpenseType) {
        guard let index = expenseIndex(for: type) else { return }
        MeetListManager.GetInstance().selectExpenseAt(index: index)
        let expense = judge.expenses[index]

        let onFinish: () -> Void = {
            popViewController()
            refreshToken = UUID()
        }

        if type == .Lodging {
            let view = LodgingExpenseDetailView(expense: expense, popViewController: onFinish)
            pushViewController(UIHostingController(rootView: view))
        } else {
            let view = ExpenseDetailView(expense: expense, popViewController: onFinish)
            pushViewController(UIHostingController(rootView: view))
        }
    }

    /// Mirrors the old `ExpensesTableViewController.prepare(for:)`'s
    /// defensive fallback: Other/Lodging expenses are created on demand if
    /// missing. In practice every `Judge` is created with all 8 expense
    /// types up front (see `Judge.init(name:level:fees:)`), so this should
    /// never actually trigger.
    private func expenseIndex(for type: Expense.ExpenseType) -> Int? {
        if let index = judge.expenses.firstIndex(where: { $0.type == type }) {
            return index
        }
        guard type == .Other || type == .Lodging else { return nil }
        guard let newExpense = Expense(type: type, date: meet.startDate) else { return nil }
        judge.expenses.append(newExpense)
        return judge.expenses.firstIndex(where: { $0.type == type })
    }
}
