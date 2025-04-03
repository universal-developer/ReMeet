//
//  PhoneStepView.swift
//  ReMeet
//  Updated on 12/03/2025.
//

import SwiftUI
import CoreTelephony

struct PhoneStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var showCountryPicker = false
    @State private var selectedCountry: Country
    @State private var isValid: Bool = false
    @State private var localPhoneNumber: String = ""
    @State private var showingDetectedRegion: Bool = true
    @State private var placeholderExample: String = ""
    
    @Environment(\.colorScheme) var colorScheme
    
    private let countryManager = CountryManager.shared
    
    // Initialize with device region detection
    init(model: OnboardingModel) {
        self.model = model
        
        // Use existing number if available, otherwise detect country
        if !model.phoneNumber.isEmpty {
            _localPhoneNumber = State(initialValue: model.phoneNumber)
            
            // Try to determine country from existing number
            let defaultCountry = CountryManager.shared.country(for: "US") ??
                Country(code: "US", name: "United States", phoneCode: "1")
            if let savedCountry = CountryManager.shared.country(for: model.selectedCountryCode) {
                _selectedCountry = State(initialValue: savedCountry)
            } else {
                _selectedCountry = State(initialValue: defaultCountry)
            }
            _showingDetectedRegion = State(initialValue: false)
        } else {
            // Detect the user's country based on device settings and SIM card
            let detectedCountryCode = PhoneStepView.detectUserCountry()
            let defaultCountry = CountryManager.shared.country(for: detectedCountryCode) ??
                Country(code: "US", name: "United States", phoneCode: "1")
            
            _selectedCountry = State(initialValue: defaultCountry)
            _localPhoneNumber = State(initialValue: "")
            _showingDetectedRegion = State(initialValue: true)
        }
        
        // Set initial placeholder based on country
        _placeholderExample = State(initialValue: getPlaceholderForCountry(code: _selectedCountry.wrappedValue.code))
    }
    
    // Get placeholder example based on country code
    private func getPlaceholderForCountry(code: String) -> String {
        switch code {
        case "US", "CA":
            return "(555) 123-4567"
        case "FR":
            return "01 23 34 56 78"  // French format in pairs
        case "GB":
            return "07700 900000"
        case "AU":
            return "0412 345 678"
        case "IN":
            return "99999 99999"
        case "DE":
            return "0170 1234567"
        case "JP":
            return "090 1234 5678"
        case "RU":
            return "912 345-67-89"
        default:
            return "123 456 7890"
        }
    }
    
    // Static method to detect user's country
    private static func detectUserCountry() -> String {
        // Method 1: Check carrier info (SIM card)
        let networkInfo = CTTelephonyNetworkInfo()
        if #available(iOS 16.0, *) {
            if let carrier = networkInfo.serviceSubscriberCellularProviders?.values.first,
               let countryCode = carrier.isoCountryCode?.uppercased() {
                print("📱 Detected country from carrier: \(countryCode)")
                return countryCode
            }
        } else {
            // Fallback for older iOS versions
            if let carrier = networkInfo.subscriberCellularProvider,
               let countryCode = carrier.isoCountryCode?.uppercased() {
                print("📱 Detected country from carrier: \(countryCode)")
                return countryCode
            }
        }
        
        // Method 2: Use device locale settings
      if let regionCode = Locale.current.region?.identifier {
            print("📱 Detected country from locale: \(regionCode)")
            return regionCode
        }
        
        // Fallback to US as default
        return "US"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Headline question
            Text("What's your phone number?")
                .font(.title3)
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
                            .foregroundColor(colorScheme == .dark ? .white : .black)
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
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .onDisappear {
                            placeholderExample = getPlaceholderForCountry(code: selectedCountry.code)
                            formatPhoneNumber()
                            showingDetectedRegion = false
                            model.selectedCountryCode = selectedCountry.code  // ✅ Save selection
                        }
                }
                
                // Phone number field with enhanced formatting and placeholder
                TextField("", text: $localPhoneNumber)
                    .font(.system(size: 18))
                    .keyboardType(.numberPad)
                    .placeholder(when: localPhoneNumber.isEmpty) {
                        Text(placeholderExample)
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 18))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .onChange(of: localPhoneNumber) { _, newValue in
                        // Apply formatting and validate as user types
                        formatPhoneNumber()
                    }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Show detected region message if applicable
           /* if showingDetectedRegion {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "C9155A").opacity(0.8))
                    
                    Text("We detected your region as \(selectedCountry.name)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 4)
                .padding(.horizontal, 20)
                .transition(.opacity)
                .animation(.easeIn, value: showingDetectedRegion)
            }*/
            
            Text("We'll send a verification code to this number")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, showingDetectedRegion ? 2 : 8)
            
            Spacer()
            
            // Full-width button at bottom
            PrimaryButton(
                title: "Next",
                action: {
                    if isValid {
                        // Save the raw digits to the model for verification
                        model.phoneNumber = localPhoneNumber.filter { $0.isNumber }
                        print("✅ Phone validation passed: '+\(selectedCountry.phoneCode) \(model.phoneNumber)'")
                        model.currentStep = .verification
                    } else {
                        print("❌ Phone validation failed: Invalid number format")
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
            // Set placeholder on appear
            placeholderExample = getPlaceholderForCountry(code: selectedCountry.code)
            
            // Check for existing phone number and format it
            if !localPhoneNumber.isEmpty {
                formatPhoneNumber()
            }
        }
    }
    
    // Enhanced formatting function with proper length limits
    private func formatPhoneNumber() {
        // First get only the digits
        var digits = localPhoneNumber.filter { $0.isNumber }
        
        // Get max length for the country and strictly enforce it
        let maxLength = getMaxLengthForCountry(code: selectedCountry.code)
        
        // Check if we need to truncate
        let needsTruncation = digits.count > maxLength
        
        // Enforce max length by truncating if necessary
        if needsTruncation {
            digits = String(digits.prefix(maxLength))
        }
        
        // Create formatted string based on country code
        var formattedNumber = ""
        
        switch selectedCountry.code {
        case "US", "CA":  // North American Numbering Plan
            if !digits.isEmpty {
                // Handle US/Canada format: (XXX) XXX-XXXX
                let areaCodeEndIndex = min(digits.count, 3)
                let areaCode = String(digits.prefix(areaCodeEndIndex))
                
                if digits.count <= 3 {
                    formattedNumber = areaCode
                } else {
                    formattedNumber = "(\(areaCode)) "
                    let prefixEndIndex = min(digits.count, 6)
                    let prefix = String(digits.prefix(prefixEndIndex).suffix(prefixEndIndex - 3))
                    formattedNumber += prefix
                    
                    if digits.count > 6 {
                        formattedNumber += "-"
                        let lineNumber = String(digits.suffix(digits.count - 6))
                        formattedNumber += lineNumber
                    }
                }
            }
            
        case "FR":  // French format: XX XX XX XX XX (in pairs)
            if !digits.isEmpty {
                // Format in pairs (French format)
                for (index, char) in digits.enumerated() {
                    if index > 0 && index % 2 == 0 {
                        formattedNumber += " "
                    }
                    formattedNumber.append(char)
                }
            }
            
        case "GB":  // UK format
            if !digits.isEmpty {
                // UK mobile typically: XXXX XXX XXX
                let firstPart = min(digits.count, 4)
                formattedNumber += String(digits.prefix(firstPart))
                
                if digits.count > 4 {
                    formattedNumber += " "
                    let secondPart = min(digits.count - 4, 3)
                    formattedNumber += String(digits.prefix(4 + secondPart).suffix(secondPart))
                    
                    if digits.count > 7 {
                        formattedNumber += " "
                        formattedNumber += String(digits.suffix(digits.count - 7))
                    }
                }
            }
            
        default:  // Generic international format
            if !digits.isEmpty {
                // Generic format: XXX XXX XXX
                for (index, char) in digits.enumerated() {
                    if index > 0 && index % 3 == 0 {
                        formattedNumber += " "
                    }
                    formattedNumber.append(char)
                }
            }
        }
        
        // Critical fix: Replace the text field value with our strictly formatted version
        if needsTruncation || formattedNumber != localPhoneNumber {
            localPhoneNumber = formattedNumber
        }
        
        // Validate the number
        validatePhoneNumber()
    }
    
    // Get maximum phone number length for a country
    private func getMaxLengthForCountry(code: String) -> Int {
        switch code {
        case "US", "CA":
            return 10  // Fixed 10 digits for US/Canada
        case "FR":
            return 10  // French mobile numbers are 10 digits
        case "GB":
            return 11  // UK has 11 digit max
        case "AU":
            return 10  // Australia has 10 digit mobile numbers
        case "IN":
            return 10  // India has 10 digit numbers
        case "JP":
            return 11  // Japan has 11 digit numbers
        default:
            return 12  // More reasonable default max
        }
    }
    
    // Validate the phone number
    private func validatePhoneNumber() {
        // Get only digits for validation
        let digits = localPhoneNumber.filter { $0.isNumber }
        
        // Basic validation rules by country
        switch selectedCountry.code {
        case "US", "CA":
            isValid = digits.count == 10  // North American numbers are 10 digits
        case "FR":
            isValid = digits.count == 10  // French mobile numbers are 10 digits
        case "GB":
            isValid = digits.count >= 10 && digits.count <= 11  // UK numbers are 10-11 digits
        case "AU":
            isValid = digits.count == 10  // Australian numbers are 10 digits
        case "IN":
            isValid = digits.count == 10  // Indian numbers are 10 digits
        default:
            isValid = digits.count >= 8 && digits.count <= getMaxLengthForCountry(code: selectedCountry.code)
        }
    }
}

// Add placeholder support for TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    PhoneStepView(model: OnboardingModel())
}
