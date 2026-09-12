# JGNR-HW 초기 구축 — 작업 Audit / 진행 관리 문서 (SSOT)

> **이 문서는 이 작업의 단일 진실 소스(SSOT)입니다.**
> `/clear` 후 또는 `/ios-agent-system:task-ios` 재실행 시 **가장 먼저 §7 진행 로그의 마지막 상태**를 확인하고 미완료 커밋부터 이어서 진행합니다.
>
> 저장 위치: `.claude/ios-agent-system/audits/20260912-initial-setup.md`
> 연관 문서: `../PRD.md` — 요구사항·기술 스택 확정표의 상위 문서
> 브랜치: `feature/jgnr-hw` (fork). PR은 upstream `apptask-jn/ios-coding-assignment-2026` `main`으로. `main`에 직접 커밋하지 않는다

---

## 0. 작업 워크플로 계약 (반드시 준수)

각 커밋 단위마다:
1. **착수 게이트 🔵** — 이 커밋의 세부 결정 포인트를 확인해 필요하면 사용자에게 질문·확정하고, 커밋 구현 계획을 컨펌받은 후에만 구현 시작
2. **구현** — 해당 커밋 범위의 파일만 작성/수정 (필요 시 서브에이전트 라우팅)
3. **검증 파이프라인** — `ios-build` 내부 빌드(앱 스킴 빌드 + `JGNR-HWTests` + 아키텍처 검사, 결정적 검사) → `ios-review`(경량 리뷰 — 비코드 변경이면 스킵) → 리뷰가 코드를 수정한 경우에만 증분 재빌드 → 커밋 게이트 빌드(앱 스킴 1회)
4. **확인 요청 🔵** — 사용자에게 **작업 서머리 + 빌드 결과 + 확인 권장 포인트**(코드 리딩 지점 `파일:라인` + 이유, 실행으로 확인하는 방법)를 보고 후 **커밋 승인 대기**. 사용자가 수정을 요청하면 반영 → 재검증 → 재보고
5. **커밋 ✔️** — 사용자 승인 후에만 커밋 (Conventional Commits)
6. **로그 갱신** — §5 상태 마커 + §7 진행 로그 갱신

> ⚠️ **사용자 승인 없이 커밋하지 않는다.** 빌드 실패 시 커밋 요청 대신 원인/수정안을 보고한다.
> 사용자가 코드와 실행 결과를 직접 확인할 수 있도록, 확인 요청에는 항상 "어디를 어떻게 보면 되는지"를 구체적으로 담는다.
>
> **LEARN 기록**: 확인 요청 단계에서 사용자가 지적한 **게이트 미검출 결함**, 반복된 빌드 에러 패턴은 §7에 `LEARN: {내용} (Commit N)` 형식으로 남긴다. 모든 커밋 완료 후 **회고 게이트**가 이 항목들을 규칙 승격 후보로 사용자에게 제안한다 (LEARN이 없으면 회고 생략).

### 상태 마커
⬜ TODO · 🟡 IN PROGRESS · 🧪 BUILD OK(미확인) · 🔵 AWAITING CONFIRM · ✔️ COMMITTED · ❌ BUILD FAIL

---

## 1. 작업 개요 & 요구사항
원본 intent: `.claude/ios-agent-system/intents/20260912-initial-requirements.md`

| # | 요구사항 | 수용 기준 |
|---|----------|-----------|
| 1 | 상품 목록 | 첫 페이지 20개, 셀에 상품명·가격(`$`)·이미지·찜 여부 (PRD F1) |
| 2 | 페이지네이션 | 마지막 페이지 16번째 onAppear → 다음 페이지 1회, `total` 도달 후 0건 (F2) |
| 3 | 풀투리프레시 | `skip=0` 재로드, 진행 중 페이지 Task 취소, 찜 유지 (F3) |
| 4 | 보기 전환 | 1열/2열 토글, 같은 `items`, UserDefaults 영속 (F4) |
| 5 | 찜 토글·영속 | 목록·상세 양쪽, UserDefaults, 재실행 유지 (F5) |
| 6 | 찜 동기화 | 단일 소스 AsyncStream 방송으로 양방향 즉시 반영 (F6) |
| 7 | 상품 상세 | `GET /products/{id}`, 9개 필드 + 찜 (F7) |
| 8 | 에러 처리 | 한국어 문구 + 다시 시도, 다음 페이지 실패는 인라인 (F8) |
| 9 | 빌드 조건 | clone → 열기 → 빌드. 외부 의존 0 (F9) |
| 10 | 유닛 테스트 | ViewModel·FavoriteRepository·DTO 매핑, Swift Testing (F10) |

---

## 2. 확정된 의사결정 (Locked Decisions)

