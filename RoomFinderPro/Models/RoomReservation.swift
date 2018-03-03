//
//  RoomReservation.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation

struct RoomReservationResponse : Codable {
    let results: [RoomReservation]
}

struct RoomReservation : Codable {
    let objectId: String?
    let title: String
    let startDateString: String
    let duration: Int
    let roomName: String
    
    // String format for encoding/decoding Dates to the API
    static let dateFormatString = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    func startDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = RoomReservation.dateFormatString
        
        if let startDate = dateFormatter.date(from: startDateString) {
            return startDate
        }
        
        return nil
    }
    
    func formattedDateString() -> String {
        var dateString = ""
        
        if let startDate = startDate() {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            dateString = formatter.string(from: startDate)
        }
        
        return dateString
    }
}
