//
//  ReservationTableViewCell.swift
//  RoomFinderPro
//
//  Created by Ferrell, Kevin on 9/2/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import UIKit

class ReservationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func configureCell(withReservation reservation: RoomReservation) {
        titleLabel.text = reservation.title
        roomLabel.text = reservation.roomName
        timeLabel.text = reservation.formattedDateString()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
