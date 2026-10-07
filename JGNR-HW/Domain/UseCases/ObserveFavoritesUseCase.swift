import Foundation

struct ObserveFavoritesUseCase: Sendable {
    let repository: any FavoriteRepository

    func execute() async -> AsyncStream<Set<Int>> {
        await repository.observe()
    }
}
