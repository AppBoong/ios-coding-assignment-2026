import Foundation
import Testing
@testable import JGNR_HW

struct URLSessionHTTPClientTests {
    private struct Payload: Decodable, Sendable {
        let ok: Bool
    }

    @Test("요청 취소는 네트워크 에러가 아니라 CancellationError로 전달된다")
    func convertsURLSessionCancellationToCancellationError() async throws {
        let client = URLSessionHTTPClient(session: StubHangingURLProtocol.makeSession())
        let task = Task<Payload, any Error> {
            try await client.request(Endpoint(path: "products"))
        }

        task.cancel()

        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
    }
}