| 결정 | 선택 | 근거/비고 |
|---|---|---|
| 스택 전체 | PRD §3 확정표 | 셋업 인터뷰 2026-09-12 |
| 찜 단일 소스 격리 | `@MainActor final class DefaultFavoriteRepository` (actor 아님) | 호출자가 전부 `@MainActor` ViewModel이라 액터 홉 불필요, O(1) Set 연산, continuation yield가 MainActor에서 단순 |
| 페이지네이션 가드 | ① 진행 중 Task ② `hasMore` ③ 임계 인덱스 `items.count - pageSize + prefetchThreshold - 1` | 성공 기준 2를 코드로 강제. `pageSize`·`prefetchThreshold`는 init 파라미터(테스트에서 작게 주입) |
| 새로고침 취소 | `refresh()`가 `nextPageTask?.cancel()` 후 새 Task. 완료 시 `Task.isCancelled` 확인해 늦은 응답 폐기. 새로고침 중 다음 페이지 차단 | 상태 역전 방지 |
| `NetworkError` associated value | `String`(description) | `Error`는 Equatable/Sendable 보장 없음 — 테스트 값 비교 |
| `NetworkError` HTTP 상태 세분화 | 전용 case: badRequest(400)·unauthorized(401)·forbidden(403)·notFound(404)·requestTimeout(408)·conflict(409)·tooManyRequests(429) · 나머지 4xx `clientError(Int)` · 5xx `serverError(Int)` · 그 외 `unexpectedStatus(Int)`. 매핑은 `init(statusCode:)` 한 곳 | 사용자 요청 2026-09-12 Commit 2 게이트 — 명확한 에러는 case로 구분, 400/500 계열 분리. `httpStatus(Int)` 폐기 |
| Base URL | `URLSessionHTTPClient`가 `URLComponents(scheme:host:)`를 보관, `Endpoint`가 path·query를 합쳐 `url`이 nil이면 `NetworkError.invalidURL` throw | 아키텍트 초안의 `URL(string:)!` 기본 인자는 강제 언래핑 금지 규칙 위반 — 옵셔널 없는 조립으로 교체 |
| ImageLoader 전달 | `EnvironmentValues.imageLoader` (인스턴스는 `AppDependencies`가 1개 생성, `JGNRHWApp`이 `.environment`로 주입) | 싱글턴 금지 유지 + 셀 깊이까지 이니셜라이저 전달 회피 |
| 목록 API 필드 축소 | `select=id,title,price,thumbnail` → `ProductSummaryDTO` 별도 | 원격 응답 책임을 좁힘 |
| Domain UseCase 테스트 | 별도 없음 (위임형) | 밀도 "테스트 간결" — Data/Presentation 테스트가 간접 검증 |
| UserDefaults 보관 방식 | `UserDefaultsKeyValueStore`는 `suiteName: String?`만 보관, 호출마다 `UserDefaults(suiteName:) ?? .standard` 접근 | Swift 6 strict에서 Sendable struct가 non-Sendable `UserDefaults`를 저장 프로퍼티로 못 가짐. `@preconcurrency import`로 낮추면 경고가 남고 검사 우회 범주 — 2026-09-12 Commit 2 결정 |
| `FavoriteRepository` 시그니처 | `toggle(id:) async` + `observe() async -> AsyncStream<Set<Int>>` 2개 — `observe()`는 구독 즉시 현재 Set을 먼저 yield하고 이후 변경마다 방송. `currentFavoriteIDs()` 폐기 | UseCase 호출처가 0인 메서드를 protocol에 두지 않는다(리뷰 Critical 기준). ViewModel은 첫 yield로 초기값을 받는다 — 2026-09-12 Commit 3 착수 게이트 결정 |
| 커밋 크기 | **커밋당 파일 5~6개 이하** — 의존 순서(하위→상위)로 나눠 각 커밋이 단독 빌드되게 하고 커밋마다 빌드 확인. Commit 4~8은 착수 게이트에서 미리 분할 제시 | 사용자 결정 2026-09-12 Commit 3 게이트 — 13파일 커밋 반려("파일이 너무 많음, 분할하여 커밋 진행") |
| Commit 1 생성 방식 | **안 B — 에이전트(opus)가 pbxproj·스킴 직접 작성** (2026-09-12 Step 2.0에서 안 A → 안 B로 변경) | 사용자 지시: Fable은 총괄만, 작업은 서브에이전트 위임. `*.pbxproj` 쓰기는 게이트 ask 승인 1회. 생성 후 showBuildSettings·build·test로 검증 |

---

## 3. 아키텍처 요약

```
App (JGNRHWApp · AppDependencies · AppCoordinator · Route)
 └─ Presentation/{ProductList, ProductDetail, Common}  — UseCase만 호출, @MainActor @Observable ViewModel
      └─ Domain/{Entities, Repositories(protocol), UseCases(struct)}  — Foundation만
            ▲
      Data/{Remote(Endpoint·DTO), Local(FavoriteLocalDataSource), Repositories(Default*)}
       └─ Shared/{Network(HTTPClient), LocalStorage(KeyValueStore), Image(ImageLoader actor · RemoteImage)}
```

핵심 시그니처 (아키텍트 청사진 — 구현 시 이 형태를 따른다):

```swift
// Domain
struct ProductSummary: Sendable, Identifiable, Equatable { let id: Int; let title: String; let price: Double; let thumbnailURL: URL? }
struct ProductPage: Sendable, Equatable { let items: [ProductSummary]; let total: Int; let skip: Int; let limit: Int }
struct Product: Sendable, Identifiable, Equatable { id, title, description, category, price, discountRate, rating, stock, brand: String?, thumbnailURL: URL?, imageURLs: [URL] }
enum ProductListLayoutMode: String, Sendable, Codable { case list, grid }
protocol ProductRepository: Sendable { func fetchPage(skip: Int, limit: Int) async throws -> ProductPage; func fetchDetail(id: Int) async throws -> Product }
protocol FavoriteRepository: Sendable { func toggle(id: Int) async; func observe() async -> AsyncStream<Set<Int>> }  // observe: 현재 스냅샷 먼저 yield (Commit 3 결정)
struct FetchProductPageUseCase: Sendable { let repository: ProductRepository; func execute(skip: Int, limit: Int) async throws -> ProductPage }
struct FetchProductDetailUseCase / ToggleFavoriteUseCase / ObserveFavoritesUseCase  // 같은 형태, 메서드 하나

// Shared
struct Endpoint: Sendable { let path: String; let queryItems: [URLQueryItem] }
protocol HTTPClient: Sendable { func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T }
struct URLSessionHTTPClient: HTTPClient { init(baseComponents: URLComponents = .dummyJSON, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) }
enum NetworkError: Error, Sendable, Equatable { case invalidURL, transport(String), httpStatus(Int), decoding(String) }
protocol KeyValueStore: Sendable { func data(forKey: String) -> Data?; func set(_ data: Data?, forKey: String) }
actor ImageLoader { init(countLimit: Int = 200, totalCostLimit: Int = 50_000_000); func image(for url: URL) async -> UIImage? }
struct RemoteImage<Content: View, Placeholder: View>: View

// Data
struct FavoriteLocalDataSource: Sendable { let store: KeyValueStore; func load() -> Set<Int>; func save(_ ids: Set<Int>) }
@MainActor final class DefaultFavoriteRepository: FavoriteRepository   // Set<Int> 진실 + continuation 목록 방송
struct DefaultProductRepository: ProductRepository { let client: HTTPClient }

// Presentation
@MainActor @Observable final class ProductListViewModel {
    private(set) var items: [ProductSummary]; favoriteIDs: Set<Int>; layoutMode; isLoadingFirstPage; isLoadingNextPage; firstPageError: String?; nextPageError: String?; hasMore
    init(fetchPage:, toggleFavorite:, observeFavorites:, <보기 모드 저장 의존성 — Commit 6 결정>, pageSize: Int = 20, prefetchThreshold: Int = 16, onSelectProduct: @escaping (Int) -> Void)
    func loadFirstPageIfNeeded() async; loadFirstPage() async; refresh() async; loadNextPageIfNeeded(currentIndex: Int); select(_:); toggleFavorite(for:); toggleLayoutMode(); isFavorite(_:) -> Bool
}
@MainActor @Observable final class ProductDetailViewModel { product: Product?; isLoading; errorMessage; isFavorite; init(productID:, fetchDetail:, toggleFavorite:, observeFavorites:); loadIfNeeded() async; toggleFavorite() }

// App
enum Route: Hashable { case productDetail(id: Int) }
@MainActor @Observable final class AppCoordinator { var path: [Route]; init(dependencies:); rootView(); destination(for:); push(_:); pop() }
@MainActor final class AppDependencies { httpClient, keyValueStore, imageLoader, productRepository, favoriteRepository, 4 UseCase; init() }
```

