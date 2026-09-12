import Foundation
import Observation

@MainActor
@Observable
final class ProductListViewModel {
    private(set) var items: [ProductSummary] = []
    private(set) var favoriteIDs: Set<Int> = []
    private(set) var layoutMode: ProductListLayoutMode
    private(set) var isLoadingFirstPage = false
    private(set) var isLoadingNextPage = false
    private(set) var firstPageError: String?
    private(set) var nextPageError: String?
    private(set) var hasMore = true

    private let fetchPage: FetchProductPageUseCase
    private let toggleFavorite: ToggleFavoriteUseCase
    private let observeFavorites: ObserveFavoritesUseCase
    private let saveLayoutMode: SaveLayoutModeUseCase
    private let pageSize: Int
    private let prefetchThreshold: Int
    private let onSelectProduct: (Int) -> Void
    private var firstPageTask: Task<Void, Never>?
    private var nextPageTask: Task<Void, Never>?

    init(
        fetchPage: FetchProductPageUseCase,
        toggleFavorite: ToggleFavoriteUseCase,
        observeFavorites: ObserveFavoritesUseCase,
        loadLayoutMode: LoadLayoutModeUseCase,
        saveLayoutMode: SaveLayoutModeUseCase,
        pageSize: Int = 20,
        prefetchThreshold: Int = 16,
        onSelectProduct: @escaping (Int) -> Void
    ) {
        self.fetchPage = fetchPage
        self.toggleFavorite = toggleFavorite
        self.observeFavorites = observeFavorites
        self.saveLayoutMode = saveLayoutMode
        self.pageSize = pageSize
        self.prefetchThreshold = prefetchThreshold
        self.onSelectProduct = onSelectProduct
        self.layoutMode = loadLayoutMode.execute() ?? .list
    }

    func observeFavoriteChanges() async {
        for await ids in await observeFavorites.execute() {
            favoriteIDs = ids
        }
    }

    func loadFirstPageIfNeeded() async {
        guard items.isEmpty, firstPageTask == nil else { return }
        await loadFirstPage()
    }

    func loadFirstPage() async {
        await runFirstPageFetch()
    }

    func refresh() async {
        // 취소한 진행 중 작업이 완전히 끝난 뒤에 새 요청을 보낸다 — 그렇지 않으면
        // 취소된 요청과 새 요청 중 어느 쪽이 먼저 도착할지가 스케줄링에 따라 달라진다
        nextPageTask?.cancel()
        await nextPageTask?.value
        nextPageTask = nil
        nextPageError = nil
        firstPageTask?.cancel()
        await firstPageTask?.value
        firstPageTask = nil
        await runFirstPageFetch()
    }

    func loadNextPageIfNeeded(currentIndex: Int) {
        guard nextPageTask == nil,
              hasMore,
              !isLoadingFirstPage,
              nextPageError == nil else { return }
        // 마지막 로드 페이지의 prefetchThreshold번째(기본 16번째) 아이템이 나타날 때 다음 페이지 — 0-based라 -1
        guard currentIndex >= items.count - pageSize + prefetchThreshold - 1 else { return }
        startNextPageFetch()
    }

    func retryNextPage() {
        guard nextPageTask == nil else { return }
        nextPageError = nil
        startNextPageFetch()
    }

    func select(_ product: ProductSummary) {
        onSelectProduct(product.id)
    }

    func toggleFavorite(for product: ProductSummary) {
        Task { await toggleFavorite.execute(id: product.id) }
    }

    func toggleLayoutMode() {
        layoutMode = layoutMode == .list ? .grid : .list
        saveLayoutMode.execute(layoutMode)
    }

    func isFavorite(_ product: ProductSummary) -> Bool {
        favoriteIDs.contains(product.id)
    }

    private func runFirstPageFetch() async {
        guard firstPageTask == nil else { return }
        isLoadingFirstPage = true
        firstPageError = nil
        let task = Task<Void, Never> {
            do {
                let page = try await self.fetchPage.execute(skip: 0, limit: self.pageSize)
                if !Task.isCancelled {
                    self.items = page.items
                    self.hasMore = self.items.count < page.total
                }
            } catch is CancellationError {
                // 취소된 새로고침/첫 페이지 요청의 결과는 버린다
            } catch {
                if !Task.isCancelled {
                    self.firstPageError = ErrorMessageFormatter.message(for: error)
                }
            }
        }
        firstPageTask = task
        await task.value
        if firstPageTask == task {
            firstPageTask = nil
            isLoadingFirstPage = false
        }
    }

    private func startNextPageFetch() {
        nextPageTask = Task { await self.loadNextPage() }
    }

    private func loadNextPage() async {
        isLoadingNextPage = true
        do {
            let page = try await fetchPage.execute(skip: items.count, limit: pageSize)
            if !Task.isCancelled {
                items.append(contentsOf: page.items)
                hasMore = items.count < page.total
            }
        } catch is CancellationError {
            // 취소는 에러로 표시하지 않는다
        } catch {
            nextPageError = ErrorMessageFormatter.message(for: error)
        }
        isLoadingNextPage = false
        nextPageTask = nil
    }
}
