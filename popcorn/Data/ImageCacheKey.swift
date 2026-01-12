import CryptoKit
import Foundation

enum ImageCacheKey {
    static func fileName(for url: URL) -> String {
        let data = Data(url.absoluteString.utf8)
        let digest = SHA256.hash(data: data)
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        return "\(hash).img"
    }
}
