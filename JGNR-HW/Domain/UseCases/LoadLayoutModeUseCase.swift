import Foundation

struct LoadLayoutModeUseCase: Sendable {
    let repository: any LayoutPreferenceRepository

    // 저장값이 없을 때의 기본 보기 모드는 렌더링 방식이 아니라 제품 규칙이므로 도메인에서 결정한다
    func execute() -> ProductListLayoutMode {
        repository.load() ?? .list
    }
}
