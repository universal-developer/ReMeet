//
//  OnboardingModel.swift
//  ReMeet
//
//  Updated on 05/03/2025.
//

//
//  OnboardingModel.swift
//  ReMeet
//
//  Updated on 11/03/2025.
//

import Foundation
import Combine
import SwiftUI

class OnboardingModel: ObservableObject {
    // User information
    @Published var firstName: String = ""
    @Published var age: Int?
    @Published var phoneNumber: String = ""
    @Published var verificationCode: String = ""
    
    // UI state
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var nameFromAppleID: Bool = false
    @Published var isPhoneVerificationSent: Bool = false
    
    // Photo collection
    @Published var userPhotos: [UIImage] = []
    @Published var selectedImage: UIImage?
    
    // Track onboarding progress
    @Published var currentStep: OnboardingStep = .phone
    
    // Validation states
    @Published var isFirstNameValid: Bool = false
    @Published var isAgeValid: Bool = false
    @Published var isPhoneValid: Bool = false
    @Published var isVerificationValid: Bool = false
    
    // Calculate overall progress (for progress bar)
    var progressPercentage: Double {
        let totalSteps = Double(OnboardingStep.allCases.count)
        let currentStepIndex = Double(currentStep.rawValue)
        return currentStepIndex / totalSteps
    }
    
    // Move to next step if validation passes
    func moveToNextStep() {
        switch currentStep {
        case .phone:
            if isPhoneValid {
                // Send verification code
                sendVerificationCode()
            }
        case .verification:
            if isVerificationValid {
                verifyCode { success in
                    if success {
                        DispatchQueue.main.async {
                            self.currentStep = .firstName
                        }
                    }
                }
            }
        case .firstName:
            if isFirstNameValid {
                currentStep = .birthday
            }
        case .birthday:
            if isAgeValid {
                currentStep = .photos
            }
        case .photos:
            // Save user profile with all collected data
            saveUserProfile { success in
                if success {
                    DispatchQueue.main.async {
                        self.currentStep = .permissions
                    }
                }
            }
        case .permissions:
            // Final step handled in view
            completeOnboarding()
        }
    }
    
    // Validate current step data
    func validateCurrentStep() {
        switch currentStep {
        case .phone:
            // Simple validation - would use better validation in production
            isPhoneValid = phoneNumber.count >= 10
        case .verification:
            // Validate that all 6 digits of the verification code are entered
            isVerificationValid = verificationCode.count == 6 && verificationCode.allSatisfy { $0.isNumber }
        case .firstName:
            isFirstNameValid = !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .birthday:
            isAgeValid = age != nil && age! >= 13
        case .photos, .permissions:
            // No validation needed for these steps
            break
        }
    }
    
    // Logic to complete onboarding
    private func completeOnboarding() {
        // Save user data, set user as logged in, etc.
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        print("🎉 Onboarding complete! User: \(firstName), Age: \(age ?? 0)")
    }
    
    // Add placeholder functions for database operations
    func sendVerificationCode() {
        // We'll implement this for real phone verification
        isPhoneVerificationSent = true
        currentStep = .verification
    }
    
    func verifyCode(completion: @escaping (Bool) -> Void) {
        // We'll implement this for real verification
        completion(true)
    }
    
    func saveUserProfile(completion: @escaping (Bool) -> Void) {
        // We'll implement database save later
        completion(true)
    }
}

// Updated enum without username
enum OnboardingStep: Int, CaseIterable {
    case phone = 0
    case verification
    case firstName
    case birthday
    case photos
    case permissions
}
