import Foundation

struct ToggleFavoriteUseCase: Sendable {
    let repository: any FavoriteRepository

    func execute(id: Int) async {
        await repository.toggle(id: id)
    }
}
