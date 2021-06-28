//
//  ARSignFinderViewController.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 9/5/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import ARKit
import SceneKit
import UIKit
import Vision
import VideoToolbox

class ARSignFinderViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var parentRoomReservationController: NewReservationTableViewController?
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    var sequenceRequestHandler = VNSequenceRequestHandler()
    let maxHistoryLength = 10
    var transpositionHistoryPoints: [CGPoint] = [ ]
    var previousPixelBuffer: CVPixelBuffer?
    var currentlyAnalyzedPixelBuffer: CVPixelBuffer?
    var currentlyAnalyzedImage: UIImage?
    let visionQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialVisionQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // Gets set to true when actively searching for text in the current frame
    var searchingForText = false
    var foundRoom = false
    var characterImages = [Int:[UIImage]]()
    var identifiedWords = [Int:String]()
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the AR experience
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }
    
    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true
    
    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
    func resetTracking() {
        // Clear AR Search Results
        foundRoom = false
        characterImages.removeAll()
        identifiedWords.removeAll()
        
        //        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
        //            fatalError("Missing expected asset catalog resources.")
        //        }
        //
        //        let imageConfiguration = ARImageTrackingConfiguration()
        //        imageConfiguration.trackingImages = referenceImages
        //        session.run(imageConfiguration)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if searchingForText || foundRoom {
            return
        }
        
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        
        let pixelBuffer: CVPixelBuffer = currentFrame.capturedImage
        
        guard previousPixelBuffer != nil else {
            previousPixelBuffer = pixelBuffer
            self.resetTranspositionHistory()
            return
        }
        
        let registrationRequest = VNTranslationalImageRegistrationRequest(targetedCVPixelBuffer: pixelBuffer)
        
        do {
            try sequenceRequestHandler.perform([registrationRequest], on: previousPixelBuffer!)
        } catch let error as NSError {
            print("failed to process request: \(error.localizedDescription)")
        }
        
        previousPixelBuffer = pixelBuffer
        
        if let results = registrationRequest.results {
            if let alignmentObservation = results.first as? VNImageTranslationAlignmentObservation {
                let alignmentTransform = alignmentObservation.alignmentTransform
                self.recordTransposition(CGPoint(x: alignmentTransform.tx, y: alignmentTransform.ty))
            }
        }
        
        if sceneStabilityAcheived() {
            if currentlyAnalyzedPixelBuffer ==  nil {
                currentlyAnalyzedPixelBuffer = pixelBuffer
                findText(frame: currentFrame)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let nodeToReturn = SCNNode()
        
        if let validImageAnchor = anchor as? ARImageAnchor {
            
            print("""
                ARImageAnchor Transform = \(validImageAnchor.transform)
                Name Of Detected Image = \(String(describing: validImageAnchor.referenceImage.name))
                Width Of Detected Image = \(validImageAnchor.referenceImage.physicalSize.width)
                Height Of Detected Image = \(validImageAnchor.referenceImage.physicalSize.height)
                """)
            
            //            let planeNode = SCNNode()
            //            let planeGeometry = SCNPlane(width: validImageAnchor.referenceImage.physicalSize.width,
            //                                         height: validImageAnchor.referenceImage.physicalSize.height)
            //            planeGeometry.firstMaterial?.diffuse.contents = UIColor.white
            //            planeNode.geometry = planeGeometry
            //            planeNode.opacity = 0.5
            //
            //            // Rotate The PlaneNode So It Matches The Rotation Of The Anchor
            //            planeNode.eulerAngles.x = -.pi / 2
            //
            //            nodeToReturn.addChildNode(planeNode)
            
            guard let name = anchor.name else { return nil }
            
            switch name {
            case "Jim Henson":
                let agendaNode = ARHelper.getRoomAgendaNodeAvailable(anchor: validImageAnchor, meetings: [Meeting]())
                nodeToReturn.addChildNode(agendaNode)
                break
            case "Frank Lloyd Wright":
                let agendaNode = ARHelper.getRoomAgendaNodeUnavailable(anchor: validImageAnchor, meetings: [Meeting]())
                nodeToReturn.addChildNode(agendaNode)
                break
            case "John Muir":
                let agendaNode = ARHelper.getRoomAgendaNodeUnavailable(anchor: validImageAnchor, meetings: [Meeting]())
                nodeToReturn.addChildNode(agendaNode)
                break
            default:
                break
            }
        }
        
        return nodeToReturn
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchLocation = touches.first?.location(in: sceneView),
            let hitNode = sceneView?.hitTest(touchLocation, options: nil).first?.node,
            let nodeName = hitNode.name
            else { return }
        
        if nodeName.range(of:"ReserveRoomButton") != nil {
            hitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            let roomComponents = nodeName.components(separatedBy: "-")
            bookRoom(room: roomComponents[1])
        }
    }
    
    func bookRoom(room: String) {
        if let parentController = parentRoomReservationController {
            let room = ConferenceRoom(roomId: 1, roomName: room)
            parentController.setSelectedRoom(room: room)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Text Detection Rountines
    
    func findText(frame currentFrame: ARFrame) {
        searchingForText = true
        
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: { (request, error) in
            if error != nil {
                print("Error in text detection: \(String(describing: error?.localizedDescription))")
            } else {
                let observationResults = request.results as! Array<VNTextObservation>
                self.currentlyAnalyzedPixelBuffer = nil
                DispatchQueue.main.async {
                    // Remove previous boxes
                    self.sceneView.layer.sublayers?.removeSubrange(0...)
                    self.characterImages.removeAll()
                    self.identifiedWords.removeAll()
                    
                    var wordCnt = 0
                    for region in observationResults {
                        self.drawRegionBox(box: region, wordCnt: wordCnt)
                        wordCnt += 1
                    }
                    
                    self.detectRoomName()
                }
            }
            
            self.searchingForText = false
        })
        
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(UIDevice.current.orientation.rawValue))!
        let transform = currentFrame.displayTransform(for: UIApplication.shared.statusBarOrientation, viewportSize: self.sceneView.frame.size).inverted()
        let image = CIImage(cvPixelBuffer: currentFrame.capturedImage).transformed(by: transform)
        
        // Capture screen shot
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(image, from: image.extent)!
        currentlyAnalyzedImage = UIImage.init(cgImage: cgImage)
        
        //let handler = VNImageRequestHandler(ciImage: image, orientation: orientation, options: [:])
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        textRequest.reportCharacterBoxes = true
        
        DispatchQueue.global(qos: .background).async {
            try? handler.perform([textRequest])
        }
    }
    
    func drawRegionBox(box: VNTextObservation, wordCnt: Int) {
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy( x: view.frame.size.width, y: -view.frame.size.height)
        transform = transform.translatedBy(x: 0, y: -1 )
        
        let adjustedBounds = box.boundingBox.applying(transform)
        
        let layer = CALayer()
        layer.frame = CGRect(x: adjustedBounds.origin.x, y: adjustedBounds.origin.y, width: adjustedBounds.width, height: adjustedBounds.height)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.green.cgColor
        
        sceneView.layer.addSublayer(layer)
        
        if let characterBoxes = box.characterBoxes {
            for charBox in characterBoxes {
                let boxBounds = charBox.boundingBox.applying(transform)
                let boxLayer = CALayer()
                boxLayer.frame = CGRect(x: boxBounds.origin.x, y: boxBounds.origin.y, width: boxBounds.width, height: boxBounds.height)
                boxLayer.borderWidth = 1.0
                boxLayer.borderColor = UIColor.blue.cgColor
                sceneView.layer.addSublayer(boxLayer)
                
                self.takeCharacterScreenShots(characterBox: charBox, wordCnt: wordCnt)
            }
        }
    }
    
    func takeCharacterScreenShots(characterBox: VNRectangleObservation, wordCnt: Int) {
        guard let currentlyAnalyzedImage = self.currentlyAnalyzedImage else { return }
        let boundingBox = characterBox.boundingBox
        
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy( x: currentlyAnalyzedImage.size.width, y: -currentlyAnalyzedImage.size.height)
        transform = transform.translatedBy(x: 0, y: -1 )
        let crop = boundingBox.applying(transform)
        
        let imageRef = currentlyAnalyzedImage.cgImage!.cropping(to: crop)
        let croppedImage = UIImage(cgImage: imageRef!, scale: currentlyAnalyzedImage.scale, orientation: currentlyAnalyzedImage.imageOrientation)
//        let imageWithInsets = insertInsets(image: croppedImage,
//                                           insetWidthDimension: 10.0,
//                                           insetHeightDimension: 10.0)
//        let size = CGSize(width: 28, height: 28)
//        let resizedImage = resize(image: imageWithInsets, targetSize: size)
//
//        let processedImage = convertToGrayscale(image: resizedImage)
        
        // Save the image with the proper word
        var characterImageArray = characterImages[wordCnt]
        if characterImageArray == nil {
            characterImageArray = [UIImage]()
        }
        
        characterImageArray?.append(croppedImage)
        characterImages[wordCnt] = characterImageArray
    }
    
    func resize(image: UIImage, targetSize: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func convertToGrayscale(image: UIImage) -> UIImage {
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context = CGContext(data: nil,
                                width: Int(UInt(image.size.width)),
                                height: Int(UInt(image.size.height)),
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        context?.draw(image.cgImage!,
                      in: CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height))
        let imageRef: CGImage = context!.makeImage()!
        let newImage: UIImage = UIImage(cgImage: imageRef)
        return newImage
    }
    
    func getPixelColor(fromImage image: UIImage, pixel: CGPoint) -> UIColor {
        let pixelData = image.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo: Int = ((Int(image.size.width) * Int(pixel.y)) + Int(pixel.x)) * 4
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo + 1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo + 2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo + 3]) / CGFloat(255.0)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func insertInsets(image: UIImage, insetWidthDimension: CGFloat, insetHeightDimension: CGFloat)
        -> UIImage {
            let adjustedImage = adjustColors(image: image)
            let upperLeftPoint: CGPoint = CGPoint(x: 0, y: 0)
            let lowerLeftPoint: CGPoint = CGPoint(x: 0, y: adjustedImage.size.height - 1)
            let upperRightPoint: CGPoint = CGPoint(x: adjustedImage.size.width - 1, y: 0)
            let lowerRightPoint: CGPoint = CGPoint(x: adjustedImage.size.width - 1,
                                                   y: adjustedImage.size.height - 1)
            let upperLeftColor: UIColor = getPixelColor(fromImage: adjustedImage, pixel: upperLeftPoint)
            let lowerLeftColor: UIColor = getPixelColor(fromImage: adjustedImage, pixel: lowerLeftPoint)
            let upperRightColor: UIColor = getPixelColor(fromImage: adjustedImage, pixel: upperRightPoint)
            let lowerRightColor: UIColor = getPixelColor(fromImage: adjustedImage, pixel: lowerRightPoint)
            let color =
                averageColor(fromColors: [upperLeftColor, lowerLeftColor, upperRightColor, lowerRightColor])
            let insets = UIEdgeInsets(top: insetHeightDimension,
                                      left: insetWidthDimension,
                                      bottom: insetHeightDimension,
                                      right: insetWidthDimension)
            let size = CGSize(width: adjustedImage.size.width + insets.left + insets.right,
                              height: adjustedImage.size.height + insets.top + insets.bottom)
            UIGraphicsBeginImageContextWithOptions(size, false, adjustedImage.scale)
            let origin = CGPoint(x: insets.left, y: insets.top)
            adjustedImage.draw(at: origin)
            let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return convertTransparent(image: imageWithInsets!, color: color)
    }
    
    func convertTransparent(image: UIImage, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let width = image.size.width
        let height = image.size.height
        let imageRect: CGRect = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        let redValue = CGFloat(color.cgColor.components![0])
        let greenValue = CGFloat(color.cgColor.components![1])
        let blueValue = CGFloat(color.cgColor.components![2])
        let alphaValue = CGFloat(color.cgColor.components![3])
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.setFillColor(red: redValue, green: greenValue, blue: blueValue, alpha: alphaValue)
        ctx.fill(imageRect)
        image.draw(in: imageRect)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func averageColor(fromColors colors: [UIColor]) -> UIColor {
        var averages = [CGFloat]()
        for i in 0..<4 {
            var total: CGFloat = 0
            for j in 0..<colors.count {
                let current = colors[j]
                let value = CGFloat(current.cgColor.components![i])
                total += value
            }
            let avg = total / CGFloat(colors.count)
            averages.append(avg)
        }
        return UIColor(red: averages[0], green: averages[1], blue: averages[2], alpha: averages[3])
    }
    
    func adjustColors(image: UIImage) -> UIImage {
        let context = CIContext(options: nil)
        if let currentFilter = CIFilter(name: "CIColorControls") {
            let beginImage = CIImage(image: image)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            currentFilter.setValue(0, forKey: kCIInputSaturationKey)
            currentFilter.setValue(1.45, forKey: kCIInputContrastKey) //previous 1.5
            if let output = currentFilter.outputImage {
                if let cgimg = context.createCGImage(output, from: output.extent) {
                    let processedImage = UIImage(cgImage: cgimg)
                    return processedImage
                }
            }
        }
        return image
    }
    
    // MARK: - Scene stability check
    
    private func resetTranspositionHistory() {
        transpositionHistoryPoints.removeAll()
    }
    
    private func recordTransposition(_ point: CGPoint) {
        transpositionHistoryPoints.append(point)
        
        if transpositionHistoryPoints.count > maxHistoryLength {
            transpositionHistoryPoints.removeFirst()
        }
    }
    
    private func sceneStabilityAcheived() -> Bool {
        if transpositionHistoryPoints.count == maxHistoryLength {
            var movingAverage: CGPoint = CGPoint.zero
            for currentPoint in transpositionHistoryPoints {
                movingAverage.x += currentPoint.x
                movingAverage.y += currentPoint.y
            }
            
            let distance = abs(movingAverage.x) + abs(movingAverage.y)
            if distance < 20 {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - CoreML OCR Functions
    
    private func detectRoomName() {
        var wordIteration = 0
        var charIteration = 0
        
        for (wordIdx, word) in characterImages {
            wordIteration += 1
            charIteration = 0
            
            for charImage in word {
                charIteration += 1
                
                
                if wordIteration == characterImages.count && charIteration == word.count {
                    classifyCharacterImage(image: charImage, wordNumber: wordIdx, isLastClassificationRequest: true)
                } else {
                    classifyCharacterImage(image: charImage, wordNumber: wordIdx, isLastClassificationRequest: false)
                }
            }
        }
    }
    
    func classifyCharacterImage(image: UIImage, wordNumber: Int, isLastClassificationRequest: Bool) {
        visionQueue.sync {
            guard let model = try? VNCoreMLModel(for: Alphanum_28x28().model) else { return }
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
                    self?.checkForMatchingRooms()
                }
            }
            
            request.imageCropAndScaleOption = .centerCrop
            
            guard let ciImage = CIImage(image: image) else {
                fatalError("Could not convert UIImage to CIImage :(")
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([request])
            }
            catch {
                print(error)
            }
        }
    }
    
    func checkForMatchingRooms() {
        for word in identifiedWords {
            print("Identified: \(word)")
        }
        
        DispatchQueue.main.async {
            self.sceneView.layer.sublayers?.removeSubrange(0...)
            
            // Only add the image tracking once
            if self.foundRoom {
                return
            }
            
            // Stop searching for text
            self.foundRoom = true
            
            // FIXME: Add room check
            self.beginARImageTracking(forRoom: ["FRANK LLOYD","WRIGHT"])
        }
    }
    
    // MARK: - ARKit Image Tracking
    
    func beginARImageTracking(forRoom roomName: [String]) {
        let referenceImageJH = ARHelper.getReferenceImage(withName: ["JIM","HENSON"])
        let refImageJH = ARReferenceImage(referenceImageJH.cgImage!, orientation: .up, physicalWidth: 0.264)
        refImageJH.name = "Jim Henson"
        
        let referenceImageFLW = ARHelper.getReferenceImage(withName: ["FRANK LLOYD","WRIGHT"])
        let refImageFLW = ARReferenceImage(referenceImageFLW.cgImage!, orientation: .up, physicalWidth: 0.264)
        refImageFLW.name = "Frank Lloyd Wright"
        
        let referenceImageJM = ARHelper.getReferenceImage(withName: ["JOHN MUIR",""])
        let refImageJM = ARReferenceImage(referenceImageJM.cgImage!, orientation: .up, physicalWidth: 0.264)
        refImageJM.name = "John Muir"
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = [refImageJH, refImageFLW, refImageJM]
        configuration.planeDetection = .vertical
        session.run(configuration, options: [])
    }

}

extension ARSignFinderViewController: ARSessionDelegate {
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Use `flatMap(_:)` to remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        blurView.isHidden = false
        statusViewController.showMessage("""
        SESSION INTERRUPTED
        The session will be reset after the interruption has ended.
        """, autoHide: false)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        blurView.isHidden = true
        statusViewController.showMessage("RESETTING SESSION")
        
        restartExperience()
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Interface Actions
    
    func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        
        statusViewController.cancelAllScheduledMessages()
        
        resetTracking()
        
        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
    
}
