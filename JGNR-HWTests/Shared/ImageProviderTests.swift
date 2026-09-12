import Foundation
import Testing
@testable import JGNR_HW

@Suite @MainActor
struct ImageProviderTests {
    @Test("비동기 로드가 끝나면 동기 캐시 조회로 같은 이미지를 즉시 얻을 수 있다")
    func cachesImageForSynchronousLookupAfterLoad() async throws {
        let directoryName = "ImageCacheTests-\(UUID().uuidString)"
        let url = try #require(URL(string: "https://stub.test/\(UUID().uuidString).png"))
        let loader = ImageLoader(session: StubImageURLProtocol.makeSession(), directoryName: directoryName)
        let provider = ImageProvider(loader: loader)

        #expect(provider.cachedImage(for: url) == nil)
        _ = try await provider.image(for: url)
        #expect(provider.cachedImage(for: url) != nil)

        try? FileManager.default.removeItem(at: URL.cachesDirectory.appending(path: directoryName))
    }
}
