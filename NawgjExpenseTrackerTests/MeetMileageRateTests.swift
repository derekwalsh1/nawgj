//
//  MeetMileageRateTests.swift
//  NawgjExpenseTrackerTests
//
//  Unit tests covering Meet.getMileageRate(forDate:), which drives mileage
//  reimbursement amounts: exact-year lookup, falling back to the most
//  recent rate for years past the table, and falling back to the earliest
//  rate for years before the table.
//

import XCTest
@testable import Expenses

final class MeetMileageRateTests: XCTestCase {

    private func date(year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = 6
        components.day = 1
        return Calendar.current.date(from: components)!
    }

    func testGetMileageRate_returnsExactMatch_forYearInTable() {
        XCTAssertEqual(Meet.getMileageRate(forDate: date(year: 2024)), Meet.FED_MILEAGE_RATES[2024])
    }

    func testGetMileageRate_forYearAfterTable_returnsMostRecentRate() {
        let futureYear = (Meet.FED_MILEAGE_RATES.keys.max() ?? 2026) + 1
        let latestYear = Meet.FED_MILEAGE_RATES.keys.max() ?? 2026
        let expected = Meet.FED_MILEAGE_RATES[latestYear]
        XCTAssertEqual(Meet.getMileageRate(forDate: date(year: futureYear)), expected)
    }

    func testGetMileageRate_beforeEarliestTableYear_returnsEarliestRate() {
        let earliestYear = Meet.FED_MILEAGE_RATES.keys.min() ?? 2016
        let expected = Meet.FED_MILEAGE_RATES[earliestYear]
        XCTAssertEqual(Meet.getMileageRate(forDate: date(year: earliestYear - 10)), expected)
    }
}
