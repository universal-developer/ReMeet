//
//  BirthdayStepView.swift
//  ReMeet
//  Created on 06/03/2025.
//

import SwiftUI

struct BirthdayStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var day: String = ""
    @State private var month: String = ""
    @State private var year: String = ""
    @State private var isValid: Bool = false
    @FocusState private var focusField: Field?
    
    enum Field {
        case day, month, year
    }
        
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Headline question with more padding now that header is simplified
            Text("When's your birthday?")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.bold)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            
            // Birthday input fields
            HStack(spacing: 20) {
                // Day field
                TextField("DD", text: $day)
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focusField, equals: .day)
                    .onChange(of: day) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue {
                            day = filtered
                        }
                        
                        if day.count == 2 {
                            focusField = .month
                        }
                        
                        if day.count > 2 {
                            day = String(day.prefix(2))
                        }
                        
                        validateBirthday()
                    }
                    .frame(width: 60)
                
                
                Text("/")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.5))
                
                // Month field
                TextField("MM", text: $month)
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focusField, equals: .month)
                    .onChange(of: month) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue {
                            month = filtered
                        }
                        
                        if month.count == 2 {
                            focusField = .year
                        }
                        
                        if month.count > 2 {
                            month = String(month.prefix(2))
                        }
                        
                        validateBirthday()
                    }
                    .frame(width: 60)
                
                Text("/")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.5))
                
                // Year field
                TextField("YYYY", text: $year)
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focusField, equals: .year)
                    .onChange(of: year) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue {
                            year = filtered
                        }
                        
                        if year.count > 4 {
                            year = String(year.prefix(4))
                        }
                        
                        validateBirthday()
                    }
                    .frame(width: 100)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Text("Only to make sure you're old enough to use ReMeet.")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)
                .padding(.top, 10)
            
            Spacer()
            
            // Bottom section with CircleArrowButton
            HStack {
                PrimaryButton(
                    title: "Next",
                    action: {
                        if isValid {
                            print("✅ Age validation passed: \(model.age ?? 0) years old")
                            model.currentStep = .phone
                        } else {
                            print("❌ Age validation failed: Complete birthdate required")
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
        .background(Color.black)
        .onAppear {
            // Focus the month field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusField = .day
            }
        }
    }
    
    // Calculate age and update model
    private func validateBirthday() {
        guard let dayInt = Int(day), let monthInt = Int(month), let yearInt = Int(year),
              day.count == 2, month.count == 2, year.count == 4,
              monthInt >= 1, monthInt <= 12,
              dayInt >= 1, dayInt <= daysInMonth(month: monthInt, year: yearInt) else {
            model.age = nil
            isValid = false
            return
        }
        
        let calendar = Calendar.current
        let birthComponents = DateComponents(year: yearInt, month: monthInt, day: dayInt)
        
        guard let birthDate = calendar.date(from: birthComponents) else {
            model.age = nil
            isValid = false
            return
        }
        
        // Make sure date is not in the future
        guard birthDate <= Date() else {
            model.age = nil
            isValid = false
            return
        }
        
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        model.age = ageComponents.year
        
        // Validate age (13+ years old)
        isValid = (model.age ?? 0) >= 13
        
        print("📅 Birthdate set: \(dayInt)/\(monthInt)/\(yearInt) - Age: \(model.age ?? 0)")
    }
    
    // Helper function to determine days in a month
    private func daysInMonth(month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        
        if let date = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }
        
        // Fallback values by month
        switch month {
        case 2:
            // Check for leap year
            if year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) {
                return 29
            } else {
                return 28
            }
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }
}

#Preview {
    BirthdayStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
