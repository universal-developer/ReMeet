//
//  QRCodeGenerator.swift
//  ReMeet
//
//  Created by Artush on 27/04/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

enum QRCodeGenerator {
    
    static private let context = CIContext()
    static private let filter = CIFilter.qrCodeGenerator()
    
    static func generateQRCode(from string: String) -> UIImage? {
        print("⚙️ Generating QR code for: \(string)")
        
        guard let data = string.data(using: .utf8) else {
            print("❌ Failed to encode string to data")
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        
        guard let ciImage = filter.outputImage else {
            print("❌ Failed to generate CIImage")
            return nil
        }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10) // 🔍 make it bigger
        let scaledImage = ciImage.transformed(by: transform)
        
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            print("✅ QR code generated successfully")
            return UIImage(cgImage: cgImage)
        } else {
            print("❌ Failed to create CGImage from CIImage")
            return nil
        }
    }
}
