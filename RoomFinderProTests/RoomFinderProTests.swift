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
        
        // Clear out local reservations cache
        let datastore = ReservationsDataStore()
        datastore.deleteAllCachedRoomReservations()
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
    
    func testCoreDataLocalCache() {
        let datastore = ReservationsDataStore()
        
        let res_30minsPast = RoomReservation(objectId: "ABC123", title: "Room Reservation 1", duration: 30, roomName: "1200A", startDate: APIDate(date: Date().addingTimeInterval((-60 * 30))))
        let res_10minsPast = RoomReservation(objectId: "ABC123", title: "Room Reservation 1", duration: 30, roomName: "1200A", startDate: APIDate(date: Date().addingTimeInterval((-60 * 10))))
        let res_30minsFuture = RoomReservation(objectId: "ABC456", title: "Room Reservation 2", duration: 30, roomName: "1200B", startDate: APIDate(date: Date().addingTimeInterval((60 * 30))))
        let reservations = [res_30minsPast, res_10minsPast, res_30minsFuture]
        
        // Save reservations to local cache
        datastore.saveRoomReservationToLocalCache(reservations: reservations)
        
        // Retreive saved reservations (should only return two: 10 mins in past and 30 mins in future)
        let cachedReservations = datastore.getRoomReservationLocalCache()
        
        XCTAssert(cachedReservations.count == 2, "Reservations were not cached")
        
    }
    
//    func testGetAvailableRoomsAPI() {
//        let exp = expectation(description: "Test should return rooms")
//
//        let datastore = ReservationsDataStore()
//        datastore.getAvailableRooms(startDate: Date(), duration: 1.0, apiResponse: { results, error in
//            XCTAssert(results!.count > 0 , "Did not return results")
//            exp.fulfill()
//        })
//
//        waitForExpectations(timeout: 10) { error in
//            if let error = error {
//                XCTFail("wait for API failed: \(error)")
//            }
//        }
//    }
//
//    func testRoomReservationAPI() {
//        let exp = expectation(description: "Test should return rooms")
//
//        let datastore = ReservationsDataStore()
//        let reservation = RoomReservation(objectId: nil, title: "Test Reservation With New Date", duration: 30, roomName: "WP 1200A", startDate: APIDate(date: Date()))
//        datastore.saveNewReservation(reservation: reservation, apiResponse: { error in
//            XCTAssert(error == nil, "Received error: \(String(describing: error))")
//            exp.fulfill()
//        })
//
//        waitForExpectations(timeout: 100) { error in
//            if let error = error {
//                XCTFail("wait for API failed: \(error)")
//            }
//        }
//    }
//
//    func testGetRoomReservationsAPI() {
//        let exp = expectation(description: "Test should return room reservations")
//
//        let datastore = ReservationsDataStore()
//        datastore.getRoomReservations(apiResponse: { results, error in
//            XCTAssert(results!.count > 0 , "Did not return results")
//            exp.fulfill()
//        })
//
//        waitForExpectations(timeout: 10) { error in
//            if let error = error {
//                XCTFail("wait for API failed: \(error)")
//            }
//        }
//    }
    
}
