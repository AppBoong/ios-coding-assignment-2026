import Foundation

struct ProductPageDTO: Decodable, Sendable {
    let products: [ProductSummaryDTO]
    let total: Int
    let skip: Int
    let limit: Int

    func toEntity() -> ProductPage {
        ProductPage(
            items: products.map { $0.toEntity() },
            total: total,
            skip: skip,
            limit: limit
        )
    }
}
