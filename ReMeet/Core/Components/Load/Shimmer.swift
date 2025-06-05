//
//  ShimmerViewModifier.swift
//  ReMeet
//
//  Created by Artush on 05/06/2025.
//


import SwiftUI

struct ShimmerViewModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let gradient = LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.2),
                            Color.gray.opacity(0.4),
                            Color.gray.opacity(0.2)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    Rectangle()
                        .fill(gradient)
                        .rotationEffect(.degrees(20))
                        .offset(x: isAnimating ? width : -width)
                        .frame(width: width * 2)
                        .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isAnimating)
                }
            )
            .mask(content)
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerViewModifier())
    }
}
