//
//  PhotosStepView.swift
//  ReMeet
//
//  Created by Artush on 19/03/2025.
//

import SwiftUI
import PhotosUI

struct PhotosStepView: View {
    @ObservedObject var model: OnboardingModel
    @Environment(\.onNextStep) var onNextStep
    
    @State private var showingImagePicker = false
    @State private var selectedPhotos: [UIImage] = []
    @State private var isPhotoLibraryDenied = false
    @State private var userPhotos: [ImageItem] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Your Photos")
                .font(.system(size: 28, weight: .bold))
            
            Text("Help others recognize you when reconnecting")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ImageGrid(images: $userPhotos)
            
            /*// Photo grid or empty state
            if selectedPhotos.isEmpty {
                // Empty state - tap to add photos
                Button(action: {
                    print("Opening photo picker")
                    showingImagePicker = true
                }) {
                    VStack(spacing: 15) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("Tap to add photos")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                }
            } else {
                // Photo grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(0..<selectedPhotos.count, id: \.self) { index in
                            Image(uiImage: selectedPhotos[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    Button(action: {
                                        selectedPhotos.remove(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .shadow(radius: 1)
                                    }
                                    .padding(5),
                                    alignment: .topTrailing
                                )
                        }
                        
                        // Add more photos button (if less than 6)
                        if selectedPhotos.count < 6 {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 30))
                                    Text("Add")
                                        .font(.caption)
                                }
                                .frame(width: 100, height: 100)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
                .frame(height: 250)
            }
            */
            Spacer()
            
            // Continue button
            Button(action: {
                // Save selected photos to model
                model.userPhotos = selectedPhotos
                model.currentStep = .permissions
                onNextStep()
            }) {
                Text(selectedPhotos.isEmpty ? "Skip" : "Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "C9155A"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.top, 20)
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker(selectedPhotos: $selectedPhotos, maxSelectionCount: 6 - selectedPhotos.count)
        }
        .alert("Photos Access Required", isPresented: $isPhotoLibraryDenied) {
            Button("Open Settings", action: openSettings)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please allow access to your photo library to add photos to your profile.")
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// PhotoPicker using PHPickerViewController
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedPhotos: [UIImage]
    var maxSelectionCount: Int
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = maxSelectionCount
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedPhotos.append(image)
                        }
                    } else if let error = error {
                        print("Photo picker error: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    PhotosStepView(model: OnboardingModel())
}
