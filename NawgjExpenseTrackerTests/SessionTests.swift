//
//  SessionTests.swift
//  NawgjExpenseTrackerTests
//
//  Unit tests covering Session's billing-time math (shared with MeetDay via
//  BillableTimeRange) and overlap detection.
//

import XCTest
@testable import Expenses

final class SessionTests: XCTestCase {

    private func date(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    private func makeSession(name: String = "Session 1", startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, breaks: Int = 0) -> Session {
        return Session(name: name,
                       startTime: date(hour: startHour, minute: startMinute),
                       endTime: date(hour: endHour, minute: endMinute),
                       breaks: breaks,
                       breakTimeInMins: nil)
    }

    // MARK: totalTimeInHours rounding (mirrors MeetDayTests)

    func testTotalTimeInHours_exactHours_needsNoRounding() {
        let session = makeSession(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)
        XCTAssertEqual(session.totalTimeInHours(), 4.0)
    }

    func testTotalTimeInHours_roundsToHalfHour_whenRemainderIsBetween15And45Minutes() {
        let session = makeSession(startHour: 8, startMinute: 0, endHour: 12, endMinute: 30)
        XCTAssertEqual(session.totalTimeInHours(), 4.5)
    }

    func testTotalTimeInHours_roundsUp_whenRemainderExceeds45Minutes() {
        let session = makeSession(startHour: 8, startMinute: 0, endHour: 12, endMinute: 46)
        XCTAssertEqual(session.totalTimeInHours(), 5.0)
    }

    // MARK: breakTimeInHours / totalBillableTimeInHours

    func testBreakTimeInHours_usesDefaultBreakMinutes() {
        let session = makeSession(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0, breaks: 2)
        XCTAssertEqual(session.breakTimeInHours(), Float(2 * MeetDay.DEFAULT_BREAK_TIME_MINS) / 60.0)
    }

    func testTotalBillableTimeInHours_subtractsBreaks() {
        let session = makeSession(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0, breaks: 1)
        let expected = 4.0 - session.breakTimeInHours()
        XCTAssertEqual(session.totalBillableTimeInHours(), expected)
    }

    func testTotalBillableTimeInHours_flooredAtMinimumBillingHours() {
        let session = makeSession(startHour: 8, startMinute: 0, endHour: 8, endMinute: 30)
        XCTAssertEqual(session.totalBillableTimeInHours(), MeetDay.MIN_BILLING_HOURS)
    }

    // MARK: overlaps(with:)

    func testOverlaps_trueWhenRangesOverlap() {
        let a = makeSession(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)
        let b = makeSession(name: "Session 2", startHour: 11, startMinute: 0, endHour: 14, endMinute: 0)
        XCTAssertTrue(a.overlaps(with: b))
        XCTAssertTrue(b.overlaps(with: a))
    }

    func testOverlaps_falseWhenRangesAreAdjacentOrDisjoint() {
        let a = makeSession(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)
        let adjacent = makeSession(name: "Session 2", startHour: 12, startMinute: 0, endHour: 14, endMinute: 0)
        let disjoint = makeSession(name: "Session 3", startHour: 13, startMinute: 0, endHour: 14, endMinute: 0)
        XCTAssertFalse(a.overlaps(with: adjacent))
        XCTAssertFalse(a.overlaps(with: disjoint))
    }

    // MARK: uuid

    func testGetUUID_isStableAcrossCalls() {
        let session = makeSession(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)
        let first = session.getUUID()
        let second = session.getUUID()
        XCTAssertEqual(first, second)
    }
}
