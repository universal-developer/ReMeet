//
//  ImageFetcher.swift
//  ReMeet
//
//  Created by Artush on 19/07/2025.
//

import UIKit

struct ImageFetcher {
    static func loadAndCacheImage(from urlString: String, cacheKey: String? = nil) async -> UIImage? {
        if let key = cacheKey {
            if let cached = ImageCacheManager.shared.getFromRAM(forKey: key) ??
                            ImageCacheManager.shared.loadFromDisk(forKey: key) {
                return cached
            }
        }

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                if let key = cacheKey {
                    ImageCacheManager.shared.setToRAM(image, forKey: key)
                    ImageCacheManager.shared.saveToDisk(image, forKey: key)
                }
                return image
            }
        } catch {
            print("❌ Failed to fetch image: \(error)")
        }

        return nil
    }
}
