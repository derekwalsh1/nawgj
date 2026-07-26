//
//  ManagerMockingTests.swift
//  NawgjExpenseTrackerTests
//
//  Demonstrates that `JudgeListManager`/`MeetListManager` consumers can be
//  tested against a mock via the `JudgeListManaging`/`MeetListManaging`
//  protocols instead of the real singleton (which touches disk).
//

import XCTest
@testable import Expenses

/// Minimal in-memory stub conforming to `JudgeListManaging`.
final class MockJudgeListManager: JudgeListManaging {
    var judges: [JudgeInfo]?
    var selectedJudge: JudgeInfo?
    var selectedJudgeIndex: Int?

    private(set) var saveJudgesCallCount = 0

    func loadAndSortJudges() {
        if let originalJudgeList = judges {
            judges = originalJudgeList.sorted(by: { $0.name < $1.name })
        }
    }

    func loadAndSortJudgesAsync() async -> [JudgeInfo] {
        loadAndSortJudges()
        return judges ?? []
    }

    func importJudges(fromFile: URL?) {}

    func loadJudges() {}

    func loadJudgesAsync() async -> [JudgeInfo] {
        return judges ?? []
    }

    func saveJudges() {
        saveJudgesCallCount += 1
    }

    func saveJudgesAsync(_ judgesToSave: [JudgeInfo]?) async -> Bool {
        saveJudgesCallCount += 1
        return true
    }

    func addJudge(_ judgeInfo: JudgeInfo) -> Bool {
        if judges == nil { judges = [] }
        guard indexOfJudge(judgeInfo) < 0 else { return false }
        judges?.append(judgeInfo)
        saveJudges()
        return true
    }

    func removeJudgeAt(_ index: Int) {
        judges?.remove(at: index)
        saveJudges()
    }

    func selectJudgeInfoAt(_ index: Int) {
        selectedJudgeIndex = index
        selectedJudge = judges?[index]
    }

    func judgeInfo(forJudgeID: String) -> String? {
        return judges?.first(where: { $0.getUUID() == forJudgeID })?.getUUID()
    }

    func updateSelectedJudgeWith(_ judgeInfo: JudgeInfo) {
        guard let index = selectedJudgeIndex else { return }
        judges?[index] = judgeInfo
        selectedJudge = judgeInfo
        saveJudges()
    }

    func indexOfJudge(_ judgeInfo: JudgeInfo) -> Int {
        return judges?.firstIndex(where: {
            $0.name.lowercased() == judgeInfo.name.lowercased() && $0.level == judgeInfo.level
        }) ?? -1
    }
}

/// Minimal in-memory stub conforming to `MeetListManaging`.
final class MockMeetListManager: MeetListManaging {
    var meets: [Meet]?
    var selectedMeetIndex: Int?
    var selectedMeetDayIndex: Int?
    var selectedJudgeIndex: Int?
    var selectedExpenseIndex: Int?
    var selectedFeeIndex: Int?

    private(set) var saveMeetsCallCount = 0

    func loadMeets() {}

    func loadMeetsAsync() async -> [Meet] {
        return meets ?? []
    }

    func saveMeets() {
        saveMeetsCallCount += 1
    }

    func saveMeetsAsync(_ meetsToSave: [Meet]?) async -> Bool {
        saveMeetsCallCount += 1
        return true
    }

    func addMeet(meet: Meet) {
        if meets == nil { meets = [] }
        meets?.append(meet)
        saveMeets()
    }

    func addJudge(judge: Judge) {
        getSelectedMeet()?.addJudge(judge: judge)
        saveMeets()
    }

    func addMeetDay(meetDay: MeetDay) {
        getSelectedMeet()?.addMeetDay(day: meetDay)
        saveMeets()
    }

    func updateSelectedMeetWith(meet: Meet) {
        if let index = selectedMeetIndex, meets != nil, index < meets!.count {
            meets![index] = meet
            saveMeets()
        }
    }

    func updateSelectedMeetDayWith(meetDay: MeetDay) {}
    func updateSelectedJudgeWith(judge: Judge) {}
    func updateSelectedFeeWith(fee: Fee) {}
    func updateSelectedExpenseWith(expense: Expense) {}

    func removeMeetAt(index: Int) {
        meets?.remove(at: index)
        saveMeets()
    }

    func removeMeetDayAt(index: Int) {}
    func removeJudgeAt(index: Int) {}

    func selectMeetAt(index: Int) {
        selectedMeetIndex = index
    }

    func selectJudgeAt(index: Int) {
        selectedJudgeIndex = index
    }

    func selectExpenseAt(index: Int) {
        selectedExpenseIndex = index
    }

    func selectFeeAt(index: Int) {
        selectedFeeIndex = index
    }

    func selectMeetDayAt(index: Int) {
        selectedMeetDayIndex = index
    }

    func selectMeetDayForFee(fee: Fee) {}

    func getSelectedMeet() -> Meet? {
        guard let allMeets = meets, let index = selectedMeetIndex else { return nil }
        return allMeets[index]
    }

    func getSelectedJudge() -> Judge? { return nil }
    func getSelectedMeetDay() -> MeetDay? { return nil }
    func getSelectedExpense() -> Expense? { return nil }
    func getSelectedFee() -> Fee? { return nil }

    func moveMeet(fromIndex: Int, toIndex: Int) {
        guard let meet = meets?.remove(at: fromIndex) else { return }
        meets?.insert(meet, at: toIndex)
        saveMeets()
    }

    func importMeet(fromFile: URL?) {}
}

final class ManagerMockingTests: XCTestCase {

    override func tearDown() {
        // Always reset back to the real singletons so other tests / the app
        // aren't left pointing at a mock.
        JudgeListManager.setInstanceForTesting(nil)
        MeetListManager.setInstanceForTesting(nil)
        super.tearDown()
    }

    func testJudgeListManagerGetInstanceReturnsInjectedMock() {
        let mock = MockJudgeListManager()
        JudgeListManager.setInstanceForTesting(mock)

        XCTAssertTrue(JudgeListManager.GetInstance() === mock)
    }

    func testAddJudgeUsesInjectedMockWithoutTouchingDisk() {
        let mock = MockJudgeListManager()
        mock.judges = []
        JudgeListManager.setInstanceForTesting(mock)

        let judgeInfo = JudgeInfo(name: "Test Judge", level: .Nine)
        let added = JudgeListManager.GetInstance().addJudge(judgeInfo)

        XCTAssertTrue(added)
        XCTAssertEqual(mock.judges?.count, 1)
        XCTAssertEqual(mock.saveJudgesCallCount, 1)
    }

    func testMeetListManagerGetInstanceReturnsInjectedMock() {
        let mock = MockMeetListManager()
        MeetListManager.setInstanceForTesting(mock)

        XCTAssertTrue(MeetListManager.GetInstance() === mock)
    }

    func testAddMeetUsesInjectedMockWithoutTouchingDisk() {
        let mock = MockMeetListManager()
        mock.meets = []
        MeetListManager.setInstanceForTesting(mock)

        guard let meet = Meet(name: "Test Meet", startDate: Date()) else {
            XCTFail("Failed to create Meet")
            return
        }
        MeetListManager.GetInstance().addMeet(meet: meet)

        XCTAssertEqual(mock.meets?.count, 1)
        XCTAssertEqual(mock.saveMeetsCallCount, 1)
    }
}
