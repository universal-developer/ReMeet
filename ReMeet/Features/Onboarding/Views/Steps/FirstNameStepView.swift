//
//  FirstNameStepView.swift
//  ReMeet
//  Updated on 05/03/2025.
//

//
//  FirstNameStepView.swift
//  ReMeet
//  Updated on 11/03/2025.
//

import SwiftUI

struct FirstNameStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var isValid: Bool = false
    @Environment(\.colorScheme) var colorScheme
        
    var body: some View {
        VStack(spacing: 20) {
            // Headline question
            Text("Let's get started, what's your name?")
                .font(.title3)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)
            
            // Input field
            TextField("First name", text: $model.firstName)
                .font(.system(size: 32))
                .fontWeight(.bold)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .onChange(of: model.firstName) { _, newValue in
                    // Update validation state
                    isValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    print("📝 First name updated: '\(newValue)' - Valid: \(isValid)")
                }
            
            Spacer()
            
            // Full-width button at bottom
            PrimaryButton(
                title: "Next",
                action: {
                    if isValid {
                        print("✅ First name validation passed: '\(model.firstName)'")
                        model.currentStep = .birthday
                    } else {
                        print("❌ First name validation failed: First name is required")
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
            // Check if initial value is valid
            isValid = !model.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

#Preview {
    FirstNameStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
