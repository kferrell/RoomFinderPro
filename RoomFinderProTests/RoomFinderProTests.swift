//
//  RoomFinderProTests.swift
//  RoomFinderProTests
//
//  Created by Ferrell, Kevin on 9/2/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import XCTest
@testable import RoomFinderPro

class RoomFinderProTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNearest30MinsFunction() {
        let interactor = ReservationsInteractor()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        // Round Up Test
        let dateRoundUp = dateFormatter.date(from: "2018-03-02T10:55:00+0000")!
        let adjustedUpDate = interactor.getNearest30Min(startDate: dateRoundUp)
        let expectedDate = dateFormatter.date(from: "2018-03-02T11:00:00+0000")!
        XCTAssert(adjustedUpDate.compare(expectedDate) == .orderedSame, "Date did not round properly")
        
        // Round Down Test
        let dateRoundDown = dateFormatter.date(from: "2018-03-02T10:07:00+0000")!
        let adjustedDownDate = interactor.getNearest30Min(startDate: dateRoundDown)
        let expectedDownDate = dateFormatter.date(from: "2018-03-02T10:00:00+0000")!
        XCTAssert(adjustedDownDate.compare(expectedDownDate) == .orderedSame, "Date did not round properly")
        
        // Round Down Mid Test
        let dateRoundDownMid = dateFormatter.date(from: "2018-03-02T10:043:00+0000")!
        let adjustedDownMidDate = interactor.getNearest30Min(startDate: dateRoundDownMid)
        let expectedDownMidDate = dateFormatter.date(from: "2018-03-02T10:30:00+0000")!
        XCTAssert(adjustedDownMidDate.compare(expectedDownMidDate) == .orderedSame, "Date did not round properly")
        
        // Round Up Mid Test
        let dateRoundUpMid = dateFormatter.date(from: "2018-03-02T10:023:00+0000")!
        let adjustedUpMidDate = interactor.getNearest30Min(startDate: dateRoundUpMid)
        let expectedUpMidDate = dateFormatter.date(from: "2018-03-02T10:30:00+0000")!
        XCTAssert(adjustedUpMidDate.compare(expectedUpMidDate) == .orderedSame, "Date did not round properly")
    }
    
}
