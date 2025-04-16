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
    @Published var fullPhoneForDisplay: String = ""
    @Published var verificationCode: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
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
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    
    struct Instrument: Codable, Identifiable {
        let id: String
        let firstName: String
        let lastName: String
        let age: Int
        let birthDay: String?
        let birthMonth: String?
        let birthYear: String?
        let phoneNumber: String
        let selectedCountryCode: String?

        enum CodingKeys: String, CodingKey {
            case id
            case firstName = "first_name"
            case lastName = "last_name"
            case age
            case birthDay = "birth_day"
            case birthMonth = "birth_month"
            case birthYear = "birth_year"
            case phoneNumber = "phone_number"
            case selectedCountryCode = "selected_country_code"
        }
    }
    
    struct UserPhoto: Encodable {
        let user_id: UUID
        let url: String
        let is_main: Bool
    }


    // MARK: - Navigation
    var progressPercentage: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var canGoBack: Bool {
        true
    }
    
    func moveToNextStep() {
        print("➡️ moveToNextStep called — current step: \(currentStep)")
        if currentStep.validate(model: self) {
            currentStep.handleNext(for: self) {}
        }
    }

    func advanceStep() {
        print("📲 Advancing from step: \(currentStep)")
        if let index = OnboardingStep.allCases.firstIndex(of: currentStep),
           index + 1 < OnboardingStep.allCases.count {
            currentStep = OnboardingStep.allCases[index + 1]
            print("➡️ Now on step: \(currentStep)")
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
        print("📞 sendVerificationCode() STARTED")

        var trimmedPhone = phoneNumber.filter { $0.isNumber }
        if trimmedPhone.hasPrefix("0") {
            trimmedPhone.removeFirst()
        }

        let country = CountryManager.shared.country(for: selectedCountryCode) ?? Country(code: "US", name: "United States", phoneCode: "1")
        let fullPhoneNumber = "\(country.phoneCode)\(trimmedPhone)"
        print("📤 Full number sent to Supabase: \(fullPhoneNumber)")

        isLoading = true

        Task {
            do {
                print("🚀 CALLING Supabase signInWithOTP...")
                try await SupabaseManager.shared.client.auth.signInWithOTP(phone: fullPhoneNumber)
                print("✅ CALL SUCCEEDED")

                DispatchQueue.main.async {
                    self.isPhoneVerificationSent = true
                    self.isLoading = false
                    self.advanceStep() // ✅ GO TO OTP STEP HERE
                }

            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to send code. Check your number."
                    print("❌ Error sending OTP: \(String(describing: error))")
                }
            }
        }
    }


    func verifyCode(completion: @escaping (Bool) -> Void) {
        var trimmedPhone = phoneNumber
        if trimmedPhone.hasPrefix("0") {
            trimmedPhone.removeFirst()
        }
        let country = CountryManager.shared.country(for: selectedCountryCode) ?? Country(code: "US", name: "United States", phoneCode: "1")
        let fullPhoneNumber = "\(country.phoneCode)\(trimmedPhone)"
        isLoading = true

        Task {
            do {
                print("📨 Verifying OTP with phone: \(fullPhoneNumber), code: \(verificationCode)")
                try await SupabaseManager.shared.client.auth.verifyOTP(phone: fullPhoneNumber, token: verificationCode, type: .sms)
                print("✅ Phone verified via Supabase")

                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id

                let existingProfiles = try await SupabaseManager.shared.client
                    .database
                    .from("profiles")
                    .select("*") // ← This is the missing piece!
                    .eq("id", value: userId.uuidString)
                    .execute()
                    .value as [Instrument]


                DispatchQueue.main.async {
                    self.isLoading = false
                    if !existingProfiles.isEmpty {
                        // ✅ Profile exists – skip onboarding
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        print("🎉 Existing user profile found, launching main app.")
                        self.currentStep = .permissions // optional: set currentStep to last step
                    } else {
                        // 🆕 No profile, continue onboarding
                        self.advanceStep()
                    }
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
        print("🧪 Supabase currentUser ID: \(SupabaseManager.shared.client.auth.currentUser?.id.uuidString ?? "nil")")
        
        guard let age = age else {
            print("🚫 Missing age, cannot save user.")
            DispatchQueue.main.async { completion(false) }
            return
        }

        Task<Void, Never> {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id

                print("🧪 Using session UUID: \(userId.uuidString)")

                let userProfile = Instrument(
                    id: userId.uuidString,
                    firstName: firstName,
                    lastName: lastName,
                    age: age,
                    birthDay: birthDay,
                    birthMonth: birthMonth,
                    birthYear: birthYear,
                    phoneNumber: phoneNumber,
                    selectedCountryCode: selectedCountryCode
                )

                print("🧪 Preparing to insert profile with ID: \(userProfile.id)")
                print("📤 Inserting profile...")

                try await SupabaseManager.shared.client
                    .database
                    .from("profiles")
                    .upsert(userProfile, onConflict: "id")
                    .execute()

                print("✅ Profile inserted.")

                for (index, image) in userPhotos.enumerated() {
                    print("📸 Uploading photo #\(index)...")

                    guard let imageData = image.jpegData(compressionQuality: 0.4) else {
                        print("❌ Could not convert photo #\(index) to compressed JPEG.")
                        continue
                    }

                    let filename = "\(userId.uuidString)/photo_\(index)_\(UUID().uuidString).jpg"
                    print("🧾 Upload filename: \(filename)")

                    try await SupabaseManager.shared.client
                        .storage
                        .from("user-photos")
                        .upload(
                            path: filename,
                            file: imageData,
                            options: FileOptions(contentType: "image/jpeg", upsert: true)
                        )

                    print("✅ Photo #\(index) uploaded.")

                    let publicUrl = "\(SupabaseManager.shared.publicStorageUrlBase)/user-photos/\(filename)"
                    print("🌐 Public URL: \(publicUrl)")

                    let isMain = (index == 0) // or check images[index].isMain if you're keeping that info
                    let photoRecord = UserPhoto(
                        user_id: userId,
                        url: publicUrl,
                        is_main: isMain
                    )


                    print("🧪 Final UserPhoto payload: user_id = \(photoRecord.user_id), url = \(photoRecord.url)")

                    try await SupabaseManager.shared.client
                        .database
                        .from("user_photos")
                        .upsert(photoRecord, onConflict: "url")
                        .execute()

                    print("✅ Photo #\(index) record inserted.")
                }

                print("🎉 All photos saved.")
                DispatchQueue.main.async { completion(true) }

            } catch {
                print("❌ Failed during saveUserProfile: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Something went wrong. Please try again."
                    completion(false)
                }
            }
        }
    }

    func completeOnboarding() {
        isLoggedIn = true
        print("🎉 Onboarding complete for: \(firstName), age \(age ?? 0)")
    }

    func reset() {
        phoneNumber = ""
        verificationCode = ""
        firstName = ""
        lastName = ""
        age = nil
        userPhotos = []
        selectedImage = nil
        isPhoneVerificationSent = false
        currentStep = .phone
    }

    private var progressSteps: [OnboardingStep] {
        [.firstName, .birthday, .photos, .permissions]
    }

    var progressStepIndex: Int {
        progressSteps.firstIndex(of: currentStep) ?? 0
    }

    var totalProgressSteps: Int {
        progressSteps.count
    }
}
