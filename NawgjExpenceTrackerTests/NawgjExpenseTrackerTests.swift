//
//  NawgjExpenceTrackerTests.swift
//  NawgjExpenceTrackerTests
//
//  Created by Derek on 10/21/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import XCTest

class NawgjExpenseTrackerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    //MARK: Meet Class Tests
    
    // Confirm that the Meet initializer returns a Meet object when passed valid parameters.
    func testMeetInitializationSucceeds() {
        let firstMeet = Meet.init(name: "Meet #1", photo: nil)
        XCTAssertNotNil(firstMeet)
        
        // Highest positive rating
        let secondMeet = Meet.init(name: "Meet #2", photo: nil)
        XCTAssertNotNil(secondMeet)
    }
    
    // Confirm that the Meal initialier returns nil when passed a negative rating or an empty name.
    func testMealInitializationFails() {
        let noNameMeet = Meet.init(name: "", photo: nil)
        XCTAssertNil(noNameMeet)
    }
}
