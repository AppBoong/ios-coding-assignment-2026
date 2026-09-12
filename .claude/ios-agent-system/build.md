# 프로젝트 지침 — ios-build

> `/setup-ios`가 생성하는 파일입니다. ios-build 에이전트 호출 시 오케스트레이터가 이 내용을
> 프롬프트에 주입합니다. 전체 세부 규칙: `PROJECT_PROFILE.md` §2, §8.

## 프로젝트 생성 명령

- **명령**: 해당 없음 — 단일 xcodeproj, 생성 도구 미사용
- **실행 필요 조건**: 해당 없음
- **실행 불필요 조건**: 항상. Xcode 16+ 파일 시스템 동기화 그룹이라 `JGNR-HW/`·`JGNR-HWTests/` 아래 .swift 파일 추가/삭제/이동은 pbxproj 편집 없이 반영된다
- **실패 시 대응**: 새 파일이 빌드에 안 잡히면 ① 파일이 `JGNR-HW/` 트리 밖에 있는지 ② 동기화 그룹 예외(`exceptions`)에 걸렸는지 확인. pbxproj를 손으로 고치지 않는다(ask 경로)

## 빌드

- **워크스페이스/프로젝트 경로**: `JGNR-HW.xcodeproj` (레포 루트) — **초기 구축 Commit 1이 생성. 생성 전에는 빌드 대상 없음**
- **빌드 도구**: XcodeBuildMCP (`build_sim` — project: `JGNR-HW.xcodeproj`, scheme: `JGNR-HW`). 폴백: `xcodebuild`
- **검증된 빌드 명령** (2026-09-12 Commit 1에서 확인):
  `xcodebuild build -project JGNR-HW.xcodeproj -scheme JGNR-HW -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO`
- **시뮬레이터 대상**: iPhone 17 Pro (iOS 26 런타임, 설치 확인됨). 대안: iPhone 15 Pro

### 스킴 선택 기준

스킴은 `JGNR-HW` 하나. 어떤 파일을 수정하든 이 스킴으로 빌드한다. 테스트 타겟 `JGNR-HWTests`는 같은 스킴에 포함.

### 최소 빌드 단위 (내부 루프 — 검증 티어의 가장 안쪽)

에이전트의 edit → build → test 루프는 **변경된 모듈 하나**를 초 단위로 돌려야 한다. 앱 스킴 전체 빌드는 커밋 게이트에서 1회만 한다.

해당 없음 — 단일 xcodeproj로 모듈 스킴이 없다. **항상 앱 스킴 `JGNR-HW`** (증분 빌드라 두 번째부터는 수 초).

| 모듈 디렉터리 | 최소 빌드 명령 |
|---|---|
| `JGNR-HW/**` (전부) | 앱 스킴 `JGNR-HW` 빌드 (위 예정 명령) |

- **공용 모듈 (변경 시 앱 스킴으로 승격)**: 해당 없음 — 항상 앱 스킴
- **앱 스킴 (커밋 게이트 빌드)**: `JGNR-HW`

### 빌드 컨피그 / 타겟 분리

