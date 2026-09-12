import Foundation
import Testing
@testable import JGNR_HW

struct ProductDTOMappingTests {
    private static let pageJSON = """
    {
        "products": [
            {"id": 1, "title": "Essence Mascara", "price": 9.99, "thumbnail": "https://example.com/1.jpg"},
            {"id": 2, "title": "Eyeshadow Palette", "price": 19.99, "thumbnail": "https://example.com/2.jpg"}
        ],
        "total": 194,
        "skip": 0,
        "limit": 2
    }
    """

    private static let detailJSON = """
    {
        "id": 1,
        "title": "Essence Mascara",
        "description": "The Essence Mascara Lash Princess",
        "category": "beauty",
        "price": 9.99,
        "discountPercentage": 7.17,
        "rating": 4.94,
        "stock": 5,
        "thumbnail": "https://example.com/1.jpg",
        "images": ["https://example.com/1.jpg", ""]
    }
    """

    @Test("페이지 DTO가 ProductPage로 매핑된다")
    func pageMapping() throws {
        let pageDTO = try JSONDecoder().decode(ProductPageDTO.self, from: Data(Self.pageJSON.utf8))
        let page = pageDTO.toEntity()
        #expect(page.items.count == 2)
        #expect(page.total == 194)
        #expect(page.skip == 0)
        #expect(page.limit == 2)
        #expect(page.items.first?.thumbnailURL == URL(string: "https://example.com/1.jpg"))
    }

    @Test("상세 DTO가 Product로 매핑된다 — brand 누락·잘못된 이미지 URL 제외")
    func detailMapping() throws {
        let detailDTO = try JSONDecoder().decode(ProductDetailDTO.self, from: Data(Self.detailJSON.utf8))
        let product = detailDTO.toEntity()
        #expect(product.discountRate == detailDTO.discountPercentage)
        #expect(product.brand == nil)
        #expect(product.imageURLs.count == 1)
        #expect(product.thumbnailURL == URL(string: "https://example.com/1.jpg"))
    }

    @Test("원격 리포지토리가 목록 엔드포인트에 select 쿼리를 보낸다")
    func pageEndpointQuery() async throws {
        let httpClient = StubHTTPClient(result: .success(Data(Self.pageJSON.utf8)))
        let repository = DefaultProductRepository(client: httpClient)
        _ = try await repository.fetchPage(skip: 0, limit: 2)
        let requestedEndpoint = await httpClient.requestedEndpoints.first
        let endpoint = try #require(requestedEndpoint)
        #expect(endpoint.path == "products")
        #expect(endpoint.queryItems.contains { $0.name == "select" && $0.value == "id,title,price,thumbnail" })
        #expect(endpoint.queryItems.contains { $0.name == "limit" })
        #expect(endpoint.queryItems.contains { $0.name == "skip" })
    }
}
