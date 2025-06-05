//
//  SplashScreenView.swift
//  ReMeet
//
//  Created by Artush on 28/04/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    let onLoadComplete: () async -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()

            VStack {
                Text("ReMeet")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color(hex: "C9155A"))
                    .padding(.top, 20)
            }
        }
        .task {
            await onLoadComplete()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    isActive = false
                }
            }
        }
    }
}
