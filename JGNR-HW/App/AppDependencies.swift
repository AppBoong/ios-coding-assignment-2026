import Foundation

@MainActor
final class AppDependencies {
    let imageLoader: ImageLoader
    let favoriteRepository: DefaultFavoriteRepository
    let fetchProductPage: FetchProductPageUseCase
    let fetchProductDetail: FetchProductDetailUseCase
    let toggleFavorite: ToggleFavoriteUseCase
    let observeFavorites: ObserveFavoritesUseCase
    let loadLayoutMode: LoadLayoutModeUseCase
    let saveLayoutMode: SaveLayoutModeUseCase

    init() {
        let httpClient = URLSessionHTTPClient()
        let keyValueStore = UserDefaultsKeyValueStore()
        let productRepository = DefaultProductRepository(client: httpClient)
        let layoutPreferenceRepository = DefaultLayoutPreferenceRepository(store: keyValueStore)

        imageLoader = ImageLoader()
        favoriteRepository = DefaultFavoriteRepository(dataSource: FavoriteLocalDataSource(store: keyValueStore))

        fetchProductPage = FetchProductPageUseCase(repository: productRepository)
        fetchProductDetail = FetchProductDetailUseCase(repository: productRepository)
        toggleFavorite = ToggleFavoriteUseCase(repository: favoriteRepository)
        observeFavorites = ObserveFavoritesUseCase(repository: favoriteRepository)
        loadLayoutMode = LoadLayoutModeUseCase(repository: layoutPreferenceRepository)
        saveLayoutMode = SaveLayoutModeUseCase(repository: layoutPreferenceRepository)
    }
}
