# PROJECT_PROFILE — JGNR-HW

> 이 파일은 `/setup-ios`가 생성하는 **프로젝트 프로필**입니다.
> ios-agent-system의 모든 에이전트가 참조하는 단일 진실 공급원(single source of truth)입니다.
> 프로젝트 컨벤션이 바뀌면 이 파일을 수정하고 `/setup-ios update`로 에이전트 지침에 재반영하세요.
>
> 생성: 2026-09-12 · 분기 B(빈/신규 레포 인터뷰) · 요구사항 원본: `intents/20260912-initial-requirements.md` · 스택 확정표: `PRD.md` §3

## 1. 프로젝트 개요

- **프로젝트명**: JGNR-HW (iOS 개발자 사전 과제 — DummyJSON 상품 목록·상세·찜 앱)
- **앱 타겟**: 단일 앱 `JGNR-HW` (Swift 모듈명은 `JGNR_HW` — Xcode가 하이픈을 언더스코어로 바꾼다. `@testable import JGNR_HW`) + 유닛 테스트 타겟 `JGNR-HWTests`
- **최소 지원 OS**: iOS 17.0
- **Swift 버전 / 동시성**: Swift 6 language mode · strict concurrency `complete` · **`SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`** (Xcode 26 기본값인 MainActor 기본 격리를 쓰지 않는다 — 격리는 타입마다 명시) · Xcode 26.5 (Swift 6.3 툴체인)
- **UX 언어**: 한국어 (상품명·브랜드 등 API 데이터는 영어 원문 그대로)

## 2. 모듈 시스템

- **유형**: 단일 xcodeproj (`JGNR-HW.xcodeproj`, 레포 루트) — 모듈 경계 대신 **디렉토리(레이어)** 로 구조를 나눈다. 과제 조건 "clone 후 추가 작업 없이 빌드"를 만족하기 위해 생성 도구(Tuist/XcodeGen)를 쓰지 않는다
- **프로젝트 생성 명령**: 불필요
- **생성 명령이 필요한 조건**: 해당 없음 — Xcode 16+ **파일 시스템 동기화 그룹**(`PBXFileSystemSynchronizedRootGroup`)으로 프로젝트를 만들어, `JGNR-HW/` 아래에 .swift 파일을 추가하면 pbxproj 편집 없이 타겟에 포함된다

### 모듈 구조

```
ios-coding-assignment-2026/
├── JGNR-HW.xcodeproj              # 단일 프로젝트 (앱 + 테스트 타겟)
├── JGNR-HW/                       # 앱 소스 루트 (check-architecture.sh의 SOURCE_ROOT)
│   ├── App/                       # 진입점 · 조립 · 네비게이션 — 유일하게 모든 레이어를 아는 곳
│   │   ├── JGNRHWApp.swift        #   @main, WindowGroup에 AppCoordinator의 루트 뷰
│   │   ├── AppDependencies.swift  #   수동 DI 조립 지점: HTTPClient·KeyValueStore → Repository → UseCase
│   │   ├── AppCoordinator.swift   #   @MainActor @Observable — NavigationStack path 소유, Route → View+ViewModel 조립
│   │   └── Route.swift            #   enum Route: Hashable { case productDetail(id: Int) }
│   ├── Presentation/              # SwiftUI View + ViewModel (화면별 폴더)
│   │   ├── ProductList/
│   │   ├── ProductDetail/
│   │   └── Common/                #   화면 공용 뷰·포맷터 (FavoriteButton, ErrorRetryView, PriceFormatter)
│   ├── Domain/                    # 순수 Swift — Foundation 외 import 금지
│   │   ├── Entities/              #   Product, ProductSummary, ProductPage (struct, Sendable)
│   │   ├── Repositories/          #   ProductRepository, FavoriteRepository (protocol) — 보기 모드 저장 경계는 AUDIT Commit 6 결정
│   │   └── UseCases/              #   FetchProductPageUseCase, FetchProductDetailUseCase, ToggleFavoriteUseCase, ObserveFavoritesUseCase (struct)
│   ├── Data/                      # Repository 구현 — 원격/로컬 책임 분리
│   │   ├── Remote/                #   ProductEndpoint, DTO(ProductDTO·ProductPageDTO·ProductSummaryDTO), DTO → Entity 매핑
│   │   ├── Local/                 #   FavoriteLocalDataSource (KeyValueStore 위의 찜 ID 집합), 보기 모드 저장
│   │   └── Repositories/          #   DefaultProductRepository(원격), DefaultFavoriteRepository(로컬 + 방송)
│   └── Shared/                    # 도메인 무관 인프라 — 상위 레이어 타입을 모른다
│       ├── Network/               #   Endpoint, HTTPClient(protocol), URLSessionHTTPClient, NetworkError
│       ├── Image/                 #   ImageLoader(actor, NSCache + in-flight 병합), RemoteImage(SwiftUI 뷰)
│       └── LocalStorage/          #   KeyValueStore(protocol), UserDefaultsKeyValueStore
└── JGNR-HWTests/                  # Swift Testing — 레이어별 폴더 미러 (Domain/, Presentation/, Data/) + Doubles/
```

