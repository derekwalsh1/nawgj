//
//  MeetMileageRateTests.swift
//  NawgjExpenseTrackerTests
//
//  Unit tests covering Meet.getMileageRate(forDate:), which drives mileage
//  reimbursement amounts: exact schedule-date lookup, mid-year changeover,
//  falling back to the most recent rate after the table, and falling back
//  to the earliest rate before the table.
//

import XCTest
@testable import Expenses

final class MeetMileageRateTests: XCTestCase {

    private func date(year: Int, month: Int = 6, day: Int = 1) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }

    func testGetMileageRate_returnsScheduledRate_beforeMidYearChange() {
        XCTAssertEqual(Meet.getMileageRate(forDate: date(year: 2026, month: 6, day: 30)), 0.725)
    }

    func testGetMileageRate_returnsUpdatedRate_onAndAfterJulyFirst2026() {
        XCTAssertEqual(Meet.getMileageRate(forDate: date(year: 2026, month: 7, day: 1)), 0.76)
        XCTAssertEqual(Meet.getMileageRate(forDate: date(year: 2026, month: 12, day: 31)), 0.76)
    }

    func testGetMileageRate_forDateAfterTable_returnsMostRecentRate() {
        XCTAssertEqual(Meet.getMileageRate(forDate: date(year: 2030, month: 1, day: 1)), 0.76)
    }

    func testGetMileageRate_beforeEarliestScheduleDate_returnsEarliestRate() {
        XCTAssertEqual(Meet.getMileageRate(forDate: date(year: 2006, month: 1, day: 1)), 0.54)
    }
}
