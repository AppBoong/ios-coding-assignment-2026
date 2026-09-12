import Foundation

struct Product: Sendable, Identifiable, Equatable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let discountRate: Double
    let rating: Double
    let stock: Int
    let brand: String?
    let thumbnailURL: URL?
    let imageURLs: [URL]
}
