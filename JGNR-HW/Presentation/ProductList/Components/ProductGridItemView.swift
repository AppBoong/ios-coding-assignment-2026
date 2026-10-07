import SwiftUI

struct ProductGridItemView: View {
    private static let cornerRadius: CGFloat = 8
    private static let verticalSpacing: CGFloat = 8

    let title: String
    let priceText: String
    let thumbnailURL: URL?
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Self.verticalSpacing) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    RemoteImage(url: thumbnailURL) { image in
                        image.resizable()
                    } placeholder: {
                        Color(.secondarySystemBackground)
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))

            Text(title)
                .font(.subheadline)
                .lineLimit(2)

            HStack(spacing: Self.verticalSpacing) {
                Text(priceText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                FavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
            }
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ProductGridItemView(
            title: "Essence Mascara Lash Princess",
            priceText: "$9.99",
            thumbnailURL: nil,
            isFavorite: true,
            onToggleFavorite: {}
        )
        ProductGridItemView(
            title: "Eyeshadow Palette with Mirror",
            priceText: "$19.99",
            thumbnailURL: nil,
            isFavorite: false,
            onToggleFavorite: {}
        )
    }
    .padding()
}