기본 Debug·Release만. xcconfig 없음. 검증은 Debug. 필수 빌드 설정(Commit 1이 pbxproj에 넣고, 이후 변경 금지):
- `SWIFT_VERSION = 6.0` (Swift 6 language mode) · `SWIFT_STRICT_CONCURRENCY = complete`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` (Xcode 26 기본 MainActor 격리를 끈다)
- `IPHONEOS_DEPLOYMENT_TARGET = 17.0` · `PRODUCT_BUNDLE_IDENTIFIER = com.appboong.jgnr-hw` · `CODE_SIGN_STYLE = Automatic`(시뮬레이터는 서명 불필요)

## 린트

- **설정**: 없음 — SwiftLint 미사용(사용자 결정). `.swiftlint.yml` 없음
- **실행 명령**: 해당 없음 — 린트 단계 생략. 컨벤션 검사는 `check-architecture.sh`(결정적) + ios-review(판단)

## 테스트 (해당 시)

- **정책**: 핵심 도메인·뷰모델 필수 (Swift Testing, 수용 기준당 1개) / UI 테스트: 작성 안 함
- **전체 실행 명령 (CI 티어)**: CI 없음. 로컬 전체: `xcodebuild test -project JGNR-HW.xcodeproj -scheme JGNR-HW -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO`
- **검증된 영향 테스트 명령 (내부 루프 티어)** (2026-09-12 Commit 1에서 실행 수 1 확인):
  `xcodebuild test -project JGNR-HW.xcodeproj -scheme JGNR-HW -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO -only-testing:JGNR-HWTests`

### 테스트 타겟 맵

| 모듈 디렉터리 | 테스트 타겟 | 실행 형태 |
|---|---|---|
| `JGNR-HW/Domain/**`, `JGNR-HW/Presentation/**`, `JGNR-HW/Data/**` | `JGNR-HWTests` | `-only-testing:JGNR-HWTests` (단일 타겟 — 폴더별 분리 없음) |
| `JGNR-HW/Shared/**`, `JGNR-HW/App/**` | `JGNR-HWTests` | 같은 타겟 (직접 테스트는 정책상 없음 — 상위 레이어 테스트가 간접 검증) |

> ios-build는 테스트를 **통과시키기 위해 테스트를 고치지 않는다.** 테스트 삭제·`XCTSkip`·기대값 수정은 채점 기준을 바꾸는 것이다. 기대값이 틀렸다고 판단되면 고치지 말고 보고한다.

## 이 프로젝트에서 자주 발생하는 빌드 에러 패턴

Swift 6 strict + 기본 격리 `nonisolated` 조합에서 예상되는 패턴 (실제 발생 시 갱신):

- `Main actor-isolated property 'x' can not be referenced from a nonisolated context` → 그 타입이 UI 상태면 타입 선언에 `@MainActor` 누락. ViewModel·Coordinator·FavoriteRepository(MainActor 선택 시)에 명시
- `Call to main actor-isolated instance method in a synchronous nonisolated context` → 호출자를 `@MainActor`로 올리거나 `Task { @MainActor in }`이 아니라 호출 구조를 고친다 (`MainActor.run`은 경고 대상)
- `Type 'X' does not conform to the 'Sendable' protocol` → Entity·DTO·UseCase는 `struct … : Sendable`. 클래스는 `@MainActor`/`actor`로 격리하거나 값 타입으로. `@unchecked Sendable`은 금지(아키텍처 검사 경고)
- `Capture of 'self' with non-sendable type in a '@Sendable' closure` → `Task { … }` 안에서 `self`가 `@MainActor` 클래스면 Task도 MainActor 상속이라 OK. 에러가 나면 `Task.detached`가 섞였거나 타입 격리 누락
- `Non-sendable type 'X' returned by call to actor-isolated function` → ImageLoader(actor)가 `UIImage`를 반환할 때: `UIImage`는 Sendable(iOS 17+ `@unchecked`가 아니라 실제 Sendable 선언). 에러가 나면 `import UIKit` 누락
- `No such module 'JGNR_HW'` / `@testable import JGNR-HW` 문법 오류 → 모듈명은 `JGNR_HW`(하이픈 → 언더스코어)
- `@Observable` 클래스 테스트에서 `Main actor-isolated initializer` 에러 → 테스트 스위트를 `@Suite @MainActor struct`로
- `Expression is 'async' but is not marked with 'await'` in Swift Testing → `@Test func x() async throws`
- 새 파일이 "Cannot find 'X' in scope" → 파일이 `JGNR-HW/` 트리 밖 또는 테스트 타겟 폴더(`JGNR-HWTests/`)에 잘못 생성

## 학습된 빌드 에러 패턴 (회고 게이트로 추가됨 — `/setup-ios update` 시 보존)

아직 없음
