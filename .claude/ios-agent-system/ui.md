# 프로젝트 지침 — ios-ui

> `/setup-ios`가 생성하는 파일입니다. ios-ui 에이전트 호출 시 오케스트레이터가 이 내용을
> 프롬프트에 주입합니다. 전체 세부 규칙: `PROJECT_PROFILE.md` §4.

## 뷰 프레임워크

- **프레임워크**: SwiftUI 전용 (iOS 17+). UIKit은 `Shared/Image` 내부의 `UIImage` 디코딩에만
- **레이아웃 방식 (UIKit 시)**: 해당 없음
- **비동기 UI 업데이트 방식**: Swift Concurrency — `.task { await viewModel.load() }`, `.refreshable { await viewModel.refresh() }`. Combine·GCD 혼입 금지. ViewModel은 `@MainActor @Observable`이므로 상태 변경이 곧 UI 갱신
- **UX 텍스트 언어**: 한국어 (상품명·브랜드 등 API 데이터는 영어 원문)
- **학습 데이터 이후 API / 문서 링크**: 없음 — iOS 17 안정 API만. iOS 26 전용 modifier(Liquid Glass 등) 사용 금지. 기본 격리가 `nonisolated`이므로 View 보조 타입(포맷터 캐시 등)에 상태가 있으면 `@MainActor` 명시

### 표준 View 작성 패턴

```swift
import SwiftUI

struct ProductListView: View {
    @Bindable var viewModel: ProductListViewModel   // Coordinator가 생성해 주입. 바인딩 불필요하면 `let`

    var body: some View {
        content
            .navigationTitle("상품")
            .toolbar {
                Button {
                    viewModel.toggleLayoutMode()
                } label: {
                    Image(systemName: viewModel.layoutMode == .list ? "square.grid.2x2" : "list.bullet")
                }
                .accessibilityLabel(viewModel.layoutMode == .list ? "2열로 보기" : "1열로 보기")
            }
            .task { await viewModel.loadFirstPageIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoadingFirstPage && viewModel.items.isEmpty {
            ProgressView("불러오는 중…")
        } else if let message = viewModel.firstPageError, viewModel.items.isEmpty {
            ErrorRetryView(message: message) { Task { await viewModel.loadFirstPage() } }
        } else {
            ScrollView {
                switch viewModel.layoutMode {
                case .list: LazyVStack(spacing: 12) { cells }
                case .grid: LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) { cells }
                }
                footer
            }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var cells: some View {
        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
            Button { viewModel.select(item) } label: {
                cell(for: item)
            }
            .buttonStyle(.plain)
            .onAppear { viewModel.loadNextPageIfNeeded(currentIndex: index) }
        }
    }
    // cell(for:)는 layoutMode에 따라 ProductRowView / ProductGridItemView — 둘 다 (title, priceText, thumbnailURL, isFavorite, onToggleFavorite)만 받는다
}
```

### 금지 패턴

- View에서 `URLSession`·`UserDefaults`·Repository·HTTPClient 접근, View 안에서 `ViewModel()`·UseCase 생성
- `AsyncImage` 사용 (캐시 없음) — 반드시 `RemoteImage`
- 1열/2열을 별도 화면·별도 데이터 소스로 만들기 — 같은 `items` 배열, 같은 `onAppear` 트리거, 컨테이너만 교체
- `List`의 셀 안에서 `onAppear` 페이지 트리거 없이 `.onChange(of: scrollOffset)` 같은 오프셋 계산
- `GeometryReader`로 셀 크기 계산(그리드는 `.flexible()` 컬럼), 고정 `.frame(width:height:)`(썸네일은 `.aspectRatio(1, contentMode: .fill)` + `.clipped()`), 정렬용 `.offset`
- `.system(size:)` 고정 폰트, `Color(red:green:blue:)`/hex 색상
- `Task.detached`, `DispatchQueue.main.async`, `@unchecked Sendable`
- `#Preview`에 네트워크·UserDefaults 의존 — 정적 더미 값으로 셀 컴포넌트만 프리뷰
- 에러/로딩을 전역 오버레이로 처리 — 화면별 ViewModel 상태로 분기
- 영어 UX 문구 ("Loading…", "Retry") — 한국어("불러오는 중…", "다시 시도")

## 디자인 시스템

- **모듈/위치**: 없음 — 시스템 표준 컴포넌트 + `Presentation/Common/` + `Shared/Image/RemoteImage`

### 사용 가능한 공용 컴포넌트

| 컴포넌트 | 위치 | 시그니처 / 용도 |
|---|---|---|
| `RemoteImage` | `Shared/Image` | `RemoteImage(url: URL?) { image in image.resizable() } placeholder: { Color(.secondarySystemBackground) }` — ImageLoader 캐시 사용 |
| `FavoriteButton` | `Presentation/Common` | `FavoriteButton(isFavorite: Bool, action: () -> Void)` — `heart`/`heart.fill`, 접근성 라벨 "찜"/"찜 해제". 셀 탭과 분리되도록 `.buttonStyle(.borderless)` |
| `ErrorRetryView` | `Presentation/Common` | `ErrorRetryView(message: String, retry: () -> Void)` — 문구 + "다시 시도" |
| `PriceFormatter` | `Presentation/Common` | `PriceFormatter.usd(_ value: Double) -> String` (`$1,234.56`), `discount(_ rate: Double) -> String` (`-12%`) |

두 번째 사용처가 생기기 전에는 `Common/`에 새 컴포넌트를 만들지 않는다.

### 허용 색상 토큰

- 텍스트: `.primary`, `.secondary`
- 배경: `Color(.systemBackground)`, `Color(.secondarySystemBackground)`(이미지 플레이스홀더·카드)
- 강조: `Color.accentColor`
- 찜 하트: `.red`(활성) / `.secondary`(비활성)
- 할인·재고 경고: `.red`(품절), `.green`(할인율) — 이 둘 외 상태색 도입 시 사용자 확인

### 금지 색상 (컴파일 에러 또는 컨벤션 위반)

- `Color(red:green:blue:)`, `Color(hex:)`, `UIColor(...)` 직접 생성
- `Color.white`/`Color.black` 고정(다크모드 깨짐) — 시맨틱 컬러로

### FontStyle

시스템 텍스트 스타일만 (Dynamic Type):
- 상품명 `.headline` (목록) / `.title2.bold()` (상세)
- 가격 `.subheadline.weight(.semibold)` (목록) / `.title3` (상세)
- 부가 정보(브랜드·카테고리·평점·재고) `.caption`, 설명 `.body`
- 고정 포인트 `.system(size:)` 금지
