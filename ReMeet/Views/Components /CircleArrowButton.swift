//
//  CircleArrowButton.swift
//  ReMeet
//
//  Created by Artush on 03/03/2025.
//

import SwiftUI

struct CircleArrowButton: View {
    var action: () -> Void
    
    // Optional parameters with default values for customization
    var backgroundColor: Color = .black
    var iconColor: Color = .white
    var diameter: CGFloat = 56
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Circle background
                Circle()
                    .fill(backgroundColor)
                    .frame(width: diameter, height: diameter)
                
                // Arrow icon
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        CircleArrowButton(action: {})
            .padding()
        
        // Preview with custom colors
        CircleArrowButton(
            action: {},
            backgroundColor: Color(hex: "C9155A"),
            iconColor: .white,
            diameter: 64
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
