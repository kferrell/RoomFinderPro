//
//  ReservationsDataStore.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation

enum ParseAPI: String {
    
    case getAvailableRooms
    case saveRoomReservation
    
    func urlString() -> String {
        switch self {
        case .getAvailableRooms:
            return "https://parseapi.back4app.com/classes/AvailableRooms"
        case .saveRoomReservation:
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

class ReservationsDataStore {
    
    init() {
        
    }
    
    func getAvailableRooms(startDate: Date, duration: Double, apiResponse: @escaping (_ results: [ConferenceRoom]?, _ error: Error?) -> ()) {
        // ###############################################################################
        // Note: Add start date and duration filtering in actual API implementation here:
        // ###############################################################################
        
        URLSession.shared.dataTask(with: ParseAPI.getAvailableRooms.request()) { (data, response, error) in
            if error != nil {
                apiResponse(nil, error)
                return
            }
            
            guard let data = data else {
                apiResponse([ConferenceRoom](), nil)
                return
            }
            
            do {
                let resultsObject = try JSONDecoder().decode(ConferenceRoomResponse.self, from: data)
                apiResponse(resultsObject.results, nil)
            } catch let jsonError {
                apiResponse(nil, jsonError)
            }
        }.resume()
    }
    
    func saveNewReservation(reservation: RoomReservation, apiResponse: @escaping (_ error: Error?) -> ()) {
        var request = ParseAPI.saveRoomReservation.request()
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        do {
            let reservationJSON = try encoder.encode(reservation)
            request.httpBody = reservationJSON
        } catch {
            apiResponse(error)
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                apiResponse(error)
                return
            }
            
            // Post was successful
            apiResponse(nil)
        }.resume()
    }
}
