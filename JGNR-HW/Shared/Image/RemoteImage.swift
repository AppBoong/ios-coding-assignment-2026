import SwiftUI

struct RemoteImage<Content: View, Placeholder: View>: View {
    @Environment(\.imageProvider) private var imageProvider
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @State private var loaded: Loaded?

    private struct Loaded {
        let url: URL
        let image: UIImage
    }

    // 캐시 히트면 첫 프레임부터 이미지를 그린다 — 셀이 재생성돼도 placeholder를 거치지 않는다
    private var image: UIImage? {
        guard let url else { return nil }
        if let loaded, loaded.url == url { return loaded.image }
        return imageProvider?.cachedImage(for: url)
    }

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url, image == nil else { return }
            guard let imageProvider else {
                // 주입을 빠뜨리면 회색 placeholder만 영원히 보이므로 디버그 빌드에서 즉시 드러낸다
                assertionFailure("ImageProvider가 주입되지 않았다 — AppDependencies의 인스턴스를 .environment로 넘겨야 한다")
                return
            }
            let result = try? await imageProvider.image(for: url)
            // url이 바뀌면 이전 url의 결과가 늦게 도착할 수 있어 취소를 확인한다
            if !Task.isCancelled, let result {
                loaded = Loaded(url: url, image: result)
            }
        }
    }
}
