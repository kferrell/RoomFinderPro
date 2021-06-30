//
//  RoomPhotoViewController.swift
//  RoomFinderPro
//
//  Created by Ferrell, Kevin on 9/3/17.
//  Copyright © 2017 Capital One. All rights reserved.
//

import UIKit
import Vision
import CoreML

class RoomPhotoViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let reservationsInteractor = ReservationsInteractor()
    var parentRoomReservationController: NewReservationTableViewController?
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var roomLabel: UILabel!
    
    var selectedPhoto: UIImage?
    var markedImage: UIImage?
    var textImages = [UIImage]()
    var characterImages = [Int:[UIImage]]()
    var identifiedWords = [Int:String]()
    
    var model: VNCoreMLModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model = try? VNCoreMLModel(for: Alphanum_28x28(configuration: MLModelConfiguration()).model)
        
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
                // DEBUG: Add text outlines to the image on screen
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
        var wordCnt = 0
        
        let img = renderer.image { ctx in
            for item in results {
                ctx.cgContext.setFillColor(UIColor.clear.cgColor)
                ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
                ctx.cgContext.setLineWidth(2)
                ctx.cgContext.addRect(item.boundingBox.applying(transform))
                ctx.cgContext.drawPath(using: .fillStroke)
                
                // Process individual character observations
                if let characterObservations = item.characterBoxes {
                    for observation in characterObservations {
                        ctx.cgContext.setFillColor(UIColor.clear.cgColor)
                        ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
                        ctx.cgContext.setLineWidth(1)
                        ctx.cgContext.addRect(observation.boundingBox.applying(transform))
                        ctx.cgContext.drawPath(using: .fillStroke)
                        
                        addScreenShotToCharImages(sourceImage: image, boundingBox: observation.boundingBox.applying(transform), wordCnt: wordCnt)
                    }
                }
                
                wordCnt += 1
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
    
    func addScreenShotToCharImages(sourceImage image: UIImage, boundingBox: CGRect, wordCnt: Int) {
        let imageRef = image.cgImage!.cropping(to: boundingBox)
        let croppedImage = UIImage(cgImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)
        
        var characterImageArray = characterImages[wordCnt]
        
        if characterImageArray == nil {
            characterImageArray = [UIImage]()
        }
        
        characterImageArray?.append(croppedImage)
        characterImages[wordCnt] = characterImageArray
    }
    
    func mixImage(topImage: UIImage, bottomImage: UIImage, topImagePoint: CGPoint = CGPoint.zero, isHaveBackground: Bool = true) -> UIImage {
        let newSize = bottomImage.size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        if isHaveBackground {
            bottomImage.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        }
        
        topImage.draw(in: CGRect(origin: topImagePoint, size: newSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        return newImage!
    }
    
    func detectRoomNumber() {
        var wordIteration = 0
        var charIteration = 0
        
        for (wordIdx, word) in characterImages {
            wordIteration += 1
            charIteration = 0
            
            for charImage in word {
                charIteration += 1
                let processedImage = reservationsInteractor.preprocessCharacterImage(image: charImage)
                
                
                if wordIteration == characterImages.count && charIteration == word.count {
                    classifyCharacterImage(image: processedImage, wordNumber: wordIdx, isLastClassificationRequest: true)
                } else {
                    classifyCharacterImage(image: processedImage, wordNumber: wordIdx, isLastClassificationRequest: false)
                }
            }
        }
    }
    
    func classifyCharacterImage(image: UIImage, wordNumber: Int, isLastClassificationRequest: Bool) {
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("Unexpected result type from VNCoreMLRequest")
            }
            
            let result = topResult.identifier
            
            var wordString = self?.identifiedWords[wordNumber] != nil ? self?.identifiedWords[wordNumber] : ""
            wordString! += result
            self?.identifiedWords[wordNumber] = wordString!
            
            if isLastClassificationRequest {
                self?.selectRoomNumber()
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("Could not convert UIImage to CIImage :(")
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            }
            catch {
                print(error)
            }
        }
    }
    
    func selectRoomNumber() {
        var maxDigitIndex = 0
        var maxDigitAmount = 0.0
        let digits = CharacterSet.decimalDigits
        
        for (_, item) in identifiedWords.enumerated() {
            if item.value.count > 0 {
                var digitCnt = 0.0
                
                for char in item.value.unicodeScalars {
                    if digits.contains(char) {
                        digitCnt += 1
                    }
                }
                
                let stringDigitPercentage = digitCnt / Double(item.value.unicodeScalars.count)
                
                print("\(item) - \(stringDigitPercentage)")
                
                if stringDigitPercentage > maxDigitAmount {
                    maxDigitIndex = item.key
                    maxDigitAmount = stringDigitPercentage
                }
            }
        }
        
        // Set the room number label to the max Digit index
        DispatchQueue.main.async {
            self.roomLabel.text = self.identifiedWords[maxDigitIndex]
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
            let room = ConferenceRoom(roomId: 1, roomName: roomLabel.text!)
            parentController.setSelectedRoom(room: room)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage.rawValue] as? UIImage {
            processPhoto(photo: pickedImage)
        }
    }

}