데이터 흐름 요약: (a) `.task` → `loadFirstPageIfNeeded` → UseCase → `items` 교체·`hasMore = items.count < total` (b) 셀 `onAppear` → 3중 가드 → `nextPageTask` → append (c) `refresh` → 진행 중 Task 취소 → skip 0 → 취소된 Task 결과 폐기 (d) 상세 토글 → Repository Set 갱신 + save + 모든 continuation yield → 두 ViewModel의 `for await` 구독이 갱신 (e) 토글 → `layoutMode` 전환 + 즉시 저장, init에서 복원

---

## 3.5 리스크와 제약 (계획 심문 — "무엇을 깨뜨릴 수 있나")

신규 앱이라 깨질 기존 동작은 없다. 계획 자체의 리스크:

| 건드리는 것 | 깨질 수 있는 것 | 근거 | 완화 |
|---|---|---|---|
| Xcode GUI로 만든 pbxproj | 동기화 그룹이 아니거나 빌드 설정 누락 | Commit 1 체크리스트 | 생성 직후 `xcodebuild -showBuildSettings`로 5개 설정 확인 + 빌드 |
| Swift 6 strict + nonisolated 기본 | Sendable·격리 컴파일 에러 다발 | build.md 에러 패턴 | Domain/DTO `Sendable` 조기 부여, 커밋마다 빌드 |
| 임계 인덱스 계산 | off-by-one으로 15/17번째 트리거 | §2 가드 공식 | Commit 6 테스트가 "16번째에서 정확히 1회, 15번째는 0회" 검증 |

---

## 4. 커밋 단위 계획 (bottom-up · 개발자 친화 순서)

| # | 커밋 메시지(안) | 범위 | 직접 검증 포인트 | 상태 |
|---|----------------|------|-----------------|------|
| 1 | `chore: scaffold JGNR-HW xcodeproj with Swift 6 strict settings` | xcodeproj(GUI 생성) + 빈 `App/JGNRHWApp.swift` + 더미 테스트 1개 + 레이어 디렉토리 | `[자동]` 빌드·테스트 1개 통과 · `[수동]` 빌드 설정 5개 값 확인 | ✔️ COMMITTED `a4c3233` (셋업 산출물은 `d2e082b`로 분리) |
| 2 | `feat(shared): add HTTPClient and KeyValueStore infrastructure` | `Shared/Network/*`, `Shared/LocalStorage/*`, `Tests/Doubles/StubHTTPClient·StubKeyValueStore` | `[자동]` 빌드 통과 | ✔️ COMMITTED `999a0bf` |
| 3a | `feat: 도메인 엔티티 추가` | `Domain/Entities/*` (4) | `[자동]` 단독 빌드 | ✔️ COMMITTED `f0d9dc1` |
| 3b | `feat: 리포지토리 계약·유스케이스 추가` | `Domain/Repositories/*` (2) + `Domain/UseCases/*` (4) | `[자동]` 단독 빌드 | ✔️ COMMITTED `8a308cc` |
| 3c | `test: 도메인 테스트 더블 추가` | `Tests/Doubles/StubProductRepository·StubFavoriteRepository` + AUDIT | `[자동]` 빌드 + 아키텍처 검사 23/23 + 테스트 1건 | ✔️ COMMITTED `90b0552` |
| 4a | `feat: 원격 상품 리포지토리 추가` | `Data/Remote/ProductEndpoint` · `Data/Remote/DTO/*` (3) · `Data/Repositories/DefaultProductRepository` · `Tests/Data/ProductDTOMappingTests` | `[자동]` 단독 빌드 + 매핑·쿼리 테스트 3건 | ✔️ COMMITTED `ed5e95e` |
| 4b | `feat: 로컬 찜 리포지토리 추가` | `Data/Local/FavoriteLocalDataSource` · `Data/Repositories/DefaultFavoriteRepository` · `Tests/Data/DefaultFavoriteRepositoryTests` + AUDIT | `[자동]` 테스트 2건(영속 복원·구독자 2개 방송) | ✔️ COMMITTED `4024456` |
| 5a | `feat: 이미지 로더 추가` | `Shared/Image/{ImageLoader,ImageLoaderError}` | `[자동]` 단독 빌드 | ✔️ COMMITTED `ff6c594` |
| 5b | `feat: RemoteImage 뷰 추가` | `Shared/Image/{RemoteImage,ImageLoaderEnvironmentKey}` | `[자동]` 단독 빌드 · `[수동]` Commit 8 후 verify | ✔️ COMMITTED `4cd1f4e` |
| 5c | `test: 이미지 로더 캐시 테스트 추가` | `Tests/Doubles/StubImageURLProtocol` · `Tests/Shared/ImageLoaderTests` + AUDIT | `[자동]` 테스트 2건(병합 1회·디스크 1회 저장) | ✔️ COMMITTED (이 커밋 — 해시는 5d 갱신 시 기입) |
| 5d | `feat: 이미지 디스크 캐시 정리` | `Shared/Image/ImageLoader`(스윕 메서드) + 테스트 1 | `[자동]` 스윕 테스트 | ⬜ |
| 6 | `feat(list): add product list screen with pagination, refresh, layout toggle` | `Presentation/ProductList/**`, `Presentation/Common/*`, `Tests/Presentation/ProductListViewModelTests` (+ 보기 모드 저장 경계 파일 — 결정에 따라 Domain/Data) | `[자동]` 테스트 4개(16번째 1회·새로고침 취소·찜 관찰·모드 영속) | ⬜ |
| 7 | `feat(detail): add product detail screen with favorite sync` | `Presentation/ProductDetail/**`, `Tests/Presentation/ProductDetailViewModelTests` | `[자동]` 테스트 2개(로드·찜 토글 반영) | ⬜ |
| 8 | `feat(app): wire dependencies and coordinator navigation` | `App/AppDependencies·AppCoordinator·Route·JGNRHWApp(교체)` | `[자동]` verify.md 시나리오 1~7 시뮬레이터 · `[수동]` 8(오프라인) | ⬜ |

