import Foundation
import os
import UIKit

final class StubImageURLProtocol: URLProtocol {
    static let state = OSAllocatedUnfairLock<[URL: Int]>(initialState: [:])

    static let pngData: Data = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }()

    static func requestCount(for url: URL) -> Int {
        state.withLock { $0[url] ?? 0 }
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubImageURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.state.withLock { $0[url, default: 0] += 1 }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: Self.pngData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
