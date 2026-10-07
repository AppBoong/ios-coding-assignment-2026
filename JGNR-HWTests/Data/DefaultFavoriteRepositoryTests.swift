import Foundation
import Testing
@testable import JGNR_HW

@Suite @MainActor
struct DefaultFavoriteRepositoryTests {
    @Test("토글 후 저장되고 새 인스턴스가 복원한다")
    func persistsAcrossInstances() async throws {
        let store = StubKeyValueStore()
        let repository1 = DefaultFavoriteRepository(dataSource: FavoriteLocalDataSource(store: store))
        await repository1.toggle(id: 7)

        let repository2 = DefaultFavoriteRepository(dataSource: FavoriteLocalDataSource(store: store))
        var iterator = await repository2.observe().makeAsyncIterator()
        let first = await iterator.next()
        #expect(first == [7])
    }

    @Test("구독자 2개가 토글 1회에 같은 Set을 받는다")
    func broadcastsToAllSubscribers() async throws {
        let store = StubKeyValueStore()
        let repository = DefaultFavoriteRepository(dataSource: FavoriteLocalDataSource(store: store))

        var iterator1 = await repository.observe().makeAsyncIterator()
        var iterator2 = await repository.observe().makeAsyncIterator()
        _ = await iterator1.next()
        _ = await iterator2.next()

        await repository.toggle(id: 3)

        let next1 = await iterator1.next()
        let next2 = await iterator2.next()
        #expect(next1 == [3])
        #expect(next2 == [3])
    }
}
