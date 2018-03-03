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
    
    var loadingIndicator: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup non-blocking loading indicator for main screen
        setupLoadingIndicator()
        
        // Load locally cached reservations during initial load
        loadDataFromLocalCache()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(loadDataFromAPI), for: .valueChanged)
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
    
    @objc func loadDataFromAPI() {
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
                    self?.refreshControl?.endRefreshing()
                    
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
    
    // MARK: Non-blocking loading indicator implementation
    
    func setupLoadingIndicator() {
        let screenSize = UIScreen.main.bounds
        let labelWidth = 215.0
        let labelStartX = (Double(screenSize.width) / 2.0) - (labelWidth / 2.0)
        loadingIndicator = UILabel(frame: CGRect(x: labelStartX, y: Double(screenSize.height) + 50.0, width: labelWidth, height: 20.0))
        loadingIndicator?.font = UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold)
        loadingIndicator?.text = "Checking for new reservations..."
        loadingIndicator?.textAlignment = .center
        loadingIndicator?.backgroundColor = UIColor.lightGray
        loadingIndicator?.layer.cornerRadius = 5.0
        loadingIndicator?.layer.masksToBounds = true
        view.addSubview(loadingIndicator!)
    }
    
    override func showActivityIndicator() {
        guard let loadingIndicator = loadingIndicator else { return }

        loadingIndicator.isHidden = false
        UIView.animate(withDuration: 1.0, animations: {
            var newFrame = loadingIndicator.frame
            newFrame.origin.y = newFrame.origin.y - 250.0
            loadingIndicator.frame = newFrame
        })
    }

    override func hideActivityIndicator() {
        guard let loadingIndicator = loadingIndicator else { return }

        UIView.animate(withDuration: 0.3, animations: {
            var newFrame = loadingIndicator.frame
            newFrame.origin.y = newFrame.origin.y + 250.0
            loadingIndicator.frame = newFrame
        }, completion: nil)
    }
}
