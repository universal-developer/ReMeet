//
//  PhoneVerificationStepView.swift
//  ReMeet
//
//  Created by Artush on 11/03/2025.
//

import SwiftUI

struct PhoneVerificationStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var isValid: Bool = false
    @State private var codeDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedField: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            // Headline
            Text("Verify your phone number")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)
            
            // Subtitle
            Text("Enter the 6-digit code we sent to\n+\(model.phoneNumber)")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Code input fields
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: $codeDigits[index])
                        .keyboardType(.numberPad)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(width: 45, height: 55)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .focused($focusedField, equals: index)
                        .onChange(of: codeDigits[index]) { newValue in
                            // Keep only digits
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                codeDigits[index] = filtered
                            }
                            
                            // Auto advance to next field
                            if !newValue.isEmpty && index < 5 {
                                focusedField = index + 1
                            }
                            
                            // Handle paste with multiple digits
                            if newValue.count > 1 {
                                let digits = Array(newValue)
                                codeDigits[index] = String(digits[0])
                                
                                // Distribute remaining digits
                                for i in 1..<min(digits.count, 6 - index) {
                                    codeDigits[index + i] = String(digits[i])
                                }
                                
                                // Focus last field or appropriate field
                                let nextIndex = min(index + digits.count, 5)
                                focusedField = nextIndex
                            }
                            
                            // Update complete code
                            updateVerificationCode()
                        }
                }
            }
            .padding(.top, 20)
            
            // Resend code button
            Button(action: {
                // Here you would implement resending the code
                print("Resending verification code...")
            }) {
                Text("Didn't receive a code? Resend")
                    .font(.footnote)
                    .foregroundColor(Color(hex: "C9155A"))
                    .padding(.top, 20)
            }
            
            Spacer()
            
            // Full-width button at bottom
            PrimaryButton(
                title: "Verify",
                action: {12
                    if isValid {
                        print("✅ Verification code validated: '\(model.verificationCode)'")
                        model.currentStep = .verification
                    } else {
                        print("❌ Verification code validation failed: Complete all 6 digits")
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
            // Focus the first field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = 0
            }
        }
    }
    
    // Update the complete verification code in the model
    private func updateVerificationCode() {
        model.verificationCode = codeDigits.joined()
        
        // Update validation state
        isValid = codeDigits.allSatisfy { !$0.isEmpty }
        
        print("📝 Verification code updated: '\(model.verificationCode)' - Valid: \(isValid)")
    }
}

#Preview {
    PhoneVerificationStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
