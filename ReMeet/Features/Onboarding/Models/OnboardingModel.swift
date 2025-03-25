//
//  OnboardingModel.swift
//  ReMeet
//
//  Updated on 05/03/2025.
//
import SwiftUI
import Combine

class OnboardingModel: ObservableObject {
    // MARK: - User Data
    @Published var phoneNumber: String = ""
    @Published var verificationCode: String = ""
    @Published var firstName: String = ""
    @Published var age: Int?

    @Published var userPhotos: [UIImage] = []
    @Published var selectedImage: UIImage?

    // MARK: - State
    @Published var isPhoneVerificationSent: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentStep: OnboardingStep = .phone

    // MARK: - Navigation
    var progressPercentage: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var canGoBack: Bool {
        true
    }

    func moveToNextStep() {
        if currentStep.validate(model: self) {
            currentStep.handleNext(for: self) {}
        }
    }

    func advanceStep() {
        if let index = OnboardingStep.allCases.firstIndex(of: currentStep),
           index + 1 < OnboardingStep.allCases.count {
            currentStep = OnboardingStep.allCases[index + 1]
        }
    }

    func moveToPreviousStep(onFirstStep: () -> Void) {
        if let index = OnboardingStep.allCases.firstIndex(of: currentStep),
           index > 0 {
            currentStep = OnboardingStep.allCases[index - 1]
        } else {
            onFirstStep()
        }
    }

    func sendVerificationCode() {
        // Real implementation here later
        isPhoneVerificationSent = true
        print("📲 Verification code sent!")
    }

    func verifyCode(completion: @escaping (Bool) -> Void) {
        // Real verification here later
        completion(true)
    }

    func saveUserProfile(completion: @escaping (Bool) -> Void) {
        // Save to DB / API
        completion(true)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        print("🎉 Onboarding complete for: \(firstName), age \(age ?? 0)")
    }

    func reset() {
        phoneNumber = ""
        verificationCode = ""
        firstName = ""
        age = nil
        userPhotos = []
        selectedImage = nil
        isPhoneVerificationSent = false
        currentStep = .phone
    }
}
