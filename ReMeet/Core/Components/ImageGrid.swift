//
//  ImageGrid.swift
//  ReMeet
//
//  Created by Artush on 20/03/2025.
//


import SwiftUI
import PhotosUI

struct ImageItem: Identifiable, Equatable {
    let id = UUID()
    var image: UIImage
    var isMain: Bool = false
    
    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct ImageGrid: View {
    @Binding var images: [ImageItem]
    @State private var selectedImage: PhotosPickerItem?
    @State private var isDragging: Bool = false
    @State private var draggedItem: ImageItem?
    let maxImages: Int
    let columns: Int
    
    init(images: Binding<[ImageItem]>, maxImages: Int = 6, columns: Int = 3) {
        self._images = images
        self.maxImages = maxImages
        self.columns = columns
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Photos")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            let gridItems = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
            
            LazyVGrid(columns: gridItems, spacing: 8) {
                ForEach(Array(images.enumerated()), id: \.element.id) { index, item in
                    ZStack(alignment: .topTrailing) {
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
                        
                        // Delete button
                        Button(action: {
                            if let index = images.firstIndex(where: { $0.id == item.id }) {
                                images.remove(at: index)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(6)
                        
                        // Main label (if it's the main photo)
                        if item.isMain {
                            Text("Main")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "C9155A"))
                                .cornerRadius(4)
                                .padding(6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "C9155A"))
                                .cornerRadius(4)
                                .padding(6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Set as main photo when tapped
                        if let index = images.firstIndex(where: { $0.id == item.id }) {
                            for i in 0..<images.count {
                                images[i].isMain = false
                            }
                            images[index].isMain = true
                        }
                    }
                }
                
                // Add empty slots to reach maxImages
                if images.count < maxImages {
                    ForEach(0..<(maxImages - images.count), id: \.self) { _ in
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
                }
            }
            .padding(.horizontal)
            
            Text("Hold & drag to reorder")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
        }
        .onChange(of: selectedImage) { newValue in
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
}

// Sample preview struct
struct ImageGridView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            ImageGrid(images: .constant([]))
        }
    }
}
