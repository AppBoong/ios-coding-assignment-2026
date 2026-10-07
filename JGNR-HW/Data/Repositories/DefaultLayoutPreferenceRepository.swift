import Foundation

struct DefaultLayoutPreferenceRepository: LayoutPreferenceRepository {
    let store: any KeyValueStore

    func load() -> ProductListLayoutMode? {
        store.value(ProductListLayoutMode.self, for: .productListLayoutMode)
    }

    func save(_ mode: ProductListLayoutMode) {
        store.set(mode, for: .productListLayoutMode)
    }
}
