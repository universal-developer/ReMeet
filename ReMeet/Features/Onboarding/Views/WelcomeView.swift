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
    
    @State private var path: [OnboardingRoute] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()
                
                Text("ReMeet")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundColor(Color(hex: "C9155A"))
                
                Text("Scan. Connect. ReMeet.")
                    .font(.title)
                    .bold()
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                SignInWithAppleButton(
                    onRequest: configureAppleSignIn,
                    onCompletion: handleAppleSignIn
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                
                // Continue button triggers route-based navigation
                Button {
                    path.append(.onboarding)
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color(hex: "C9155A"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 4)
                
                Button {
                    path.append(.qrScan)
                } label: {
                    Text("Want to connect with someone? Just scan")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .underline()
                        .padding(.bottom, 30)
                }
            }
            .navigationDestination(for: OnboardingRoute.self) { route in
                switch route {
                case .onboarding:
                    OnboardingContainerView()
                case .qrScan:
                    QRScannerView()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName]
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let fullName = appleIDCredential.fullName {
                print("User's first name: \(fullName.givenName ?? "Not provided")")
            }
            print("✅ Successfully authenticated with Apple")
        case .failure(let error):
            print("❌ Authentication failed: \(error.localizedDescription)")
        }
    }
}

// Routing enum
enum OnboardingRoute: Hashable {
    case onboarding
    case qrScan
}

#Preview {
    WelcomeView()
}
