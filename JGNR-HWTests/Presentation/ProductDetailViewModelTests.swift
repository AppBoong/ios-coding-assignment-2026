import Foundation
import Testing
@testable import JGNR_HW

@Suite @MainActor
struct ProductDetailViewModelTests {
    private func makeProduct(id: Int) -> Product {
        Product(
            id: id,
            title: "상품 \(id)",
            description: "설명 \(id)",
            category: "카테고리",
            price: 9.99,
            discountRate: 0,
            rating: 4.5,
            stock: 10,
            brand: "브랜드",
            thumbnailURL: nil,
            imageURLs: []
        )
    }

    private func makeViewModel(
        productID: Int,
        product: StubProductRepository,
        favorite: StubFavoriteRepository = .init()
    ) -> ProductDetailViewModel {
        ProductDetailViewModel(
            productID: productID,
            fetchDetail: FetchProductDetailUseCase(repository: product),
            toggleFavorite: ToggleFavoriteUseCase(repository: favorite),
            observeFavorites: ObserveFavoritesUseCase(repository: favorite)
        )
    }

    @Test("로드 성공 시 product를 설정하고 실패 시 한국어 문구를 보여준다")
    func loadsProductOrShowsError() async throws {
        let expected = makeProduct(id: 7)
        let product = StubProductRepository(detailResult: .success(expected))
        let viewModel = makeViewModel(productID: 7, product: product)

        await viewModel.loadIfNeeded()

        #expect(viewModel.product == expected)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
        let calls = await product.fetchDetailCalls
        #expect(calls == [7])

        let failingProduct = StubProductRepository(detailResult: .failure(NetworkError.notFound))
        let failingViewModel = makeViewModel(productID: 7, product: failingProduct)

        await failingViewModel.loadIfNeeded()

        #expect(failingViewModel.product == nil)
        #expect(failingViewModel.errorMessage == "상품을 찾을 수 없습니다")
    }

    @Test("구독 첫 yield로 현재 찜 상태를 받고 토글 후 방송으로 갱신된다")
    func togglingFavoriteUpdatesStream() async throws {
        let product = StubProductRepository(detailResult: .success(makeProduct(id: 3)))
        let favorite = StubFavoriteRepository(favoriteIDs: [3])
        let viewModel = makeViewModel(productID: 3, product: product, favorite: favorite)

        let observing = Task { await viewModel.observeFavoriteChanges() }

        await waitUntil { viewModel.isFavorite }
        #expect(viewModel.isFavorite)

        viewModel.toggleFavorite()

        await waitUntil { !viewModel.isFavorite }
        #expect(!viewModel.isFavorite)
        #expect(favorite.toggledIDs == [3])

        observing.cancel()
    }
}
