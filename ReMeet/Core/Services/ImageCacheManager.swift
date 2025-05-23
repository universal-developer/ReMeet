//
//  ImageCacheManager.swift
//  ReMeet
//
//  Created by Artush on 17/05/2025.
//

import UIKit
import CryptoKit

struct ImageItem: Identifiable, Equatable {
    let id = UUID()
    var image: UIImage
    var isMain: Bool = false
    var url: String? = nil  // Optional to support local-only images

    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }
}


final class ImageCacheManager {
    static let shared = ImageCacheManager()
    private init() {}

    private let ramCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default

    // MARK: - RAM
    func setToRAM(_ image: UIImage, forKey key: String) {
        ramCache.setObject(image, forKey: key as NSString)
    }

    func getFromRAM(forKey key: String) -> UIImage? {
        ramCache.object(forKey: key as NSString)
    }

    // MARK: - Disk
    private func getFilePath(forKey key: String) -> URL? {
        guard let docs = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docs.appendingPathComponent("\(key).jpg")
    }

    func saveToDisk(_ image: UIImage, forKey key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8),
              let filePath = getFilePath(forKey: key) else { return }

        try? data.write(to: filePath)
    }

    func loadFromDisk(forKey key: String) -> UIImage? {
        guard let filePath = getFilePath(forKey: key),
              fileManager.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath) else { return nil }

        return UIImage(data: data)
    }

    func loadDataFromDisk(forKey key: String) -> Data? {
        guard let filePath = getFilePath(forKey: key),
              fileManager.fileExists(atPath: filePath.path) else { return nil }

        return try? Data(contentsOf: filePath)
    }

    func removeFromDisk(forKey key: String) {
        guard let filePath = getFilePath(forKey: key) else { return }
        try? fileManager.removeItem(at: filePath)
    }

    // MARK: - Hash Check
    func sha256(of data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    func hasDifferentContentThanDisk(data: Data, forKey key: String) -> Bool {
        guard let localData = loadDataFromDisk(forKey: key) else {
            return true
        }
        return sha256(of: localData) != sha256(of: data)
    }
    
    func stableHash(for string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

}
