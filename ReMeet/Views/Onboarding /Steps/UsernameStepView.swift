//
//  UsernameStepView.swift
//  ReMeet
//  Updated on 05/03/2025.
//

import SwiftUI

struct UsernameStepView: View {
    @ObservedObject var model: OnboardingModel
    
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
            
            Text("This is how others will find you on ReMeet")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Button at bottom right
            HStack {
                Spacer()
                CircleArrowButton(
                    action: {
                        if model.username.count >= 3 && !model.username.contains(" ") {
                            print("✅ Username validation passed: '\(model.username)'")
                            // Complete onboarding
                            UserDefaults.standard.set(true, forKey: "isLoggedIn")
                            print("🎉 Onboarding complete!")
                        } else {
                            print("❌ Username validation failed: Must be at least 3 characters with no spaces")
                        }
                    },
                    backgroundColor: Color(hex: "C9155A")
                )
                .padding(.trailing, 24)
            }
            .padding(.bottom, 32)
        }
    }
}
#Preview {
    UsernameStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
