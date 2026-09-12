import Foundation

protocol LayoutPreferenceRepository: Sendable {
    func load() -> ProductListLayoutMode?
    func save(_ mode: ProductListLayoutMode)
}
