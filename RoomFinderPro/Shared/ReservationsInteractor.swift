//
//  ReservationsInteractor.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation

class ReservationsInteractor {
    
    init() {
        
    }
    
    func getNearest30Min(startDate: Date) -> Date {
        let cal = Calendar.current
        let startOfHour = cal.dateInterval(of: .hour, for: startDate)!.start
        
        // Round to whole seconds
        let seconds = startDate.timeIntervalSince(startOfHour).rounded()
        let minutes = seconds / 60
        
        // Determine how to round the minutes to the nearest 30 min interval
        var minuteAdjustment = minutes
        if minutes < 15 {
            // Round to 00
            minuteAdjustment = 0
        } else if minutes >= 15 && minutes <= 30 {
            // Round up to 30
            minuteAdjustment += (30.0 - minutes)
        } else if minutes > 30 && minutes < 45 {
            // Round down to 30
            minuteAdjustment -= minutes - 30
        } else {
            // Round up to next 00
            minuteAdjustment += 60 - minutes
        }
        
        return startOfHour.addingTimeInterval(minuteAdjustment * 60)
    }
    
    func getLabelText(forMinDuration duration: Double) -> String {
        if duration < 60 {
            return "\(Int(duration)) min"
        } else {
            // Round to nearest 0.01
            let hours = round((duration / 60.0) / 0.01) * 0.01
            return "\(hours) hrs"
        }
    }
}
