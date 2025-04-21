//
//  AnnotationFactory.swift
//  ReMeet
//
//  Created by Artush on 20/04/2025.
//

import UIKit

final class AnnotationFactory {
    static func makeAnnotationView(
        initials: String?,
        image: UIImage?,
        userId: String,
        target: Any?,
        action: Selector?
    ) -> UIView {
        let view: UIView

        if let image = image {
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 25
            imageView.layer.borderWidth = 2
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.clipsToBounds = true
            view = imageView
        } else {
            let label = UILabel()
            label.text = initials ?? "?"
            label.textColor = .white
            label.textAlignment = .center
            label.font = .boldSystemFont(ofSize: 22)
            label.backgroundColor = .systemPink
            label.layer.cornerRadius = 25
            label.layer.borderWidth = 2
            label.layer.borderColor = UIColor.white.cgColor
            label.clipsToBounds = true
            label.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            view = label
        }

        view.accessibilityIdentifier = userId
        view.isUserInteractionEnabled = true

        if let target = target, let action = action {
            let tap = UITapGestureRecognizer(target: target, action: action)
            view.addGestureRecognizer(tap)
        }

        return view
    }
}
