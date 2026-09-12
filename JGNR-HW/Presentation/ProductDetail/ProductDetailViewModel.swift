import Foundation
import Observation

@MainActor
@Observable
final class ProductDetailViewModel {
    private(set) var product: Product?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isFavorite = false

    private let productID: Int
    private let fetchDetail: FetchProductDetailUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let observeFavorites: ObserveFavoritesUseCase
    private var loadTask: Task<Void, Never>?

    init(
        productID: Int,
        fetchDetail: FetchProductDetailUseCase,
        toggleFavorite: ToggleFavoriteUseCase,
        observeFavorites: ObserveFavoritesUseCase
    ) {
        self.productID = productID
        self.fetchDetail = fetchDetail
        self.toggleFavoriteUseCase = toggleFavorite
        self.observeFavorites = observeFavorites
    }

    func observeFavoriteChanges() async {
        for await ids in await observeFavorites.execute() {
            isFavorite = ids.contains(productID)
        }
    }

    func loadIfNeeded() async {
        guard product == nil, loadTask == nil else { return }
        await load()
    }

    func load() async {
        guard loadTask == nil else { return }
        isLoading = true
        errorMessage = nil
        let task = Task<Void, Never> {
            do {
                let result = try await self.fetchDetail.execute(id: self.productID)
                if !Task.isCancelled {
                    self.product = result
                }
            } catch is CancellationError {
                // 취소된 요청의 결과는 버린다
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = ErrorMessageFormatter.message(for: error)
                }
            }
        }
        loadTask = task
        await task.value
        if loadTask == task {
            loadTask = nil
            isLoading = false
        }
    }

    func toggleFavorite() {
        Task { await toggleFavoriteUseCase.execute(id: productID) }
    }
}
