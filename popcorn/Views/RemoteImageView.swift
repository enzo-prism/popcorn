import SwiftUI
import UIKit

struct RemoteImageView: View {
    let url: URL?

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black.opacity(0.08)
            }
        }
        .task(id: url) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        guard let url else {
            image = nil
            return
        }

        if let cached = ImageCache.shared.image(for: url) {
            image = cached
            return
        }

        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let uiImage = UIImage(data: data) else {
                return
            }
            ImageCache.shared.insert(uiImage, for: url)
            image = uiImage
        } catch {
            return
        }
    }
}

#Preview {
    RemoteImageView(url: nil)
        .frame(width: 200, height: 280)
}
