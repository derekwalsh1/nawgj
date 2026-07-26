//
//  FeeDetailView.swift
//  NawgjExpenceTracker
//
//  SwiftUI replacement for FeeDetailsViewController. Pushed from
//  FeeListView after MeetListManager.selectFeeAt(index:) and
//  selectMeetDayForFee(fee:) have already been called, so `fee` is the
//  live, already-selected model object and `meetDay` is its associated
//  MeetDay (used to display total/break time and to compute the default,
//  non-overridden billable hours).
//
//  Unlike the Expenses detail screens, this screen has no Cancel option in
//  the old UIKit code - the "Fee List" back button unwound and saved
//  unconditionally via `prepare(for:sender:)`. This SwiftUI replacement
//  matches that behavior by persisting changes immediately whenever a
//  field changes (see `persistFee()`), the same live-save convention used
//  by MeetDetailView/MeetJudgeDetailView, rather than the Cancel/Done
//  staging pattern used by the Expenses detail screens (which did have a
//  Cancel button in the old code).
//
//  New feature: manual rate override. `Fee` already had `rate` and
//  `rateOverridden` properties, but the old screen never actually let the
//  user edit them - it only ever displayed `judge.level.rate` and never
//  persisted a rate back onto the fee. This screen adds an "Adjust Rate"
//  toggle + text field so a judge's rate can be manually overridden for a
//  single fee, independent of their level's standard rate. See
//  `Judge.changeLevel(level:)`, which was updated to skip fees with
//  `rateOverridden == true` so overrides survive level changes.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI

struct FeeDetailView: View {

    let fee: Fee
    let judge: Judge
    let meetDay: MeetDay?
    let popViewController: () -> Void

    @State private var hoursOverridden: Bool
    @State private var adjustedHours: Int
    @State private var adjustedMinutes: Int
    @State private var rateOverridden: Bool
    @State private var rateText: String
    @State private var excludeJudge: Bool

    init(fee: Fee, judge: Judge, meetDay: MeetDay?, popViewController: @escaping () -> Void) {
        self.fee = fee
        self.judge = judge
        self.meetDay = meetDay
        self.popViewController = popViewController

        _hoursOverridden = State(initialValue: fee.hoursOverridden)
        _excludeJudge = State(initialValue: fee.exclude ?? false)
        _rateOverridden = State(initialValue: fee.rateOverridden)

        let hours = Int(fee.hours)
        let minutes = Int(((fee.hours - Float(hours)) * 60).rounded())
        _adjustedHours = State(initialValue: hours)
        _adjustedMinutes = State(initialValue: minutes)

        _rateText = State(initialValue: Self.rateFormatter.string(from: NSNumber(value: fee.rate)) ?? "")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    private static let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter
    }()

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    private static let rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private static let hoursRange = Array(0...24)
    private static let minutesRange = Array(0...60)

    private var billableHours: Float {
        if hoursOverridden {
            return Float(adjustedHours) + Float(adjustedMinutes) / 60.0
        }
        return meetDay?.totalBillableTimeInHours() ?? fee.hours
    }

    private var effectiveRate: Float {
        if rateOverridden, let parsed = Self.rateFormatter.number(from: rateText) {
            return parsed.floatValue
        }
        return judge.level.rate
    }

    private var totalFee: Float {
        excludeJudge ? 0 : billableHours * effectiveRate
    }

    var body: some View {
        Form {
            Section {
                labeledRow("Date", Self.dateFormatter.string(from: fee.date))
                labeledRow("Total Time", Self.timeFormatter.string(from: TimeInterval((meetDay?.totalTimeInHours() ?? 0) * 60 * 60)) ?? "")
                labeledRow("Break Time", Self.timeFormatter.string(from: TimeInterval((meetDay?.breakTimeInHours() ?? 0) * 60 * 60)) ?? "")
                labeledRow("Billable Time", Self.timeFormatter.string(from: TimeInterval(billableHours * 60 * 60)) ?? "")
                labeledRow("Judge's Rate", rateOverridden ? "$\(Self.rateFormatter.string(from: NSNumber(value: effectiveRate)) ?? "0")/Hour (Manual)" : String(format: "$%0.1f/Hour (%@)", judge.level.rate, judge.level.description))
                labeledRow("Fee", Self.currencyFormatter.string(from: totalFee as NSNumber) ?? "")
            }

            Section("Fee Adjustments") {
                Toggle("Adjust Judge's Time", isOn: $hoursOverridden)
                    .disabled(excludeJudge)
                    .onChange(of: hoursOverridden) { _ in persistFee() }

                if hoursOverridden {
                    HStack {
                        Picker("Hours", selection: $adjustedHours) {
                            ForEach(Self.hoursRange, id: \.self) { hour in
                                Text("\(hour) \(hour == 1 ? "hour" : "hours")").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .onChange(of: adjustedHours) { _ in persistFee() }

                        Picker("Minutes", selection: $adjustedMinutes) {
                            ForEach(Self.minutesRange, id: \.self) { minute in
                                Text("\(minute) \(minute == 1 ? "minute" : "minutes")").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .onChange(of: adjustedMinutes) { _ in persistFee() }
                    }
                }

                Toggle("Adjust Rate", isOn: $rateOverridden)
                    .onChange(of: rateOverridden) { newValue in
                        if !newValue {
                            rateText = Self.rateFormatter.string(from: NSNumber(value: judge.level.rate)) ?? ""
                        }
                        persistFee()
                    }

                if rateOverridden {
                    HStack {
                        Text("Rate($)")
                        Spacer()
                        TextField("Rate($)", text: $rateText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: rateText) { _ in persistFee() }
                    }
                }

                Toggle("Judge did not work this day", isOn: $excludeJudge)
                    .onChange(of: excludeJudge) { _ in persistFee() }
            }
        }
        .navigationTitle(Self.dateFormatter.string(from: fee.date))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Fee List") {
                    popViewController()
                }
            }
        }
    }

    @ViewBuilder
    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }

    private func persistFee() {
        fee.hoursOverridden = hoursOverridden
        fee.exclude = excludeJudge
        fee.hours = billableHours
        fee.rateOverridden = rateOverridden
        fee.rate = effectiveRate

        MeetListManager.GetInstance().updateSelectedFeeWith(fee: fee)
    }
}
