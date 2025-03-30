//
//  PersonalisationStepView.swift
//  ReMeet
//
//  Created by Artush on 29/03/2025.
//

import SwiftUI

struct PersonalisationStepView: View {
    @ObservedObject var model: OnboardingModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            // Icon at the top
            ZStack {
                Circle()
                    .fill(Color(hex: "C9145B").opacity(0.2))
                    .frame(width: 70, height: 70)
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "C9145B"))

            }
            
            Text("Great, let's make your profile stand out!")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Follow the next steps and we will get help you set up your profile!")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            
            Spacer()
            
            PrimaryButton(
                title: "Next",
                action: {
                    model.moveToNextStep()
                }
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    PersonalisationStepView(model: OnboardingModel())
}