> 각 검증 포인트에 **`[자동]`/`[수동]` 마커**를 붙인다 — `[자동]`은 시뮬레이터 조작으로 확인 가능한 항목(`/verify-ios`가 실행), `[수동]`은 사람만 판단 가능한 항목.
> Commit 1 직후 `/setup-ios update`를 실행해 `build.md`의 검증된 빌드·테스트 명령을 채운다.

---

## 5. 커밋별 상세 & 상태

### Commit 1 — scaffold ✔️ COMMITTED
- **파일**: `JGNR-HW.xcodeproj/`, `JGNR-HW/App/JGNRHWApp.swift`(`Text("JGNR-HW")`), `JGNR-HWTests/JGNRHWTests.swift`(더미 `@Test` 1개), 빈 디렉토리는 커밋되지 않으므로 레이어 폴더는 각 커밋이 만든다 + 셋업 산출물(`.claude/ios-agent-system/*.md`·`intents/`·`audits/`·`AGENTS.md`·`CLAUDE.md`·`.gitignore`)
- **완료조건**: `xcodebuild build`·`test` 통과, `xcodebuild -showBuildSettings`에 `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`, `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `PRODUCT_BUNDLE_IDENTIFIER = com.appboong.jgnr-hw`. pbxproj에 `PBXFileSystemSynchronizedRootGroup` 존재
- **비목표**: 화면·레이어 코드 없음. Info.plist 물리 파일 없음(`GENERATE_INFOPLIST_FILE = YES`)
- **예산** (기본값: 프로필 §12): 신규 타입 1 · protocol 0 · 모듈 0 · 테스트 1 · 주석 없음 · 밀도 초과 없음
- **세부 결정 포인트**: 생성 방식 — 기본값 안 A(사용자가 Xcode GUI). 체크리스트: File > New > Project > iOS App / Product Name `JGNR-HW` / Organization Identifier `com.appboong` / Interface SwiftUI / Language Swift / Testing System **Swift Testing** / Storage None / 저장 위치 레포 루트(체크박스 "Create Git repository" 해제) → 생성 후 타겟 Build Settings에서 Swift Language Version 6, Strict Concurrency Complete, **Default Actor Isolation = nonisolated**, Minimum Deployments iOS 17.0 → `ContentView.swift` 삭제, `JGNR_HWApp.swift`를 `App/JGNRHWApp.swift`로 이동·개명. 대안 안 B(에이전트가 pbxproj 작성 — ask 승인 필요)는 사용자가 요청할 때만
- **확인 권장 포인트**: `xcodebuild -showBuildSettings | grep -E "SWIFT_VERSION|STRICT_CONCURRENCY|DEFAULT_ACTOR|DEPLOYMENT_TARGET|BUNDLE_IDENTIFIER"` 출력, `grep -c PBXFileSystemSynchronizedRootGroup JGNR-HW.xcodeproj/project.pbxproj`
- **상태**: ✔️ COMMITTED `a4c3233` (2026-09-12 14:21). 셋업 산출물은 사용자 요청으로 별도 커밋 `d2e082b`

### Commit 2 — Shared 인프라 ✔️ COMMITTED
- **파일**: `Shared/Network/{Endpoint,HTTPClient,URLSessionHTTPClient,NetworkError}.swift`, `Shared/LocalStorage/{KeyValueStore,UserDefaultsKeyValueStore}.swift`, `JGNR-HWTests/Doubles/{StubHTTPClient,StubKeyValueStore}.swift`
- **완료조건**: 빌드 통과. `URLSessionHTTPClient`가 2xx 외 상태를 `NetworkError(statusCode:)` 매핑(전용 case·clientError·serverError·unexpectedStatus)으로, 디코딩 실패를 `decoding`, URL 조립 실패를 `invalidURL`로 던진다. `UserDefaultsKeyValueStore`는 `Data?`만 다룬다
- **비목표**: 실제 API 호출·재시도·캐시 헤더. 인증 없음
- **예산**: 신규 타입 6 · protocol 2(HTTPClient·KeyValueStore — 더블 동반) · 테스트 0(Commit 4·6이 더블로 간접 검증) · 주석 없음
- **세부 결정 포인트**: 없음 — 기본값: `URLComponents.dummyJSON` 정적 프로퍼티(scheme https, host dummyjson.com)
- **확인 권장 포인트**: `URLSessionHTTPClient.request` 에러 분기, `Endpoint` → URL 조립에 강제 언래핑 없음
- **상태**: 대기

### Commit 3 — Domain ✔️ COMMITTED (3a `f0d9dc1` · 3b `8a308cc` · 3c `90b0552`)
- **파일**: `Domain/Entities/{ProductSummary,ProductPage,Product,ProductListLayoutMode}.swift`, `Domain/Repositories/{ProductRepository,FavoriteRepository}.swift`, `Domain/UseCases/{FetchProductPage,FetchProductDetail,ToggleFavorite,ObserveFavorites}UseCase.swift`, `JGNR-HWTests/Doubles/{StubProductRepository,StubFavoriteRepository}.swift`
- **완료조건**: 빌드 통과, `check-architecture.sh` Domain 규칙 통과(Foundation만)
- **비목표**: UseCase protocol 없음. 보기 모드 Repository는 Commit 6 결정 후
- **예산**: 신규 타입 10 · protocol 2(더블 동반) · 테스트 0 · 주석 없음
- **세부 결정 포인트**: `FavoriteRepository`를 2개 요구사항(`toggle`·`observe`)으로 축소, `currentFavoriteIDs()` 폐기 — §2 참조 (2026-09-12 착수 게이트). 더블: `actor StubProductRepository`(호출 기록 + 결과 주입), `@MainActor final class StubFavoriteRepository`(테스트가 Set을 yield)
- **확인 권장 포인트**: `FavoriteRepository.observe()`가 `AsyncStream<Set<Int>>`를 돌려주는 시그니처(단일 소스 방송의 계약 — 첫 yield = 현재 스냅샷)
- **리뷰 잔여(다음 커밋 확인)**: ① `ProductListLayoutMode`를 Domain에 둔 근거를 Commit 6 저장 경계 결정 시 커밋 메시지에 한 줄 ② 더블의 다중 구독 구조를 `DefaultFavoriteRepository`(Commit 4)도 동일하게 갈지 착수 게이트에서 확인 ③ `StubProductRepository` 큐 소비 규칙(마지막 결과 재사용)이 Commit 6 첫 테스트 의도와 맞는지 재확인
- **상태**: ✔️ COMMITTED — 3a `f0d9dc1`(Entity 4) · 3b `8a308cc`(protocol 2 + UseCase 4) · 3c(더블 2 + AUDIT). 표면: 타입 12(예산 10, 초과 2 = 더블 중첩 `Failure`·`PageCall`) · protocol 2 · 테스트 0 · 주석 0

### Commit 4 — Data ✔️ COMMITTED (4a `ed5e95e` · 4b `4024456`)
- **파일**: `Data/Remote/ProductEndpoint.swift`, `Data/Remote/DTO/{ProductSummaryDTO,ProductPageDTO,ProductDetailDTO}.swift`(각각 `toEntity()`), `Data/Local/FavoriteLocalDataSource.swift`, `Data/Repositories/{DefaultProductRepository,DefaultFavoriteRepository}.swift`, `JGNR-HWTests/Data/{ProductDTOMappingTests,DefaultFavoriteRepositoryTests}.swift`
- **완료조건**: 테스트 통과 — ① DTO JSON(brand 누락 포함) → Entity 매핑 ② 토글 후 `StubKeyValueStore`에 저장되고 새 인스턴스가 복원 ③ `observe()` 구독자 2개가 토글 1회에 같은 Set을 받음
- **비목표**: 네트워크 실제 연결(verify-ios), 디스크 캐시
- **예산**: 신규 타입 7 · protocol 0 · 테스트 3 · 주석: 찜 ID 인코딩 형식(JSON `[Int]`) 근거 1줄 허용
- **분할 (2026-09-12 착수 게이트)**: **4a** `feat: 원격 상품 리포지토리 추가` — `Data/Remote/ProductEndpoint` · `Data/Remote/DTO/{ProductSummaryDTO,ProductPageDTO,ProductDetailDTO}` · `Data/Repositories/DefaultProductRepository` · `Tests/Data/ProductDTOMappingTests` (6) / **4b** `feat: 로컬 찜 리포지토리 추가` — `Data/Local/FavoriteLocalDataSource` · `Data/Repositories/DefaultFavoriteRepository` · `Tests/Data/DefaultFavoriteRepositoryTests` (3)
- **세부 결정 포인트**: 결정 포인트 없음 — 기본값 확정: UserDefaults 키 `favorite.productIDs`, 값 JSON `[Int]` 정렬 · `ProductEndpoint`는 enum + `static func page(skip:limit:)`/`detail(id:)` · `discountPercentage → discountRate` · 잘못된 URL은 썸네일 nil / `images`는 compactMap 제외 · `DefaultFavoriteRepository`는 다중 구독(목록·상세 동시) + `onTermination` 해제 + 첫 yield 현재 스냅샷. DummyJSON 실측: `brand` 194개 중 92개 누락
- **확인 권장 포인트**: `DefaultFavoriteRepository`의 continuation 보관·해제(`onTermination`에서 제거 — 누수 방지)
- **리뷰 반영 (사용자 지시 "리뷰 지적 모두 수정")**: ① `save` 인코딩 실패 시 `set(nil)` 삭제 → `guard … return`(쓰기 무시) ② `observe()` `bufferingPolicy: .bufferingNewest(1)` 명시 ③ 매핑 테스트 1 → 3 분리(페이지/상세+brand 누락/select 쿼리). 미반영: `load()` 디코딩 실패 → 빈 Set 폴백(리뷰어 "지금 고칠 필요 없음", KeyValueStore가 throw하지 않아 대안 없음 — Commit 6 `LocalStorageKey` 추출 때 재확인)
- **상태**: ✔️ COMMITTED. 표면: 타입 9(예산 7 + 테스트 스위트 2) · protocol 0 · 테스트 5(예산 3 — 사용자 지시로 분리) · 주석 1줄(허용). 위험도 HIGH(고위험 영역 접촉) — 심층 리뷰는 Commit 8 후 `/review-ios` 권장

### Commit 5 — Shared/Image ✔️ COMMITTED (5a `ff6c594` · 5b `4cd1f4e` · 5c) / 5d ⬜
- **파일**: `Shared/Image/{ImageLoader,ImageLoaderError,RemoteImage,ImageLoaderEnvironmentKey}.swift`
- **완료조건**: 빌드 통과. `ImageLoader`가 **메모리(NSCache 상한) → 디스크(Caches/ImageCache, SHA256 파일명) → 네트워크** 순으로 조회, 같은 URL 동시 요청을 in-flight `Task` 딕셔너리로 병합, 디코딩(`UIImage(data:)`)을 actor 안에서 수행. `RemoteImage`는 `.task(id: url)`로 로드하고 사라지면 취소
- **비목표**: 다운샘플링, 프로그레시브 로딩, 디스크 캐시 만료·용량 정리
- **예산**: 신규 타입 4(에러 enum +1) · protocol 0 · 테스트 0(밀도 간결 — verify/trace로 확인) · 주석: in-flight 병합 의도 1줄 + 파일명 해시 근거 1줄 허용
- **세부 결정 포인트 (2026-09-12 착수 게이트 · 사용자 참고 코드 제공)**: 사용자가 메모리→디스크→네트워크 3단 로더 코드를 참고로 제시 → **디스크 캐시를 범위에 포함**(비목표에서 제거). 규칙 충돌 조정: `static let shared` 제거(Locked: AppDependencies 생성 + Environment 주입) · `///` 제거(밀도 간결) · `DataFetcher` protocol 제거(사용처 1곳 → `URLSession` 직접 주입) · `cachedImage(for:)` 제외(호출처 0) · `urls(for:)[0]` → `URL.cachesDirectory` · NSCache 상한 200개/50MB 유지 · `image(for:) async throws -> UIImage` + `ImageLoaderError { invalidResponse, decodingFailed }`
- **커밋 게이트 수정 (2026-09-12 사용자 지시 "리뷰어가 찾은 부분 전부 확인 + 캐시 테스트 + 디스크 정리 방안 + nonisolated 트레이드오프")**: ① `fetch`·`fileURL`을 `nonisolated`로 — 디스크 IO·디코딩을 actor 밖 협력 풀에서, actor 임계구역은 `inFlight`·NSCache만(트레이드오프: 홉 2회·동시 디코딩 메모리 — 썸네일 규모 무시 가능) ② `EnvironmentKey.defaultValue` 계산 프로퍼티 → `static let`(접근마다 새 로더 함정 제거) ③ `init(directoryName:)` 주입(테스트 격리) ④ `JGNR-HWTests/Shared/ImageLoaderTests` 2개(동시 요청 병합 1회 · 디스크 1회 저장+새 인스턴스 재사용) + `Doubles/StubImageURLProtocol` — 예산 테스트 0 → 2(사용자 요청). 디스크 이중 저장 없음 확인(SHA256 경로 동일 + 메모리·디스크 miss일 때만 fetch + in-flight 병합). 유지: `.task` 취소가 fetch를 안 멈춤(대기자 보호), `try? write` best-effort
- **Commit 5d (신규 · 사용자 결정 · 원래 5b에서 번호 이동)**: `feat: 이미지 디스크 캐시 정리` — init에서 nonisolated Task로 1회 스윕: 수정일 7일 초과 삭제 + 총량 100MB 초과 시 오래된 순 삭제. 측정 가능한 변경이라 단독 커밋. 예산 타입 0 · 메서드 1 · 테스트 1(스윕 동작) · 주석 1줄(임계값 근거)
- **확인 권장 포인트**: `ImageLoader.image(for:)`의 병합 분기, `fetch`가 actor 상태를 읽지 않는 것(nonisolated 근거), 메모리 경고 대응은 NSCache 자동
- **상태**: ✔️ COMMITTED — 사용자 요청으로 3분할(5a 로더 2파일 · 5b 뷰 2파일 · 5c 테스트 2파일+AUDIT). 표면: 타입 6(예산 4 + 테스트 2) · protocol 0 · 테스트 2(사용자 요청) · 주석 3줄. 5d 대기

