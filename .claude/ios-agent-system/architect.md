# 프로젝트 지침 — ios-architect

> `/setup-ios`가 생성하는 파일입니다. ios-architect 에이전트(및 설계 관련 탐색 에이전트) 호출 시
> 오케스트레이터가 이 내용을 프롬프트에 주입합니다. 전체 세부 규칙: `PROJECT_PROFILE.md` §2~§3.

## 모듈 시스템

- **유형**: 단일 xcodeproj (`JGNR-HW.xcodeproj`, 레포 루트). 모듈 경계 대신 디렉토리(레이어)로 구조를 나눈다
- **프로젝트 생성 명령**: 불필요 (조건: 해당 없음 — Xcode 16+ 파일 시스템 동기화 그룹이라 `JGNR-HW/` 아래 .swift 추가만으로 타겟에 포함. pbxproj 편집 금지)

### 모듈 구조

```
JGNR-HW/                    # SOURCE_ROOT (Swift 모듈명 JGNR_HW)
├── App/                    # 조립·네비게이션: JGNRHWApp, AppDependencies(DI), AppCoordinator(path), Route
├── Presentation/           # 화면별 폴더: ProductList/, ProductDetail/, Common/
├── Domain/                 # Entities/, Repositories/(protocol), UseCases/(struct) — Foundation만
├── Data/                   # Remote/(Endpoint·DTO·매핑), Local/(FavoriteLocalDataSource), Repositories/(Default*)
└── Shared/                 # Network/(HTTPClient), Image/(ImageLoader actor + RemoteImage), LocalStorage/(KeyValueStore)
JGNR-HWTests/               # Swift Testing — Domain/, Presentation/, Data/, Doubles/
```

의존 방향: `App → Presentation → Domain ← Data`, `Data → Shared`, `Presentation → Shared/Image(RemoteImage 뷰만)`. Domain은 아무것도 모른다. Shared는 상위 레이어 타입을 모른다.

### 새 모듈 생성 기준

해당 없음 — 단일 타겟. 새 레이어 디렉토리를 만들지 않는다(5개 고정). 새 화면 = `Presentation/<화면명>/`, 새 인프라 = `Shared/<역할>/`(도메인 무관 + 사용처 2곳 이상일 때만).

### 외부 의존성 (확정 목록 — 임의 추가 금지)

없음 — 표준 라이브러리만 (Foundation · SwiftUI · Observation · Swift Testing). 이미지 캐시·네트워크·저장소 자체 구현. 새 의존성은 사용자 의사결정 사항.

## 디자인 패턴 / 아키텍처

- **패턴**: MVVM-C — `@MainActor @Observable` ViewModel + NavigationStack path를 소유한 `AppCoordinator`
- **아키텍처 추상화 수준**: 풀 Clean — Presentation / Domain(Entity·Repository protocol·UseCase) / Data(Repository 구현) / Shared(인프라)
- **비동기 처리 방식**: Swift Concurrency 전용 — async/await · actor · AsyncStream · Task (이 방식 외 도입은 사용자 의사결정 사항. Combine·GCD·완료 핸들러 금지)
- **DI 방식**: 수동 이니셜라이저 주입. 조립 지점은 `App/AppDependencies.swift`(인프라→Repository→UseCase, 앱 수명 단일 인스턴스)와 `App/AppCoordinator.swift`(Route별 ViewModel 생성 + 네비게이션 클로저 주입) 두 곳뿐. 싱글턴·`shared` 금지
- **네비게이션 방식**: `AppCoordinator.path: [Route]` + 루트 `NavigationStack(path:)` + `navigationDestination(for: Route.self)`. ViewModel은 Coordinator를 모른다 — `onSelectProduct: (Int) -> Void` 클로저 주입
- **학습 데이터 이후 API / 문서 링크**: 없음 — iOS 17 안정 API·Swift 6 표준 문법. 단 빌드 설정 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`(Xcode 26 설정)를 쓰므로 **모든 UI 상태 타입에 `@MainActor`를 명시**해야 한다

### 피처(화면) 단위 파일 구조

```
Presentation/<Feature>/
├── <Feature>View.swift              # 상태 분기(로딩/에러/정상)만
├── <Feature>ViewModel.swift         # @MainActor @Observable final class — UseCase만 의존
└── Components/<Cell>View.swift      # 표시 값만 받는 셀
Domain/UseCases/<Verb><Noun>UseCase.swift          # struct, Sendable, execute(...)
Domain/Repositories/<Noun>Repository.swift         # protocol (새 데이터 소스일 때만)
Data/Repositories/Default<Noun>Repository.swift
Data/Remote/<Noun>Endpoint.swift + Data/Remote/DTO/<Noun>DTO.swift   # 새 API일 때만
JGNR-HWTests/Presentation/<Feature>ViewModelTests.swift
```

### 패턴 핵심 규칙

- View는 그리기와 이벤트 전달만. ViewModel은 Coordinator가 만들어 주입(`let viewModel`). View 안 의존성 생성 금지
- ViewModel: `@MainActor @Observable final class`, **UseCase만 의존**, 상태 `private(set)`, 진행 중 `Task`를 프로퍼티로 잡아 중복 실행 방지(페이지네이션 필수), `import SwiftUI` 금지
- UseCase: `struct` + `Sendable` + 메서드 하나. Repository protocol만 의존. UseCase 자체의 protocol은 만들지 않는다(테스트는 Repository 더블로 조립)
- Repository protocol(Domain): `Sendable`, `async throws`. **원격(ProductRepository)과 로컬(FavoriteRepository)을 분리** — 과제의 "책임 구분"이 이 경계다
- Repository 구현(Data): `Default*`. DTO는 Data 밖으로 나가지 않는다 — `toEntity()`로 변환
- 찜 단일 소스: `DefaultFavoriteRepository`(앱 수명 단일 인스턴스, `@MainActor` 또는 actor)가 `Set<Int>`를 진실로 삼고 `AsyncStream<Set<Int>>`로 방송 + `KeyValueStore`에 즉시 저장. 목록·상세 ViewModel은 `ObserveFavoritesUseCase`로 같은 스트림 구독
- 격리 명시: UI 상태 타입 `@MainActor`, 공유 가변 상태는 `actor`(ImageLoader) / `@MainActor` 클래스, 경계 넘는 값은 `Sendable` struct
- 추상화 예산(밀도 "표준"): protocol은 테스트 더블이 있는 경계 4개(ProductRepository · FavoriteRepository · HTTPClient · KeyValueStore)로 시작. 그 외는 concrete. 사용처 1곳 protocol·제네릭·베이스 클래스 금지
- 설계 산출물에는 **왜 그렇게 나눴는지**를 한 줄씩 남긴다 — PR 본문(설계 설명·기술 판단)의 재료가 된다

## 네이밍 컨벤션 (설계 산출물에 적용)

- 약어 대문자: `productID`, `thumbnailURL`, `imageURLs`
- 접미사: `*View` / `*ViewModel` / `*UseCase` / `*Repository`(protocol) / `Default*Repository` / `*DTO` / `*Endpoint` / `*DataSource` / `*Store`. 파일명 = 최상위 타입명
- 상태 보유만 `final class`, 나머지 `struct`/`enum`. Entity·DTO·UseCase는 `Sendable`
- 매직 넘버 금지 — 페이지 크기·임계값은 `static let` 또는 이니셜라이저 파라미터(테스트에서 주입)
- UX 문구 한국어는 Presentation에만. Domain·Data에 사용자 문구 금지
