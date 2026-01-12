import Foundation
import UIKit

actor ImageDiskCache {
    private let directoryURL: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let baseURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        directoryURL = baseURL.appendingPathComponent("PopcornImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func image(for url: URL) async -> UIImage? {
        let fileURL = directoryURL.appendingPathComponent(ImageCacheKey.fileName(for: url))
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func insert(data: Data, for url: URL) async {
        let fileURL = directoryURL.appendingPathComponent(ImageCacheKey.fileName(for: url))
        try? data.write(to: fileURL, options: .atomic)
    }
}
