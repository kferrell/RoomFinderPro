//
//  ConferenceRoom.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation

struct ConferenceRoomResponse : Codable {
    let results: [ConferenceRoom]
}

struct ConferenceRoom : Codable {
    let roomId: Int
    let roomName: String
}
