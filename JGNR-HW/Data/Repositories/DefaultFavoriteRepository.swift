import Foundation

@MainActor
final class DefaultFavoriteRepository: FavoriteRepository {
    private let dataSource: FavoriteLocalDataSource
    private var favoriteIDs: Set<Int>
    private var continuations: [UUID: AsyncStream<Set<Int>>.Continuation] = [:]

    init(dataSource: FavoriteLocalDataSource) {
        self.dataSource = dataSource
        self.favoriteIDs = dataSource.load()
    }

    func toggle(id: Int) async {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        dataSource.save(favoriteIDs)
        broadcast()
    }

    func observe() async -> AsyncStream<Set<Int>> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            continuation.yield(favoriteIDs)
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.continuations[id] = nil
                }
            }
        }
    }

    private func broadcast() {
        for continuation in continuations.values {
            continuation.yield(favoriteIDs)
        }
    }
}
