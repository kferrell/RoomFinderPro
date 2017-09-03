//
//  MeetingFormViewController.swift
//  RoomFinderPro
//
//  Created by Ferrell, Kevin on 9/2/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import Foundation
import Eureka

class MeetingFormViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Add Meeting"
        
        form +++ Section("Section1")
            <<< TextRow(){ row in
                //row.title = "Text Row"
                row.placeholder = "Title"
            }
            <<< IntRow(){
                //$0.title = "Phone Row"
                $0.placeholder = "Number of Participants"
            }
            <<< DateTimeRow(){
                $0.title = "Start"
                $0.value = Date()
            }
            <<< DateTimeRow(){
                $0.title = "Start"
                $0.value = Date()
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
            }
            <<< TextRow(){ row in
                row.placeholder = "Room"
            }
    }
    
    func takePhoto() {
        
    }
}
