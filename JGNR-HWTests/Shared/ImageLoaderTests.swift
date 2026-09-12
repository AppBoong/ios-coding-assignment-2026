import Foundation
import Testing
@testable import JGNR_HW

struct ImageLoaderTests {
    @Test("같은 URL 동시 요청은 네트워크를 1회만 탄다")
    func mergesInFlightRequests() async throws {
        let directoryName = "ImageCacheTests-\(UUID().uuidString)"
        let url = try #require(URL(string: "https://stub.test/\(UUID().uuidString).png"))
        let loader = ImageLoader(session: StubImageURLProtocol.makeSession(), directoryName: directoryName)

        async let first = loader.image(for: url)
        async let second = loader.image(for: url)
        _ = try await (first, second)
        #expect(StubImageURLProtocol.requestCount(for: url) == 1)

        _ = try await loader.image(for: url)
        #expect(StubImageURLProtocol.requestCount(for: url) == 1)

        try? FileManager.default.removeItem(at: URL.cachesDirectory.appending(path: directoryName))
    }

    @Test("디스크 캐시는 한 번만 저장되고 새 인스턴스가 네트워크 없이 재사용한다")
    func reusesDiskCache() async throws {
        let directoryName = "ImageCacheTests-\(UUID().uuidString)"
        let url = try #require(URL(string: "https://stub.test/\(UUID().uuidString).png"))
        let cacheDirectory = URL.cachesDirectory.appending(path: directoryName)

        let loader1 = ImageLoader(session: StubImageURLProtocol.makeSession(), directoryName: directoryName)
        _ = try await loader1.image(for: url)
        let filesAfterFirstLoad = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        #expect(filesAfterFirstLoad.count == 1)

        let loader2 = ImageLoader(session: StubImageURLProtocol.makeSession(), directoryName: directoryName)
        _ = try await loader2.image(for: url)
        #expect(StubImageURLProtocol.requestCount(for: url) == 1)
        let filesAfterSecondLoad = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        #expect(filesAfterSecondLoad.count == 1)

        try? FileManager.default.removeItem(at: cacheDirectory)
    }
}
