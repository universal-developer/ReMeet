//
//  UsernameStepView.swift
//  ReMeet
//  Updated on 05/03/2025.
//

import SwiftUI

import SwiftUI

struct UsernameStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var isValid: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Headline question
            Text("Choose a username")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)
            
            // Username input
            TextField("Username", text: $model.username)
                .font(.system(size: 32))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: model.username) { newValue in
                    // Username must be at least 3 characters with no spaces
                    isValid = newValue.count >= 3 && !newValue.contains(" ")
                    print("📝 Username updated: '\(newValue)' - Valid: \(isValid)")
                }
            
            Text("This is how others will find you on ReMeet")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Full-width button at bottom
            PrimaryButton(
                title: "Complete",
                action: {
                    if isValid {
                        print("✅ Username validation passed: '\(model.username)'")
                        // Complete onboarding
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        print("🎉 Onboarding complete!")
                    } else {
                        print("❌ Username validation failed: Must be at least 3 characters with no spaces")
                    }
                },
                backgroundColor: isValid ? Color(hex: "C9155A") : Color.gray.opacity(0.5)
            )
            .frame(maxWidth: .infinity)
            .disabled(!isValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    UsernameStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