### 새 모듈 생성 기준

해당 없음 — 단일 타겟. 대신 **새 레이어 디렉토리**는 만들지 않는다(App·Presentation·Domain·Data·Shared 고정). 새 화면은 `Presentation/<화면명>/` 폴더, 새 인프라는 `Shared/<역할>/` 폴더로만 추가한다. Shared 하위 폴더 추가 기준: 도메인을 모르는 기술 관심사(네트워크·이미지·저장소처럼)이고 2개 이상의 상위 레이어 파일이 쓸 때.

### 외부 의존성 (라이브러리 / SDK)

없음 — 표준 라이브러리만 (Foundation, SwiftUI, Observation, Swift Testing). 과제 조건 "clone 후 추가 작업 없이 빌드"와 "외부 라이브러리 사용 시 이유 설명"을 고려해 의존성 0으로 확정. 이미지 캐시·네트워크·저장소는 자체 구현. **새 의존성 추가는 사용자 의사결정 사항 — 에이전트가 임의로 추가하지 않음.**

## 3. 디자인 패턴 / 아키텍처

- **패턴**: MVVM-C — `@MainActor @Observable` ViewModel + NavigationStack path를 소유한 `@MainActor @Observable` AppCoordinator
- **아키텍처 추상화 수준**: 풀 Clean Architecture — Presentation → Domain(Entity · Repository protocol · UseCase) ← Data(Repository 구현) · Shared(인프라). 의존 방향은 항상 Domain을 향한다
- **비동기 처리 방식**: Swift Concurrency 전용 — `async/await`, `actor`, `AsyncStream`, `Task`. Combine·RxSwift·GCD(`DispatchQueue`)·완료 핸들러 도입 금지. `Task.detached`·`@unchecked Sendable`·`nonisolated(unsafe)`는 아키텍처 검사가 경고한다
- **DI 방식**: 수동 이니셜라이저 주입. 조립 지점은 두 곳뿐 — `App/AppDependencies.swift`(인프라 → Repository → UseCase 생성, 앱 수명 동안 단일 인스턴스)와 `App/AppCoordinator.swift`(Route마다 ViewModel 생성 + 네비게이션 클로저 주입). 그 외 어디서도 `init()`으로 의존성을 만들지 않는다. 싱글턴·전역 `shared` 금지
- **네비게이션 방식**: `AppCoordinator`가 `path: [Route]`를 소유하고 루트 `NavigationStack(path:)` + `navigationDestination(for: Route.self)`로 화면을 만든다. ViewModel은 Coordinator를 모른다 — 이동이 필요한 ViewModel은 `onSelectProduct: (Int) -> Void` 같은 **클로저를 주입**받고, Coordinator가 `{ [weak self] id in self?.push(.productDetail(id: id)) }`를 넘긴다
- **학습 데이터 이후 API / 문서 링크**: 없음 — iOS 17 안정 API와 Swift 6 표준 문법 범위. iOS 26 전용 API(Liquid Glass 등)·Swift 6.2+ 신규 타입 사용 안 함. 단 **빌드 설정 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`** 는 Xcode 26 신규 설정이므로 pbxproj에 명시적으로 넣는다

### 피처(화면) 단위 파일 구조

```
Presentation/ProductList/
├── ProductListView.swift            # 화면. 상태 분기(로딩/에러/목록) + 1열/2열 레이아웃 전환
├── ProductListViewModel.swift       # @MainActor @Observable. 페이지네이션·새로고침·찜 관찰·보기 모드
(ProductListLayoutMode는 Domain/Entities — 영속 대상이라 Entity)
└── Components/
    ├── ProductRowView.swift         # 1열 셀
    └── ProductGridItemView.swift    # 2열 셀
