//
//  ExpenseTests.swift
//  NawgjExpenseTrackerTests
//
//  Unit tests covering Expense total calculations, including the
//  mileage and single-room lodging special cases.
//

import XCTest
@testable import Expenses

final class ExpenseTests: XCTestCase {

    func testGetExpenseTotal_mileage_multipliesAmountByRate() {
        let expense = Expense(type: .Mileage, amount: 100.0, notes: "", date: Date(),
                               mileageRate: 0.67, isCustomMileageRate: false,
                               isPrivateLodgingRequested: false, totalNights: 0, amountPerNight: 0)
        XCTAssertEqual(expense.getExpenseTotal(), 67.0, accuracy: 0.0001)
    }

    func testGetExpenseTotal_lodging_usesSingleRoomCapMinusAmountPerNight() {
        let expense = Expense(type: .Lodging, amount: 0.0, notes: "", date: Date(),
                               mileageRate: 0.0, isCustomMileageRate: false,
                               isPrivateLodgingRequested: true, totalNights: 2, amountPerNight: 80.0)
        // (SINGLE_ROOM_REQUEST_MAX_DAILY_EXPENSE_DOLLARS - amountPerNight) * totalNights
        let expected = (Meet.SINGLE_ROOM_REQUEST_MAX_DAILY_EXPENSE_DOLLARS - 80.0) * 2
        XCTAssertEqual(expense.getExpenseTotal(), expected, accuracy: 0.0001)
    }

    func testGetExpenseTotal_lodging_withZeroNights_isZero() {
        let expense = Expense(type: .Lodging, amount: 0.0, notes: "", date: Date(),
                               mileageRate: 0.0, isCustomMileageRate: false,
                               isPrivateLodgingRequested: true, totalNights: 0, amountPerNight: 50.0)
        XCTAssertEqual(expense.getExpenseTotal(), 0.0, accuracy: 0.0001)
    }

    func testGetExpenseTotal_lodging_withNilNightsAndAmount_isZero() {
        let expense = Expense(type: .Lodging, amount: 0.0, notes: "", date: Date(), mileageRate: 0.0)
        expense.totalNights = nil
        expense.amountPerNight = nil
        XCTAssertEqual(expense.getExpenseTotal(), 0.0, accuracy: 0.0001)
    }

    func testGetExpenseTotal_defaultTypes_returnAmountUnchanged() {
        let types: [Expense.ExpenseType] = [.Meals, .Toll, .Airfare, .Transportation, .Parking, .Other]
        for type in types {
            let expense = Expense(type: type, amount: 42.5, notes: "", date: Date(), mileageRate: 0.0)
            XCTAssertEqual(expense.getExpenseTotal(), 42.5, "Unexpected total for \(type.description)")
        }
    }

    func testConvenienceInit_looksUpMileageRate_forKnownYear() {
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 1
        let date = Calendar.current.date(from: components)!

        let expense = Expense(type: .Mileage, amount: 10.0, notes: "", date: date)
        XCTAssertEqual(expense.mileageRate, Meet.FED_MILEAGE_RATES[2024])
    }
}
