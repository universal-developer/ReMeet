//
//
//  SupabasePhotoUploader.swift
//  ReMeet
//
//  Created by Artush on 22/05/2025.

import Foundation
import UIKit
import Supabase

struct SupabaseUserPhoto: Codable {
    let user_id: UUID
    let url: String
    var is_main: Bool
    let sort_order: Int
}

struct PhotoUploadPayload: Encodable {
    let p_data: [SupabaseUserPhoto]
}

class SupabasePhotoUploader {
    static let shared = SupabasePhotoUploader()
    private let bucket = "user-photos"
    private let table = "user_photos"

    private init() {}

    private var debounceTask: Task<Void, Never>?

    func uploadUpdatedPhotos(_ incomingImages: [ImageItem], for userID: UUID) async {
        print("📸 Starting upload for \(incomingImages.count) images...")

        do {
            // Step 1: Upload images in parallel
            typealias UploadResult = (index: Int, url: String)
            var uploadResults: [UploadResult] = []

            await withTaskGroup(of: UploadResult?.self) { group in
                for (index, imageItem) in incomingImages.enumerated() {
                    print("📤 Preparing image #\(index) - isMain: \(imageItem.isMain)")

                    group.addTask {
                        guard let uiImage = imageItem.image,
                              let data = uiImage.jpegData(compressionQuality: 0.4) else {
                            print("❌ [\(index)] Skipped: Missing image data")
                            return nil
                        }
                        
                        let fileName = "\(userID.uuidString)/photo_\(index)_\(UUID().uuidString).jpg"
                        let publicURL = "\(SupabaseManager.shared.publicStorageUrlBase)/\(self.bucket)/\(fileName)"

                        do {
                            try await SupabaseManager.shared.client.storage
                                .from(self.bucket)
                                .upload(
                                    path: fileName,
                                    file: data,
                                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                                )

                            print("✅ [\(index)] Uploaded to \(publicURL)")
                            return (index, publicURL)

                        } catch {
                            print("❌ [\(index)] Upload failed: \(error.localizedDescription)")
                            return nil
                        }
                    }
                }

                for await result in group {
                    if let item = result {
                        uploadResults.append(item)
                    }
                }
            }

            print("📦 Finished uploads. Processing \(uploadResults.count) successful items...")

            // Step 2: Build DB records aligned with original input
            var photoRecords: [SupabaseUserPhoto] = []

            for result in uploadResults.sorted(by: { $0.index < $1.index }) {
                let imageItem = incomingImages[result.index]

                print("📝 Preparing DB record [\(result.index)] isMain: \(imageItem.isMain) url: \(result.url)")

                photoRecords.append(SupabaseUserPhoto(
                    user_id: userID,
                    url: result.url,
                    is_main: imageItem.isMain,
                    sort_order: result.index
                ))
            }

            // Step 3: Guarantee exactly one main photo
            let mainCount = photoRecords.filter(\.is_main).count
            if mainCount != 1 {
                print("⚠️ Found \(mainCount) main photos! Fixing to ensure exactly 1.")
                for i in 0..<photoRecords.count {
                    photoRecords[i].is_main = (i == 0)
                }
            }

            print("📤 Final DB photo records:")
            for (i, record) in photoRecords.enumerated() {
                print("   \(i): \(record.url) | isMain: \(record.is_main)")
            }

            // Step 4: Send to Supabase RPC
            let payload = PhotoUploadPayload(p_data: photoRecords)

            try await SupabaseManager.shared.client
                .rpc("overwrite_user_photos", params: payload)
                .execute()

            print("✅ RPC overwrite_user_photos executed successfully")

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
    
    func imagesHaveChanged(original: [ImageItem], current: [ImageItem]) -> Bool {
        guard original.count == current.count else { return true }
        for (a, b) in zip(original, current) {
            if a != b || a.isMain != b.isMain {
                return true
            }
        }
        return false
    }

}
