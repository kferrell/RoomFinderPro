//
//  ReservationsTableViewController.swift
//  RoomFinderPro
//
//  Created by Ferrell, Kevin on 9/2/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import UIKit

class ReservationsTableViewController: UITableViewController {
    
    var reservations = [Reservation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Meetings"
        populateDummyData()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAddEventForm))
    }
    
    @objc func showAddEventForm() {
        let meetingForm = MeetingFormViewController(nibName: nil, bundle: nil)
        let navController = UINavigationController(rootViewController: meetingForm)
        present(navController, animated: true, completion: nil)
    }
    
    func populateDummyData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let baseDate = formatter.date(from: "2017/09/28 09:30")
        
        reservations.append(Reservation(title: "Standup", numberOfParticipants: 10, startDate: baseDate!, endDate: baseDate!.addingTimeInterval(30 * 60), building: "WC4", room: "3134"))
        reservations.append(Reservation(title: "Design Review", numberOfParticipants: 10, startDate: baseDate!.addingTimeInterval(60 * 60), endDate: baseDate!.addingTimeInterval(60 * 60 + 30 * 60), building: "WC4", room: "2145"))
        reservations.append(Reservation(title: "Project Planning", numberOfParticipants: 10, startDate: baseDate!.addingTimeInterval(60 * 240), endDate: baseDate!.addingTimeInterval(60 * 240 + 30 * 60), building: "WC4", room: "4800"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
