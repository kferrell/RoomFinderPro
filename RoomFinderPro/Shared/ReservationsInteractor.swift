//
//  ReservationsInteractor.swift
//  RoomFinderPro
//
//  Created by Kevin Ferrell on 3/2/18.
//  Copyright © 2018 Capital One. All rights reserved.
//

import Foundation
import UIKit

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
    
    func preprocessCharacterImage(image: UIImage) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        let addToHeight2 = height / 2
        let addToWidth2 = ((6 * height) / 3 - width) / 2
        let imageWithInsets = insertInsets(image: image,
                                           insetWidthDimension: addToWidth2,
                                           insetHeightDimension: addToHeight2)
        let size = CGSize(width: 28, height: 28)
        let resizedImage = resize(image: imageWithInsets, targetSize: size)
        let grayScaleImage = convertToGrayscale(image: resizedImage)
        return grayScaleImage
    }
    
    func resize(image: UIImage, targetSize: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
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
    
    func fixOrientation(image: UIImage) -> UIImage {
        if image.imageOrientation == UIImage.Orientation.up {
            return image
        }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        if let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return normalizedImage
        } else {
            return image
        }
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
        ctx.setFillColor(red: redValue, green: greenValue, blue: blueValue, alpha: alphaValue)
        ctx.fill(imageRect)
        image.draw(in: imageRect)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
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
}
