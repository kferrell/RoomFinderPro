//
//  RoomPhotoViewController.swift
//  RoomFinderPro
//
//  Created by Ferrell, Kevin on 9/3/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import UIKit
import Vision
import SwiftOCR

class RoomPhotoViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var parentRoomReservationController: MeetingFormViewController?
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var roomLabel: UILabel!
    
    var selectedPhoto: UIImage?
    var markedImage: UIImage?
    var textImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let photo = selectedPhoto {
            processPhoto(photo: photo)
        }
    }
    
    func processPhoto(photo: UIImage) {
        photoView.image = photo
        detectAndDisplayText(forImage: photo)
    }
    
    func detectAndDisplayText(forImage image: UIImage) {
        // Remove preview text markings if needed
        self.textImages.removeAll()
        
        // Create the Vision request handler
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [VNImageOption:Any]())
        
        // Setup text recognition tequest
        let request = VNDetectTextRectanglesRequest(completionHandler: { (request, error) in
            if error != nil {
                print("Error in text detection: \(String(describing: error?.localizedDescription))")
            } else {
                // DEBUG: Add text markings to the image on screen
                self.markedImage = self.mixImage(topImage: self.drawRectangleForTextDectect(image: self.photoView.image!,
                                                                                          results: request.results as! Array<VNTextObservation>),
                                                                                      bottomImage: image)
                DispatchQueue.main.async {
                    self.photoView.image = self.markedImage
                }
                
                // Run room number detection functions
                self.detectRoomNumber()
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
                ctx.cgContext.setFillColor(UIColor.clear.cgColor)
                ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
                ctx.cgContext.setLineWidth(2)
                ctx.cgContext.addRect(item.boundingBox.applying(transform))
                ctx.cgContext.drawPath(using: .fillStroke)
                
                addScreenShotToTextImages(sourceImage: image, boundingBox: item.boundingBox.applying(transform))
            }
        }
        return img
    }
    
    func addScreenShotToTextImages(sourceImage image: UIImage, boundingBox: CGRect) {
        // Increase the bounding box around the letters by 10% to improve OCR
        let pct = 0.1 as CGFloat
        let newRect = boundingBox.insetBy(dx: -boundingBox.width*pct/2, dy: -boundingBox.height*pct/2)
        
        let imageRef = image.cgImage!.cropping(to: newRect)
        let croppedImage = UIImage(cgImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)
        textImages.append(croppedImage)
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
    
    func detectRoomNumber() {
        var textStrings = [String]()
        var imageCnt = 0
        
        for item in textImages {
            let swiftOCRInstance = SwiftOCR()
            
            swiftOCRInstance.recognize(item) { recognizedString in
                print("text: \(recognizedString)")
                textStrings.append(recognizedString)
                imageCnt += 1
                
                // Select the room number once all strings are processed
                if imageCnt == self.textImages.count {
                    self.selectRoomNumber(fromStrings: textStrings)
                }
            }
        }
    }
    
    func selectRoomNumber(fromStrings textStrings: [String]) {
        var maxDigitIndex = 0
        var maxDigitAmount = 0.0
        let digits = CharacterSet.decimalDigits
        
        for (idx, item) in textStrings.enumerated() {
            if item.count > 0 {
                var digitCnt = 0.0
                
                for char in item.unicodeScalars {
                    if digits.contains(char) {
                        digitCnt += 1
                    }
                }
                
                let stringDigitPercentage = digitCnt / Double(item.unicodeScalars.count)
                
                print("\(item) - \(stringDigitPercentage)")
                
                if stringDigitPercentage > maxDigitAmount {
                    maxDigitIndex = idx
                    maxDigitAmount = stringDigitPercentage
                }
            }
        }
        
        // Set the room number label to the max Digit index
        DispatchQueue.main.async {
            self.roomLabel.text = textStrings[maxDigitIndex]
        }
    }
    
    @IBAction func retakePhoto(_ sender: Any) {
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
    
    @IBAction func bookRoom(_ sender: Any) {
        if let parentController = parentRoomReservationController {
            parentController.setRoomNumber(toValue: roomLabel.text!)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            processPhoto(photo: pickedImage)
        }
    }

}
