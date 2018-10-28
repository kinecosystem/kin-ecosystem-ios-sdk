//
//  QR.swift
//  KinEcosystem
//
//  Created by Corey Werner on 28/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

class QR {
    /**
     Create a QR image from a string.
     
     - Parameter string: The string used in the QR image.
     - Parameter size: The size of the `UIImageView` that will display the image.
     - Returns: A QR image.
     */
    class func generateImage(from string: String, for size: CGSize? = nil) -> UIImage? {
        let data = string.data(using: .isoLatin1)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        let transform: CGAffineTransform
        
        if let size = size {
            let scaleX = size.width / outputImage.extent.width
            let scaleY = size.height / outputImage.extent.height
            transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        }
        else {
            transform = CGAffineTransform(scaleX: 10, y: 10)
        }
        
        return UIImage(ciImage: outputImage.transformed(by: transform))
    }
    
    class func decode(image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options) else {
            return nil
        }
        
        let features = detector.features(in: ciImage)
        var decodedString = ""
        
        for feature in features {
            if let feature = feature as? CIQRCodeFeature {
                decodedString += feature.messageString ?? ""
            }
        }
        
        if decodedString.isEmpty {
            return nil
        }
        else {
            return decodedString
        }
    }
}
