//
//  ARHelper.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 9/5/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit

struct Meeting {
    var startTime: Date
    var duration: Double
    var name: String
}

class ARHelper {
    
    static func getReferenceImage(withName name: [String]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1000, height: 342.4))
        
        let img = renderer.image { ctx in
            // White background
            let rectangle = CGRect(x: 0, y: 0, width: 1000, height: 342.4)
            
            let fillPattern = UIColor(patternImage: UIImage(named: "background-pattern")!)
            ctx.cgContext.setFillColor(fillPattern.cgColor)
            // ctx.cgContext.setFillColor(UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0).cgColor)
            ctx.cgContext.addRect(rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            // Apple Logo
            let textLine1 = ""
            let textColor = UIColor.black
            let textFont = UIFont(name: "Helvetica", size: 130)!
            
            let textFontAttributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: textColor,
                ] as [NSAttributedString.Key : Any]
            
            let rect = CGRect(origin: CGPoint(x: 30.0, y: 30.0), size: rectangle.size)
            textLine1.draw(in: rect, withAttributes: textFontAttributes)
            
            // Room Name (each word on separate line)
            let roomNameFont = UIFont(name: "Helvetica", size: 93)!
            let roomNameAttributes = [
                NSAttributedString.Key.font: roomNameFont,
                NSAttributedString.Key.foregroundColor: textColor,
                NSAttributedString.Key.kern: 14.0
                ] as [NSAttributedString.Key : Any]
            var currentY = 60.0
            
            for word in name {
                word.draw(in: CGRect(origin: CGPoint(x: 180.0, y: currentY), size: rectangle.size), withAttributes: roomNameAttributes)
                currentY += 100
            }
        }
        
        return img
    }
    
    static func createTextNode(string: String) -> SCNNode {
        let text = SCNText(string: string, extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1.0)
        text.flatness = 0.01
        text.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: text)
        
        let fontSize = Float(0.02)
        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        
        return textNode
    }
    
    static func getRoomAgendaNodeAvailable(anchor: ARImageAnchor, meetings: [Meeting]) -> SCNNode {
        let agendaNode = SCNNode()
        let agendaGeometry = SCNPlane(width: anchor.referenceImage.physicalSize.width,
                                      height: anchor.referenceImage.physicalSize.height)
        agendaGeometry.cornerRadius = 0.005
        agendaGeometry.firstMaterial?.diffuse.contents = UIColor(red: 66.0/255.0, green: 128.0/255.0, blue: 61.0/255.0, alpha: 1.0)
        agendaNode.geometry = agendaGeometry
        agendaNode.opacity = 1.0
        agendaNode.eulerAngles.x = -.pi / 2
        
        let textXOrigin = Float(-(anchor.referenceImage.physicalSize.width / 2) + (anchor.referenceImage.physicalSize.width * 0.08))
        let textYOrigin = Float((agendaGeometry.height / 2) - (agendaGeometry.height * 0.30))
        let fontSize = Float(0.001)
        
        // Header:
        let text = anchor.name ?? "Jim Henson"
        let header = SCNText(string: text, extrusionDepth: 0.01)
        header.font = UIFont(name: ".SFUIDisplay-Semibold", size: 12.0)
        header.flatness = 0.01
        header.firstMaterial?.diffuse.contents = UIColor.white
        let headerNode = SCNNode(geometry: header)
        headerNode.position.x = textXOrigin
        headerNode.position.y = textYOrigin
        headerNode.position.z = 0.0001
        headerNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        agendaNode.addChildNode(headerNode)
        
        // Available Until
        let message = SCNText(string: "Available for 1.5 Hrs", extrusionDepth: 0.01)
        message.font = UIFont(name: ".SFUIDisplay-Medium", size: 10.0)
        message.flatness = 0.01
        message.firstMaterial?.diffuse.contents = UIColor.white
        let messageNode = SCNNode(geometry: message)
        messageNode.position.x = textXOrigin
        messageNode.position.y = textYOrigin - 0.015
        messageNode.position.z = 0.0002
        messageNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        agendaNode.addChildNode(messageNode)
        
        // Time:
        let time = SCNText(string: ARHelper.getCurrentTime(), extrusionDepth: 0.01)
        time.font = UIFont(name: ".SFUIDisplay", size: 10.0)
        time.flatness = 0.01
        time.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.right)
        time.firstMaterial?.diffuse.contents = UIColor.white
        let timeNode = SCNNode(geometry: time)
        timeNode.position.x = (textXOrigin * -1) - Float((anchor.referenceImage.physicalSize.width * 0.15))
        timeNode.position.y = textYOrigin
        timeNode.position.z = 0.0003
        timeNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        agendaNode.addChildNode(timeNode)
        
        // Events:
        let events = SCNText(string: "4 Upcoming Events", extrusionDepth: 0.01)
        events.font = UIFont(name: ".SFUIDisplay", size: 7.0)
        events.flatness = 0.01
        events.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.right)
        events.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)
        let eventsNode = SCNNode(geometry: events)
        eventsNode.position.x = (textXOrigin * -1) - Float((anchor.referenceImage.physicalSize.width * 0.22))
        eventsNode.position.y = textYOrigin - 0.015
        eventsNode.position.z = 0.0004
        eventsNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        agendaNode.addChildNode(eventsNode)
        
        
        // Button
        let buttonGeometry = SCNPlane(width: (anchor.referenceImage.physicalSize.width / 2.5), height: (anchor.referenceImage.physicalSize.height * 0.25))
        buttonGeometry.cornerRadius = 0.005
        buttonGeometry.firstMaterial?.diffuse.contents = UIColor(red: 119.0/255.0, green: 211.0/255.0, blue: 110.0/255.0, alpha: 1.0)
        let buttonNode = SCNNode(geometry: buttonGeometry)
        buttonNode.position.x = Float(-(anchor.referenceImage.physicalSize.width / 2) + (anchor.referenceImage.physicalSize.width * 0.27))
        buttonNode.position.y = textYOrigin - 0.04
        buttonNode.position.z = 0.0005
        buttonNode.opacity = 1.0
        buttonNode.name = "ReserveRoomButton-" + text
        agendaNode.addChildNode(buttonNode)
        
        // Button Text
        let buttonText = SCNText(string: "Reserve Room", extrusionDepth: 0.01)
        buttonText.font = UIFont(name: ".SFUIDisplay-Semibold", size: 8.0)
        buttonText.flatness = 0.01
        buttonText.firstMaterial?.diffuse.contents = UIColor.white
        let buttonTextNode = SCNNode(geometry: buttonText)
        buttonTextNode.position.x = Float(-(buttonGeometry.width / 4)) // Float(-(anchor.referenceImage.physicalSize.width / 9))
        buttonTextNode.position.y = Float(-(buttonGeometry.height / 4)) //Float(-anchor.referenceImage.physicalSize.height * 0.6)
        buttonTextNode.position.z = 0.0006
        buttonTextNode.opacity = 1.0
        buttonTextNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        buttonNode.addChildNode(buttonTextNode)
        
        return agendaNode
    }
    
    static func getRoomAgendaNodeUnavailable(anchor: ARImageAnchor, meetings: [Meeting]) -> SCNNode {
        let agendaNode = SCNNode()
        let agendaGeometry = SCNPlane(width: anchor.referenceImage.physicalSize.width,
                                      height: anchor.referenceImage.physicalSize.height)
        agendaGeometry.cornerRadius = 0.005
        agendaGeometry.firstMaterial?.diffuse.contents = UIColor(red: 141.0/255.0, green: 31.0/255.0, blue: 42.0/255.0, alpha: 1.0)
        agendaNode.geometry = agendaGeometry
        agendaNode.opacity = 1.0
        agendaNode.eulerAngles.x = -.pi / 2
        
        let textXOrigin = Float(-(anchor.referenceImage.physicalSize.width / 2) + (anchor.referenceImage.physicalSize.width * 0.08))
        let textYOrigin = Float((agendaGeometry.height / 2) - (agendaGeometry.height * 0.30))
        let fontSize = Float(0.001)
        
        // Header:
        let text = anchor.name ?? "Jim Henson"
        let header = SCNText(string: text, extrusionDepth: 0.01)
        header.font = UIFont(name: ".SFUIDisplay-Semibold", size: 12.0)
        header.flatness = 0.01
        header.firstMaterial?.diffuse.contents = UIColor.white
        let headerNode = SCNNode(geometry: header)
        headerNode.position.x = textXOrigin
        headerNode.position.y = textYOrigin
        headerNode.position.z = 0.0001
        headerNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        agendaNode.addChildNode(headerNode)
        
        // Available Until
        let message = SCNText(string: "Reserved for the next 1 Hr", extrusionDepth: 0.01)
        message.font = UIFont(name: ".SFUIDisplay-Medium", size: 10.0)
        message.flatness = 0.01
        message.firstMaterial?.diffuse.contents = UIColor.white
        let messageNode = SCNNode(geometry: message)
        messageNode.position.x = textXOrigin
        messageNode.position.y = textYOrigin - 0.015
        messageNode.position.z = 0.0002
        messageNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        agendaNode.addChildNode(messageNode)
        
        // Time:
        let time = SCNText(string: ARHelper.getCurrentTime(), extrusionDepth: 0.01)
        time.font = UIFont(name: ".SFUIDisplay", size: 10.0)
        time.flatness = 0.01
        time.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.right)
        time.firstMaterial?.diffuse.contents = UIColor.white
        let timeNode = SCNNode(geometry: time)
        timeNode.position.x = (textXOrigin * -1) - Float((anchor.referenceImage.physicalSize.width * 0.15))
        timeNode.position.y = textYOrigin
        timeNode.position.z = 0.0003
        timeNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        agendaNode.addChildNode(timeNode)
        
        // Events:
        let events = SCNText(string: "2 Upcoming Events", extrusionDepth: 0.01)
        events.font = UIFont(name: ".SFUIDisplay", size: 7.0)
        events.flatness = 0.01
        events.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.right)
        events.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)
        let eventsNode = SCNNode(geometry: events)
        eventsNode.position.x = (textXOrigin * -1) - Float((anchor.referenceImage.physicalSize.width * 0.22))
        eventsNode.position.y = textYOrigin - 0.015
        eventsNode.position.z = 0.0004
        eventsNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        agendaNode.addChildNode(eventsNode)
        
        
        // Button
        let buttonGeometry = SCNPlane(width: (anchor.referenceImage.physicalSize.width / 2.5), height: (anchor.referenceImage.physicalSize.height * 0.25))
        buttonGeometry.cornerRadius = 0.005
        buttonGeometry.firstMaterial?.diffuse.contents = UIColor(red: 243.0/255.0, green: 75.0/255.0, blue: 90.0/255.0, alpha: 1.0)
        let buttonNode = SCNNode(geometry: buttonGeometry)
        buttonNode.position.x = Float(-(anchor.referenceImage.physicalSize.width / 2) + (anchor.referenceImage.physicalSize.width * 0.27))
        buttonNode.position.y = textYOrigin - 0.04
        buttonNode.position.z = 0.0005
        buttonNode.opacity = 1.0
        buttonNode.name = "ReserveRoomButton-" + text
        agendaNode.addChildNode(buttonNode)
        
        // Button Text
        let buttonText = SCNText(string: "End Meeting", extrusionDepth: 0.01)
        buttonText.font = UIFont(name: ".SFUIDisplay-Semibold", size: 8.0)
        buttonText.flatness = 0.01
        buttonText.firstMaterial?.diffuse.contents = UIColor.white
        let buttonTextNode = SCNNode(geometry: buttonText)
        buttonTextNode.position.x = Float(-(buttonGeometry.width / 4)) // Float(-(anchor.referenceImage.physicalSize.width / 9))
        buttonTextNode.position.y = Float(-(buttonGeometry.height / 4)) //Float(-anchor.referenceImage.physicalSize.height * 0.6)
        buttonTextNode.position.z = 0.0006
        buttonTextNode.opacity = 1.0
        buttonTextNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        buttonNode.addChildNode(buttonTextNode)
        
        return agendaNode
    }
    
    static func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        
        let dateString = formatter.string(from: Date())
        return dateString
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATextLayerAlignmentMode(_ input: CATextLayerAlignmentMode) -> String {
	return input.rawValue
}