Domain/UseCases/FetchProductPageUseCase.swift
Data/Remote/ProductEndpoint.swift + DTO/…               # 새 API가 생길 때만
JGNR-HWTests/Presentation/ProductListViewModelTests.swift
```

### 패턴 핵심 규칙

- **View**: 상태를 그리고 사용자 이벤트를 ViewModel 메서드로 넘기는 것만 한다. 비즈니스 판단·네트워크·저장소 접근·페이지 계산 금지. ViewModel은 Coordinator가 만들어 주입한다(`let viewModel`, 바인딩이 필요하면 `@Bindable`). View 안에서 `ViewModel()`·UseCase·Repository를 생성하지 않는다
- **ViewModel**: `@MainActor @Observable final class`. **UseCase만** 의존한다(Repository·HTTPClient·UserDefaults 직접 참조 금지 — 아키텍처 검사가 막는다). 상태는 `private(set) var`로 노출, 변경은 메서드로만. 비동기 작업은 `Task`로 시작하고 진행 중인 `Task`를 프로퍼티로 잡아 중복 실행을 막는다(페이지네이션 필수). `import SwiftUI` 금지 — `Foundation` + `Observation`만
- **UseCase**: `Domain/UseCases/`의 `struct`, `Sendable`, 메서드 하나(`execute(...)` 또는 `callAsFunction`). Repository protocol만 의존. 프로토콜을 따로 만들지 않는다 — 테스트는 Repository 더블로 UseCase를 실제로 조립한다
- **Repository protocol**(Domain): `Sendable`, `async throws`. 원격은 `ProductRepository`(fetchPage/fetchDetail), 로컬은 `FavoriteRepository`(isFavorite/toggle/favoriteIDs 스트림). **원격과 로컬을 한 Repository에 섞지 않는다** — 과제의 "책임 구분" 요구를 이 경계로 표현한다
- **Repository 구현**(Data): `Default*Repository`. 원격은 `HTTPClient` + `Endpoint` + DTO 매핑, 로컬은 `KeyValueStore`. DTO는 Data 밖으로 나가지 않는다 — Domain Entity로 변환해서 반환
- **찜 동기화 단일 소스**: `DefaultFavoriteRepository`는 앱 수명 단일 인스턴스(`AppDependencies`가 보유). 메모리의 `Set<Int>`를 진실로 삼고 `AsyncStream<Set<Int>>`로 방송하며, 변경 시 `KeyValueStore`에 즉시 저장한다. 목록·상세 ViewModel은 `ObserveFavoritesUseCase`로 같은 스트림을 구독한다 — 화면 간 콜백·NotificationCenter로 동기화하지 않는다
- **격리 명시**: 기본 격리가 `nonisolated`이므로 UI 상태를 가진 타입(ViewModel·Coordinator·SwiftUI 뷰 보조 타입)은 반드시 `@MainActor`를 붙인다. 공유 가변 상태는 `actor`(ImageLoader) 또는 `@MainActor` 클래스(FavoriteRepository)로 보호한다. 경계를 넘는 값은 `Sendable` struct
- **에러**: Shared의 `NetworkError`는 기술 정보만. 사용자 문구는 Presentation(`Common/`)에서 한국어로 매핑

## 4. 뷰 프레임워크 / 디자인 시스템

- **뷰 프레임워크**: SwiftUI 전용 (UIKit은 `UIImage` 디코딩 등 Shared/Image 내부에서만)
- **레이아웃 방식 (UIKit 시)**: 해당 없음
- **디자인 시스템 모듈**: 없음 — 시스템 표준 컴포넌트 + `Presentation/Common/` 공용 뷰 + `Shared/Image/RemoteImage`

### 사용 가능한 공용 컴포넌트

- `RemoteImage(url: URL?) { image in … } placeholder: { … }` — `Shared/Image`. 자체 `ImageLoader` 캐시를 쓰는 비동기 이미지 뷰. **`AsyncImage` 직접 사용 금지**(캐시 없음)
- `FavoriteButton(isFavorite: Bool, action: () -> Void)` — `Presentation/Common`. 하트 토글, 접근성 라벨 "찜"/"찜 해제"
- `ErrorRetryView(message: String, retry: () -> Void)` — `Presentation/Common`. 에러 문구 + "다시 시도" 버튼
- `PriceFormatter` — `Presentation/Common`. USD 통화 문자열(`$1,234.56`), 할인율(`-12%`)
- 위 목록에 없는 공용 뷰는 두 번째 사용처가 생길 때 `Common/`으로 추출한다

### 색상 / 폰트 규칙

- 색상: 시스템 시맨틱 컬러만 — `.primary`, `.secondary`, `Color.accentColor`, `Color(.systemBackground)`, `Color(.secondarySystemBackground)`. 찜 하트는 `.red`(활성)/`.secondary`(비활성). 하드코딩 `Color(red:green:blue:)`·hex 금지
- 폰트: 시스템 텍스트 스타일만 — `.headline`(상품명), `.subheadline`·`.body`, `.caption`(부가 정보). 고정 포인트 `.system(size:)` 금지 (Dynamic Type)
- 다크모드: 시맨틱 컬러를 쓰므로 별도 처리 없음

### View 작성 패턴 / 금지 패턴

- 표준: `struct XxxView: View { let viewModel: XxxViewModel; var body: some View { content.task { await viewModel.load() } } }` + `@ViewBuilder private var content` 안에서 `로딩 / 에러 / 정상` 분기. 셀 컴포넌트는 Entity가 아니라 표시에 필요한 값(제목·가격 문자열·URL·isFavorite)만 받는다
- 리스트: 1열은 `List` 또는 `LazyVStack`, 2열은 `LazyVGrid(columns: 2)`. 두 모드가 **같은 데이터 배열과 같은 `onAppear` 페이지 트리거**를 쓴다. 전환 시 `ScrollView` 하나 안에서 컨테이너만 바꾼다(상태 리셋 방지)
- 금지: View에서 `URLSession`·`UserDefaults`·Repository 접근, View 안 `Task.detached`, `GeometryReader`로 셀 크기 계산(그리드 컬럼은 `.flexible()`), 고정 `.frame(width:height:)`(아이콘·썸네일 정사각 비율은 `aspectRatio`로), `AsyncImage`, `#Preview`에 실제 네트워크 의존성

