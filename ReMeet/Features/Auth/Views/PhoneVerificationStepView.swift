//
//  PhoneVerificationStepView.swift
//  ReMeet
//
//  Created by Artush on 11/03/2025.
//

import SwiftUI

struct PhoneVerificationStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var codeDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedField: Int?
    @Environment(\.colorScheme) var colorScheme

    var isValid: Bool {
        model.currentStep.validate(model: model)
    }


    var body: some View {
        let country = CountryManager.shared.country(for: model.selectedCountryCode) ?? Country(code: "US", name: "United States", phoneCode: "1")
        
        VStack(spacing: 20) {
            Text("Verify your phone number")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)

            Text("Enter the 6-digit code we sent to\n+\(country.phoneCode)\(model.phoneNumber)")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
                        .onChange(of: codeDigits[index]) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                codeDigits[index] = filtered
                            }

                            if !filtered.isEmpty && index < 5 {
                                focusedField = index + 1
                            }

                            if filtered.count > 1 {
                                let digits = Array(filtered)
                                codeDigits[index] = String(digits[0])
                                for i in 1..<min(digits.count, 6 - index) {
                                    codeDigits[index + i] = String(digits[i])
                                }
                                focusedField = min(index + digits.count, 5)
                            }

                            updateVerificationCode()
                        }
                }
            }
            .padding(.top, 20)

            Button(action: {
                print("🔁 Resending verification code...")
                model.sendVerificationCode()
            }) {
                Text("Didn't receive a code? Resend")
                    .font(.footnote)
                    .foregroundColor(Color(hex: "C9155A"))
                    .padding(.top, 20)
            }

            Spacer()

            PrimaryButton(
                title: "Verify",
                action: {
                    if isValid {
                        model.moveToNextStep()
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = 0
            }
        }
    }

    private func updateVerificationCode() {
        model.verificationCode = codeDigits.joined()
        print("📝 Code updated: \(model.verificationCode)")
    }
}

#Preview {
    PhoneVerificationStepView(model: OnboardingModel())
}
