import SwiftUI

struct ProductDetailView: View {
    fileprivate static let contentPadding: CGFloat = 16

    let viewModel: ProductDetailViewModel   // Coordinator가 주입. 바인딩 불필요하므로 let

    var body: some View {
        content
            .navigationTitle("상품 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    FavoriteButton(isFavorite: viewModel.isFavorite) { viewModel.toggleFavorite() }
                }
            }
            .task { await viewModel.loadIfNeeded() }
            .task { await viewModel.observeFavoriteChanges() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.product == nil {
            ProgressView("불러오는 중…")
        } else if let message = viewModel.errorMessage, viewModel.product == nil {
            ErrorRetryView(message: message) {
                Task { await viewModel.load() }
            }
        } else if let product = viewModel.product {
            ScrollView {
                ProductDetailContent(product: product)
                    .padding(Self.contentPadding)
            }
            .background(Color(.systemBackground))
        }
    }
}

private struct ProductDetailContent: View {
    private static let sectionSpacing: CGFloat = 12

    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: Self.sectionSpacing) {
            ImageGallery(imageURLs: product.imageURLs, thumbnailURL: product.thumbnailURL)

            Text(product.title)
                .font(.title2.bold())

            HStack {
                Text(PriceFormatter.usd(product.price))
                    .font(.title3)
                if product.discountRate > 0 {
                    Text(PriceFormatter.discount(product.discountRate))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            AdditionalInfo(product: product)

            Text(product.description)
                .font(.body)
        }
    }
}

private struct ImageGallery: View {
    let imageURLs: [URL]
    let thumbnailURL: URL?

    var body: some View {
        let urls = imageURLs.isEmpty ? [thumbnailURL].compactMap { $0 } : imageURLs
        TabView {
            // 페이지 식별은 위치로 한다 — imageURLs는 상세 수명 동안 수정·삭제가 없어 인덱스가 안정적이고,
            // URL 유일성은 서버가 보장하지 않는다. 편집·삭제 기능이 생기면 서버 id를 받거나 id를 부여한 페이지 모델로 전환한다
            ForEach(Array(urls.enumerated()), id: \.offset) { _, url in
                RemoteImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color(.secondarySystemBackground)
                }
                .aspectRatio(contentMode: .fit)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct AdditionalInfo: View {
    private static let lineSpacing: CGFloat = 4

    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: Self.lineSpacing) {
            if let brand = product.brand {
                Text("브랜드 \(brand)")
            }
            Text("카테고리 \(product.category)")
            Text("평점 \(String(format: "%.1f", product.rating))")
            stockText
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var stockText: some View {
        if product.stock == 0 {
            Text("품절")
                .foregroundStyle(.red)
        } else {
            Text("재고 \(product.stock)개")
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ProductDetailContent(
                product: Product(
                    id: 1,
                    title: "Essence Mascara Lash Princess",
                    description: "The Essence Mascara Lash Princess is a popular mascara known for its volumizing and lengthening effects. Achieve the perfect lash look with this long-lasting and cruelty-free formula.",
                    category: "beauty",
                    price: 9.99,
                    discountRate: 12.5,
                    rating: 4.3,
                    stock: 0,
                    brand: "Essence",
                    thumbnailURL: nil,
                    imageURLs: []
                )
            )
            .padding(ProductDetailView.contentPadding)
        }
        .navigationTitle("상품 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}
