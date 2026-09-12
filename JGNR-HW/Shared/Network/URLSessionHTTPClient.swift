import Foundation

struct URLSessionHTTPClient: HTTPClient {
    private let baseComponents: URLComponents
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseComponents: URLComponents = .dummyJSON, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.baseComponents = baseComponents
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        var components = baseComponents
        components.path = endpoint.path.hasPrefix("/") ? endpoint.path : "/\(endpoint.path)"
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: URLRequest(url: url))
        } catch {
            throw NetworkError.transport(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.transport("Non-HTTP response")
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw NetworkError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(String(describing: error))
        }
    }
}

extension URLComponents {
    static var dummyJSON: URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "dummyjson.com"
        return components
    }
}