## 5. 네트워크 / 데이터 레이어

- **클라이언트**: `Shared/Network/HTTPClient` protocol — `func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T`. 구현 `URLSessionHTTPClient(session: URLSession = .shared, decoder: JSONDecoder)`. 인증 없음(공개 API)
- **Endpoint**: `Shared/Network/Endpoint` struct(`path`, `queryItems`) — 도메인 무관. `Data/Remote/ProductEndpoint`가 `static func page(limit:skip:)`, `static func detail(id:)`로 구체 엔드포인트를 만든다. Base URL `https://dummyjson.com`
- **API 계약** (DummyJSON):
  - 목록 `GET /products?limit=20&skip={n}&select=id,title,price,thumbnail` → `{ products: [ {id,title,price,thumbnail} ], total, skip, limit }`
  - 상세 `GET /products/{id}` → `{ id, title, description, category, price, discountPercentage, rating, stock, brand?, thumbnail, images: [String] }` (`brand`는 없는 상품이 있다 — optional)
- **DTO / 매핑**: DTO는 `Data/Remote/DTO/`에 `Decodable & Sendable` struct. 서버 필드명 그대로(`discountPercentage`) 두고 `toEntity()`에서 Domain 네이밍(`discountRate`, `thumbnailURL: URL?`)으로 바꾼다. 문자열 URL은 매핑 시 `URL(string:)`으로 변환하고 실패하면 `nil`(크래시 금지)
- **에러 타입**: `NetworkError: Error, Sendable` — `invalidURL`, `transport(underlying)`, `httpStatus(Int)`, `decoding(underlying)`. Repository는 그대로 던지고, Presentation이 한국어 문구로 매핑
- **동시성**: `URLSessionHTTPClient`는 `Sendable` struct. 취소는 `Task` 취소를 그대로 전파(`URLSession.data(for:)`는 취소 지원)

