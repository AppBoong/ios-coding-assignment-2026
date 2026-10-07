import UIKit

// 메모리 캐시를 MainActor에 가둔다 — 뷰가 MainActor라 캐시 히트를 동기로 읽을 수 있고,
// NSCache를 Sendable로 우회하지 않아도 된다. 디스크·네트워크·중복 요청 병합은 ImageLoader가 담당한다
@MainActor
final class ImageProvider {
    private let cache = NSCache<NSURL, UIImage>()
    private let loader: ImageLoader

    init(loader: ImageLoader, countLimit: Int = 200, totalCostLimit: Int = 50_000_000) {
        self.loader = loader
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = cachedImage(for: url) { return cached }
        let image = try await loader.image(for: url)
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)
        return image
    }
}
