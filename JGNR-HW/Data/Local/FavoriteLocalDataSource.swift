import Foundation

struct FavoriteLocalDataSource: Sendable {
    let store: any KeyValueStore

    func load() -> Set<Int> {
        Set(store.value([Int].self, for: .favoriteIDs) ?? [])
    }

    func save(_ ids: Set<Int>) {
        // 찜 ID를 정렬된 JSON [Int]로 인코딩 — 사람이 읽을 수 있고 순서가 안정적이라 diff·디버깅이 쉬움
        store.set(ids.sorted(), for: .favoriteIDs)
    }
}
