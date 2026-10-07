import Foundation
import os
@testable import JGNR_HW

final class StubKeyValueStore: KeyValueStore {
    private let storage = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])

    func data(forKey key: String) -> Data? {
        storage.withLock { $0[key] }
    }

    func set(_ data: Data?, forKey key: String) {
        storage.withLock { state in
            if let data {
                state[key] = data
            } else {
                state.removeValue(forKey: key)
            }
        }
    }
}
