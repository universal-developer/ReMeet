//
//  OnboardingStep.swift
//  ReMeet
//
//  Created by Artush on 25/03/2025.
//

enum OnboardingStep: Int, CaseIterable {
    case phone, verification, personalisation, firstName, birthday, photos

    func validate(model: OnboardingModel) -> Bool {
        switch self {
        case .phone:
            return model.phoneNumber.count >= 10
        case .verification:
            return model.verificationCode.count == 6 &&
                   model.verificationCode.allSatisfy { $0.isNumber }
        case .personalisation:
            return true
        case .firstName:
            return !model.firstName.trimmingCharacters(in: .whitespaces).isEmpty
        case .birthday:
            return model.age != nil && model.age! >= 13
        case .photos :
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
        case .personalisation:
            model.advanceStep()
        case .firstName, .birthday:
            model.advanceStep()
        case .photos:
            model.saveUserProfile { success in
                if success { model.advanceStep() }
                else {
                    model.errorMessage = "Couldn't save your profile. Please try again."
                }
            }
            
            model.completeOnboarding()
        /*case .permissions:
            model.completeOnboarding()
                        
            print("📱 Phone: \(model.phoneNumber)")
            print("👤 First Name: \(model.firstName)")
            print("🎂 Age: \(model.age ?? -1)")
            print("📷 Photos selected: \(model.userPhotos.count)")*/
        }
    }
}
