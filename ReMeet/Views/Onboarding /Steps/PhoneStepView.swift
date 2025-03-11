//
//  PhoneStepView.swift
//  ReMeet
//  Updated on 05/03/2025.
//

import SwiftUI
import PhoneNumberKit

struct PhoneStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var showCountryPicker = false
    @State private var selectedCountry: Country
    
    private let countryManager = CountryManager.shared
    
    // Initialize with US as default
    init(model: OnboardingModel) {
        self.model = model
        
        // Set default country (US)
        let defaultCountry = CountryManager.shared.country(for: "US") ??
            Country(code: "US", name: "United States", phoneCode: "1")
        _selectedCountry = State(initialValue: defaultCountry)
    }
    
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
                Button(action: {
                    showCountryPicker = true
                }) {
                    HStack {
                        Text(countryManager.countryFlag(selectedCountry.code))
                            .font(.system(size: 18))
                        
                        Text("+" + selectedCountry.phoneCode)
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
                .sheet(isPresented: $showCountryPicker) {
                    CountryPickerView(selectedCountry: $selectedCountry)
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
                    .onChange(of: model.phoneNumber) { newValue in
                        model.phoneNumber = countryManager.formatPhoneNumber(
                            newValue,
                            countryCode: selectedCountry.code
                        )
                    }
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
                        if validatePhoneNumber() {
                            model.currentStep = .username
                        }
                    },
                    backgroundColor: Color(hex: "C9155A")
                )
                .padding(.trailing, 24)
            }
            .padding(.bottom, 32)
        }
    }
    
    // Validate the phone number
    private func validatePhoneNumber() -> Bool {
        let isValid = countryManager.isValidPhoneNumber(
            model.phoneNumber,
            countryCode: selectedCountry.code
        )
        
        if isValid {
            print("✅ Phone validation passed: '+\(selectedCountry.phoneCode) \(model.phoneNumber)'")
            return true
        } else {
            print("❌ Phone validation failed: Invalid number format")
            return false
        }
    }
}

#Preview {
    PhoneStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
