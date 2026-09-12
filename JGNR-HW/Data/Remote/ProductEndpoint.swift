import Foundation

enum ProductEndpoint {
    static let summaryFields = "id,title,price,thumbnail"

    static func page(skip: Int, limit: Int) -> Endpoint {
        Endpoint(
            path: "products",
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "skip", value: String(skip)),
                URLQueryItem(name: "select", value: summaryFields)
            ]
        )
    }

    static func detail(id: Int) -> Endpoint {
        Endpoint(path: "products/\(id)")
    }
}
