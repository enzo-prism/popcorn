import Foundation
import UIKit

actor ImagePipeline {
    static let shared = ImagePipeline()

    private let memoryCache = ImageCache.shared
    private let diskCache = ImageDiskCache()
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    func image(for url: URL) async -> UIImage? {
        if let cached = memoryCache.image(for: url) {
            return cached
        }
        if let cached = await diskCache.image(for: url) {
            memoryCache.insert(cached, for: url)
            return cached
        }
        if let task = inFlight[url] {
            return await task.value
        }

        let task = Task { [diskCache] () -> UIImage? in
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                guard let image = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                await diskCache.insert(data: data, for: url)
                ImageCache.shared.insert(image, for: url)
                return image
            } catch {
#if DEBUG
                print("Image fetch failed \(url): \(error)")
#endif
                return nil
            }
        }

        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        return image
    }

    func prefetch(_ urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = await self.image(for: url)
                }
            }
        }
    }
}
