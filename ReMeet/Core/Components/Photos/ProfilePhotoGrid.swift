//  ProfilePhotoGrid.swift
//  ReMeet
//
//  Created by Artush on 22/05/2025.

import SwiftUI
import PhotosUI

struct ProfilePhotoGrid: View {
    @Binding var images: [ImageItem]
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profile: ProfileStore

    var showDeleteButtons: Bool = false

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var draggedIndex: Int? = nil
    @State private var isShowingPicker: Bool = false
    @State private var isUploadingNewPhotos: Bool = false

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
                        .onDrag {
                            draggedIndex = index
                            return NSItemProvider(object: "\(index)" as NSString)
                        }
                        .onDrop(of: [.text], isTargeted: nil) { _ in
                            handleDrop(toIndex: index)
                        }

                    Text(item.isMain ? "Main" : "\(index + 1)")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .padding(6)
                        .offset(y: size.height - 28)
                    
                    if showDeleteButtons {
                        Button(action: {
                            if index < images.count {
                                let removed = images.remove(at: index)
                                recalculateMainFlag()
                                
                                withAnimation {
                                    profile.preloadedProfilePhotos = images
                                    profile.profilePhotoURLs = images.compactMap { $0.url }
                                }

                                // Optional: remove from RAM/disk if needed
                                if let url = removed.url {
                                    let key = "user_photo_\(ImageCacheManager.shared.stableHash(for: url))"
                                    ImageCacheManager.shared.removeFromRAM(forKey: key)
                                    ImageCacheManager.shared.removeFromDisk(forKey: key)

                                    // ✅ DELETE FROM Supabase
                                    Task {
                                        do {
                                            try await SupabaseManager.shared.client
                                                .from("user_photos")
                                                .delete()
                                                .eq("user_id", value: profile.userId ?? "")
                                                .eq("url", value: url)
                                                .execute()
                                            print("🧹 Deleted photo from Supabase.")
                                        } catch {
                                            print("❌ Failed to delete from Supabase: \(error)")
                                        }
                                    }
                                }

                                // Re-upload remaining images with updated order + is_main
                                Task {
                                    if let userID = try? await SupabaseManager.shared.client.auth.session.user.id {
                                        await SupabasePhotoUploader.shared.uploadUpdatedPhotos(images, for: userID)
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                        }
                        .offset(x: 6, y: -6)
                    }

                } else {
                    Color.gray.opacity(0.3)
                        .frame(width: size.width, height: size.height)
                        .cornerRadius(cornerRadius)
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
            profile.preloadedProfilePhotos = images
            profile.profilePhotoURLs = images.compactMap { $0.url }
        }

        if let userID = try? await SupabaseManager.shared.client.auth.session.user.id {
            await SupabasePhotoUploader.shared.uploadUpdatedPhotos(images, for: userID)
        }
    }

    private func handleDrop(toIndex: Int) -> Bool {
        guard let fromIndex = draggedIndex,
              fromIndex != toIndex,
              fromIndex < images.count,
              toIndex < images.count else {
            draggedIndex = nil
            return false
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            let item = images.remove(at: fromIndex)
            images.insert(item, at: toIndex)
            recalculateMainFlag()
        }

        draggedIndex = nil

        Task.detached {
            guard let userID = try? await SupabaseManager.shared.client.auth.session.user.id else { return }

            await SupabasePhotoUploader.shared.uploadUpdatedPhotos(images, for: userID)

            await MainActor.run {
                profile.preloadedProfilePhotos = images
                profile.profilePhotoURLs = images.compactMap { $0.url }
            }
        }

        return true
    }

    private func recalculateMainFlag() {
        for i in 0..<images.count {
            images[i].isMain = (i == 0)
        }
    }
}
