import Foundation

struct DefaultProductRepository: ProductRepository {
    let client: any HTTPClient

    func fetchPage(skip: Int, limit: Int) async throws -> ProductPage {
        let dto: ProductPageDTO = try await client.request(ProductEndpoint.page(skip: skip, limit: limit))
        return dto.toEntity()
    }

    func fetchDetail(id: Int) async throws -> Product {
        let dto: ProductDetailDTO = try await client.request(ProductEndpoint.detail(id: id))
        return dto.toEntity()
    }
}
