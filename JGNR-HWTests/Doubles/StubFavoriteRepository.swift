import Foundation
@testable import JGNR_HW

@MainActor
final class StubFavoriteRepository: FavoriteRepository {
    private(set) var favoriteIDs: Set<Int>
    private(set) var toggledIDs: [Int] = []
    private var continuations: [UUID: AsyncStream<Set<Int>>.Continuation] = [:]

    init(favoriteIDs: Set<Int> = []) {
        self.favoriteIDs = favoriteIDs
    }

    func toggle(id: Int) async {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        toggledIDs.append(id)
        broadcast()
    }

    func observe() async -> AsyncStream<Set<Int>> {
        let id = UUID()
        return AsyncStream { continuation in
            continuation.yield(favoriteIDs)
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.continuations[id] = nil
                }
            }
        }
    }

    func emit(_ ids: Set<Int>) {
        favoriteIDs = ids
        broadcast()
    }

    private func broadcast() {
        for continuation in continuations.values {
            continuation.yield(favoriteIDs)
        }
    }
}
