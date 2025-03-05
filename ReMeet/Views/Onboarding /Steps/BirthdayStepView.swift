//
//  BirthdayStepView.swift
//  ReMeet
//  Updated on 05/03/2025.
//

import SwiftUI

struct BirthdayStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var selectedDay: Int?
    @State private var selectedMonth: Int?
    @State private var selectedYear: Int?
    
    // Years to show (13+ years old)
    private let currentYear = Calendar.current.component(.year, from: Date())
    private var years: [Int] {
        Array((currentYear-100...currentYear-13).reversed())
    }
    
    // Months of the year
    private let months = ["January", "February", "March", "April", "May", "June",
                         "July", "August", "September", "October", "November", "December"]
    
    // Days of the month
    private var days: [Int] {
        Array(1...31)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Headline question
            Text("When's your birthday?")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)
            
            // Date picker with separate columns
            HStack(spacing: 20) {
                // Day picker
                Picker("Day", selection: $selectedDay) {
                    Text("Day").foregroundColor(.gray).tag(nil as Int?)
                    ForEach(days, id: \.self) { day in
                        Text("\(day)").tag(day as Int?)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 70)
                .clipped()
                .compositingGroup()
                .onChange(of: selectedDay) { _ in calculateAge() }
                
                // Month picker
                Picker("Month", selection: $selectedMonth) {
                    Text("Month").foregroundColor(.gray).tag(nil as Int?)
                    ForEach(0..<months.count, id: \.self) { index in
                        Text(months[index]).tag(index as Int?)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100)
                .clipped()
                .compositingGroup()
                .onChange(of: selectedMonth) { _ in calculateAge() }
                
                // Year picker
                Picker("Year", selection: $selectedYear) {
                    Text("Year").foregroundColor(.gray).tag(nil as Int?)
                    ForEach(years, id: \.self) { year in
                        Text("\(year)").tag(year as Int?)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 80)
                .clipped()
                .compositingGroup()
                .onChange(of: selectedYear) { _ in calculateAge() }
            }
            .frame(height: 150)
            .padding(.top, 10)
            
            Text("Only to make sure you're old enough to use ReMeet.")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Button at bottom right
            HStack {
                Spacer()
                CircleArrowButton(
                    action: {
                        if selectedDay != nil && selectedMonth != nil && selectedYear != nil {
                            if let age = model.age, age >= 13 {
                                print("✅ Age validation passed: \(age) years old")
                                model.currentStep = .phone
                            } else {
                                print("❌ Age validation failed: Must be at least 13 years old")
                            }
                        } else {
                            print("❌ Age validation failed: Complete birthdate required")
                        }
                    },
                    backgroundColor: Color(hex: "C9155A")
                )
                .padding(.trailing, 24)
            }
            .padding(.bottom, 32)
        }
    }
    
    // Calculate age and update model
    private func calculateAge() {
        guard let day = selectedDay, let month = selectedMonth, let year = selectedYear else {
            model.age = nil
            return
        }
        
        let calendar = Calendar.current
        let birthComponents = DateComponents(year: year, month: month + 1, day: day)
        
        guard let birthDate = calendar.date(from: birthComponents) else {
            model.age = nil
            return
        }
        
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        model.age = ageComponents.year
        
        print("📅 Birthdate set: \(day)/\(month+1)/\(year) - Age: \(model.age ?? 0)")
    }
}

#Preview {
    BirthdayStepView(model: OnboardingModel())
        .preferredColorScheme(.dark)
}
