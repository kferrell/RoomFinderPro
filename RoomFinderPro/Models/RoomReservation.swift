//
//  RoomReservation.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation

// Response object container for API
struct RoomReservationResponse : Codable {
    let results: [RoomReservation]
}

// Date object container for API
struct APIDate : Codable {
    let __type = "Date"
    let date : Date
    
    enum CodingKeys: String, CodingKey {
        case __type
        case date = "iso"
    }
}

struct RoomReservation : Codable {
    let objectId: String?
    let title: String
    let duration: Int
    let roomName: String
    let startDate: APIDate
    
    func formattedDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        let dateString = formatter.string(from: startDate.date)
        
        return dateString
    }
}
