//
//  AvailableRoomsTableViewController.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import UIKit

class AvailableRoomsTableViewController: BaseTableViewController {
    
    let datastore = ReservationsDataStore()
    var startDate: Date?
    var duration: Double?
    var rooms = [ConferenceRoom]()
    weak var parentReservationController: NewReservationTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
    }
    
    func loadData() {
        guard let startDate = startDate, let duration = duration else { return }
        
        showActivityIndicator()
        datastore.getAvailableRooms(startDate: startDate, duration: duration, apiResponse: { [weak self] results, error in
            guard let strongSelf = self else { return }
            
            if let results = results {
                strongSelf.rooms = results
            }
            
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
                strongSelf.hideActivityIndicator()
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AvailableRoomCell", for: indexPath)
        cell.textLabel?.text = rooms[indexPath.row].roomName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRoom = rooms[indexPath.row]
        parentReservationController?.setSelectedRoom(room: selectedRoom)
        navigationController?.popViewController(animated: true)
    }
}
