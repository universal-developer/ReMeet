//
//  OnboardingContainerView.swift
//  ReMeet
//
//  Created by Artush on 29/03/2025.
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

                // Slide transition container
                Group {
                    switch model.currentStep {
                    case .phone:
                        AnyView(PhoneStepView(model: model))
                    case .verification:
                        AnyView(PhoneVerificationStepView(model: model))
                    case .personalisation:
                        AnyView(PersonalisationStepView(model: model))
                    case .firstName:
                        AnyView(FirstNameStepView(model: model))
                    case .birthday:
                        AnyView(BirthdayStepView(model: model))
                    case .photos:
                        AnyView(PhotosStepView(model: model))
                    case .permissions:
                        AnyView(PermissionsView(model: model))
                    }
                }
                .id(model.currentStep)
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
}

#Preview {
    OnboardingContainerView()
}
