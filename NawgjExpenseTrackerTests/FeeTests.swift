//
//  FeeTests.swift
//  NawgjExpenseTrackerTests
//
//  Unit tests covering Fee total/hours calculations, including the
//  exclude-from-billing behavior used by the fee detail screen.
//

import XCTest
@testable import Expenses

final class FeeTests: XCTestCase {

    private func makeFee(hours: Float, rate: Float, exclude: Bool = false) -> Fee {
        return Fee(date: Date(), hours: hours, rate: rate, rateOverridden: false,
                   hoursOverridden: false, notes: nil, exclude: exclude, meetDayUUID: "uuid")
    }

    func testGetFeeTotal_multipliesHoursByRate() {
        let fee = makeFee(hours: 4.0, rate: 20.0)
        XCTAssertEqual(fee.getFeeTotal(), 80.0)
    }

    func testGetFeeTotal_isZero_whenExcluded() {
        let fee = makeFee(hours: 4.0, rate: 20.0, exclude: true)
        XCTAssertEqual(fee.getFeeTotal(), 0.0)
    }

    func testGetFeeTotal_treatsNilExclude_asNotExcluded() {
        let fee = makeFee(hours: 3.0, rate: 10.0)
        fee.exclude = nil
        XCTAssertEqual(fee.getFeeTotal(), 30.0)
    }

    func testGetHours_returnsHours_whenNotExcluded() {
        let fee = makeFee(hours: 5.5, rate: 20.0)
        XCTAssertEqual(fee.getHours(), 5.5)
    }

    func testGetHours_isZero_whenExcluded() {
        let fee = makeFee(hours: 5.5, rate: 20.0, exclude: true)
        XCTAssertEqual(fee.getHours(), 0.0)
    }

    func testMeetDayUUID_getterAndSetter() {
        let fee = makeFee(hours: 1.0, rate: 1.0)
        XCTAssertEqual(fee.getMeetDayUUID(), "uuid")

        fee.setMeetDayUUID(uuid: "new-uuid")
        XCTAssertEqual(fee.getMeetDayUUID(), "new-uuid")
    }
}
