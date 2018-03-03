//
//  ReservationsTableViewController.swift
//  RoomFinderPro
//
//  Created by Ferrell, Kevin on 9/2/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import UIKit

class ReservationsTableViewController: BaseTableViewController {
    
    let reservationsDataStore = ReservationsDataStore()
    var reservations = [RoomReservation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load locally cached reservations during initial load
        loadDataFromLocalCache()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // Refresh latest data from the API
        loadDataFromAPI()
    }
    
    func loadDataFromLocalCache() {
        reservations = reservationsDataStore.getRoomReservationLocalCache()
        self.tableView.reloadData()
    }
    
    func loadDataFromAPI() {
        showActivityIndicator()
        reservationsDataStore.getRoomReservations(apiResponse: { [weak self] results, error in
            if let results = results {
                // Sort reservations by date
                let sortedReservations = results.sorted(by: {
                    guard let reservationDate0 = $0.startDate(), let reservationDate1 = $1.startDate() else { return false }
                    return reservationDate0.compare(reservationDate1) == .orderedDescending
                })
                
                self?.reservations = sortedReservations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.hideActivityIndicator()
                    
                    // Cache results locally for next cold start
                    self?.reservationsDataStore.saveRoomReservationToLocalCache(reservations: sortedReservations)
                }
            }
        })
    }
    
    func deleteReservationFromAPI(reservation: RoomReservation) {
        reservationsDataStore.deleteRoomReservation(reservation: reservation, apiResponse: { error in
            if let error = error {
                print("Unable to delete reservation: \(error)")
            }
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reservations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReservationCell", for: indexPath) as! ReservationTableViewCell
        cell.configureCell(withReservation: reservations[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let alert = UIAlertController(title: "Delete Reservation", message: "Are you sure that you wish to delete this room reservation?", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deleteReservationFromAPI(reservation: self.reservations[indexPath.row])
                self.reservations.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            alert.addAction(deleteAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        return [delete]
    }
}