### Commit 6 — ProductList ⬜
- **파일**: `Presentation/ProductList/{ProductListView,ProductListViewModel}.swift`, `Presentation/ProductList/Components/{ProductRowView,ProductGridItemView}.swift`, `Presentation/Common/{FavoriteButton,ErrorRetryView,PriceFormatter}.swift`, `JGNR-HWTests/Presentation/ProductListViewModelTests.swift` + 보기 모드 저장 경계(결정에 따라)
- **완료조건**: 테스트 4개 통과 — ① 16번째 onAppear 반복 5회에 fetch 호출 1회, 15번째는 0회, `total` 도달 후 0회 ② 새로고침이 진행 중 페이지를 취소하고 skip 0 결과로 교체 ③ 찜 스트림 yield가 `favoriteIDs`에 반영 ④ 토글한 모드가 저장되고 새 ViewModel이 복원. 프리뷰로 1열/2열 정적 확인
- **비목표**: Coordinator 통합(Commit 8), 상세 화면
- **예산**: 신규 타입 8 · protocol 0~1(결정 A면 +1, 더블 동반) · 테스트 4 · 주석: 임계 인덱스 공식 근거 1줄 허용
- **로컬 저장 키·인코딩 정리 (2026-09-12 사용자 결정)**: 두 번째 키(보기 모드)가 생기는 이 커밋에서 `Data/Local/LocalStorageKey.swift`에 `enum LocalStorageKey: String { case favoriteIDs, productListLayoutMode }`를 추출하고, `FavoriteLocalDataSource`(Commit 4)의 문자열 키를 이 enum으로 교체한다. Codable 인코딩/디코딩 헬퍼도 사용처가 둘이 되는 이 시점에 Data/Local의 `KeyValueStore` extension으로 추출한다. `Shared/LocalStorage`는 `Data?`만 다루는 상태를 유지 — 키·타입 구분은 Data/Local 소유. 예산: 타입 +1(enum), extension 1
- **세부 결정 포인트**: **보기 모드 저장 경계** — 아키텍트 안(ViewModel이 `KeyValueStore` 직접 주입)은 아키텍처 검사 `Presentation → KeyValueStore` fail 규칙과 충돌. 선택지: **A(기본값·규칙 준수)** Domain `LayoutPreferenceRepository { load() -> ProductListLayoutMode?; save(_:) }` + `Data/Local/DefaultLayoutPreferenceRepository` + UseCase 2개(`LoadLayoutModeUseCase`·`SaveLayoutModeUseCase`) — protocol +1, 타입 +4 / **B(예외 허용)** ViewModel이 `KeyValueStore`를 직접 받고 `check-architecture.sh` 해당 규칙에서 `KeyValueStore` 제외 + 프로필 §3에 "UI 설정 예외" 명문화 — 타입 +0. 착수 게이트에서 확정
- **확인 권장 포인트**: `loadNextPageIfNeeded`의 3중 가드 순서, `refresh()`의 취소·폐기 경로, 1열/2열 전환 시 `ScrollView` 유지
- **상태**: 대기

