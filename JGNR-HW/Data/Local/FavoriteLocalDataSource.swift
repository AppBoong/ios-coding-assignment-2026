import Foundation

struct FavoriteLocalDataSource: Sendable {
    static let key = "favorite.productIDs"

    let store: any KeyValueStore

    func load() -> Set<Int> {
        guard let data = store.data(forKey: Self.key),
              let ids = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return Set(ids)
    }

    func save(_ ids: Set<Int>) {
        // 찜 ID를 정렬된 JSON [Int]로 인코딩 — 사람이 읽을 수 있고 순서가 안정적이라 diff·디버깅이 쉬움
        guard let data = try? JSONEncoder().encode(ids.sorted()) else { return }
        store.set(data, forKey: Self.key)
    }
}
