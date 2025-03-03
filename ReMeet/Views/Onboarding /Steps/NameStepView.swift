//
//  NameStep.swift
//  ReMeet
//
//  Created by Artush on 16/02/2025.
//

import SwiftUI

struct NameStepView: View {
    @State private var name: String = ""
    @State private var navigateToNextScreen = false

    var body: some View {
        ZStack {
            // Background color
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                VStack(alignment: .center, spacing: 24) {
                    Text("ReMeet.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "C9155A"))

                    Text("Let's get started, what's your name?")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .fontWeight(.bold)

                    TextField("Your name", text: $name)
                        .font(.system(size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .textFieldStyle(PlainTextFieldStyle())
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                Spacer()
                
                // Navigation link (hidden, activated by the button)
                NavigationLink(
                    destination: NameStepView(),
                    isActive: $navigateToNextScreen,
                    label: { EmptyView() }
                )
                
                // Circular arrow button (right-aligned at bottom)
                HStack {
                    Spacer() // This pushes the button to the right
                    
                    CircleArrowButton(
                        action: {
                            // Only navigate if name is not empty
                            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                navigateToNextScreen = true
                            }
                        },
                        backgroundColor: Color(hex: "C9155A")
                    )
                    .padding(.trailing, 24) // Add some padding on the right side
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark) // Force dark mode
    }
}

#Preview {
    NameStepView()
}
