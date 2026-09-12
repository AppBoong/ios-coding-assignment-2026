import Foundation

struct ProductSummary: Sendable, Identifiable, Equatable {
    let id: Int
    let title: String
    let price: Double
    let thumbnailURL: URL?
}
