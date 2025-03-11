//
//  OnboardingContainerView.swift
//  ReMeet
//
//  Updated on 06/03/2025.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var model = OnboardingModel()
    @Environment(\.presentationMode) var presentationMode
    
    // For transition animations
    @State private var currentPageOffset: CGFloat = 0
    @State private var animating = false
    
    var body: some View {
        ZStack {
            // Background color
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // New header design: back button + progress bar
                HStack(spacing: 16) {
                    // Back button
                    Button(action: {
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
                        currentStep: model.currentStep.rawValue-1
                    )
                    .frame(height: 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Current step view with transition
                ZStack {
                    switch model.currentStep {
                    case .firstName:
                        FirstNameStepView(model: model)
                            .transition(AnyTransition.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    case .lastName:
                        LastNameStepView(model: model)
                            .transition(AnyTransition.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    case .birthday:
                        BirthdayStepView(model: model)
                            .transition(AnyTransition.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    case .phone:
                        PhoneStepView(model: model)
                            .transition(AnyTransition.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    case .username:
                        UsernameStepView(model: model)
                            .transition(AnyTransition.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.currentStep)
                .offset(x: currentPageOffset)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true) // Ensure the default back button doesn't appear
        .onReceive(model.$currentStep) { newStep in
            // Debug print to track step changes
            print("💫 Moving to step: \(newStep) - Progress: \(Int(model.progressPercentage * 100))%")
            
            // Smooth page transition
            performTransition()
        }
    }
    
    // Helper computed property to determine if back navigation is possible
    private var canGoBack: Bool {
        // Always show back button, even on first step
        return true
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
        case .username:
            model.currentStep = .phone
        }
    }
    
    // Function to animate transitions
    private func performTransition() {
        guard !animating else { return }
        
        animating = true
        
        // Simulate a page swipe effect
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPageOffset = -50
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentPageOffset = 50
            
            withAnimation(.easeOut(duration: 0.2)) {
                currentPageOffset = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animating = false
            }
        }
    }
}


// For preview purposes only if needed
// OnboardingStep and progressPercentage should be defined in your main OnboardingModel class

#Preview {
    OnboardingContainerView()
}
