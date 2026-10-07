import Foundation

struct SaveLayoutModeUseCase: Sendable {
    let repository: any LayoutPreferenceRepository

    func execute(_ mode: ProductListLayoutMode) {
        repository.save(mode)
    }
}
