import SwiftUI

struct ProductRowView: View {
    // 썸네일은 아이콘과 동급으로 취급되는 본질적 고정 크기 요소 — 리스트 셀 규격이므로 .frame(width:height:) 허용
    private static let thumbnailSize: CGFloat = 80
    private static let cornerRadius: CGFloat = 8
    private static let horizontalSpacing: CGFloat = 12
    private static let textSpacing: CGFloat = 4

    let title: String
    let priceText: String
    let thumbnailURL: URL?
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: Self.horizontalSpacing) {
            RemoteImage(url: thumbnailURL) { image in
                image.resizable()
            } placeholder: {
                Color(.secondarySystemBackground)
            }
            .aspectRatio(1, contentMode: .fill)
            .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))

            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(title)
                    .font(.body)
                    .lineLimit(2)
                Text(priceText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            FavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ProductRowView(
            title: "Essence Mascara Lash Princess",
            priceText: "$9.99",
            thumbnailURL: nil,
            isFavorite: true,
            onToggleFavorite: {}
        )
        ProductRowView(
            title: "Eyeshadow Palette with Mirror",
            priceText: "$19.99",
            thumbnailURL: nil,
            isFavorite: false,
            onToggleFavorite: {}
        )
    }
    .padding()
}
