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

            Button(action: {
                model.userPhotos = imageItems.map { $0.image }
                print("📷 Photos selected: \(model.userPhotos.count)")
                model.moveToNextStep()
            }) {
                Text(imageItems.isEmpty ? "Skip" : "Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "C9155A"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.top, 20)
        .onAppear {
            // Optional: Load previously selected photos
            if !model.userPhotos.isEmpty {
                imageItems = model.userPhotos.map { ImageItem(image: $0) }
            }
        }
    }
}

#Preview {
    PhotosStepView(model: OnboardingModel())
}

