//
//  ReservationsDataStore.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation

enum APIError: Error {
    case RequestError(String)
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
    
    func getRoomReservations(apiResponse: @escaping (_ results: [RoomReservation]?, _ error: Error?) -> ()) {
        URLSession.shared.dataTask(with: ParseAPI.getRoomReservations.request()) { (data, response, error) in
            if error != nil {
                apiResponse(nil, error)
                return
            }
            
            guard let data = data else {
                apiResponse([RoomReservation](), nil)
                return
            }
            
            do {
                let resultsObject = try JSONDecoder().decode(RoomReservationResponse.self, from: data)
                apiResponse(resultsObject.results, nil)
            } catch let jsonError {
                apiResponse(nil, jsonError)
            }
        }.resume()
    }
    
    func deleteRoomReservation(reservation: RoomReservation, apiResponse: @escaping (_ error: Error?) -> ()) {
        guard let objectId = reservation.objectId else {
            apiResponse(APIError.RequestError("Reservation must contain an ID to be deleted"))
            return
        }
        
        let urlString = ParseAPI.deleteRoomReservation.urlString() + "/" + objectId
        var request = ParseAPI.deleteRoomReservation.request()
        request.url = URL(string: urlString)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                apiResponse(error)
                return
            }
            
            // Delete was successful
            apiResponse(nil)
        }.resume()
    }
}
