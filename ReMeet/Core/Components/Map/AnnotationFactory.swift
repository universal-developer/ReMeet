//
//  AnnotationFactory.swift
//  ReMeet
//
//  Created by Artush on 20/04/2025.
//

import UIKit

final class AnnotationFactory {
    static func makeStackedAvatarView(
        image: UIImage?,
        name: String,
        userId: String,
        target: Any?,
        action: Selector?
    ) -> UIView {
        let annotationView = UIView()
        annotationView.backgroundColor = .clear
        annotationView.clipsToBounds = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Profile image or ghost
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        imageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 50).isActive = true

        // Label (Me / Name)
        let isDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark

        let nameLabel = PaddingLabel()
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 150).isActive = true
        nameLabel.textAlignment = .center
        nameLabel.textColor = isDarkMode ? .white : .black
        nameLabel.backgroundColor = isDarkMode ? UIColor.black.withAlphaComponent(0.8) : .white
        nameLabel.layer.cornerRadius = 10
        nameLabel.clipsToBounds = true
        nameLabel.padding = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail




        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(nameLabel)
        annotationView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: annotationView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: annotationView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: annotationView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: annotationView.trailingAnchor)
        ])

        annotationView.accessibilityIdentifier = userId
        annotationView.isUserInteractionEnabled = true
        annotationView.setContentHuggingPriority(.required, for: .horizontal)
        annotationView.setContentCompressionResistancePriority(.required, for: .horizontal)

        if let target = target, let action = action {
            let tap = UITapGestureRecognizer(target: target, action: action)
            annotationView.addGestureRecognizer(tap)
        }

        return annotationView
    }


}

