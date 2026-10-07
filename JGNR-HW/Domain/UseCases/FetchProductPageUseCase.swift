import Foundation

struct FetchProductPageUseCase: Sendable {
    let repository: any ProductRepository

    func execute(skip: Int, limit: Int) async throws -> ProductPage {
        try await repository.fetchPage(skip: skip, limit: limit)
    }
}
