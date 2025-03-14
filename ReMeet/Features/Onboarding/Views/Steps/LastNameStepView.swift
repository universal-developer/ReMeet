//
//  LastNameStepView.swift
//  ReMeet
//  Updated on 05/03/2025.
//

import SwiftUI

struct LastNameStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var isValid: Bool = false
    
    // Local state to avoid direct binding issues
    @State private var localLastName: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Headline question
            Text("Hey \(model.firstName)! What's your last name?")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)
            
            // Input field - using local state first
            TextField("Last name", text: $localLastName)
                .font(.system(size: 32))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .onChange(of: localLastName) { _, newValue in
                    // Update validation state
                    isValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    // Safely update model
                    model.lastName = newValue
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
        .onAppear {
            // Initialize local state from model
            localLastName = model.lastName
            // Initialize validation state
            isValid = !model.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

#Preview {
    LastNameStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
