//
//  EditablePhotoGrid.swift
//  ReMeet
//
//  Created by Artush on 20/06/2025.
//


import SwiftUI
import PhotosUI

struct EditablePhotoGrid: View {
    @Binding var images: [ImageItem]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var draggedIndex: Int? = nil
    @State private var isShowingPicker: Bool = false
    @State private var isUploadingNewPhotos: Bool = false

    private let spacing: CGFloat = 8
    private let cornerRadius: CGFloat = 12
    private let maxImages = 6
    private let vibrateAngle: Angle = .degrees(2)

    var body: some View {
        VStack {
            GeometryReader { geo in
                let width = geo.size.width
                let full = width - spacing * 2
                let smallSize = (full - spacing * 2) / 3
                let largeHeight = smallSize * 2 + spacing

                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        gridSlot(index: 0, size: CGSize(width: smallSize * 2 + spacing, height: largeHeight))

                        VStack(spacing: spacing) {
                            gridSlot(index: 1, size: CGSize(width: smallSize, height: smallSize))
                            gridSlot(index: 2, size: CGSize(width: smallSize, height: smallSize))
                        }
                    }

                    HStack(spacing: spacing) {
                        ForEach(3..<6, id: \.self) { index in
                            gridSlot(index: index, size: CGSize(width: smallSize, height: smallSize))
                        }
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.width * 0.95)

            if isUploadingNewPhotos {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Uploading photos...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
        .photosPicker(isPresented: $isShowingPicker,
                      selection: $selectedItems,
                      maxSelectionCount: maxImages - images.count,
                      matching: .images)
        .onChange(of: selectedItems) { _ in
            Task {
                await handleNewPhotoSelection()
            }
        }
    }

    @ViewBuilder
    private func gridSlot(index: Int, size: CGSize) -> some View {
        if index < images.count {
            let item = images[index]

            ZStack(alignment: .topTrailing) {
                if let uiImage = item.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .cornerRadius(cornerRadius)
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? 2 : -2)) // playful tilt
                        .animation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true), value: images.count)

                    // delete button
                    Button(action: {
                        withAnimation {
                            images.remove(at: index)
                            recalculateMainFlag()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .offset(x: 6, y: -6)

                    // index/main tag
                    Text(item.isMain ? "Main" : "\(index + 1)")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .padding(6)
                        .offset(y: size.height - 28)
                }
            }
        } else if index == images.count && images.count < maxImages {
            Button {
                isShowingPicker = true
            } label: {
                placeholderCell(size: size)
            }
        } else {
            placeholderCell(size: size)
        }
    }

    private func placeholderCell(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(.gray.opacity(0.4))
                .frame(width: size.width, height: size.height)

            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.gray.opacity(0.6))
        }
    }

    private func handleNewPhotoSelection() async {
        isUploadingNewPhotos = true
        defer { isUploadingNewPhotos = false }

        var newItems: [ImageItem] = []

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                if images.count + newItems.count < maxImages {
                    newItems.append(ImageItem(image: image))
                }
            }
        }

        selectedItems = []

        await MainActor.run {
            if images.isEmpty && !newItems.isEmpty {
                newItems[0].isMain = true
            }
            images.append(contentsOf: newItems)
            recalculateMainFlag()
        }

        if let userID = try? await SupabaseManager.shared.client.auth.session.user.id {
            await SupabasePhotoUploader.shared.uploadUpdatedPhotos(images, for: userID)
        }
    }

    private func recalculateMainFlag() {
        for i in 0..<images.count {
            images[i].isMain = (i == 0)
        }
    }
}
