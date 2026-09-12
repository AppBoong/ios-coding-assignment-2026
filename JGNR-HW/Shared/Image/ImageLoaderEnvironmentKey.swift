import SwiftUI

private struct ImageLoaderEnvironmentKey: EnvironmentKey {
    // 프리뷰 전용 폴백 — 실제 인스턴스는 AppDependencies가 1개 생성해 .environment(\.imageLoader, ...)로 주입한다
    static let defaultValue = ImageLoader()
}

extension EnvironmentValues {
    var imageLoader: ImageLoader {
        get { self[ImageLoaderEnvironmentKey.self] }
        set { self[ImageLoaderEnvironmentKey.self] = newValue }
    }
}
