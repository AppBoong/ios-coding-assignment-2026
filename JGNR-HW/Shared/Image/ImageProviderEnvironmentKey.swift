import SwiftUI

private struct ImageProviderEnvironmentKey: EnvironmentKey {
    // @MainActor 타입은 nonisolated 기본값이 될 수 없어 옵셔널로 둔다 — 실제 인스턴스는 AppDependencies가 1개 생성해 주입한다
    static let defaultValue: ImageProvider? = nil
}

extension EnvironmentValues {
    var imageProvider: ImageProvider? {
        get { self[ImageProviderEnvironmentKey.self] }
        set { self[ImageProviderEnvironmentKey.self] = newValue }
    }
}
