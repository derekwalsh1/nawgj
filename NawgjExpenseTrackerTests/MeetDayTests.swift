//
//  MeetDayTests.swift
//  NawgjExpenseTrackerTests
//
//  Unit tests covering MeetDay's billing-time rounding, break-time, and
//  minimum-billing-hours rules. These lock in current behavior so future
//  refactors don't silently change how judges are billed.
//

import XCTest
@testable import Expenses

final class MeetDayTests: XCTestCase {

    private func date(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    private func makeMeetDay(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, breaks: Int = 0) -> MeetDay {
        return MeetDay(meetDate: date(hour: 0, minute: 0),
                        startTime: date(hour: startHour, minute: startMinute),
                        endTime: date(hour: endHour, minute: endMinute),
                        breaks: breaks)
    }

    // MARK: totalTimeInHours rounding
    // Current behavior rounds to the nearest half hour: a remainder of
    // <=15 minutes rounds down, >15 and <=45 minutes rounds to :30, and
    // >45 minutes rounds up to the next hour.

    func testTotalTimeInHours_exactHours_needsNoRounding() {
        let meetDay = makeMeetDay(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)
        XCTAssertEqual(meetDay.totalTimeInHours(), 4.0)
    }

    func testTotalTimeInHours_roundsDown_whenRemainderIsAtMost15Minutes() {
        let meetDay = makeMeetDay(startHour: 8, startMinute: 0, endHour: 12, endMinute: 15)
        XCTAssertEqual(meetDay.totalTimeInHours(), 4.0)
    }

    func testTotalTimeInHours_roundsToHalfHour_whenRemainderIsBetween15And45Minutes() {
        let meetDay = makeMeetDay(startHour: 8, startMinute: 0, endHour: 12, endMinute: 30)
        XCTAssertEqual(meetDay.totalTimeInHours(), 4.5)

        let meetDayAt45 = makeMeetDay(startHour: 8, startMinute: 0, endHour: 12, endMinute: 45)
        XCTAssertEqual(meetDayAt45.totalTimeInHours(), 4.5)
    }

    func testTotalTimeInHours_roundsUp_whenRemainderExceeds45Minutes() {
        let meetDay = makeMeetDay(startHour: 8, startMinute: 0, endHour: 12, endMinute: 46)
        XCTAssertEqual(meetDay.totalTimeInHours(), 5.0)
    }

    // MARK: breakTimeInHours

    func testBreakTimeInHours_usesDefaultBreakTime_whenNotOverridden() {
        let meetDay = makeMeetDay(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0, breaks: 2)
        // 2 breaks * 30 default minutes = 60 minutes = 1 hour
        XCTAssertEqual(meetDay.breakTimeInHours(), 1.0)
    }

    func testBreakTimeInHours_usesCustomBreakTime() {
        let meetDay = MeetDay(meetDate: date(hour: 0, minute: 0),
                               startTime: date(hour: 8, minute: 0),
                               endTime: date(hour: 12, minute: 0),
                               breaks: 3, breakTime: 10)
        // 3 breaks * 10 minutes = 30 minutes = 0.5 hour
        XCTAssertEqual(meetDay.breakTimeInHours(), 0.5)
    }

    func testBreakTimeInHours_isZero_withNoBreaks() {
        let meetDay = makeMeetDay(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0, breaks: 0)
        XCTAssertEqual(meetDay.breakTimeInHours(), 0.0)
    }

    // MARK: totalBillableTimeInHours

    func testTotalBillableTimeInHours_subtractsBreakTime() {
        let meetDay = makeMeetDay(startHour: 8, startMinute: 0, endHour: 13, endMinute: 0, breaks: 2)
        // 5 total hours - 1 hour of breaks (2 * 30 min) = 4 billable hours
        XCTAssertEqual(meetDay.totalBillableTimeInHours(), 4.0)
    }

    func testTotalBillableTimeInHours_capsBreakDeductionAtMaxBreakTime() {
        // Many long breaks would normally deduct more than MAX_BREAK_TIME_HOURS (2.0),
        // but the deduction should be capped at 2 hours.
        let meetDay = MeetDay(meetDate: date(hour: 0, minute: 0),
                               startTime: date(hour: 8, minute: 0),
                               endTime: date(hour: 16, minute: 0),
                               breaks: 10, breakTime: 60)
        // 8 total hours - capped 2 hour break deduction = 6 billable hours
        XCTAssertEqual(meetDay.totalBillableTimeInHours(), 6.0)
    }

    func testTotalBillableTimeInHours_neverGoesBelowMinimumBillingHours() {
        let meetDay = makeMeetDay(startHour: 8, startMinute: 0, endHour: 8, endMinute: 30, breaks: 0)
        XCTAssertEqual(meetDay.totalBillableTimeInHours(), MeetDay.MIN_BILLING_HOURS)
    }
}
