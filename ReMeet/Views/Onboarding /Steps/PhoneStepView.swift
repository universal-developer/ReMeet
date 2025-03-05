//
//  PhoneStepView.swift
//  ReMeet
//  Updated on 05/03/2025.
//

import SwiftUI

struct PhoneStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var selectedCountryCode = "+1"
    
    // Country codes (shortened list for demo)
    private let countryCodes = ["+1", "+44", "+91", "+61", "+33", "+49", "+7", "+81", "+86"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Headline question
            Text("What's your phone number?")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)
            
            // Phone input
            HStack(spacing: 8) {
                // Country code selector
                Menu {
                    ForEach(countryCodes, id: \.self) { code in
                        Button(code) {
                            selectedCountryCode = code
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCountryCode)
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                
                // Phone number field
                TextField("Phone number", text: $model.phoneNumber)
                    .font(.system(size: 18))
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Text("We'll send a verification code to this number")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 8)
            
            Spacer()
            
            // Button at bottom right
            HStack {
                Spacer()
                CircleArrowButton(
                    action: {
                        let digitsOnly = model.phoneNumber.filter { $0.isNumber }
                        if digitsOnly.count >= 10 {
                            print("✅ Phone validation passed: '\(selectedCountryCode) \(model.phoneNumber)'")
                            model.currentStep = .username
                        } else {
                            print("❌ Phone validation failed: Need 10 digits")
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
    PhoneStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
