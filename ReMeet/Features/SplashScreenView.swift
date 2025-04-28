//
//  SplashScreenView.swift
//  ReMeet
//
//  Created by Artush on 28/04/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack {
                Text("ReMeet")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color(hex: "C9155A"))
                    .padding(.top, 20)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    isActive = false
                }
            }
        }
    }
}