### Commit 7 — ProductDetail ⬜
- **파일**: `Presentation/ProductDetail/{ProductDetailView,ProductDetailViewModel}.swift`, `JGNR-HWTests/Presentation/ProductDetailViewModelTests.swift`
- **완료조건**: 테스트 2개 통과 — ① 로드 성공 시 `product` 설정·에러 nil, 실패 시 한국어 메시지 ② 토글 후 스트림 yield로 `isFavorite` 반영. 이미지는 `images` 가로 `TabView(.page)`, 없으면 thumbnail
- **비목표**: 이미지 확대, 공유
- **예산**: 신규 타입 2 · protocol 0 · 테스트 2 · 주석 없음
- **세부 결정 포인트**: 없음 — 기본값(필드 9개, `$`·`-12%` 포맷)
- **확인 권장 포인트**: 상세 ViewModel의 구독 Task가 deinit/뷰 소멸 시 취소되는지
- **상태**: 대기

### Commit 8 — App 조립·네비게이션 ⬜
- **파일**: `App/{AppDependencies,AppCoordinator,Route}.swift`, `App/JGNRHWApp.swift`(교체)
- **완료조건**: 시뮬레이터에서 verify.md 시나리오 1~7 통과(`/verify-ios`). `check-architecture.sh` 전체 통과
- **비목표**: README·PR 본문(사용자 작성 — pr-drafts 초안은 회고 뒤 제안), 딥링크
- **예산**: 신규 타입 3 · protocol 0 · 테스트 0 · 주석 없음
- **세부 결정 포인트**: 없음 — 기본값(`NavigationStack(path: $coordinator.path)`, 네비게이션 클로저 `[weak coordinator]`)
- **확인 권장 포인트**: `AppDependencies.init`이 유일한 조립 지점인지, `ImageLoader` environment 주입 위치
- **상태**: 대기