## 6. 에러 / 로딩 처리

- 전역 매니저 없음 — **화면별 ViewModel이 자체 처리**. 목록: `isLoadingFirstPage`, `isLoadingNextPage`, `firstPageError: String?`, `nextPageError: String?`. 상세: `isLoading`, `errorMessage`
- 첫 로드 실패 → 전체 화면 `ErrorRetryView`. 다음 페이지 실패 → 목록 유지 + 푸터에 인라인 재시도. 새로고침 실패 → 기존 목록 유지 + 에러 표시
- 페이지네이션 중복 방지: `loadNextPageIfNeeded(currentIndex:)`가 ① 진행 중 Task 있음 ② `hasMore == false` ③ 인덱스가 임계값 미만 중 하나면 즉시 return. 트리거 임계 = `items.count - pageSize + 15`(마지막 페이지의 16번째)
- 새로고침 중에는 다음 페이지 로드를 시작하지 않고, 새로고침 완료 시 진행 중 페이지 Task를 취소한다
- 찜 토글은 낙관적으로 즉시 반영(로컬이라 실패 경로가 사실상 없음). 저장 실패는 로그만
- 보기 방식(1열/2열)은 UserDefaults에 영속(사용자 확정) — 목록 ViewModel이 시작 시 읽고 토글 시 저장한다. 찜과 같은 `KeyValueStore`를 쓰되 키·UseCase는 분리

## 7. 네이밍 / 코드 컨벤션

- 약어는 전부 대문자: `productID`(not productId), `thumbnailURL`(not thumbnailUrl), `imageURLs`
- 접미사 규칙: `*View`, `*ViewModel`, `*UseCase`, `*Repository`(protocol) / `Default*Repository`(구현), `*DTO`, `*Endpoint`, `*DataSource`, `*Store`(KeyValue). 파일명 = 최상위 타입명
- 타입: `final class`는 상태 보유(ViewModel·Coordinator·FavoriteRepository)에만, 나머지는 `struct`/`enum`. Domain Entity·DTO·UseCase는 `Sendable`
- 접근 제어: 단일 모듈이므로 `internal` 기본. 상태는 `private(set)`. 테스트가 볼 필요 없는 헬퍼는 `private`
- 강제 언래핑·`try!`·`as!` 금지(테스트 코드 제외). 옵셔널 URL은 `nil` 허용 + 플레이스홀더
- 매직 넘버 금지: 페이지 크기·임계값은 ViewModel의 `static let` 또는 이니셜라이저 파라미터(테스트에서 작게 주입)
- UX 문자열: 한국어 리터럴을 View/Common에 직접(로컬라이제이션 파일 없음). Domain·Data에 사용자 문구 금지
- `#Preview`: 정적 더미 데이터로만. 네트워크·UserDefaults에 의존하는 프리뷰 금지
- `// TODO`·`// FIXME`는 AUDIT에 적고 코드에 남기지 않는다

### 테스트 코드 네이밍 (공통 표준 — 레포에 기존 관례가 명시된 경우만 그것을 우선)

