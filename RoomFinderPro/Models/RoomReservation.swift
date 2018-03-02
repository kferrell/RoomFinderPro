//
//  RoomReservation.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation

struct RoomReservation : Codable {
    let objectId: String?
    let title: String
    let startDateString: String
    let duration: Int
    let roomName: String
}
