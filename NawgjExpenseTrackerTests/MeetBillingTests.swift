//
//  MeetBillingTests.swift
//  NawgjExpenseTrackerTests
//
//  Unit tests covering the per-judge, per-day minimum-billing-hours rule
//  (Meet.recomputeBillableHours(for:day:)): the 3-hour minimum applies once
//  across everything a judge worked on a given day, not to each session
//  independently, and manually-overridden hours participate in that same
//  rule as the judge's "actual hours worked".
//

import XCTest
@testable import Expenses

final class MeetBillingTests: XCTestCase {

    private func date(hour: Int, minute: Int, day: Int = 1) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    private func makeSession(name: String = "Session", startHour: Int, startMinute: Int = 0, endHour: Int, endMinute: Int = 0) -> Session {
        return Session(name: name,
                       startTime: date(hour: startHour, minute: startMinute),
                       endTime: date(hour: endHour, minute: endMinute),
                       breaks: 0,
                       breakTimeInMins: 0)
    }

    private func makeMeet(sessions: [Session], day: Int = 1) -> (meet: Meet, day: MeetDay) {
        let meetDay = MeetDay(meetDate: date(hour: 0, minute: 0, day: day), sessions: sessions, id: "day-\(day)")
        let meet = Meet(name: "Test Meet", startDate: date(hour: 0, minute: 0))!
        meet.days = [meetDay]
        return (meet, meetDay)
    }

    private func makeJudge() -> Judge {
        return Judge(name: "Test Judge", level: .National, expenses: [], fees: [])
    }

    // MARK: Single session, under the minimum

    func testAssignJudge_singleShortSession_billsTheMinimum() {
        let session = makeSession(startHour: 8, endHour: 9) // 1 hour
        let (meet, day) = makeMeet(sessions: [session])
        let judge = makeJudge()

        meet.assignJudge(judge, to: session, in: day)

        XCTAssertEqual(judge.totalBillableHours(), MeetDay.MIN_BILLING_HOURS)
    }

    // MARK: Multiple sessions - combined actual hours already clear the minimum

    func testAssignJudge_twoBackToBackSessions_billsActualCombinedHours_notDoubleMinimum() {
        let session1 = makeSession(name: "Session 1", startHour: 8, endHour: 10) // 2 hours
        let session2 = makeSession(name: "Session 2", startHour: 10, endHour: 12) // 2 hours
        let (meet, day) = makeMeet(sessions: [session1, session2])
        let judge = makeJudge()

        meet.assignJudge(judge, to: session1, in: day)
        meet.assignJudge(judge, to: session2, in: day)

        // Each session alone is under the minimum, but worked together they
        // total 4 actual hours - already above the 3-hour floor, so the
        // judge should be billed 4, not 3+3=6.
        XCTAssertEqual(judge.totalBillableHours(), 4.0)
    }

    func testAssignJudge_twoNonContiguousShortSessions_sameDay_billsTheMinimumOnce() {
        // Sessions with a gap between them (not back-to-back) on the same
        // day still share a single 3-hour day minimum.
        let session1 = makeSession(name: "Morning", startHour: 8, endHour: 9) // 1 hour
        let session2 = makeSession(name: "Evening", startHour: 17, endHour: 18) // 1 hour
        let (meet, day) = makeMeet(sessions: [session1, session2])
        let judge = makeJudge()

        meet.assignJudge(judge, to: session1, in: day)
        meet.assignJudge(judge, to: session2, in: day)

        XCTAssertEqual(judge.totalBillableHours(), MeetDay.MIN_BILLING_HOURS)
    }

    // MARK: Unassigning re-applies the day minimum to what remains

    func testUnassignJudge_leavesRemainingSessionAlone_rebillsItAtTheMinimum() {
        let session1 = makeSession(name: "Session 1", startHour: 8, endHour: 10) // 2 hours
        let session2 = makeSession(name: "Session 2", startHour: 10, endHour: 12) // 2 hours
        let (meet, day) = makeMeet(sessions: [session1, session2])
        let judge = makeJudge()

        meet.assignJudge(judge, to: session1, in: day)
        meet.assignJudge(judge, to: session2, in: day)
        XCTAssertEqual(judge.totalBillableHours(), 4.0)

        meet.unassignJudge(judge, from: session2)

        XCTAssertEqual(judge.totalBillableHours(), MeetDay.MIN_BILLING_HOURS)
    }

