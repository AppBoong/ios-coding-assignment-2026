# 프로젝트 지침 — ios-review

> `/setup-ios`가 생성하는 파일입니다. ios-review 에이전트 호출 시 오케스트레이터가 이 내용을
> 프롬프트에 주입하며, ios-review는 하위 리뷰어 호출 시 이 체크리스트를 다시 전달합니다.
> 전체 세부 규칙: `PROJECT_PROFILE.md` §3, §5~§7, §9.

## 프로젝트 컨텍스트 (리뷰어에게 전달)

- 디자인 패턴: MVVM-C (`@MainActor @Observable` ViewModel + NavigationStack path 소유 AppCoordinator)
- Swift 버전/동시성: Swift 6 language mode · strict concurrency complete · **기본 격리 `nonisolated`** (격리는 명시)
- 아키텍처 추상화: 풀 Clean — Presentation → Domain(Entity·Repository protocol·UseCase) ← Data · Shared(인프라)
- 비동기 처리 방식: Swift Concurrency 전용 (async/await · actor · AsyncStream · Task)
- 확정 기술 스택 문서: `.claude/ios-agent-system/PRD.md` §3 (스택 이탈 여부 대조 — 외부 라이브러리 0)

## 시니어 공통 리뷰 축 (모든 레포 공통 — 항상 점검)

프로젝트 특화 체크리스트와 별개로, 모든 리뷰에서 아래를 점검한다:

- **스레드 세이프티 / 데이터 레이스**: 공유 가변 상태 접근 경로, actor isolation의 근거, Sendable 처리, 늦게 도착한 비동기 결과로 인한 상태 역전(새로고침 중 도착한 이전 페이지 응답 등), 프로젝트의 비동기 방식(Swift Concurrency) 외 방식 혼입
- **메모리**: retain cycle(클로저 `[weak self]` 누락 — 특히 Coordinator가 ViewModel에 넘기는 네비게이션 클로저), Timer/Observer/구독의 해제(AsyncStream 구독 Task 취소), 해제된 객체를 참조하는 콜백, 캐시/컬렉션의 무한 성장(ImageLoader NSCache 상한)
- **아키텍처/컨벤션 적합성**: PROJECT_PROFILE의 패턴·레이어 경계·네이밍 준수, PRD §3 스택 확정표와 실제 구현의 일치 (문서에 없는 라이브러리/패턴 도입 여부)
- **추상화 적정성 / SOLID**: 사용처가 1곳뿐인 프로토콜·레이어(과설계), 테스트 경계에 추상화가 없는 곳(부족설계), SRP·DIP 위반 — 과설계와 부족설계를 동등하게 지적. 이 중 **grep으로 판정되는 셋은 Critical(즉시 제거)**: ① 이번 diff에서 채택(conform)이 1곳뿐이고 테스트 더블도 없는 신규 protocol ② 이번 diff에서 추가됐는데 호출처가 0곳인 신규 메서드·타입 ③ 함수명·타입명을 재진술한 주석. 판단이 필요한 나머지(레이어 과다, SRP)는 보고만
- **구현 의도**: 주요 설계 결정(상태 모델, 동시성 처리, 레이어 배치)에 "왜 이렇게 했는가"의 답이 코드에서 읽히는가 — 읽히지 않으면 질문으로 남기고 대안을 제시. 이 프로젝트는 심사자가 코드로 설계를 읽는 과제라 특히 중요
- **하드코딩 배치** (diff에 View 코드가 포함된 경우): 아이콘처럼 본질적으로 고정 크기인 요소 외의 고정 `.frame(width:height:)`, 정렬 목적의 `.offset`, 커스텀 그리기 외의 `GeometryReader`, 토큰이 있는데 숫자로 쓴 패딩, UIKit `frame =` 대입 — 컨테이너(Stack/Grid/ViewThatFits/제약)가 배치를 결정해야 다른 기기·Dynamic Type에서 깨지지 않는다 (세부: 플러그인 스킬 `ios-layout`의 리뷰 축). 검사를 끄는 동시성 우회(`@unchecked Sendable`·`nonisolated(unsafe)`·`Task.detached`·`DispatchQueue.main.async` 신규 추가)도 같은 범주로 본다 (스킬 `swift-concurrency`)
- **테스트 네이밍 / 주석 정책** (diff에 테스트·주석이 포함된 경우): Swift Testing은 영어 메서드명 + `@Test("한글 설명")`, 테스트명에 SUT 메서드명 포함 금지; 주석은 비자명한 의도·근거에만 — 코드/이름을 재진술한 주석은 제거 지적. 밀도 "간결": `///`·`MARK` 신규 도입 지적 (세부: PROJECT_PROFILE §7·§12)

