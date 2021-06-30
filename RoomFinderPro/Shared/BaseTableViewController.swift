//
//  BaseTableViewController.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation
import UIKit

class BaseTableViewController: UITableViewController {
    
    var activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
    var activityIndicatorBackground = UIView(frame: CGRect(x: (UIScreen.main.bounds.size.width / 2) - 50, y: (UIScreen.main.bounds.size.height / 2) - 200, width: 100, height: 100))
    
    // MARK: Generic Loading Indicator
    
    func showActivityIndicator() {
        activityIndicatorBackground.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4)
        activityIndicatorBackground.layer.cornerRadius = 10
        
        activityIndicatorBackground.addSubview(activityIndicator)
        view.addSubview(activityIndicatorBackground)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        
        let horizontalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: activityIndicatorBackground, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(horizontalConstraint)
        
        let verticalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: activityIndicatorBackground, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(verticalConstraint)
        
        let backgroundHorizontalConstraint = NSLayoutConstraint(item: activityIndicatorBackground, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: activityIndicatorBackground, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(backgroundHorizontalConstraint)
        
        let backgroundVerticalConstraint = NSLayoutConstraint(item: activityIndicatorBackground, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: activityIndicatorBackground, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(backgroundVerticalConstraint)
        
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        activityIndicatorBackground.removeFromSuperview()
    }
}
