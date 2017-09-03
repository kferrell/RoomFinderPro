//
//  RoomPhotoViewController.swift
//  RoomFinderPro
//
//  Created by Ferrell, Kevin on 9/3/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import UIKit
import Vision

class RoomPhotoViewController: UIViewController {
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var roomLabel: UILabel!
    
    var selectedPhoto: UIImage?
    var markedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let photo = selectedPhoto {
            photoView.image = photo
            detectAndDisplayText(forImage: photo)
        }
    }
    
    func detectAndDisplayText(forImage image: UIImage) {
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [VNImageOption:Any]())
        
        let request = VNDetectTextRectanglesRequest(completionHandler: { (request, error) in
            if error != nil {
                print("Error in text detection: \(String(describing: error?.localizedDescription))")
            } else {
                self.markedImage = self.mixImage(topImage: self.drawRectangleForTextDectect(image: self.photoView.image!, results: request.results as! Array<VNTextObservation>), bottomImage: image)
                
                DispatchQueue.main.async {
                    self.photoView.image = self.markedImage
                }
            }
        })
        
        request.reportCharacterBoxes = true
        
        do {
            try handler.perform([request])
        } catch {
            print("Unable to detect text")
        }
    }
    
    func drawRectangleForTextDectect(image: UIImage, results:Array<VNTextObservation>) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        var transform = CGAffineTransform.identity;
        transform = transform.scaledBy( x: image.size.width, y: -image.size.height);
        transform = transform.translatedBy(x: 0, y: -1 );
        
        let img = renderer.image { ctx in
            for item in results {
                //let TextObservation:VNTextObservation = item
                ctx.cgContext.setFillColor(UIColor.clear.cgColor)
                ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
                ctx.cgContext.setLineWidth(2)
                ctx.cgContext.addRect(item.boundingBox.applying(transform))
                ctx.cgContext.drawPath(using: .fillStroke)
            }
        }
        return img
    }
    
    func mixImage(topImage: UIImage, bottomImage: UIImage, topImagePoint: CGPoint = CGPoint.zero, isHaveBackground: Bool = true) -> UIImage {
        let newSize = bottomImage.size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        if(isHaveBackground==true){
            bottomImage.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        }
        topImage.draw(in: CGRect(origin: topImagePoint, size: newSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        return newImage!
    }
    
    @IBAction func retakePhoto(_ sender: Any) {
        
    }
    
    @IBAction func bookRoom(_ sender: Any) {
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

}
