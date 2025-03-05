//
//  FirstNameStepView.swift
//  ReMeet
//  Updated on 05/03/2025.
//

import SwiftUI

struct FirstNameStepView: View {
    @ObservedObject var model: OnboardingModel
        
    var body: some View {
        VStack(spacing: 20) {
            // Headline question
            Text("Let's get started, what's your name?")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20) // Add some space at the top
            
            // Input field
            TextField("First name", text: $model.firstName)
                .font(.system(size: 32))
                .fontWeight(.bold)
                .foregroundColor(.white) // Changed from gray to white for better visibility
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .onChange(of: model.firstName) { newValue in
                    print("📝 First name updated: '\(newValue)'")
                }
            
            Spacer()
            
            // Button at bottom right
            HStack {
                Spacer()
                CircleArrowButton(
                    action: {
                        if !model.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            print("✅ First name validation passed: '\(model.firstName)'")
                            model.currentStep = .lastName
                        } else {
                            print("❌ First name validation failed: First name is required")
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
    FirstNameStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
