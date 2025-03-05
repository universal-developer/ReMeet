//
//  OnboardingContainerView.swift
//  ReMeet
//
//  Updated on 05/03/2025.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var model = OnboardingModel()
    
    // For transition animations
    @State private var currentPageOffset: CGFloat = 0
    @State private var animating = false
    
    var body: some View {
        ZStack {
            // Background color
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top header area with logo and progress bar
                VStack(spacing: 6) {
                    // App branding with higher placement like BeReal
                    Text("ReMeet")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(Color(hex: "C9155A"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16) // Reduced top padding to move logo higher
                    
                    // Progress bar directly below logo
                    SegmentedProgressBar(
                        totalSteps: OnboardingStep.allCases.count,
                        currentStep: model.currentStep.rawValue
                    )
                    .frame(height: 4)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                
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
        .onReceive(model.$currentStep) { newStep in
            // Debug print to track step changes
            print("💫 Moving to step: \(newStep) - Progress: \(Int(model.progressPercentage * 100))%")
            
            // Smooth page transition
            performTransition()
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

// Segmented progress bar that clearly shows each step
struct SegmentedProgressBar: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? Color(hex: "C9155A") : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}
