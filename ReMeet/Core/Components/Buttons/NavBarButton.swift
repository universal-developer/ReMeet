//
//  NavBarButton.swift
//  ReMeet
//
//  Created by Artush on 23/06/2025.
//


import SwiftUI

struct NavBarButton: View {
    var title: String
    var action: () -> Void
    var isEnabled: Bool = true
    var backgroundColor: Color = Color(hex: "C9155A")
    var disabledColor: Color = Color(.systemGray5)
    var foregroundColor: Color = .white
    var font: Font = .system(size: 16, weight: .semibold)

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundColor(isEnabled ? foregroundColor : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isEnabled ? backgroundColor : disabledColor)
                .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}
