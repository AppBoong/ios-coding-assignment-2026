import Foundation

protocol FavoriteRepository: Sendable {
    func toggle(id: Int) async
    func observe() async -> AsyncStream<Set<Int>>
}
