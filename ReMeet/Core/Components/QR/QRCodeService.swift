//
//  QRCodeService.swift
//  ReMeet
//
//  Created by Artush on 28/04/2025.
//

import SwiftUI
import QRCode

struct QRCodeService {
    static func generate(
        from string: String,
        foregroundColor: UIColor = .black,
        backgroundColor: UIColor = .white,
        logo: UIImage? = nil,
        size: CGFloat = 300
    ) -> UIImage? {
        do {
            var doc = try QRCode.Document(utf8String: string, errorCorrection: .high)
            
            // Style
            doc.design.backgroundColor(backgroundColor.cgColor)
            doc.design.foregroundColor(foregroundColor.cgColor)
            doc.design.shape.onPixels = QRCode.PixelShape.RoundedPath()
            
            // Add logo if available
            if let logoImage = logo?.cgImage {
                doc.logoTemplate = QRCode.LogoTemplate(
                    image: logoImage,
                    path: CGPath(
                        rect: CGRect(x: 0.35, y: 0.35, width: 0.3, height: 0.3),
                        transform: nil
                    )
                )
            }
            
            // Output a UIImage
            return try doc.uiImage(CGSize(width: size, height: size))
        } catch {
            print("❌ Failed to generate QR code: \(error)")
            return nil
        }
    }
}
