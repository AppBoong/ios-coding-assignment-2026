import SwiftUI

struct ProductListView: View {
    private static let gridColumnCount = 2
    private static let gridSpacing: CGFloat = 12
    private static let contentPadding: CGFloat = 16
    private static let contentTopID = "product-list-content-top"

    let viewModel: ProductListViewModel

    var body: some View {
        content
            .navigationTitle("상품")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleLayoutMode()
                    } label: {
                        Image(systemName: viewModel.layoutMode == .list ? "square.grid.2x2" : "list.bullet")
                    }
                    .accessibilityLabel(viewModel.layoutMode == .list ? "2열로 보기" : "1열로 보기")
                }
            }
            .task { await viewModel.loadFirstPageIfNeeded() }
            .task { await viewModel.observeFavoriteChanges() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoadingFirstPage && viewModel.items.isEmpty {
            ProgressView("불러오는 중…")
        } else if let message = viewModel.firstPageError, viewModel.items.isEmpty {
            ErrorRetryView(message: message) {
                Task { await viewModel.loadFirstPage() }
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: Self.gridSpacing) {
                        if let message = viewModel.firstPageError, !viewModel.items.isEmpty {
                            ErrorRetryView(message: message) {
                                Task { await viewModel.refresh() }
                            }
                        }
                        switch viewModel.layoutMode {
                        case .list:
                            LazyVStack(spacing: Self.gridSpacing) {
                                cells
                            }
                        case .grid:
                            LazyVGrid(
                                columns: Array(
                                    repeating: GridItem(.flexible(), spacing: Self.gridSpacing),
                                    count: Self.gridColumnCount
                                ),
                                spacing: Self.gridSpacing
                            ) {
                                cells
                            }
                        }
                        footer
                    }
                    .padding(Self.contentPadding)
                    .id(Self.contentTopID)
                }
                .background(Color(.systemBackground))
                .refreshable {
                    await viewModel.refresh()
                    // 인디케이터 접힘 애니메이션이 끝난 뒤 한 프레임 재계산 유도
                    try? await Task.sleep(for: .milliseconds(500))
                    await MainActor.run {
                        withAnimation(.none) {
                            proxy.scrollTo(Self.contentTopID, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private var cells: some View {
        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, product in
            cell(for: product)
                .contentShape(Rectangle())
                .onTapGesture { viewModel.select(product) }
                .accessibilityAddTraits(.isButton)
                .onAppear { viewModel.loadNextPageIfNeeded(currentIndex: index) }
        }
    }

    @ViewBuilder
    private func cell(for product: ProductSummary) -> some View {
        let priceText = PriceFormatter.usd(product.price)
        switch viewModel.layoutMode {
        case .list:
            ProductRowView(
                title: product.title,
                priceText: priceText,
                thumbnailURL: product.thumbnailURL,
                isFavorite: viewModel.isFavorite(product),
                onToggleFavorite: { viewModel.toggleFavorite(for: product) }
            )
        case .grid:
            ProductGridItemView(
                title: product.title,
                priceText: priceText,
                thumbnailURL: product.thumbnailURL,
                isFavorite: viewModel.isFavorite(product),
                onToggleFavorite: { viewModel.toggleFavorite(for: product) }
            )
        }
    }

    @ViewBuilder
    private var footer: some View {
        if viewModel.isLoadingNextPage {
            ProgressView()
        } else if let message = viewModel.nextPageError {
            ErrorRetryView(message: message) {
                viewModel.retryNextPage()
            }
        }
    }
}
