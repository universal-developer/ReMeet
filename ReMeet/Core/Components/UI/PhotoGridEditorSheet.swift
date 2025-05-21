//
//  PhotoGridEditorSheet.swift
//  ReMeet
//
//  Created by Artush on 21/05/2025.
//

import SwiftUI
import PhotosUI

struct PhotoGridEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profile: ProfileStore
    @State private var localImages: [ImageItem] = []
    @State private var selectedImage: PhotosPickerItem?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Edit Your Photos")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)

                PhotoGridView(images: localImages, onPlaceholderTapped: {
                    // trigger photo picker
                    presentPhotoPicker()
                })
                .padding(.top, 4)

                Spacer()

                Button("Save Changes") {
                    profile.cachedProfileImages = localImages
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "C9155A"))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .navigationTitle("Photo Editor")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                self.localImages = profile.cachedProfileImages
            }
            .photosPicker(isPresented: $showingPicker, selection: $selectedImage, matching: .images)
        }
        .onChange(of: selectedImage) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let newItem = ImageItem(image: uiImage, isMain: localImages.isEmpty)
                    localImages.append(newItem)
                    selectedImage = nil
                }
            }
        }
    }

    @State private var showingPicker = false

    private func presentPhotoPicker() {
        showingPicker = true
    }
}
