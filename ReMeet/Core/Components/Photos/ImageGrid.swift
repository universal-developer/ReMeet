//
//  ImageGrid.swift
//  ReMeet
//
//  Created by Artush on 20/03/2025.
//

import SwiftUI
import PhotosUI



struct ImageGrid: View {
    @Binding var images: [ImageItem]
    @State private var selectedImage: PhotosPickerItem?
    @State private var draggedItem: ImageItem?
    @Environment(\.colorScheme) var colorScheme
    
    let maxImages: Int
    let columns: Int
    
    init(images: Binding<[ImageItem]>, maxImages: Int = 6, columns: Int = 3) {
        self._images = images
        self.maxImages = maxImages
        self.columns = columns
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            gridContent
            instructionText
        }
        .onChange(of: selectedImage) { newValue in
            handleSelectedImage(newValue)
        }
    }
    
    // MARK: - Extracted Views
    
    private var headerView: some View {
        Text("Your Photos")
            .font(.headline)
            .padding(.horizontal)
    }
    
    private var gridContent: some View {
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
        
        return LazyVGrid(columns: gridItems, spacing: 8) {
            // Existing images
            ForEach(Array(images.enumerated()), id: \.element.id) { index, item in
                imageCell(item: item, index: index)
            }
            
            // Empty slots
            if images.count < maxImages {
                ForEach(0..<(maxImages - images.count), id: \.self) { _ in
                    addPhotoButton
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func imageCell(item: ImageItem, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            // Image
            Image(uiImage: item.image)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, idealHeight: 110, maxHeight: 110)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onDrag {
                    self.draggedItem = item
                    return NSItemProvider(object: item.id.uuidString as NSString)
                }
                .onDrop(of: [.text], isTargeted: nil) { providers in
                    handleDrop(for: item)
                }
            
            // Delete button
            deleteButton(for: item)
            
            // Photo indicator (Main or number)
            photoIndicator(item: item, index: index)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            setAsMainPhoto(item)
        }
    }
    
    private var addPhotoButton: some View {
        PhotosPicker(selection: $selectedImage, matching: .images) {
            VStack {
                Image(systemName: "plus")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            }
            .frame(height: 110)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func deleteButton(for item: ImageItem) -> some View {
        Button(action: {
            if let index = images.firstIndex(where: { $0.id == item.id }) {
                images.remove(at: index)
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(6)
    }
    
    private func photoIndicator(item: ImageItem, index: Int) -> some View {
        Group {
            if item.isMain {
                Text("Main")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorScheme == .dark ? .black : .white)
                    .cornerRadius(4)
            } else {
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorScheme == .dark ? .black : .white)
                    .cornerRadius(4)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
    
    private var instructionText: some View {
        Text("Hold & drag to reorder")
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func handleDrop(for item: ImageItem) -> Bool {
        guard let source = draggedItem,
              source.id != item.id else {
            return false
        }
        
        guard let sourceIndex = images.firstIndex(of: source),
              let destinationIndex = images.firstIndex(of: item) else {
            return false
        }
        
        withAnimation {
            var updatedImages = images
            updatedImages.move(fromOffsets: IndexSet(integer: sourceIndex),
                            toOffset: destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex)
            images = updatedImages
        }
        return true
    }
    
    private func setAsMainPhoto(_ item: ImageItem) {
        if let index = images.firstIndex(where: { $0.id == item.id }) {
            for i in 0..<images.count {
                images[i].isMain = false
            }
            images[index].isMain = true
        }
    }
    
    private func handleSelectedImage(_ newValue: PhotosPickerItem?) {
        Task {
            if let data = try? await newValue?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                let newItem = ImageItem(image: uiImage, isMain: images.isEmpty)
                DispatchQueue.main.async {
                    images.append(newItem)
                    selectedImage = nil
                }
            }
        }
    }
}

// Sample preview struct
struct ImageGrid_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            ImageGrid(images: .constant([]))
        }
    }
}
