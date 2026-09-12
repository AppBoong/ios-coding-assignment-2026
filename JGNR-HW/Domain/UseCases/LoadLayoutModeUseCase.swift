import Foundation

struct LoadLayoutModeUseCase: Sendable {
    let repository: any LayoutPreferenceRepository

    func execute() -> ProductListLayoutMode? {
        repository.load()
    }
}
