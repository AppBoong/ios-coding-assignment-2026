import Foundation

enum NetworkError: Error, Sendable, Equatable {
    case invalidURL
    case transport(String)
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case requestTimeout
    case conflict
    case tooManyRequests
    case clientError(Int)
    case serverError(Int)
    case unexpectedStatus(Int)
    case decoding(String)

    init(statusCode: Int) {
        switch statusCode {
        case 400:
            self = .badRequest
        case 401:
            self = .unauthorized
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        case 408:
            self = .requestTimeout
        case 409:
            self = .conflict
        case 429:
            self = .tooManyRequests
        case 400..<500:
            self = .clientError(statusCode)
        case 500..<600:
            self = .serverError(statusCode)
        default:
            self = .unexpectedStatus(statusCode)
        }
    }
}
