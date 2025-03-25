//
//  OnboardingStep.swift
//  ReMeet
//
//  Created by Artush on 25/03/2025.
//

enum OnboardingStep: Int, CaseIterable {
    case phone, verification, firstName, birthday, photos, permissions

    func validate(model: OnboardingModel) -> Bool {
        switch self {
        case .phone:
            return model.phoneNumber.count >= 10
        case .verification:
            return model.verificationCode.count == 6 &&
                   model.verificationCode.allSatisfy { $0.isNumber }
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
            model.advanceStep()
        case .verification:
            model.verifyCode { success in
                if success { model.advanceStep() }
            }
        case .firstName, .birthday:
            model.advanceStep()
        case .photos:
            model.saveUserProfile { success in
                if success { model.advanceStep() }
            }
        case .permissions:
            model.completeOnboarding()
        }
    }
}
