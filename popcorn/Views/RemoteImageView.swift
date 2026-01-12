import SwiftUI
import UIKit

struct RemoteImageView<Placeholder: View>: View {
    let url: URL?
    let placeholder: Placeholder
    @StateObject private var loader = CachedImageLoader()

    init(url: URL?, @ViewBuilder placeholder: () -> Placeholder = { Color.black.opacity(0.08) }) {
        self.url = url
        self.placeholder = placeholder()
    }

    var body: some View {
        ZStack {
            placeholder
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .onAppear {
            loader.load(url: url)
        }
        .onChange(of: url) { newValue in
            loader.load(url: newValue)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

#Preview {
    RemoteImageView(url: nil)
        .frame(width: 200, height: 280)
}
