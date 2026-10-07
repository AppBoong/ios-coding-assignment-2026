import Foundation

struct ProductDetailDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    let brand: String?
    let thumbnail: String
    let images: [String]

    func toEntity() -> Product {
        Product(
            id: id,
            title: title,
            description: description,
            category: category,
            price: price,
            discountRate: discountPercentage,
            rating: rating,
            stock: stock,
            brand: brand,
            thumbnailURL: URL(string: thumbnail),
            imageURLs: images.compactMap(URL.init(string:))
        )
    }
}