- **XCTest / RxTest**: 영어 자연어 문장형 + 행위 중심. 비개발자에게 시나리오를 설명하듯 평문 문장을 언더스코어로 잇는다.
  - 권장: `func test_delivery_with_past_date_is_invalid()`
  - 지양: `func test_isDeliveryValid_invalidDate_returnsFalse()` (템플릿형 — MethodName_Scenario_ExpectedResult)
  - 테스트명에 SUT 메서드명(API명)을 넣지 않는다 — 구현이 아니라 동작(behavior)을 서술 (리팩토링으로 메서드명이 바뀌어도 테스트명이 유효해야 함)
- **Swift Testing** (이 프로젝트의 테스트 프레임워크): 메서드명은 영어 + `@Test("한글 설명")` display name으로 시나리오 서술.
  - 예: `@Test("16번째 아이템이 보이면 다음 페이지를 한 번만 요청한다") func nextPageIsRequestedOnceWhenSixteenthItemAppears()`
  - `@MainActor` ViewModel 테스트는 `@Suite @MainActor struct`로 선언. 더블은 `JGNR-HWTests/Doubles/`에 `Stub*`/`Spy*` 접두사

### 주석 정책 (공통 표준)

- 주석은 **설명이 정말 필요한 곳에만** 단다: 비자명한 의도/설계 근거, 엣지 케이스가 중요한 이유, 관련 이슈 참조 등.
- 코드나 이름(함수명·타입명)으로 표현 가능한 내용을 주석으로 중복 서술하지 않는다 — 함수명을 번역·재진술한 주석 금지 (drift만 유발).
- 밀도 "간결": `///` 문서화 주석·`MARK` 구획을 새로 도입하지 않는다 (§12)

## 8. 빌드 / 검증

- **워크스페이스/프로젝트 경로**: `JGNR-HW.xcodeproj` (레포 루트) — 초기 구축 Commit 1이 생성
- **빌드 스킴**: `JGNR-HW` 하나. 모든 수정은 이 스킴으로 빌드한다(모듈 스킴 없음)
- **빌드 도구**: XcodeBuildMCP (연결 확인됨) — 폴백 `xcodebuild`
- **빌드 컨피그 / 타겟 분리**: 기본 Debug·Release만. xcconfig 없음. 검증은 Debug
- **린트**: 없음 — SwiftLint 미사용(사용자 결정). 하네스 게이트의 린트 차단 경로는 비활성이며 보호 경로·숨은 유니코드·무력화 주석 검사만 동작. 컨벤션은 리뷰 게이트와 `check-architecture.sh`가 본다
- **CI/CD**: 없음 (사용자 결정). 로컬 하네스만
- **유닛 테스트 정책**: 핵심 도메인·뷰모델 필수 — Swift Testing. 대상: ViewModel(페이지네이션 중복 방지·새로고침·찜 관찰·보기 모드), UseCase, `DefaultFavoriteRepository`(토글·영속·방송), DTO→Entity 매핑. 네트워크는 `HTTPClient` 스텁으로 대체. 밀도 "간결": 수용 기준당 1개
- **UI 테스트 정책**: 작성 안 함. 시뮬레이터 확인은 `/verify-ios`
- **테스트 실행 명령**: `xcodebuild test -project JGNR-HW.xcodeproj -scheme JGNR-HW -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:JGNR-HWTests` — **미정(미검증)**: Commit 1(scaffold) 이후 `/setup-ios update`가 실제 실행 수(N>0)를 확인해 `build.md`에 기록

## 9. 코드 리뷰 체크리스트

리뷰 에이전트가 모든 리뷰에서 확인하는 프로젝트 특화 항목:

