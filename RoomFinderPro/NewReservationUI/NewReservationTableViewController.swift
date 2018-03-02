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
    case EndDate
    case EndDatePicker
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
            row = Row.EndDate
        case (0, 4):
            row = Row.EndDatePicker
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

class NewReservationTableViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var roomNumberLabel: UILabel!
    
    var startDatePickerIsHidden = true
    var endDatePickerIsHidden = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func startDateDidChange(_ sender: Any) {
        setLabel(startDateLabel, date: startDatePicker.date)
    }
    
    @IBAction func endDateDidChange(_ sender: Any) {
        setLabel(endDateLabel, date: endDatePicker.date)
    }
    
    func setLabel(_ label: UILabel, date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy-MM-dd HH:mm"
        label.text = formatter.string(from: date)
    }
    
    func toggleStartDatePicker() {
        startDatePickerIsHidden = !startDatePickerIsHidden
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func toggleEndDatePicker() {
        endDatePickerIsHidden = !endDatePickerIsHidden
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.modalTransitionStyle = .flipHorizontal
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        //imagePickerController.cameraCaptureMode = .photo
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Get a reference to the image taken by the user
        let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
        
        // Initialize the image analyizer view and pass in the user's photo
        let storyboard: UIStoryboard = UIStoryboard(name: "Main",bundle: nil)
        let photoViewController = storyboard.instantiateViewController(withIdentifier: "RoomPhotoViewController") as! RoomPhotoViewController
        photoViewController.selectedPhoto = pickedImage
        photoViewController.parentRoomReservationController = self
        navigationController?.pushViewController(photoViewController, animated: true)
    }
    
    func setRoomNumber(toValue roomNumber: String) {
        roomNumberLabel.text = roomNumber
    }
    
    @IBAction func cancelForm(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveForm(_ sender: Any) {
    }
    
    // MARK: UITableviewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = Row(indexPath: indexPath)
        
        if startDatePickerIsHidden && row == .StartDatePicker {
            return 0
        } else if endDatePickerIsHidden && row == .EndDatePicker {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Row(indexPath: indexPath)
        
        if row == .StartDate {
            toggleStartDatePicker()
        } else if row == .EndDate {
            toggleEndDatePicker()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
