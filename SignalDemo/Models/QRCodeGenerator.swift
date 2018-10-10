//
//  QRCodeGenerator.swift
//  Signal
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit

/// Centralized generation of QR code images
struct QRCodeGenerator {
    /// Main QR Code generation method
    ///
    /// - Parameters:
    ///   - type: The type of QR code (with its associated value) to use for the
    ///   - resizeRate: CIFilter result is 31x31 pixels in size - set this rate to positive for enlarging and negative for shrinking. Defaults to 20.
    ///
    /// - Returns: A UIImage with the given QR code
    static func qrCodeImage(for string: String, resizeRate: CGFloat = 20) -> UIImage {
        return UIImage.imageQRCode(for: "quetzalcoatl://\(string)", resizeRate: resizeRate)
    }
}

struct QRCodeDetector {
    static func detect(from image: UIImage) -> CIQRCodeFeature? {
        guard let cgImage = image.cgImage else { return nil }

        let ciImage = CIImage(cgImage: cgImage)

        var options: [AnyHashable : Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let context = CIContext()
        guard let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options as? [String : Any]) else { return nil }

        if ciImage.properties[kCGImagePropertyOrientation as String] == nil {
            options = [CIDetectorImageOrientation: 1]
        } else if let anOrientation = ciImage.properties[kCGImagePropertyOrientation as String] {
                options = [CIDetectorImageOrientation: anOrientation]
        }

        return qrDetector.features(in: ciImage, options: options as? [String : Any]).first(where: { feature -> Bool in feature is CIQRCodeFeature }) as? CIQRCodeFeature
    }
}
