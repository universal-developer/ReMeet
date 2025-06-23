//
//  CircularIconButton.swift
//  ReMeet
//
//  Created by Artush on 23/06/2025.
//

import SwiftUI

struct CircularIconButton: View {
    let systemName: String
    let action: () -> Void
    var size: CGFloat = 32
    var iconSize: CGFloat = 16
    var background: Color = Color(.systemBackground)
    var iconColor: Color = Color(.label)
    var accessibilityLabel: String? = nil

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: size, height: size) // 👈 Add this
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel(accessibilityLabel ?? systemName)
    }
}
