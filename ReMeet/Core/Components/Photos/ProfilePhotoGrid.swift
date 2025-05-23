//
//  ProfilePhotoGrid.swift
//  ReMeet
//  Created by Artush on 22/05/2025.

import SwiftUI
import PhotosUI

// Removed duplicate ImageItem definition; it's reused from ImageGrid.swift

struct ProfilePhotoGrid: View {
    @Binding var images: [ImageItem]
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profile: ProfileStore
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var draggedIndex: Int? = nil
    @State private var isShowingPicker: Bool = false
    
    private let spacing: CGFloat = 8
    private let cornerRadius: CGFloat = 12
    private let maxImages = 6
    
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
                        gridSlot(index: 3, size: CGSize(width: smallSize, height: smallSize))
                        gridSlot(index: 4, size: CGSize(width: smallSize, height: smallSize))
                        gridSlot(index: 5, size: CGSize(width: smallSize, height: smallSize))
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.width * 0.95)
        }
        .padding(.horizontal)
        .photosPicker(isPresented: $isShowingPicker,
                      selection: $selectedItems,
                      maxSelectionCount: maxImages - images.count,
                      matching: .images)
        .onChange(of: selectedItems) { _ in
            Task {
                for item in selectedItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        if images.count < maxImages {
                            images.append(ImageItem(image: image, isMain: images.isEmpty))
                        }
                    }
                }
                selectedItems = []
            }
        }
    }
    
    @ViewBuilder
    private func gridSlot(index: Int, size: CGSize) -> some View {
        if index < images.count {
            let item = images[index]
            
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: item.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(cornerRadius)
                // No tap gesture for now
                    .onDrag {
                        draggedIndex = index
                        return NSItemProvider(object: "\(index)" as NSString)
                    }
                    .onDrop(of: [.text], isTargeted: nil) { _ in
                        handleDrop(toIndex: index)
                    }
                
                label(forIndex: index)
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
    
    private func label(forIndex index: Int) -> some View {
        let isMain = index == 0
        return Text(isMain ? "Main" : "\(index + 1)")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(6)
            .padding(6)
    }
    
    private func setAsMain(at index: Int) {
        guard index < images.count else { return }
        
        for i in 0..<images.count {
            images[i].isMain = false
        }
        images[index].isMain = true
        if index != 0 {
            images.swapAt(0, index)
        }
    }
    
    private func handleDrop(toIndex: Int) -> Bool {
        guard let fromIndex = draggedIndex,
              fromIndex != toIndex,
              fromIndex < images.count,
              toIndex < images.count else {
            return false
            
            draggedIndex = nil
            saveReorderedPhotosToSupabase()
            return true
            
        }
        
        withAnimation {
            let item = images.remove(at: fromIndex)
            images.insert(item, at: toIndex)
        }
        
        draggedIndex = nil
        return true
    }
    
    private func saveReorderedPhotosToSupabase() {
        Task {
            guard let userID = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
            
            // Step 1: Delete existing metadata
            try? await SupabaseManager.shared.client
                .from("user_photos")
                .delete()
                .eq("user_id", value: userID.uuidString)
                .execute()
            
            // Step 2: Upload current order
            for (i, item) in images.enumerated() {
                guard let url = item.url else { continue }
                
                let photo = SupabaseUserPhoto(
                    user_id: userID,
                    url: url,
                    is_main: i == 0
                )
                
                try? await SupabaseManager.shared.client
                    .from("user_photos")
                    .insert(photo)
                    .execute()
            }
            
            print("✅ Saved reordered photos to Supabase.")
            
            // Step 3: Clear old cache and replace it with updated main image
            ImageCacheManager.shared.removeFromDisk(forKey: "user_photo_main")
            ImageCacheManager.shared.setToRAM(UIImage(), forKey: "user_photo_main")
            
            if let newMain = images.first,
               let newURL = newMain.url,
               let url = URL(string: newURL),
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                
                let key = "user_photo_main"
                ImageCacheManager.shared.setToRAM(image, forKey: key)
                ImageCacheManager.shared.saveToDisk(image, forKey: key)
                
                await MainActor.run {
                    profile.userImage = image
                }
            }
        }
    }
}
    
func imagesHaveChanged(original: [ImageItem], current: [ImageItem]) -> Bool {
    guard original.count == current.count else { return true }
    for (a, b) in zip(original, current) {
        if a != b || a.isMain != b.isMain { return true }
    }
    return false
}
