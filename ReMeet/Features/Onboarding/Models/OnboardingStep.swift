//
//  OnboardingStep.swift
//  ReMeet
//
//  Created by Artush on 25/03/2025.
//

enum OnboardingStep: Int, CaseIterable {
    case phone, verification, personalisation, firstName, birthday, photos, permissions

    func validate(model: OnboardingModel) -> Bool {
        switch self {
        case .phone:
            return model.phoneNumber.count >= 10
        case .verification:
            return model.verificationCode.count == 6 && model.verificationCode.allSatisfy { $0.isNumber }
        case .personalisation:
            return true
        case .firstName:
            return !model.firstName.trimmingCharacters(in: .whitespaces).isEmpty
        case .birthday:
            return model.age != nil && model.age! >= 13
        case .photos, .permissions:
            return true
        }
    }

    func handleNext(for model: OnboardingModel, completion: @escaping () -> Void) {
        switch self {
        case .phone:
            model.sendVerificationCode()
        case .verification:
            model.verifyCode { success in
                if success {
                    model.advanceStep()
                    completion()
                } else {
                    model.errorMessage = "Verification failed. Please check the code and try again."
                }
            }

        case .personalisation, .firstName, .birthday:
            model.advanceStep()
            completion()
        case .photos:
            model.saveUserProfile { success in
                if success {
                    model.advanceStep()
                    completion()
                } else {
                    model.errorMessage = "Couldn't save your profile. Please try again."
                }
            }
        case .permissions:
            model.completeOnboarding()
            completion()
        }
    }
}
