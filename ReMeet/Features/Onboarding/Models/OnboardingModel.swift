//
//  OnboardingModel.swift
//  ReMeet
//
//  Updated on 05/03/2025.
//

import SwiftUI
import Combine
import Storage

class OnboardingModel: ObservableObject {
    // MARK: - User Data
    @Published var phoneNumber: String = ""
    @Published var selectedCountryCode: String = ""
    @Published var verificationCode: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var username: String = ""
    @Published var age: Int?
    @Published var birthDay: String = ""
    @Published var birthMonth: String = ""
    @Published var birthYear: String = ""
    @Published var userPhotos: [UIImage] = []
    @Published var selectedImage: UIImage?

    // MARK: - State
    @Published var isPhoneVerificationSent: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentStep: OnboardingStep = .phone

    struct Instrument: Encodable {
        let id: String
        let firstName: String
        let lastName: String
        let username: String
        let age: Int
        let birthDay: String
        let birthMonth: String
        let birthYear: String
        let phoneNumber: String
        let selectedCountryCode: String

        enum CodingKeys: String, CodingKey {
            case id
            case firstName = "first_name"
            case lastName = "last_name"
            case username = "username"
            case age
            case birthDay = "birth_day"
            case birthMonth = "birth_month"
            case birthYear = "birth_year"
            case phoneNumber = "phone_number"
            case selectedCountryCode = "selected_country_code"
        }
    }

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
        // Strip leading zero if it exists
        var trimmedPhone = phoneNumber
        if trimmedPhone.hasPrefix("0") {
            trimmedPhone.removeFirst()
        }

        let fullPhoneNumber = "+\(selectedCountryCode)\(trimmedPhone)"
        print("📤 Sending OTP to: \(fullPhoneNumber)")
        
        isLoading = true
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signInWithOTP(phone: fullPhoneNumber)
                DispatchQueue.main.async {
                    self.isPhoneVerificationSent = true
                    self.isLoading = false
                    print("✅ OTP sent")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to send code. Check your number."
                    print("❌ Error sending OTP: \(error)")
                }
            }
        }
    }



    func verifyCode(completion: @escaping (Bool) -> Void) {
        var trimmedPhone = phoneNumber
        if trimmedPhone.hasPrefix("0") {
            trimmedPhone.removeFirst()
        }
        let fullPhoneNumber = "+\(selectedCountryCode)\(trimmedPhone)"
        isLoading = true
        Task {
            do {
                try await SupabaseManager.shared.client.auth.verifyOTP(phone: fullPhoneNumber, token: verificationCode, type: .sms)
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("✅ Phone verified via Supabase")
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Invalid code. Please try again."
                    print("❌ OTP verification failed: \(error)")
                    completion(false)
                }
            }
        }
    }


    func saveUserProfile(completion: @escaping (Bool) -> Void) {
        guard let age = age,
              let userId = SupabaseManager.shared.client.auth.currentUser?.id.uuidString else {
            print("🚫 Missing data, cannot save user.")
            completion(false)
            return
        }

        let user = Instrument(
            id: userId,
            firstName: firstName,
            lastName: lastName,
            username: username,
            age: age,
            birthDay: birthDay,
            birthMonth: birthMonth,
            birthYear: birthYear,
            phoneNumber: phoneNumber,
            selectedCountryCode: selectedCountryCode
        )

        Task {
            do {
                try await SupabaseManager.shared.client
                    .database
                    .from("profiles")
                    .insert(user)
                    .execute()

                for (index, image) in userPhotos.enumerated() {
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        let filename = "\(userId)/photo_\(index)_\(UUID().uuidString).jpg"

                        try await SupabaseManager.shared.client
                            .storage
                            .from("user-photos")
                            .upload(
                                path: filename,
                                file: imageData,
                                options: FileOptions(contentType: "image/jpeg")
                            )

                        let publicUrl = "\(SupabaseManager.shared.publicStorageUrlBase)/user-photos/\(filename)"

                        try await SupabaseManager.shared.client
                            .database
                            .from("user_photos")
                            .insert([
                                "user_id": userId,
                                "url": publicUrl
                            ])
                            .execute()
                    }
                }

                print("✅ User and photos saved to Supabase.")
                completion(true)

            } catch {
                print("❌ Failed to save user/photos: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        print("🎉 Onboarding complete for: \(firstName), age \(age ?? 0)")
    }

    func reset() {
        phoneNumber = ""
        verificationCode = ""
        firstName = ""
        lastName = ""
        username = ""
        age = nil
        userPhotos = []
        selectedImage = nil
        isPhoneVerificationSent = false
        currentStep = .phone
    }

    private var progressSteps: [OnboardingStep] {
        [.firstName, .birthday, .photos]
    }

    var progressStepIndex: Int {
        progressSteps.firstIndex(of: currentStep) ?? 0
    }

    var totalProgressSteps: Int {
        progressSteps.count
    }
}
