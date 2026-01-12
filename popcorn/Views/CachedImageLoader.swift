import Foundation
import UIKit

@MainActor
final class CachedImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var currentURL: URL?
    private var task: Task<Void, Never>?

    func load(url: URL?) {
        guard currentURL != url else { return }
        task?.cancel()
        currentURL = url
        image = nil

        guard let url else { return }
        task = Task { [weak self] in
            let fetched = await ImagePipeline.shared.image(for: url)
            guard let self, !Task.isCancelled, self.currentURL == url else { return }
            self.image = fetched
        }
    }

    func cancel() {
        task?.cancel()
    }
}
