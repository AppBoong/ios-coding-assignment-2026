import Foundation
@testable import JGNR_HW

actor StubProductRepository: ProductRepository {
    enum Failure: Error, Sendable {
        case noResult
    }

    struct PageCall: Equatable, Sendable {
        let skip: Int
        let limit: Int
    }

    private(set) var fetchPageCalls: [PageCall] = []
    private(set) var fetchDetailCalls: [Int] = []
    private var pageResults: [Result<ProductPage, any Error & Sendable>]
    private var detailResult: Result<Product, any Error & Sendable>
    private var pageDelay: Duration = .zero

    init(
        pageResults: [Result<ProductPage, any Error & Sendable>] = [],
        detailResult: Result<Product, any Error & Sendable> = .failure(Failure.noResult)
    ) {
        self.pageResults = pageResults
        self.detailResult = detailResult
    }

    func setPageResults(_ results: [Result<ProductPage, any Error & Sendable>]) {
        pageResults = results
    }

    func setDetailResult(_ result: Result<Product, any Error & Sendable>) {
        detailResult = result
    }

    func setPageDelay(_ delay: Duration) {
        pageDelay = delay
    }

    func fetchPage(skip: Int, limit: Int) async throws -> ProductPage {
        fetchPageCalls.append(PageCall(skip: skip, limit: limit))
        if pageDelay > .zero {
            try await Task.sleep(for: pageDelay)
        }
        guard let result = pageResults.first else {
            throw Failure.noResult
        }
        if pageResults.count > 1 {
            pageResults.removeFirst()
        }
        return try result.get()
    }

    func fetchDetail(id: Int) async throws -> Product {
        fetchDetailCalls.append(id)
        return try detailResult.get()
    }
}
