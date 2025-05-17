//
//  TagSelectionStepView.swift
//  ReMeet
//
//  Created by Artush on 16/05/2025.
//

import SwiftUI

struct TagSelectionStepView: View {
    @ObservedObject var model: OnboardingModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ScrollView {
                VStack {
                    
                    Text("So,tell your future connections about you!")
                        .font(.title2)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                    
                    // PERSONALITY
                    TagCategorySelector(
                        //title: "Personality",
                        tags: TagData.personality,
                        selectionLimit: 3,
                        selected: $model.selectedPersonality
                    )

                    // LANGUAGES
                    TagCategorySelector(
                        //title: "Languages You Speak",
                        tags: TagData.languages,
                        selectionLimit: 10,
                        selected: $model.selectedLanguages
                    )

                    // LIFESTYLE (Optional)
                    TagCategorySelector(
                        //title: "Lifestyle",
                        tags: TagData.lifestyle,
                        selectionLimit: 2,
                        selected: $model.selectedLifestyle
                    )
                }
            }
        }
        .padding()
        //.edgesIgnoringSafeArea(.all)
    }
}


#Preview {
    TagSelectionStepView(model: OnboardingModel())
}
