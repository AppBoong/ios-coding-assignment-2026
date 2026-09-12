import Foundation

protocol ProductRepository: Sendable {
    func fetchPage(skip: Int, limit: Int) async throws -> ProductPage
    func fetchDetail(id: Int) async throws -> Product
}
