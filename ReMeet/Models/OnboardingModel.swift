//
//  OnboardingModel.swift
//  ReMeet
//
//  Updated on 05/03/2025.
//

import Foundation
import Combine

class OnboardingModel: ObservableObject {
    // User information
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var age: Int?
    @Published var phoneNumber: String = ""
    @Published var username: String = ""
    
    // Track onboarding progress
    @Published var currentStep: OnboardingStep = .firstName
    
    // Validation states
    @Published var isFirstNameValid: Bool = false
    @Published var isLastNameValid: Bool = false
    @Published var isAgeValid: Bool = false
    @Published var isPhoneValid: Bool = false
    @Published var isUsernameValid: Bool = false
    
    // Calculate overall progress (for progress bar)
    var progressPercentage: Double {
        let totalSteps = Double(OnboardingStep.allCases.count)
        let currentStepIndex = Double(currentStep.rawValue)
        return currentStepIndex / totalSteps
    }
    
    // Move to next step if validation passes
    func moveToNextStep() {
        switch currentStep {
        case .firstName:
            if isFirstNameValid {
                currentStep = .lastName
            }
        case .lastName:
            if isLastNameValid {
                currentStep = .birthday
            }
        case .birthday:
            if isAgeValid {
                currentStep = .phone
            }
        case .phone:
            if isPhoneValid {
                currentStep = .username
            }
        case .username:
            if isUsernameValid {
                // Finish onboarding
                completeOnboarding()
            }
        }
    }
    
    // Logic to complete onboarding
    private func completeOnboarding() {
        // Save user data, set user as logged in, etc.
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        print("🎉 Onboarding complete! User: \(firstName) \(lastName), Age: \(age ?? 0), Username: \(username)")
    }
    
    // Validate current step data
    func validateCurrentStep() {
        switch currentStep {
        case .firstName:
            isFirstNameValid = !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .lastName:
            isLastNameValid = !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .birthday:
            isAgeValid = age != nil && age! >= 13
        case .phone:
            // Simple validation - would use better validation in production
            isPhoneValid = phoneNumber.count >= 10
        case .username:
            isUsernameValid = username.count >= 3 && !username.contains(" ")
        }
    }
}

// Define the onboarding steps - now with separate first and last name steps
enum OnboardingStep: Int, CaseIterable {
    case firstName = 0
    case lastName
    case birthday
    case phone
    case username
}
