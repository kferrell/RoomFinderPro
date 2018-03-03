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
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        loadDataFromAPI()
    }
    
    func loadDataFromAPI() {
        showActivityIndicator()
        reservationsDataStore.getRoomReservations(apiResponse: { [weak self] results, error in
            if let results = results {
                self?.reservations = results
            }
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.hideActivityIndicator()
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
                tableView.deleteRows(at: [indexPath], with: .automatic)
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            alert.addAction(deleteAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        return [delete]
    }
}
