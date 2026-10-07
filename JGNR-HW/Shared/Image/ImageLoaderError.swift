import Foundation

enum ImageLoaderError: Error, Equatable, Sendable {
    case invalidResponse
    case decodingFailed
}
