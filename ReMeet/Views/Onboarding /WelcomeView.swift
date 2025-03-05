//
//  WelcomeView.swift
//  ReMeet
//
//  Created by Artush on 16/02/2025.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false // Checks if the user is logged in

    var body: some View {
        VStack {
            Spacer()

            // App Logo
            Text("ReMeet")
                .font(.system(size: 54, weight: .bold))
                .bold()
                .foregroundColor(Color(hex: "C9155A")) // Adjust to your brand color

            Text("Scan. Connect. ReMeet.")
                .font(.title)
                .bold()
                .foregroundColor(.white)
            
            Spacer()

            // Continue Button (For Sign Up / Login)
            NavigationLink(destination: OnboardingContainerView()) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "C9155A"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)
            

            // Scan QR Button (Guest Mode)
            NavigationLink(destination: QRScannerView()) {
                Text("Want to connect with someone? Just scan")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .underline()
                    .padding(.bottom, 30)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all)) // Background color
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationView {
        WelcomeView()
    }
}
