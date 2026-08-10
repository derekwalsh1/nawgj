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

    func removeAllJudges() {
        judges = []
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

    func addSession(session: Session, to day: MeetDay) {
        getSelectedMeet()?.addSession(session, to: day)
        saveMeets()
    }

    @discardableResult
    func removeSession(_ session: Session, from day: MeetDay) -> Bool {
        guard let removed = getSelectedMeet()?.removeSession(session, from: day) else { return false }
        if removed { saveMeets() }
        return removed
    }

    @discardableResult
    func assignJudge(_ judge: Judge, to session: Session, in day: MeetDay) -> Result<Void, Meet.SessionAssignmentError> {
        guard let result = getSelectedMeet()?.assignJudge(judge, to: session, in: day) else { return .success(()) }
        if case .success = result { saveMeets() }
        return result
    }

    func unassignJudge(_ judge: Judge, from session: Session) {
        getSelectedMeet()?.unassignJudge(judge, from: session)
        saveMeets()
    }

    @discardableResult
    func validateSessionChange(_ session: Session, in day: MeetDay) -> Result<Void, Meet.SessionChangeError> {
        guard let meet = getSelectedMeet() else { return .success(()) }
        return meet.validateSessionChange(session, in: day)
    }

    func sessionChanged(_ session: Session, in day: MeetDay) {
        getSelectedMeet()?.sessionChanged(session, in: day)
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

final class MeetSessionAssignmentTests: XCTestCase {

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    func testAddSession_doesNotAutoAssignExistingJudges() {
        let meetDate = date(year: 2026, month: 8, day: 1, hour: 0, minute: 0)
        let originalSession = Session(
            name: "Session 1",
            startTime: date(year: 2026, month: 8, day: 1, hour: 8, minute: 0),
            endTime: date(year: 2026, month: 8, day: 1, hour: 11, minute: 0),
            breaks: 0,
            breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS
        )
        let meetDay = MeetDay(meetDate: meetDate, sessions: [originalSession], id: UUID().uuidString)
        let existingFee = Fee(
            date: meetDate,
            hours: originalSession.totalBillableTimeInHours(),
            rate: Judge.Level.LevelNine.rate,
            notes: "",
            meetDayUUID: meetDay.getUUID(),
            sessionUUID: originalSession.getUUID()
        )!
        let judge = Judge(name: "Judge 1", level: .LevelNine, expenses: [], fees: [existingFee])
        let meet = Meet(name: "Meet", days: [meetDay], judges: [judge], startDate: meetDate, meetDescription: nil, location: nil)!

        let newSession = Session(
            name: "Session 2",
            startTime: date(year: 2026, month: 8, day: 1, hour: 12, minute: 0),
            endTime: date(year: 2026, month: 8, day: 1, hour: 15, minute: 0),
            breaks: 0,
            breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS
        )

        meet.addSession(newSession, to: meetDay)

        XCTAssertEqual(meetDay.sessions.count, 2)
        XCTAssertEqual(judge.fees.count, 1)
        XCTAssertFalse(judge.fees.contains(where: { $0.getSessionUUID() == newSession.getUUID() }))
    }

    func testAddMeetDay_doesNotAutoAssignExistingJudgesToInitialSession() {
        let meetDate = date(year: 2026, month: 8, day: 1, hour: 0, minute: 0)
        let existingSession = Session(
            name: "Session 1",
            startTime: date(year: 2026, month: 8, day: 1, hour: 8, minute: 0),
            endTime: date(year: 2026, month: 8, day: 1, hour: 11, minute: 0),
            breaks: 0,
            breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS
        )
        let existingDay = MeetDay(meetDate: meetDate, sessions: [existingSession], id: UUID().uuidString)
        let existingFee = Fee(
            date: meetDate,
            hours: existingSession.totalBillableTimeInHours(),
            rate: Judge.Level.LevelNine.rate,
            notes: "",
            meetDayUUID: existingDay.getUUID(),
            sessionUUID: existingSession.getUUID()
        )!
        let judge = Judge(name: "Judge 1", level: .LevelNine, expenses: [], fees: [existingFee])
        let meet = Meet(name: "Meet", days: [existingDay], judges: [judge], startDate: meetDate, meetDescription: nil, location: nil)!

        let newDayDate = date(year: 2026, month: 8, day: 2, hour: 0, minute: 0)
        let initialSession = Session(
            name: "Session 1",
            startTime: date(year: 2026, month: 8, day: 2, hour: 8, minute: 0),
            endTime: date(year: 2026, month: 8, day: 2, hour: 11, minute: 0),
            breaks: 0,
            breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS
        )
        let newDay = MeetDay(meetDate: newDayDate, sessions: [initialSession], id: UUID().uuidString)

        meet.addMeetDay(day: newDay)

        XCTAssertEqual(meet.days.count, 2)
        XCTAssertEqual(judge.fees.count, 1)
        XCTAssertFalse(judge.fees.contains(where: { $0.getSessionUUID() == initialSession.getUUID() }))
    }

    func testValidateSessionChange_failsWhenAssignedJudgeWouldBeDoubleBooked() {
        let meetDate = date(year: 2026, month: 8, day: 1, hour: 0, minute: 0)
        let morningSession = Session(
            name: "Morning",
            startTime: date(year: 2026, month: 8, day: 1, hour: 8, minute: 0),
            endTime: date(year: 2026, month: 8, day: 1, hour: 10, minute: 0),
            breaks: 0,
            breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS
        )
        let afternoonSession = Session(
            name: "Afternoon",
            startTime: date(year: 2026, month: 8, day: 1, hour: 11, minute: 0),
            endTime: date(year: 2026, month: 8, day: 1, hour: 13, minute: 0),
            breaks: 0,
            breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS
        )
        let meetDay = MeetDay(meetDate: meetDate, sessions: [morningSession, afternoonSession], id: UUID().uuidString)
        let morningFee = Fee(
            date: meetDate,
            hours: morningSession.totalBillableTimeInHours(),
            rate: Judge.Level.LevelNine.rate,
            notes: "",
            meetDayUUID: meetDay.getUUID(),
            sessionUUID: morningSession.getUUID()
        )!
        let afternoonFee = Fee(
            date: meetDate,
            hours: afternoonSession.totalBillableTimeInHours(),
            rate: Judge.Level.LevelNine.rate,
            notes: "",
            meetDayUUID: meetDay.getUUID(),
            sessionUUID: afternoonSession.getUUID()
        )!
        let judge = Judge(name: "Judge 1", level: .LevelNine, expenses: [], fees: [morningFee, afternoonFee])
        let meet = Meet(name: "Meet", days: [meetDay], judges: [judge], startDate: meetDate, meetDescription: nil, location: nil)!

        let editedMorningSession = Session(
            name: "Morning",
            startTime: date(year: 2026, month: 8, day: 1, hour: 9, minute: 30),
            endTime: date(year: 2026, month: 8, day: 1, hour: 12, minute: 0),
            breaks: 0,
            breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS,
            uuid: morningSession.getUUID()
        )

        let result = meet.validateSessionChange(editedMorningSession, in: meetDay)

        switch result {
        case .success:
            XCTFail("Expected session edit validation to fail for overlapping assigned sessions")
        case .failure(.overlappingAssignments(let conflicts)):
            XCTAssertEqual(conflicts, [Meet.SessionOverlapConflict(judgeName: "Judge 1", conflictingSessionName: "Afternoon")])
        }
    }

    func testAssignedJudgeCountForDay_countsOnlyJudgesAssignedToThatDay() {
        let dayOneDate = date(year: 2026, month: 8, day: 1, hour: 0, minute: 0)
        let dayTwoDate = date(year: 2026, month: 8, day: 2, hour: 0, minute: 0)
        let dayOneSession = Session(
            name: "Day 1",
            startTime: date(year: 2026, month: 8, day: 1, hour: 8, minute: 0),
            endTime: date(year: 2026, month: 8, day: 1, hour: 11, minute: 0),
            breaks: 0,
            breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS
        )
        let dayTwoSession = Session(
            name: "Day 2",
            startTime: date(year: 2026, month: 8, day: 2, hour: 8, minute: 0),
            endTime: date(year: 2026, month: 8, day: 2, hour: 11, minute: 0),
            breaks: 0,
            breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS
        )
        let dayOne = MeetDay(meetDate: dayOneDate, sessions: [dayOneSession], id: UUID().uuidString)
        let dayTwo = MeetDay(meetDate: dayTwoDate, sessions: [dayTwoSession], id: UUID().uuidString)

        let dayOneFee = Fee(
            date: dayOneDate,
            hours: dayOneSession.totalBillableTimeInHours(),
            rate: Judge.Level.LevelNine.rate,
            notes: "",
            meetDayUUID: dayOne.getUUID(),
            sessionUUID: dayOneSession.getUUID()
        )!
        let dayTwoFee = Fee(
            date: dayTwoDate,
            hours: dayTwoSession.totalBillableTimeInHours(),
            rate: Judge.Level.LevelNine.rate,
            notes: "",
            meetDayUUID: dayTwo.getUUID(),
            sessionUUID: dayTwoSession.getUUID()
        )!

        let dayOneJudge = Judge(name: "Judge 1", level: .LevelNine, expenses: [], fees: [dayOneFee])
        let dayTwoJudge = Judge(name: "Judge 2", level: .LevelNine, expenses: [], fees: [dayTwoFee])
        let unassignedJudge = Judge(name: "Judge 3", level: .LevelNine, expenses: [], fees: [])
        let meet = Meet(name: "Meet", days: [dayOne, dayTwo], judges: [dayOneJudge, dayTwoJudge, unassignedJudge], startDate: dayOneDate, meetDescription: nil, location: nil)!

        XCTAssertEqual(meet.assignedJudgeCountForDay(dayIndex: 0), 1)
        XCTAssertEqual(meet.assignedJudgeCountForDay(dayIndex: 1), 1)
    }
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
