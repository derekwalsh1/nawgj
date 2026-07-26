//
//  FeeListView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for the old storyboard-driven "Fees" list screen
//  (formerly FeeTableViewController), pushed from MeetJudgeDetailView's
//  "Adjust Fees" row. Shows one row per meet-day fee; tapping a row pushes
//  the SwiftUI `FeeDetailView`.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI
import UIKit

struct FeeListView: View {

    let judge: Judge
    let pushViewController: (UIViewController) -> Void
    let popViewController: () -> Void

    init(judge: Judge, pushViewController: @escaping (UIViewController) -> Void, popViewController: @escaping () -> Void) {
        self.judge = judge
        self.pushViewController = pushViewController
        self.popViewController = popViewController
    }

    /// Bumped whenever this screen (re)appears so rows - which read
    /// directly from `judge.fees` rather than local `@State` - redraw with
    /// any changes made in `FeeDetailView`.
    @State private var refreshToken = UUID()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    var body: some View {
        List(Array(judge.fees.enumerated()), id: \.offset) { index, fee in
            Button {
                rowTapped(index: index)
            } label: {
                row(for: fee)
            }
            .buttonStyle(.plain)
        }
        .id(refreshToken)
        .listStyle(.plain)
        .navigationTitle("Fees")
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
    private func row(for fee: Fee) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateFormatter.string(from: fee.date))
                    .foregroundColor(.primary)
                Text(String(format: "Hours: %0.2f - Total Fees: %@", fee.getHours(), Self.numberFormatter.string(from: fee.getFeeTotal() as NSNumber) ?? ""))
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

    // MARK: Navigation

    private func rowTapped(index: Int) {
        MeetListManager.GetInstance().selectFeeAt(index: index)
        let fee = judge.fees[index]
        MeetListManager.GetInstance().selectMeetDayForFee(fee: fee)
        let meetDay = MeetListManager.GetInstance().getSelectedMeetDay()

        let onFinish: () -> Void = {
            popViewController()
            refreshToken = UUID()
        }

        let view = FeeDetailView(fee: fee, judge: judge, meetDay: meetDay, popViewController: onFinish)
        pushViewController(UIHostingController(rootView: view))
    }
}