    // MARK: Manually-overridden hours participate in the same minimum rule

    func testOverriddenFee_belowMinimum_isToppedUpToMinimum() {
        let session = makeSession(startHour: 8, endHour: 12) // 4 hours
        let (meet, day) = makeMeet(sessions: [session])
        let judge = makeJudge()

        meet.assignJudge(judge, to: session, in: day)
        guard let fee = judge.fees.first else { return XCTFail("Expected a fee to be created") }

        // Judge only actually worked 2 of the available 4 hours.
        fee.hoursOverridden = true
        fee.actualHours = 2.0
        meet.recomputeBillableHours(for: judge, day: day)

        XCTAssertEqual(fee.hours, MeetDay.MIN_BILLING_HOURS)
        XCTAssertEqual(fee.actualHours, 2.0, "The entered actual hours should be preserved, not overwritten by the minimum top-up")
    }

    func testOverriddenFee_aboveMinimum_isNotAdjusted() {
        let session = makeSession(startHour: 8, endHour: 12) // 4 hours
        let (meet, day) = makeMeet(sessions: [session])
        let judge = makeJudge()

        meet.assignJudge(judge, to: session, in: day)
        guard let fee = judge.fees.first else { return XCTFail("Expected a fee to be created") }

        fee.hoursOverridden = true
        fee.actualHours = 5.0
        meet.recomputeBillableHours(for: judge, day: day)

        XCTAssertEqual(fee.hours, 5.0)
    }

    // MARK: Fees on different days are independent

    func testFeesOnDifferentDays_eachGetTheirOwnMinimum() {
        let sessionDay1 = makeSession(startHour: 8, endHour: 9) // 1 hour
        let sessionDay2 = makeSession(startHour: 8, endHour: 9) // 1 hour
        let day1 = MeetDay(meetDate: date(hour: 0, minute: 0, day: 1), sessions: [sessionDay1], id: "day-1")
        let day2 = MeetDay(meetDate: date(hour: 0, minute: 0, day: 2), sessions: [sessionDay2], id: "day-2")
        let meet = Meet(name: "Test Meet", startDate: date(hour: 0, minute: 0, day: 1))!
        meet.days = [day1, day2]
        let judge = makeJudge()

        meet.assignJudge(judge, to: sessionDay1, in: day1)
        meet.assignJudge(judge, to: sessionDay2, in: day2)

        XCTAssertEqual(judge.totalBillableHours(), MeetDay.MIN_BILLING_HOURS * 2)
    }

    // MARK: Excluded fees don't participate in the day total

    func testExcludedFee_doesNotParticipateInDayMinimum() {
        let session1 = makeSession(name: "Session 1", startHour: 8, endHour: 9) // 1 hour
        let session2 = makeSession(name: "Session 2", startHour: 9, endHour: 10) // 1 hour
        let (meet, day) = makeMeet(sessions: [session1, session2])
        let judge = makeJudge()

        meet.assignJudge(judge, to: session1, in: day)
        meet.assignJudge(judge, to: session2, in: day)

        guard let excludedFee = judge.fees.first(where: { $0.getSessionUUID() == session1.getUUID() }) else {
            return XCTFail("Expected a fee for session1")
        }
        excludedFee.exclude = true
        meet.recomputeBillableHours(for: judge, day: day)

        // The remaining (non-excluded) session is alone under the minimum,
        // so it should be topped up on its own.
        guard let remainingFee = judge.fees.first(where: { $0.getSessionUUID() == session2.getUUID() }) else {
            return XCTFail("Expected a fee for session2")
        }
        XCTAssertEqual(remainingFee.hours, MeetDay.MIN_BILLING_HOURS)
        XCTAssertEqual(excludedFee.getHours(), 0.0)
    }
}