## 핵심 리뷰 체크리스트 (모든 리뷰에서 확인)

- [ ] Presentation이 UseCase만 의존 — Repository·HTTPClient·UserDefaults·DTO·Endpoint 직접 참조 없음 (아키텍처 검사도 막지만 우회 표현 확인)
- [ ] Domain에 Foundation 외 import 없음, DTO·ViewModel·저장소 타입 참조 없음. UseCase는 `struct` + Repository protocol만
- [ ] 원격(`ProductRepository`)과 로컬(`FavoriteRepository`) 책임이 한 타입에 섞이지 않았다. DTO가 Data 밖으로 나가지 않는다
- [ ] 찜 상태 진실은 `DefaultFavoriteRepository` 단일 인스턴스 + `AsyncStream` 방송 — 화면 간 콜백·NotificationCenter·중복 캐시 없음
- [ ] 페이지네이션: 진행 중 Task 가드 + `hasMore` 가드 + 임계 인덱스(마지막 페이지 16번째)가 있고, 테스트가 "여러 번 onAppear해도 요청 1회"를 검증한다
- [ ] 새로고침이 `skip=0`으로 리셋하고 진행 중 페이지 Task를 취소하며, 늦게 도착한 이전 응답이 새 목록을 덮지 않는다
- [ ] `@MainActor`가 ViewModel·Coordinator·UI 상태 타입에 명시. `@unchecked Sendable`·`nonisolated(unsafe)`·`Task.detached`·`DispatchQueue`·`MainActor.run` 신규 추가 없음
- [ ] Combine·GCD·완료 핸들러 혼입 없음. 외부 라이브러리 import 없음 (PRD §3 — 의존성 0)
- [ ] 의존성 생성은 `AppDependencies`·`AppCoordinator`에서만. View/ViewModel 안 `init()` 조립·싱글턴·`static shared` 없음
- [ ] ViewModel은 Coordinator를 모른다 — 네비게이션은 주입된 클로저. 클로저 캡처는 `[weak self]`
- [ ] `AsyncImage` 미사용, `RemoteImage` 사용. `ImageLoader`가 같은 URL in-flight 요청을 병합하고 NSCache 상한을 둔다
- [ ] 약어 대문자(`productID`·`thumbnailURL`), 접미사 규칙, 강제 언래핑·`try!`·`as!` 없음(테스트 제외), 매직 넘버 없음
- [ ] UX 문구 한국어, Domain·Data에 사용자 문구 없음. `NetworkError` → 한국어 매핑은 Presentation/Common
- [ ] 1열/2열이 같은 `items`·같은 `onAppear` 트리거를 쓰고 컨테이너만 바뀐다. 전환 시 리로드·이미지 재요청 없음
- [ ] 고정 `.frame(width:height:)`·`GeometryReader` 셀 계산·`.system(size:)`·하드코딩 색상 없음. 시맨틱 컬러·텍스트 스타일만
- [ ] 새 protocol이 생겼으면 테스트 더블이 같은 diff에 있다 (밀도 "표준" — 경계 4개 외 추가는 근거 필요)
- [ ] 수용 기준당 테스트 1개(밀도 "간결"), 테스트명 규칙, 재진술 주석·`///`·`MARK` 신규 도입 없음
- [ ] pbxproj 직접 편집 없음(동기화 그룹). `#Preview`에 네트워크·UserDefaults 의존 없음

