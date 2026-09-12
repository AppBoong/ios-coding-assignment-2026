import Testing
@testable import JGNR_HW

struct LoadLayoutModeUseCaseTests {
    @Test("저장값이 있으면 그 값을 반환한다")
    func returnsStoredMode() {
        let useCase = LoadLayoutModeUseCase(repository: StubLayoutPreferenceRepository(storedMode: .grid))

        #expect(useCase.execute() == .grid)
    }

    @Test("저장값이 없으면 기본값을 반환한다")
    func returnsDefaultModeWhenNothingStored() {
        let useCase = LoadLayoutModeUseCase(repository: StubLayoutPreferenceRepository())

        #expect(useCase.execute() == .list)
    }
}