- [ ] Presentation이 UseCase만 의존한다 — Repository·HTTPClient·UserDefaults·DTO 직접 참조 없음
- [ ] Domain에 Foundation 외 import·DTO·ViewModel 참조 없음. UseCase는 struct + Repository protocol만
- [ ] 원격(ProductRepository)과 로컬(FavoriteRepository) 책임이 섞이지 않았다
- [ ] 찜 상태의 진실은 `DefaultFavoriteRepository` 하나 — 화면 간 콜백/NotificationCenter로 동기화하지 않았다
- [ ] 페이지네이션: 진행 중 Task 가드·`hasMore` 가드·임계 인덱스(마지막 페이지 16번째)가 있고, 테스트가 "한 번만 호출"을 검증한다
- [ ] 새로고침이 `skip=0`으로 리셋하고 진행 중 페이지 Task를 취소한다
- [ ] `@MainActor`가 ViewModel·Coordinator·UI 상태 타입에 명시돼 있다(기본 격리 nonisolated). `@unchecked Sendable`·`nonisolated(unsafe)`·`Task.detached`·`DispatchQueue` 신규 추가 없음
- [ ] Combine·GCD·완료 핸들러 혼입 없음. 외부 라이브러리 import 없음(PRD §3)
- [ ] 의존성 생성은 `AppDependencies`·`AppCoordinator`에서만. View/ViewModel 안 `init()` 조립·싱글턴 없음
- [ ] ViewModel은 Coordinator를 모른다 — 네비게이션은 주입된 클로저
- [ ] `AsyncImage` 미사용, `RemoteImage` 사용. ImageLoader가 in-flight 요청을 병합한다
- [ ] 약어 대문자(`productID`·`thumbnailURL`), 접미사 규칙, 강제 언래핑·`try!` 없음(테스트 제외)
- [ ] UX 문구 한국어, Domain·Data에 사용자 문구 없음
- [ ] 고정 `.frame(width:height:)`·`GeometryReader` 셀 계산·고정 포인트 폰트·하드코딩 색상 없음
- [ ] Swift Testing 네이밍(영어 메서드 + `@Test("한글")`), 수용 기준당 테스트 1개, 재진술 주석·`///`·`MARK` 신규 도입 없음
- [ ] pbxproj 직접 편집 없음(동기화 그룹) — 새 파일은 디렉토리에 추가만

## 10. 성능 분석 특화 포인트

- `Shared/Image/ImageLoader`: NSCache 상한(`countLimit`/`totalCostLimit`) 설정 여부, 메모리 경고 시 비움, 같은 URL 동시 요청 병합, 셀 재사용 시 이전 요청 취소
- 목록 스크롤: 셀에서 이미지 디코딩이 메인에서 일어나지 않는지(`UIImage(data:)`는 actor 안에서), `LazyVStack`/`LazyVGrid` 사용, 1열↔2열 전환 시 전체 리로드·이미지 재요청 없음
- 페이지네이션: 같은 페이지 중복 요청(네트워크 로그로 확인), `total` 도달 후 요청 0건
- 찜 스트림: ViewModel이 사라질 때 `AsyncStream` 구독 Task가 취소되는지(누수·좀비 구독)
- 초기에는 위 항목만 — 이슈 발견 시 축적

## 11. 설치된 도구 현황

<!-- /setup-ios Step 4 완료 후 기록 (2026-09-12) -->

| 도구 | 상태 | 비고 |
|------|------|------|
| XcodeBuildMCP | ✅ 연결됨 (플러그인 번들, npx) | 빌드/시뮬레이터 |
| Xcode MCP (mcpbridge) | ✅ 등록됨 (user 스코프, 2026-09-12) | 파일 단위 진단·프리뷰 렌더·문서 검색 전용 — 빌드에는 쓰지 않음. 다음 세션부터 연결 |
| xctools MCP | ⬜ 미등록 (선택) | 미설치 시 ios-trace가 `xcrun xctrace`/정적 분석으로 폴백 |
| apple-docs MCP | ⬜ 미등록 | 폴백: WebSearch |
| context7 MCP | ⬜ 미등록 | 폴백: WebSearch |
| swiftlens MCP | ⬜ 미등록 | 폴백: Grep/Glob |
| axiom | ⬜ 미등록 | 선택 |
| Figma MCP | ⬜ 미등록 | 디자인 파일 없음 — 해당 없음 |
| pr-review-toolkit 플러그인 | ✅ 설치됨 | ios-review 하위 리뷰어 |
| feature-dev 플러그인 | ✅ 설치됨 | code-explorer/architect |
| SwiftLint CLI | ✅ 설치됨 (미사용) | 린트 정책 "사용 안 함" — .swiftlint.yml 없음 |
| 모듈 생성 CLI | 해당 없음 | 단일 xcodeproj (tuist는 설치돼 있으나 미사용) |
| xcbeautify | ⬜ 미설치 | 선택 — 없으면 xcodebuild 원출력 사용 |
| gh CLI | ✅ 2.97 | draft PR 제안에 사용 |