## Critical로 분류할 프로젝트 특화 위반

- Presentation → Repository/HTTPClient/UserDefaults/DTO 직접 참조, Domain → SwiftUI/UIKit/Combine import 또는 DTO·ViewModel 참조 (레이어 경계 붕괴)
- 원격/로컬 책임이 한 Repository에 섞임 (과제 핵심 요구 위반)
- 찜 상태를 두 곳에서 각자 관리(목록·상세 각각 UserDefaults 읽기) — 동기화 요구 위반
- 페이지네이션 중복 요청 가드 부재, 또는 가드 테스트 부재
- Combine·RxSwift·GCD·외부 라이브러리 도입, `@unchecked Sendable`·`nonisolated(unsafe)` 신규 추가
- 싱글턴·`static shared`·View 안 의존성 생성
- 강제 언래핑·`try!`(프로덕션 코드), `URL(string:)!`
- 채택 1곳 + 더블 없는 신규 protocol, 호출처 0인 신규 타입·메서드, 재진술 주석

## 학습된 규칙 (회고 게이트로 추가됨 — `/setup-ios update` 시 보존)

아직 없음

### diff가 보여주지 않는 것 (리뷰의 구조적 한계)

**죽은 코드는 한 번에 죽지 않는다.** A 시점에 쓰이던 것이 추가되고, B 시점에 다른 PR이 읽는 쪽을 지우면서 죽는다. **어느 diff에도 "이게 지금 죽었다"는 정보가 없다.** 사람 리뷰든 LLM 리뷰든 diff를 보는 한 구조적으로 잡을 수 없다.

이 범주는 **리뷰 규칙을 추가해서 해결할 수 없다.** 변경 시점이 아니라 상태로만 판별되므로 주기적 전체 스캔이라는 다른 층이 필요하다. 회고 게이트에서 이런 결함이 나오면 `review-checklist`에 항목을 늘리지 말고 **"검증 공백"으로 분류**한다.

해당 범주 예: 읽는 곳이 사라진 State 프로퍼티, 호출처가 0건인 액션, 참조가 끊긴 헬퍼, 아무도 import하지 않는 모듈.

### 이 목록은 줄어들어야 한다

자동 검사(`check-architecture.sh` 또는 `protected.yml`)로 **승격된 항목은 이 파일에서 삭제한다.** 기계가 이미 쓰기 시점에 막는 것을 리뷰가 다시 확인하면 토큰만 쓰고 검출은 늘지 않는다. (이 레포는 SwiftLint를 쓰지 않으므로 승격처는 `check-architecture.sh`의 PATTERN_RULES다.)

- 승격 시 회고 게이트가 삭제하고, 제거 이력을 `- ~~{규칙}~~ → {승격처}, {날짜}` 한 줄로 남긴다.
- 리뷰어는 **판단이 필요한 것만** 본다. 문자열·구조로 판별되는 것은 여기 있으면 안 된다.

<!-- 승격되어 제거된 항목 (이력) -->
아직 없음

## 고위험(민감) 영역 — 변경 분석의 위험도 HIGH 판정 기준

- `JGNR-HW/Data/Repositories/DefaultFavoriteRepository.swift`, `JGNR-HW/Data/Local/**`, `JGNR-HW/Shared/LocalStorage/**` — 찜 영속 데이터(UserDefaults 키·인코딩). 키 이름·저장 형식이 바뀌면 기존 찜이 사라진다
- `JGNR-HW/App/AppDependencies.swift`, `JGNR-HW/App/AppCoordinator.swift` — 전역 조립·공유 인스턴스(찜 단일 소스의 수명)
- `JGNR-HW/Presentation/ProductList/ProductListViewModel.swift` — 페이지네이션·새로고침 동시성(상태 역전·중복 요청)
- `JGNR-HW/Shared/Image/ImageLoader.swift` — 공유 캐시(메모리 상한·in-flight 병합)
- 결제·인증·DB 스키마: 없음 — 공통 기준(공유 상태/diff 300줄+)만 적용
