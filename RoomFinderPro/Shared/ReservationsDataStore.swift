//
//  ReservationsDataStore.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum APIError: Error {
    case RequestError(String)
}

class ReservationsDataStore {
    
    init() {
        
    }
    
    // MARK: API Functions
    
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
    
    // MARK: CoreData Local Cache Functions
    
    func saveRoomReservationToLocalCache(reservations: [RoomReservation]) {
        // Remove all existing items from the cache
        deleteAllCachedRoomReservations()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        for item in reservations {
            guard let objectId = item.objectId, let startDate = item.startDate() else { continue }
            
            let entity = NSEntityDescription.entity(forEntityName: "CachedRoomReservation", in: managedContext)!
            let cachedReservation = NSManagedObject(entity: entity, insertInto: managedContext)
            cachedReservation.setValue(objectId, forKey: "objectId")
            cachedReservation.setValue(item.title, forKey: "title")
            cachedReservation.setValue(item.roomName, forKey: "roomName")
            cachedReservation.setValue(item.duration, forKey: "duration")
            cachedReservation.setValue(startDate, forKey: "startDate")
        }
        
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
    }
    
    func deleteAllCachedRoomReservations() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedRoomReservation")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            let _ = try managedContext.execute(request)
        } catch {
            print(error)
        }
    }
    
    func getRoomReservationLocalCache() -> [RoomReservation] {
        var roomReservations = [RoomReservation]()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return roomReservations }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CachedRoomReservation")
        
        // Only show reservations in the future (and those that start 15 mins in the past in case the user is running late)
        let dateFilter = NSPredicate(format: "startDate >= %@", Date().addingTimeInterval((-60 * 15)) as NSDate)
        fetchRequest.predicate = dateFilter
        
        do {
            let cachedReservations = try managedContext.fetch(fetchRequest)
            
            // Convert cached reservations into normal RoomReservation objects (view models)
            for item in cachedReservations {
                if let objectId = item.value(forKey: "objectId") as? String, let title = item.value(forKey: "title") as? String, let roomName = item.value(forKey: "roomName") as? String, let duration = item.value(forKey: "duration") as? Int, let startDate = item.value(forKey: "startDate") as? Date {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = RoomReservation.dateFormatString
                    
                    let roomReservation = RoomReservation(objectId: objectId, title: title, startDateString: dateFormatter.string(from: startDate), duration: duration, roomName: roomName)
                    roomReservations.append(roomReservation)
                }
            }
        } catch let error as NSError {
            print("Could not fetch local cache. \(error), \(error.userInfo)")
        }
        
        return roomReservations
    }
}
