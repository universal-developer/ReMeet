//
//  LastNameStepView.swift
//  ReMeet
//  Updated on 05/03/2025.
//

import SwiftUI

struct LastNameStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var isValid: Bool = false
        
    var body: some View {
        VStack(spacing: 20) {
            // Headline question
            Text("What's your last name?")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)
            
            // Input field
            TextField("Last name", text: $model.lastName)
                .font(.system(size: 32))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .onChange(of: model.lastName) { newValue in
                    // Update validation state
                    isValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    print("📝 Last name updated: '\(newValue)' - Valid: \(isValid)")
                }
            
            Spacer()
            
            // Full-width button at bottom
            PrimaryButton(
                title: "Next",
                action: {
                    if isValid {
                        print("✅ Last name validation passed: '\(model.lastName)'")
                        model.currentStep = .birthday
                    } else {
                        print("❌ Last name validation failed: Last name is required")
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
    LastNameStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