## 12. 워크플로 옵션

<!-- /setup-ios Round 4(신규) 또는 분기 A 확정 단계에서 한 번 정한다. task-ios Step 0이 이 섹션만 추가로 읽는다. 매 작업 묻지 않는다 -->

| 옵션 | 값 | 효과 |
|------|----|------|
| intent 자동 정리 | 예 | 예: 자유 서술로 시작한 비단순 작업을 task-ios Step 1이 "정리만" 규칙으로 `intents/`에 먼저 저장(질문 0) → AUDIT §1이 그 경로를 가리킴. 아니오: 파일 없이 진행(AUDIT §1 "없음") |
| CI AI 리뷰 | 끔 | 라벨: ci.yml에 ai-review 잡 생성, 라벨 붙은 PR만 실행 |
| 회고 시 평가 케이스 저장 제안 | 아니오 | 예: 회고 multiSelect에 "평가 케이스로 저장" 선택지 추가 |
| draft PR 제안 | 예 — **본문 초안은 `.claude/ios-agent-system/pr-drafts/{YYYYMMDD}-{slug}.md`에 먼저 저장**(gitignore 처리됨). `gh pr create --draft`는 사용자 승인 시에만 실행하고, 초안 파일은 최종 PR 본문(설계 설명·기술 판단·개선점·AI 활용 내역) 작성 시 참고 자료로 남긴다 | 아니오: 회고 뒤 PR 제안을 띄우지 않음 |
| intent 승인 필요 | 아니오 | 예: `/task-ios <intent 파일>`은 `status: approved`인 intent만 받음. 아니오: 세션 안 컨펌이 승인 |

### 산출물 밀도 (task-ios 커밋 예산의 기본값)

<!-- /setup-ios가 분기 A·B 공통으로 한 번 묻는다. task-ios Step 1.5가 커밋 예산을 잡을 때 이 값을 기본값으로 쓰고, 기본값을 넘길 때만 Step 1.6에서 묻는다. update 시 보존 -->

프리셋: 기타(축별 지정) — 추상화 **표준** · 테스트 **간결** · 주석 **간결** · 모듈 **표준**

| 축 | 값 | 간결 | 표준 | 풍부 |
|----|----|------|------|------|
| 추상화 | 표준 | 새 protocol 0. 테스트 더블이 실제로 있는 경계만 예외 | 테스트 경계 + 구현이 2개 이상 예정된 곳 | 프로젝트 패턴이 정한 레이어 인터페이스는 사용처가 1곳이어도 허용 |
| 테스트 | 간결 | 수용 기준당 1개, 도메인·뷰모델만 | 수용 기준당 1개 + 경계 케이스 1개 | 전 레이어, 경계·에러 케이스 포함 |
| 주석 | 간결 | 비자명한 의도·근거만. `///` 문서화 주석 없음, `MARK` 신규 도입 없음 | + public API에만 `///` | 모든 public 타입·메서드 `///` + `MARK` 구획 |
| 모듈 | 표준 | 새 모듈 0 — 기존 모듈에 추가 | §2 "새 모듈 생성 기준"을 충족할 때만 | 피처마다 모듈 |

> 추상화 "표준"의 이 프로젝트 적용: protocol은 **테스트 더블이 있는 경계 4개**(ProductRepository · FavoriteRepository · HTTPClient · KeyValueStore)로 시작한다. UseCase·ViewModel·Coordinator·ImageLoader는 protocol 없이 concrete. 새 protocol은 더블이 실제로 생기거나 두 번째 구현이 예정된 때만.
