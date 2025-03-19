//
//  WelcomeView.swift
//  ReMeet
//
//  Created by Artush on 16/02/2025.
//

import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                // App Logo
                Text("ReMeet")
                    .font(.system(size: 54, weight: .bold))
                    .bold()
                    .foregroundColor(Color(hex: "C9155A"))

                Text("Scan. Connect. ReMeet.")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                Spacer()
                
                // Apple Sign In Button (adjusted)
                SignInWithAppleButton(
                    onRequest: configureAppleSignIn,
                    onCompletion: handleAppleSignIn
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
                .padding(.horizontal, 16)

                // Custom Continue Button (adjusted to match)
                NavigationLink(destination: OnboardingContainerView()) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold)) // Match Apple's font size
                        .frame(maxWidth: .infinity)
                        .frame(height: 55) // Same height as Apple button
                        .background(Color(hex: "C9155A"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 4) // Space between buttons
                
                // Scan QR Button (Guest Mode)
                NavigationLink(destination: QRScannerView()) {
                    Text("Want to connect with someone? Just scan")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .underline()
                        .padding(.bottom, 30)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
        }
    }
    
    func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName]
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            // Cast to the specific credential type
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Now you can access the user identifier, full name, etc.
                if let fullName = appleIDCredential.fullName {
                    print("User's first name: \(fullName.givenName ?? "Not provided")")
                }
                
                // For now, just print success
                print("Successfully authenticated with Apple")
            }
        case .failure(let error):
            print("Authentication failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    WelcomeView()
}
