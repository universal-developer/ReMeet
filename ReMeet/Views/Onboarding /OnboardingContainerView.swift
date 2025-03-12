//
//  OnboardingContainerView.swift
//  ReMeet
//
//  Updated on 12/03/2025.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var model = OnboardingModel()
    @Environment(\.presentationMode) var presentationMode
    
    // Direction tracking for animation
    @State private var slideDirection: SlideDirection = .forward
    
    // Define slide directions for better animations
    enum SlideDirection {
        case forward
        case backward
    }
    
    var body: some View {
        ZStack {
            // Background color
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // New header design: back button + progress bar
                HStack(spacing: 16) {
                    // Back button
                    Button(action: {
                        slideDirection = .backward
                        navigateToPreviousStep()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                    .opacity(canGoBack ? 1.0 : 0.0) // Hide on first step
                    
                    // Progress bar
                    SegmentedProgressBar(
                        totalSteps: OnboardingStep.allCases.count,
                        currentStep: model.currentStep.rawValue
                    )
                    .frame(height: 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Current step view with improved transition
                currentStepView
                    .transition(slideDirection == .forward ?
                               .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                               .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    .animation(.easeInOut(duration: 0.3), value: model.currentStep)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    // Extract the step view logic to a computed property
    @ViewBuilder
    private var currentStepView: some View {
        switch model.currentStep {
        case .firstName:
            FirstNameStepView(model: model)
                .onNextStep { moveToNextStep() }
        case .lastName:
            LastNameStepView(model: model)
                .onNextStep { moveToNextStep() }
        case .birthday:
            BirthdayStepView(model: model)
                .onNextStep { moveToNextStep() }
        case .phone:
            PhoneStepView(model: model)
                .onNextStep { moveToNextStep() }
        case .verification:
            PhoneVerificationStepView(model: model)
                .onNextStep { moveToNextStep() }
        case .username:
            UsernameStepView(model: model)
                .onNextStep { moveToNextStep() }
        }
    }
    
    // Helper computed property to determine if back navigation is possible
    private var canGoBack: Bool {
        // Always show back button, even on first step
        return true
    }
    
    // Navigate to next step with forward animation
    private func moveToNextStep() {
        slideDirection = .forward
        
        // Your logic for determining next step would go here
        // For now, we'll just implement directly in each view
    }
    
    // Navigate to previous step
    private func navigateToPreviousStep() {
        switch model.currentStep {
        case .firstName:
            // Dismiss this view to go back to WelcomeView
            presentationMode.wrappedValue.dismiss()
        case .lastName:
            model.currentStep = .firstName
        case .birthday:
            model.currentStep = .lastName
        case .phone:
            model.currentStep = .birthday
        case .verification:
            model.currentStep = .phone
        case .username:
            model.currentStep = .verification
        }
    }
}

// View modifier for handling next step actions
extension View {
    func onNextStep(action: @escaping () -> Void) -> some View {
        self.environment(\.onNextStep, action)
    }
}

// Environment key for next step actions
struct OnNextStepKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var onNextStep: () -> Void {
        get { self[OnNextStepKey.self] }
        set { self[OnNextStepKey.self] = newValue }
    }
}

#Preview {
    OnboardingContainerView()
}
