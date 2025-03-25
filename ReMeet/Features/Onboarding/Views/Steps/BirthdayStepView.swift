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
    @FocusState private var focusField: Field?
    @Environment(\.colorScheme) var colorScheme

    enum Field {
        case day, month, year
    }

    var isValid: Bool {
        model.currentStep.validate(model: model)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("When's your birthday?")
                .font(.title2)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black)
                .fontWeight(.bold)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            HStack(spacing: 20) {
                TextField("DD", text: $day)
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focusField, equals: .day)
                    .onChange(of: day) { _ in handleChange(for: .day) }
                    .frame(width: 60)

                Text("/")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black)

                TextField("MM", text: $month)
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focusField, equals: .month)
                    .onChange(of: month) { _ in handleChange(for: .month) }
                    .frame(width: 60)

                Text("/")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black)

                TextField("YYYY", text: $year)
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focusField, equals: .year)
                    .onChange(of: year) { _ in handleChange(for: .year) }
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

            PrimaryButton(
                title: "Next",
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
                focusField = .day
            }
        }
    }

    private func handleChange(for field: Field) {
        switch field {
        case .day:
            day = day.filter { $0.isNumber }.prefix(2).description
            if day.count == 2 { focusField = .month }
        case .month:
            month = month.filter { $0.isNumber }.prefix(2).description
            if month.count == 2 { focusField = .year }
        case .year:
            year = year.filter { $0.isNumber }.prefix(4).description
        }
        validateBirthday()
    }

    private func validateBirthday() {
        guard let dayInt = Int(day), let monthInt = Int(month), let yearInt = Int(year),
              day.count == 2, month.count == 2, year.count == 4,
              monthInt >= 1, monthInt <= 12,
              dayInt >= 1, dayInt <= daysInMonth(month: monthInt, year: yearInt) else {
            model.age = nil
            return
        }

        let calendar = Calendar.current
        let birthComponents = DateComponents(year: yearInt, month: monthInt, day: dayInt)

        guard let birthDate = calendar.date(from: birthComponents), birthDate <= Date() else {
            model.age = nil
            return
        }

        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        model.age = ageComponents.year

        print("📅 Birthdate set: \(dayInt)/\(monthInt)/\(yearInt) - Age: \(model.age ?? 0)")
    }

    private func daysInMonth(month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        var components = DateComponents(year: year, month: month)
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30 // fallback
        }
        return range.count
    }
}

#Preview {
    BirthdayStepView(model: OnboardingModel())
}
