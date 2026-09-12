import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.body)
                .foregroundStyle(isFavorite ? .red : .secondary)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(isFavorite ? "찜 해제" : "찜")
    }
}

#Preview {
    HStack {
        FavoriteButton(isFavorite: true, action: {})
        FavoriteButton(isFavorite: false, action: {})
    }
}
