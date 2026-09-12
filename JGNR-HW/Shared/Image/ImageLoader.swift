import CryptoKit
import Foundation
import UIKit

actor ImageLoader {
    static let cacheDirectoryName = "ImageCache"

    private let session: URLSession
    private let fileManager = FileManager.default
    private let directory: URL
    private let memoryCache = NSCache<NSURL, UIImage>()
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    init(
        session: URLSession = .shared,
        directoryName: String = ImageLoader.cacheDirectoryName,
        countLimit: Int = 200,
        totalCostLimit: Int = 50_000_000
    ) {
        self.session = session
        directory = URL.cachesDirectory.appending(path: directoryName)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        memoryCache.countLimit = countLimit
        memoryCache.totalCostLimit = totalCostLimit
    }

    // 같은 URL에 대한 동시 요청은 진행 중인 Task 하나를 함께 기다려 중복 다운로드를 막는다
    func image(for url: URL) async throws -> UIImage {
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached
        }
        if let running = inFlight[url] {
            return try await running.value
        }
        let task = Task { try await fetch(url) }
        inFlight[url] = task
        defer { inFlight[url] = nil }
        let image = try await task.value
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        memoryCache.setObject(image, forKey: url as NSURL, cost: cost)
        return image
    }

    private nonisolated func fetch(_ url: URL) async throws -> UIImage {
        let file = fileURL(for: url)
        if let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            return image
        }
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw ImageLoaderError.invalidResponse
        }
        guard let image = UIImage(data: data) else {
            throw ImageLoaderError.decodingFailed
        }
        try? data.write(to: file, options: .atomic)
        return image
    }

    // URL 문자열을 그대로 파일명으로 쓰면 경로 구분자·길이 제한에 걸리므로 SHA256 해시로 고정 길이 이름을 만든다
    private nonisolated func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: name)
    }
}
