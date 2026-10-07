import Foundation

struct ProductPage: Sendable, Equatable {
    let items: [ProductSummary]
    let total: Int
    let skip: Int
    let limit: Int
}
