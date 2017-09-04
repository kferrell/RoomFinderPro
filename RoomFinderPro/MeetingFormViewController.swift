//
//  MeetingFormViewController.swift
//  RoomFinderPro
//
//  Created by Ferrell, Kevin on 9/2/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import Foundation
import Eureka

class MeetingFormViewController: FormViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var parentReservationView: ReservationsTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Add Meeting"
        
        form +++ Section("Section1")
            <<< TextRow(){ row in
                //row.title = "Text Row"
                row.placeholder = "Title"
                row.tag = "Title"
            }
            <<< IntRow(){
                //$0.title = "Phone Row"
                $0.placeholder = "Number of Participants"
                $0.tag = "Participants"
            }
            <<< DateTimeRow(){
                $0.title = "Start"
                $0.value = Date()
                $0.tag = "StartTime"
            }
            <<< DateTimeRow(){
                $0.title = "End"
                $0.value = Date()
                $0.tag = "EndTime"
            }
            +++ Section("Meeting Location")
            <<< ButtonRow() { (row: ButtonRow) -> Void in
                row.title = "Find By Photo"
                row.cell.accessibilityTraits = UIAccessibilityTraitButton
                row.cell.accessibilityLabel = "Find By Photo"
                }  .onCellSelection({ (cell, row) in
                    self.takePhoto()
            })
            <<< PushRow<String>(){
                $0.title = "Building"
                $0.selectorTitle = "Select a building"
                $0.options = ["West Creek 1", "West Creek 2", "West Creek 3", "West Creek 4", "West Creek 5", "West Creek 6", "West Creek 7", "West Creek 8", "Commons"]
                $0.tag = "Building"
            }
            <<< TextRow(){ row in
                row.placeholder = "Room"
                row.tag = "RoomRow"
            }
            +++ Section("Book Room")
            <<< ButtonRow() { (row: ButtonRow) -> Void in
                row.title = "Book Room"
                row.cell.accessibilityTraits = UIAccessibilityTraitButton
                row.cell.accessibilityLabel = "Boom Room"
                }  .onCellSelection({ (cell, row) in
                    self.bookRoom()
                })
    }
    
    func takePhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.modalTransitionStyle = .flipHorizontal
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .camera
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = ["public.image"]
        imagePickerController.cameraCaptureMode = .photo
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
        
        // Init image analysis view
        let storyboard: UIStoryboard = UIStoryboard(name: "Main",bundle: nil)
        let photoViewController = storyboard.instantiateViewController(withIdentifier: "RoomPhotoViewController") as! RoomPhotoViewController
        photoViewController.selectedPhoto = pickedImage
        photoViewController.parentRoomReservationController = self
        navigationController?.pushViewController(photoViewController, animated: true)
    }
    
    func setRoomNumber(toValue roomNumber: String) {
        let row: TextRow? = form.rowBy(tag: "RoomRow")
        row?.value = roomNumber
        
        tableView.reloadData()
    }
    
    func bookRoom() {
        let titleRow: TextRow? = form.rowBy(tag: "Title")
        let participantsRow: IntRow? = form.rowBy(tag: "Participants")
        let startRow: DateTimeRow? = form.rowBy(tag: "StartTime")
        let endRow: DateTimeRow? = form.rowBy(tag: "EndTime")
        let buildingRow: BaseRow? = form.rowBy(tag: "Building")
        let roomRow: TextRow? = form.rowBy(tag: "RoomRow")
        
        let title = titleRow?.value
        let participants = participantsRow?.value
        let start = startRow?.value
        let end = endRow?.value
        let building = buildingRow?.baseValue as? String
        let room = roomRow?.value
        
        if let title = title, let participants = participants, let start = start, let end = end, let building = building, let room = room, let reservationView = parentReservationView {
            let newMeeting = Reservation(title: title, numberOfParticipants: participants, startDate: start, endDate: end, building: building, room: room)
            parentReservationView?.addNewReservation(reservation: newMeeting)
            dismiss(animated: true, completion: nil)
        }
    }
}
