import Foundation
import Testing
@testable import JGNR_HW

@Suite @MainActor
struct ProductListViewModelTests {
    private func makeSummaries(count: Int, startingAt start: Int = 0) -> [ProductSummary] {
        (0..<count).map { offset in
            ProductSummary(id: start + offset, title: "상품 \(start + offset)", price: 9.99, thumbnailURL: nil)
        }
    }

    private func makePage(count: Int, total: Int, skip: Int, startingAt: Int? = nil) -> ProductPage {
        ProductPage(items: makeSummaries(count: count, startingAt: startingAt ?? skip), total: total, skip: skip, limit: count)
    }

    private func makeViewModel(
        product: StubProductRepository,
        favorite: StubFavoriteRepository = .init(),
        layout: StubLayoutPreferenceRepository = .init(),
        onSelect: @escaping (Int) -> Void = { _ in }
    ) -> ProductListViewModel {
        ProductListViewModel(
            fetchPage: FetchProductPageUseCase(repository: product),
            toggleFavorite: ToggleFavoriteUseCase(repository: favorite),
            observeFavorites: ObserveFavoritesUseCase(repository: favorite),
            loadLayoutMode: LoadLayoutModeUseCase(repository: layout),
            saveLayoutMode: SaveLayoutModeUseCase(repository: layout),
            onSelectProduct: onSelect
        )
    }

    private func waitUntil(_ condition: @MainActor () -> Bool) async {
        for _ in 0..<200 {
            if condition() { return }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test("마지막 페이지 16번째 아이템에서만 다음 페이지를 1회 요청한다")
    func requestsNextPageOnceAtThreshold() async throws {
        let product = StubProductRepository(pageResults: [
            .success(makePage(count: 20, total: 40, skip: 0)),
            .success(makePage(count: 20, total: 40, skip: 20))
        ])
        await product.setPageDelay(.milliseconds(50))
        let viewModel = makeViewModel(product: product)

        await viewModel.loadFirstPageIfNeeded()
        #expect(viewModel.items.count == 20)

        viewModel.loadNextPageIfNeeded(currentIndex: 14)
        var calls = await product.fetchPageCalls
        #expect(calls.count == 1)

        for _ in 0..<5 {
            viewModel.loadNextPageIfNeeded(currentIndex: 15)
        }
        await waitUntil { viewModel.isLoadingNextPage }
        calls = await product.fetchPageCalls
        #expect(calls.count == 2)

        await waitUntil { viewModel.items.count == 40 }
        #expect(viewModel.items.count == 40)

        viewModel.loadNextPageIfNeeded(currentIndex: 35)
        calls = await product.fetchPageCalls
        #expect(calls.count == 2)
    }

    @Test("새로고침은 진행 중 다음 페이지를 취소하고 첫 페이지로 교체한다")
    func refreshCancelsNextPageAndReplacesItems() async throws {
        let product = StubProductRepository(pageResults: [
            .success(makePage(count: 20, total: 60, skip: 0)),
            .success(makePage(count: 20, total: 60, skip: 0, startingAt: 1000))
        ])
        await product.setPageDelay(.milliseconds(50))
        let viewModel = makeViewModel(product: product)

        await viewModel.loadFirstPageIfNeeded()
        viewModel.loadNextPageIfNeeded(currentIndex: 15)
        await viewModel.refresh()
        await waitUntil { !viewModel.isLoadingNextPage }

        #expect(viewModel.items.count == 20)
        let first = try #require(viewModel.items.first)
        #expect(first.id == 1000)
        let calls = await product.fetchPageCalls
        #expect(calls.map(\.skip) == [0, 20, 0])
        #expect(viewModel.nextPageError == nil)
        #expect(viewModel.isLoadingNextPage == false)
    }

    @Test("찜 스트림 변경이 favoriteIDs에 반영되고 토글은 UseCase로 전달된다")
    func reflectsFavoriteStream() async throws {
        let product = StubProductRepository(pageResults: [.success(makePage(count: 20, total: 20, skip: 0))])
        let favorite = StubFavoriteRepository()
        let viewModel = makeViewModel(product: product, favorite: favorite)

        await viewModel.loadFirstPageIfNeeded()
        let item3 = try #require(viewModel.items.first { $0.id == 3 })

        let observing = Task { await viewModel.observeFavoriteChanges() }

        favorite.emit([3])
        await waitUntil { viewModel.favoriteIDs == [3] }
        #expect(viewModel.favoriteIDs == [3])
        #expect(viewModel.isFavorite(item3) == true)

        viewModel.toggleFavorite(for: item3)
        await waitUntil { favorite.toggledIDs == [3] }
        #expect(favorite.toggledIDs == [3])

        observing.cancel()
    }

    @Test("보기 모드 토글이 저장되고 새 ViewModel이 복원한다")
    func persistsLayoutMode() async throws {
        let product = StubProductRepository(pageResults: [.success(makePage(count: 1, total: 1, skip: 0))])
        let layout = StubLayoutPreferenceRepository()
        let viewModel = makeViewModel(product: product, layout: layout)

        #expect(viewModel.layoutMode == .list)

        viewModel.toggleLayoutMode()
        #expect(viewModel.layoutMode == .grid)
        #expect(layout.savedModes == [.grid])

        let restored = makeViewModel(product: product, layout: layout)
        #expect(restored.layoutMode == .grid)
    }
}
