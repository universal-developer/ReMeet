//
//  PhotosStepView.swift
//  ReMeet
//
//  Created by Artush on 19/03/2025.
//

import SwiftUI

struct PhotosStepView: View {
    @ObservedObject var model: OnboardingModel
    @State private var imageItems: [ImageItem] = []
    
    var isValid: Bool {
        if imageItems.count > 0 {
            model.currentStep.validate(model: model)
            return true
        }
        
        return false
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Your Photos")
                .font(.system(size: 28, weight: .bold))

            Text("Help others recognize you when reconnecting")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ImageGrid(images: $imageItems)

            Spacer()
            
            PrimaryButton(
                title: "Continue",
                action: {
                    print("📷 Photos selected: \(model.userPhotos.count)")
                    if isValid {
                        model.moveToNextStep()
                    }
                },
                backgroundColor: isValid ? Color(hex: "C9155A") : Color.gray.opacity(0.5)
            )
            .frame(maxWidth: .infinity)
            .disabled(!isValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
        }
        .padding(.top, 20)
        .onAppear {
            // Optional: Load previously selected photos
            if !model.userPhotos.isEmpty {
                imageItems = model.userPhotos.map { ImageItem(image: $0) }
            }
        }
        .onChange(of: imageItems) { newItems in
            model.userPhotos = newItems.map { $0.image }
        }
    }
}

#Preview {
    PhotosStepView(model: OnboardingModel())
}

