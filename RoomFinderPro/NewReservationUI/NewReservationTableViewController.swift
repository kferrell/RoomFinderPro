//
//  NewReservationTableViewController.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/1/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import UIKit

enum Row: Int {
    case Title
    case StartDate
    case StartDatePicker
    case Duration
    case RoomNumber
    case PhotoButton
    case Unknown
    
    init(indexPath: IndexPath) {
        var row = Row.Unknown
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            row = Row.Title
        case (0, 1):
            row = Row.StartDate
        case (0, 2):
            row = Row.StartDatePicker
        case (0, 3):
            row = Row.Duration
        case (1, 0):
            row = Row.RoomNumber
        case (1, 1):
            row = Row.PhotoButton
        default:
            ()
        }
        
        assert(row != Row.Unknown)
        
        self = row
    }
}

class NewReservationTableViewController: BaseTableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var meetingTitleLabel: UITextField!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var durationStepper: UIStepper!
    @IBOutlet weak var roomNumberLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var startDatePickerIsHidden = true
    let reservationsInteractor = ReservationsInteractor()
    let reservationsDataStore = ReservationsDataStore()
    var selectedRoom: ConferenceRoom?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set a default meeting title
        meetingTitleLabel.text = "Conference Call Reservation"
        
        // Set minimum date value to two hours in the past
        startDatePicker.minimumDate = Date().addingTimeInterval((-120 * 60))
        
        // Set the start date to the nearest 30 min block
        startDatePicker.date = reservationsInteractor.getNearest30Min(startDate: Date())
        setLabel(startDateLabel, date: startDatePicker.date)
        
        validateForm()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        meetingTitleLabel.resignFirstResponder()
        return true
    }
    
    @IBAction func meetingTitleEdited(_ sender: Any) {
        validateForm()
    }
    
    @IBAction func startDateDidChange(_ sender: Any) {
        setLabel(startDateLabel, date: startDatePicker.date)
    }
    
    @IBAction func durationStepperDidChange(_ sender: Any) {
        // Hide the keyboard if displayed
        meetingTitleLabel.resignFirstResponder()
        
        let labelValue = reservationsInteractor.getLabelText(forMinDuration: durationStepper.value)
        durationLabel.text = "Duration: \(labelValue)"
    }
    
    func setLabel(_ label: UILabel, date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        label.text = formatter.string(from: date)
    }
    
    func toggleStartDatePicker() {
        startDatePickerIsHidden = !startDatePickerIsHidden
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    @IBAction func cancelForm(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveForm(_ sender: Any) {
        guard let meetingTitle = meetingTitleLabel.text, let selectedRoom = selectedRoom else { return }

        let reservation = RoomReservation(objectId: nil, title: meetingTitle, duration: Int(durationStepper.value), roomName: selectedRoom.roomName, startDate: APIDate(date: startDatePicker.date))
        
        showActivityIndicator()
        reservationsDataStore.saveNewReservation(reservation: reservation, apiResponse: { [weak self] error in
            DispatchQueue.main.async {
                self?.hideActivityIndicator()
                
                if error == nil {
                    self?.dismiss(animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Error", message: "RoomFinderPro was unable to make your reservation at this time. Please try again later.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FindAvailableRooms" {
            // Hide the keyboard if displayed
            meetingTitleLabel.resignFirstResponder()
            
            if let destination = segue.destination as? AvailableRoomsTableViewController {
                destination.parentReservationController = self
                destination.startDate = startDatePicker.date
                destination.duration = durationStepper.value
            }
        }
    }
    
    func setSelectedRoom(room: ConferenceRoom) {
        selectedRoom = room
        roomNumberLabel.text = room.roomName
        validateForm()
    }
    
    func validateForm() {
        guard let meetingTitle = meetingTitleLabel.text else {
            saveButton.isEnabled = false
            return
        }
        
        if !meetingTitle.isEmpty && selectedRoom != nil {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
    // MARK: UITableviewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = Row(indexPath: indexPath)
        
        if startDatePickerIsHidden && row == .StartDatePicker {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Row(indexPath: indexPath)
        
        if row == .StartDate {
            // Hide the keyboard if displayed
            meetingTitleLabel.resignFirstResponder()
            
            toggleStartDatePicker()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        // Hide the keyboard if displayed
        meetingTitleLabel.resignFirstResponder()
        
        // Initialize the image analyizer view and pass in the user's photo
        let storyboard: UIStoryboard = UIStoryboard(name: "Main",bundle: nil)
        let photoViewController = storyboard.instantiateViewController(withIdentifier: "ARSignViewController") as! ARSignFinderViewController
        photoViewController.parentRoomReservationController = self
        navigationController?.pushViewController(photoViewController, animated: true)
    }
}
