//
//  ReservationsDataStore.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation

enum ParseAPI: String {
    
    case AvailableRooms
    
    func urlString() -> String {
        switch self {
        case .AvailableRooms:
            return "https://parseapi.back4app.com/classes/AvailableRooms"
        }
    }
    
    func request() -> URLRequest {
        var request = URLRequest(url: URL(string: urlString())!)
        
        // Add default request headers
        request.addValue("dVKA56dLYAgu3vp2zPc5U0sMWDhsSSA3ImJxuNGF", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("hJtWNgzI9f2KXzLLdA5EGLZGO5goIU4vwhGbys3M", forHTTPHeaderField: "X-Parse-Master-Key")
        
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
        
        URLSession.shared.dataTask(with: ParseAPI.AvailableRooms.request()) { (data, response, error) in
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
}
