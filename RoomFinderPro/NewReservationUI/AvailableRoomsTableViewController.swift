//
//  AvailableRoomsTableViewController.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import UIKit

class AvailableRoomsTableViewController: UITableViewController {
    
    let datastore = ReservationsDataStore()
    var startDate: Date?
    var duration: Double?
    var rooms = [ConferenceRoom]()
    weak var parentReservationController: NewReservationTableViewController?
    
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    var activityIndicatorBackground = UIView(frame: CGRect(x: (UIScreen.main.bounds.size.width / 2) - 50, y: (UIScreen.main.bounds.size.height / 2) - 200, width: 100, height: 100))

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
    
    // MARK: Generic Loading Indicator
    
    func showActivityIndicator() {
        activityIndicatorBackground.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4)
        activityIndicatorBackground.layer.cornerRadius = 10
        
        activityIndicatorBackground.addSubview(activityIndicator)
        view.addSubview(activityIndicatorBackground)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        
        let horizontalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: activityIndicatorBackground, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(horizontalConstraint)
        
        let verticalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: activityIndicatorBackground, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(verticalConstraint)
        
        let backgroundHorizontalConstraint = NSLayoutConstraint(item: activityIndicatorBackground, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: activityIndicatorBackground, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(backgroundHorizontalConstraint)
        
        let backgroundVerticalConstraint = NSLayoutConstraint(item: activityIndicatorBackground, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: activityIndicatorBackground, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(backgroundVerticalConstraint)
        
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        activityIndicatorBackground.removeFromSuperview()
    }
}
