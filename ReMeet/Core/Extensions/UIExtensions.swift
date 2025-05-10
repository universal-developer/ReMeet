//
//  UIExtensions.swift
//  ReMeet
//
//  Created by Artush on 11/05/2025.
//

import UIKit

final class PaddingLabel: UILabel {
    var padding: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        return CGSize(width: superSize.width + padding.left + padding.right,
                      height: superSize.height + padding.top + padding.bottom)
    }
}
