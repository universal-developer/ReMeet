//
//  SupabasePhotoUploader.swift
//  ReMeet
//
//  Created by ChatGPT on 22/05/2025.

import Foundation
import UIKit
import Supabase

struct SupabaseUserPhoto: Codable {
    let user_id: UUID
    let url: String
    let is_main: Bool
}

class SupabasePhotoUploader {
    static let shared = SupabasePhotoUploader()
    private let bucket = "user-photos"
    private let table = "user_photos"

    private init() {}

    private var debounceTask: Task<Void, Never>?

    func uploadUpdatedPhotos(_ incomingImages: [ImageItem], for userID: UUID) async {
        var images = incomingImages // make mutable copy to allow mutation

        do {
            // Ensure exactly one image is marked as main
            let mainCount = images.filter { $0.isMain }.count
            if mainCount != 1 {
                for i in 0..<images.count {
                    images[i].isMain = (i == 0)
                }
            }

            // 1. Delete old records
            try await SupabaseManager.shared.client.database.from(table)
                .delete()
                .eq("user_id", value: userID.uuidString)
                .execute()

            print("🧹 Deleted existing user photo rows")

            for (index, imageItem) in images.enumerated() {
                guard let data = imageItem.image.jpegData(compressionQuality: 0.4) else {
                    print("⚠️ Could not convert image #\(index)")
                    continue
                }

                let fileName = "\(userID.uuidString)/photo_\(index)_\(UUID().uuidString).jpg"

                // Upload to Supabase storage
                try await SupabaseManager.shared.client.storage
                    .from(bucket)
                    .upload(path: fileName, file: data, options: FileOptions(contentType: "image/jpeg", upsert: true))

                let publicURL = "\(SupabaseManager.shared.publicStorageUrlBase)/\(bucket)/\(fileName)"
                let photo = SupabaseUserPhoto(user_id: userID, url: publicURL, is_main: imageItem.isMain)

                try await SupabaseManager.shared.client.database.from(table)
                    .insert([photo], returning: .minimal)
                    .execute()

                print("✅ Saved photo #\(index)")
            }

            print("🎉 All profile photos updated on Supabase")
        } catch {
            print("❌ Upload failed: \(error.localizedDescription)")
        }
    }

        func syncPhotosIfChanged(current: [ImageItem], original: [ImageItem], userID: UUID) {
        debounceTask?.cancel()
        debounceTask = Task(priority: .background) { [originalCopy = original] in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second debounce
            guard imagesHaveChanged(original: originalCopy, current: current) else { return }
            await self.uploadUpdatedPhotos(current, for: userID)
        }
    }
}
