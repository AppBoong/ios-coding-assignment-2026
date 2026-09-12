import SwiftUI

struct RemoteImage<Content: View, Placeholder: View>: View {
    @Environment(\.imageLoader) private var imageLoader
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url else {
                image = nil
                return
            }
            image = nil
            let loaded = try? await imageLoader.image(for: url)
            if !Task.isCancelled {
                image = loaded
            }
        }
    }
}
