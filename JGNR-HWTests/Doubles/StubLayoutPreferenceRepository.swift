import Foundation
import os
@testable import JGNR_HW

final class StubLayoutPreferenceRepository: LayoutPreferenceRepository {
    private struct State {
        var storedMode: ProductListLayoutMode?
        var savedModes: [ProductListLayoutMode] = []
    }

    private let state: OSAllocatedUnfairLock<State>

    init(storedMode: ProductListLayoutMode? = nil) {
        state = OSAllocatedUnfairLock(initialState: State(storedMode: storedMode))
    }

    var storedMode: ProductListLayoutMode? {
        state.withLock { $0.storedMode }
    }

    var savedModes: [ProductListLayoutMode] {
        state.withLock { $0.savedModes }
    }

    func load() -> ProductListLayoutMode? {
        state.withLock { $0.storedMode }
    }

    func save(_ mode: ProductListLayoutMode) {
        state.withLock { state in
            state.storedMode = mode
            state.savedModes.append(mode)
        }
    }
}
