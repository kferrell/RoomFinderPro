//
//  ParseAPI.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation

enum ParseAPI: String {
    
    case getAvailableRooms
    case saveRoomReservation
    case getRoomReservations
    case deleteRoomReservation
    
    func urlString() -> String {
        switch self {
        case .getAvailableRooms:
            return "https://parseapi.back4app.com/classes/AvailableRooms"
        case .saveRoomReservation, .getRoomReservations, .deleteRoomReservation:
            return "https://parseapi.back4app.com/classes/RoomReservation"
        }
    }
    
    func request() -> URLRequest {
        var request = URLRequest(url: URL(string: urlString())!)
        
        // Add default request headers
        request.addValue("", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("", forHTTPHeaderField: "X-Parse-Master-Key")
        
        return request
    }
}
