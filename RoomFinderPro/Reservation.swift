//
//  Reservation.swift
//  RoomFinderPro
//
//  Created by Ferrell, Kevin on 9/2/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import Foundation

class Reservation {
    var title: String
    var numberOfParticipants: Int
    var startDate: Date
    var endDate: Date
    var building: String
    var room: String
    
    init(title: String, numberOfParticipants: Int, startDate: Date, endDate: Date, building: String, room: String) {
        self.title = title
        self.numberOfParticipants = numberOfParticipants
        self.startDate = startDate
        self.endDate = endDate
        self.building = building
        self.room = room
    }
}