---

## 6. 개발자가 직접 검증하는 방법

```bash
# 빌드 (Commit 1 이후)
xcodebuild build -project JGNR-HW.xcodeproj -scheme JGNR-HW \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO
# 테스트
xcodebuild test -project JGNR-HW.xcodeproj -scheme JGNR-HW \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:JGNR-HWTests
# 아키텍처·보호 경로
bash .claude/ios-agent-system/harness/check-architecture.sh
bash .claude/ios-agent-system/harness/check-protected.sh --cached
```
Xcode: `JGNR-HW.xcodeproj` 열기 → 스킴 `JGNR-HW` → iPhone 17 Pro → ⌘R / ⌘U

---

## 7. 진행 로그 (append-only)
| 시각 | 이벤트 |
|------|--------|
| 2026-09-12 13:55 | AUDIT 생성 (setup-ios Step 5.5). 아키텍트 청사진 반영, 규칙 충돌 2건 조정(보기 모드 저장 경계 → Commit 6 결정 포인트, `URL(string:)!` → URLComponents). 다음 액션: 사용자 최종 컨펌 |
| 2026-09-12 14:05 | 계획 확정 — 사용자 컨펌 완료. 셋업 산출물(.claude/*.md·AGENTS.md·CLAUDE.md·.gitignore)은 Commit 1(scaffold)에 함께 커밋. 하네스 실행물(.claude/hooks/·harness/·settings.json·protected.yml)은 gitignore(로컬 전용). Commit 1 착수 가능 |
| 2026-09-12 14:02 | Commit 1 착수 게이트 통과 — 생성 방식 안 A → 안 B(에이전트 pbxproj 작성)로 변경, 스코프 잠금 없음. 운영 규칙: Fable은 오케스트레이션·확인만, 구현은 opus/sonnet/haiku 위임 |
| 2026-09-12 14:15 | Commit 1 검증 통과 — ios-build(앱 스킴 빌드·arch 23/23·테스트 1건)·ios-review(LOW, Critical 0). buildable folder 실증: 새 폴더 2단계 파일 추가 후 pbxproj md5 불변, 테스트 2건 실행 |
| 2026-09-12 14:21 | ✔️ COMMITTED — 사용자 요청으로 2건 분리: `d2e082b` chore(셋업 산출물) · `a4c3233` chore(scaffold). 다음 액션: Commit 2 착수 게이트(Step 2.0) |
| 2026-09-12 14:40 | 커밋 메시지 컨벤션 확정(type 접두사 + 20자 이내 한글 제목, 본문 4줄 이내) — 커밋 2건 재작성 `d2e082b`·`a4c3233`. Commit 2 착수 게이트 통과(결정 포인트 없음), sonnet 구현 에이전트 스폰 |
| 2026-09-12 14:30 | Commit 2 구현 완료(sonnet) → ios-build 통과 → ios-review HIGH(LocalStorage 고위험 영역), Critical 0. `@preconcurrency import Foundation`을 검사 우회로 판정 → 사용자 결정 안 A(suiteName만 보관) 채택, 수정 위임 |
| 2026-09-12 14:30 | LEARN: 동시성 우회 금지 목록에 `@preconcurrency import`가 없어 구현 에이전트가 에러를 경고로 낮추는 데 사용 — 문자열로 판별 가능하므로 `check-architecture.sh` PATTERN_RULES 승격 후보 (Commit 2, 게이트 미검출 아님 — ios-review가 잡음) |
| 2026-09-12 14:38 | Commit 2 게이트 수정 요청 — NetworkError HTTP 상태 세분화(전용 case 7 + clientError/serverError/unexpectedStatus). 취향·방향 변경이라 LEARN 아님. sonnet 수정 위임 |
| 2026-09-12 14:46 | NetworkError 세분화 반영·빌드 통과. 사용자 결정: 로컬 저장 키·인코딩은 Data/Local 소유, Commit 6에서 `LocalStorageKey` enum + Codable 헬퍼 추출(§5 Commit 6에 기록). Commit 2 커밋 승인 |
| 2026-09-12 14:47 | ✔️ COMMITTED `999a0bf` feat: 네트워크·로컬 저장 인프라 추가. 다음 액션: Commit 3 착수 게이트 |
| 2026-09-12 14:53 | Resume — AUDIT 마커·git log 대사 일치(1·2 COMMITTED). 스코프 잠금 없음. Commit 3 착수 게이트 통과 — 결정 1건: `FavoriteRepository` 2개 요구사항으로 축소(`currentFavoriteIDs` 폐기, observe 첫 yield = 현재 스냅샷). sonnet 구현 에이전트 스폰 |
| 2026-09-12 15:08 | Commit 3 검증 통과 — ios-build(앱 스킴 빌드·arch 23/23·테스트 1건, 자동 수정 0)·ios-review(LOW, Critical 0, High 1: 더블 큐 소비 규칙 비자명 — 보고만). 커밋 게이트에서 사용자 반려: 13파일은 과다 → 3분할 + 이후 커밋당 5~6파일 이하 규칙(§2 기록). 3a `f0d9dc1`·3b `8a308cc` 단독 빌드 확인 후 커밋, 3c(더블+AUDIT) 커밋. 다음 액션: Commit 4 착수 게이트(분할안 제시) |
| 2026-09-12 15:10 | Commit 4 착수 게이트 통과 — 4a(원격 6파일)/4b(로컬 3파일) 분할, 결정 포인트 없음(기본값 §5 기록). DummyJSON 실측으로 DTO 필드 확정. sonnet 구현 에이전트 스폰 |
| 2026-09-12 15:26 | Commit 4 검증 통과 — ios-build(빌드·arch 23/23·테스트 4건 2회 연속, flaky 없음)·ios-review(HIGH: 고위험 영역 접촉, Critical 0, High 1·Medium 1). 사용자 지시로 리뷰 지적 3건 반영(sonnet) → 재검증 테스트 6/6. 4a `ed5e95e` 단독 빌드 확인 후 커밋, 4b(로컬+AUDIT) 커밋. 다음 액션: Commit 5(Shared/Image) 착수 게이트 |
| 2026-09-12 15:30 | ✔️ Commit 4 COMMITTED — 4a `ed5e95e` · 4b `4024456`. Commit 5 착수 게이트 통과 — 사용자 참고 코드(3단 캐시 로더) 채택, 규칙 충돌 5건 조정(§5 기록), 디스크 캐시 범위 포함. sonnet 구현 에이전트 스폰 |
| 2026-09-12 15:44 | Commit 5 검증 통과 — ios-build(경고 0·arch 23/23·회귀 6/6)·ios-review(HIGH: 공유 캐시, Critical 0, 면접관 질문 3: actor 블로킹 IO·defaultValue·취소). 커밋 게이트에서 사용자 요청: 전 항목 확인·캐시 테스트·디스크 정리 방안·nonisolated 트레이드오프 → 결정: nonisolated 적용, 디스크 스윕은 5b 별도 커밋. 테스트·defaultValue 수정 sonnet 위임 |
| 2026-09-12 15:54 | Commit 5 수정 반영 완료(nonisolated·defaultValue static let·directoryName 주입·캐시 테스트 2) → 재검증 8/8·경고 0. 사용자 요청으로 커밋 분할: 5a `ff6c594` · 5b `4cd1f4e` 단독 빌드 확인 후 커밋, 5c(테스트+AUDIT) 커밋. 다음 액션: 5d 디스크 캐시 스윕 착수 게이트 |
| 2026-09-12 15:54 | LEARN: 과잉 산출물 아님 — 커밋 크기 규칙(5~6파일)에 테스트·더블·AUDIT 파일도 포함해 세야 함. 7파일 제안이 두 번째 반려 (Commit 5, 게이트 미검출 아님 — 오케스트레이터 계획 오류) |

> 일반 이벤트 외에 **`LEARN:` 이벤트**를 기록한다 — 검증 파이프라인이 잡지 못해 사용자가 지적한 결함, 자동 수정이 반복된 빌드 에러 등 "규칙으로 만들 후보".

---

## 8. Resume 체크리스트
1. §7 마지막 줄에서 현재 커밋/상태 파악
2. 해당 커밋의 §5 완료조건 확인
3. 미완이면 이어서 구현 → 빌드 → 확인 요청 → 커밋 → §5/§7 갱신
4. `git log --oneline` 으로 실제 커밋 상태 교차검증
