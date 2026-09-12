import SwiftUI

@MainActor
@Observable
final class AppCoordinator {
    var path: [Route] = []

    private let dependencies: AppDependencies
    // 목록 VM은 앱 수명 1개 — body 재평가마다 만들면 pop 시 목록이 초기화된다
    @ObservationIgnored private var listViewModel: ProductListViewModel?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func rootView() -> some View {
        ProductListView(viewModel: makeListViewModelIfNeeded())
    }

    func destination(for route: Route) -> some View {
        switch route {
        case .productDetail(let id):
            ProductDetailView(viewModel: makeDetailViewModel(id: id))
        }
    }

    func push(_ route: Route) {
        // 셀 더블탭으로 같은 상세가 두 장 쌓이는 것을 막는다
        guard path.last != route else { return }
        path.append(route)
    }

    private func makeListViewModelIfNeeded() -> ProductListViewModel {
        if let listViewModel {
            return listViewModel
        }
        let viewModel = ProductListViewModel(
            fetchPage: dependencies.fetchProductPage,
            toggleFavorite: dependencies.toggleFavorite,
            observeFavorites: dependencies.observeFavorites,
            loadLayoutMode: dependencies.loadLayoutMode,
            saveLayoutMode: dependencies.saveLayoutMode,
            onSelectProduct: { [weak self] id in self?.push(.productDetail(id: id)) }
        )
        listViewModel = viewModel
        return viewModel
    }

    private func makeDetailViewModel(id: Int) -> ProductDetailViewModel {
        ProductDetailViewModel(
            productID: id,
            fetchDetail: dependencies.fetchProductDetail,
            toggleFavorite: dependencies.toggleFavorite,
            observeFavorites: dependencies.observeFavorites
        )
    }
}
