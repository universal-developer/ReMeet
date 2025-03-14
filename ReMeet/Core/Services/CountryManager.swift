//
//  CountryManager.swift
//  ReMeet
//
//  Created by Artush on 11/03/2025.
//

import Foundation
// We'll still import PhoneNumberKit, but we'll use it minimally
import PhoneNumberKit

class CountryManager {
    static let shared = CountryManager()
    
    // Hardcoded list of countries with their codes
    lazy var allCountries: [Country] = {
        return [
            Country(code: "US", name: "United States", phoneCode: "1"),
            Country(code: "CA", name: "Canada", phoneCode: "1"),
            Country(code: "GB", name: "United Kingdom", phoneCode: "44"),
            Country(code: "AU", name: "Australia", phoneCode: "61"),
            Country(code: "FR", name: "France", phoneCode: "33"),
            Country(code: "DE", name: "Germany", phoneCode: "49"),
            Country(code: "JP", name: "Japan", phoneCode: "81"),
            Country(code: "CN", name: "China", phoneCode: "86"),
            Country(code: "IN", name: "India", phoneCode: "91"),
            Country(code: "RU", name: "Russia", phoneCode: "7"),
            Country(code: "BR", name: "Brazil", phoneCode: "55"),
            Country(code: "MX", name: "Mexico", phoneCode: "52"),
            Country(code: "IT", name: "Italy", phoneCode: "39"),
            Country(code: "ES", name: "Spain", phoneCode: "34"),
            Country(code: "KR", name: "South Korea", phoneCode: "82"),
            Country(code: "TR", name: "Turkey", phoneCode: "90"),
            Country(code: "NL", name: "Netherlands", phoneCode: "31"),
            Country(code: "IL", name: "Israel", phoneCode: "972"),
            Country(code: "CH", name: "Switzerland", phoneCode: "41"),
            Country(code: "SG", name: "Singapore", phoneCode: "65"),
        ].sorted()
    }()
    
    func country(for regionCode: String) -> Country? {
        return allCountries.first { $0.code == regionCode }
    }
    
    func countryFlag(_ countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            flag.unicodeScalars.append(UnicodeScalar(base + scalar.value)!)
        }
        return flag
    }
    
    // Format phone number according to country
    func formatPhoneNumber(_ number: String, countryCode: String) -> String {
        // Basic implementation: just keep digits
        let digitsOnly = number.filter { $0.isNumber }
        return digitsOnly
    }
    
    // Simple validation without using PhoneNumberKit's parse method
    func isValidPhoneNumber(_ number: String, countryCode: String) -> Bool {
        let digitsOnly = number.filter { $0.isNumber }
        
        // Basic validation rules:
        // 1. Need at least 7 digits (typical minimum for phone numbers)
        // 2. Not more than 15 digits (maximum length according to E.164 standard)
        let isValidLength = digitsOnly.count >= 7 && digitsOnly.count <= 15
        
        // You could add country-specific validation rules here
        
        return isValidLength
    }
}
