import Foundation

extension KeyValueStore {
    func value<T: Decodable>(_ type: T.Type, for key: LocalStorageKey) -> T? {
        guard let data = data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func set<T: Encodable>(_ value: T?, for key: LocalStorageKey) {
        guard let value else {
            set(nil, forKey: key.rawValue)
            return
        }
        guard let data = try? JSONEncoder().encode(value) else { return }
        set(data, forKey: key.rawValue)
    }
}
