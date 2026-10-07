import Foundation

struct ProductSummaryDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let price: Double
    let thumbnail: String

    func toEntity() -> ProductSummary {
        ProductSummary(
            id: id,
            title: title,
            price: price,
            thumbnailURL: URL(string: thumbnail)
        )
    }
}
