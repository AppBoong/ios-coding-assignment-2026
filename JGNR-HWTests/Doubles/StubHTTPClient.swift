import Foundation
@testable import JGNR_HW

actor StubHTTPClient: HTTPClient {
    private var result: Result<Data, any Error & Sendable>
    private(set) var requestedEndpoints: [Endpoint] = []

    init(result: Result<Data, any Error & Sendable> = .success(Data())) {
        self.result = result
    }

    func setResult(_ result: Result<Data, any Error & Sendable>) {
        self.result = result
    }

    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        requestedEndpoints.append(endpoint)
        let data = try result.get()
        return try JSONDecoder().decode(T.self, from: data)
    }
}
