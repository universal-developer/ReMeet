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
    @Environment(\.colorScheme) var colorScheme
    @State private var slideDirection: SlideDirection = .forward

    enum SlideDirection {
        case forward, backward
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Button(action: {
                        slideDirection = .backward
                        model.moveToPreviousStep {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: 40, height: 40)
                    }
                    .opacity(model.canGoBack ? 1.0 : 0.0)

                    SegmentedProgressBar(
                        totalSteps: OnboardingStep.allCases.count,
                        currentStep: model.currentStep.rawValue
                    )
                    .frame(height: 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Animated step transition
                currentStepView
                    .transition(slideDirection == .forward ?
                                .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                                .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    .animation(.easeInOut(duration: 0.3), value: model.currentStep)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch model.currentStep {
        case .phone:
            PhoneStepView(model: model)
        case .verification:
            PhoneVerificationStepView(model: model)
        case .firstName:
            FirstNameStepView(model: model)
        case .birthday:
            BirthdayStepView(model: model)
        case .photos:
            PhotosStepView(model: model)
        case .permissions:
            PermissionsView(model: model)
        }
    }
}


#Preview {
    OnboardingContainerView()
}
