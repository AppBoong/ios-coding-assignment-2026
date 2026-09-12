import Foundation

struct FetchProductDetailUseCase: Sendable {
    let repository: any ProductRepository

    func execute(id: Int) async throws -> Product {
        try await repository.fetchDetail(id: id)
    }
}
