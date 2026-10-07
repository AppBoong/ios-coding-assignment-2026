import Foundation
import Testing
@testable import JGNR_HW

struct DefaultLayoutPreferenceRepositoryTests {
    @Test("저장한 보기 모드를 새 인스턴스가 복원한다")
    func persistsAcrossInstances() {
        let store = StubKeyValueStore()
        DefaultLayoutPreferenceRepository(store: store).save(.grid)

        #expect(DefaultLayoutPreferenceRepository(store: store).load() == .grid)
    }
}
