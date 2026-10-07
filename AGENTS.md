# AGENTS.md — JGNR-HW

> `/ios-agent-system:setup-ios`가 생성한 파일입니다. **불변 규칙만** 담습니다 — 채운 뒤 150줄을 넘기지 마십시오.
> 색상 토큰·에러 패턴·체크리스트 같은 지식은 여기 넣지 않습니다. 그것은 `.claude/ios-agent-system/`의 하위 지침이 필요한 에이전트에만 주입됩니다.
> 이 파일의 독자는 Claude Code만이 아닙니다 — Codex, Xcode 내장 에이전트, Cursor, 사람 모두 같은 규칙을 봅니다.

## 스택

- 플랫폼/언어: iOS 17.0+ · Swift 6 language mode · strict concurrency complete · **기본 actor 격리 `nonisolated`** (UI 상태 타입에 `@MainActor` 명시) · SwiftUI 전용 · Xcode 26.5
- 아키텍처: MVVM-C · 단일 xcodeproj(`JGNR-HW.xcodeproj`, 모듈명 `JGNR_HW`) · 디렉토리 레이어 `App / Presentation / Domain / Data / Shared` · 풀 Clean(Domain에 UseCase)
- 비동기/DI/네트워크: Swift Concurrency 전용 · 수동 이니셜라이저 주입(`App/AppDependencies` + `App/AppCoordinator`만 조립) · URLSession + Codable · 찜은 UserDefaults · 이미지는 자체 actor 캐시 · **외부 의존성 0**
- 확정 스택 문서: `.claude/ios-agent-system/PRD.md` §3 — **여기 없는 라이브러리·패턴 도입은 사용자 결정 사항**
- 브랜치: 작업은 `feature/jgnr-hw`에서, PR은 upstream(`apptask-jn/ios-coding-assignment-2026`) `main`으로. `main`에 직접 커밋하지 않는다

## 레이어 규칙

- 의존 방향은 `App → Presentation → Domain ← Data`, `Data → Shared`뿐이다. Presentation은 **UseCase만** 호출한다 — Repository·HTTPClient·UserDefaults·DTO를 직접 참조하지 않는다.
- Domain(`Entities/`·`Repositories/` protocol·`UseCases/` struct)은 Foundation 외 아무것도 import하지 않고 DTO·ViewModel·저장소 타입을 모른다.
- 원격 데이터(`ProductRepository`)와 로컬 데이터(`FavoriteRepository`)는 별도 Repository다 — 한 타입에 섞지 않는다. DTO는 Data 밖으로 나가지 않는다.
- Shared(`Network/`·`Image/`·`LocalStorage/`)는 도메인 무관 인프라 — 상위 레이어 타입을 모른다.
- 찜 상태의 진실은 `DefaultFavoriteRepository` 단일 인스턴스(`AsyncStream` 방송) 하나다. 화면 간 콜백·NotificationCenter로 동기화하지 않는다.
- ViewModel은 Coordinator를 모른다 — 네비게이션은 주입된 클로저(`onSelectProduct`)로 요청한다.

## 명령

| 목적 | 명령 |
|------|------|
| 최소 단위 빌드 (변경 모듈) | 해당 없음 — 항상 앱 스킴 (단일 xcodeproj) |
| 앱 스킴 빌드 (커밋 전) | `xcodebuild build -project JGNR-HW.xcodeproj -scheme JGNR-HW -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO` (Commit 1 이후 — 검증된 명령은 `build.md`) |
| 영향 테스트 (변경 모듈) | `xcodebuild test -project JGNR-HW.xcodeproj -scheme JGNR-HW -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:JGNR-HWTests` |
| 아키텍처 검사 | `bash .claude/ios-agent-system/harness/check-architecture.sh` |
| 보호 경로 검사 (커밋 전) | `bash .claude/ios-agent-system/harness/check-protected.sh --cached` |
| 린트 | 해당 없음 — SwiftLint 미사용 |

이 레포는 CI가 없다. 커밋 전 앱 스킴 빌드 + 테스트 타겟 실행이 전체 검증이다. 파일 하나 바꿀 때마다 클린 빌드하지 말고 증분 빌드를 쓴다.

## 금지

- `// swiftlint:disable`를 **새로** 추가하지 않는다 — 위반을 고친다. (하네스 게이트가 쓰기 시점에 취소한다)
- 아래 "보호 경로"를 직접 수정하지 않는다 — `<파일>.proposed`로 제안하고 사람이 반영한다.
- PRD §3 확정표에 없는 라이브러리·패턴을 도입하지 않는다.
- `git commit --no-verify`, `git push --force`, `git reset --hard`를 쓰지 않는다.
- 테스트를 삭제·`XCTSkip`·기대값 수정으로 통과시키지 않는다 — 구현을 고치거나 이의를 보고한다.
- 사용처가 1곳인 protocol·제네릭·베이스 클래스·헬퍼를 만들지 않는다 — 두 번째 사용처가 생길 때 추출한다. 수용 기준에 없는 테스트, 이름을 재진술하는 주석도 만들지 않는다.
- Combine·RxSwift·GCD(`DispatchQueue`)·완료 핸들러·`Task.detached`·`@unchecked Sendable`·`nonisolated(unsafe)`를 새로 넣지 않는다 — Swift Concurrency 전용.
- 싱글턴·`static shared`·View/ViewModel 안 의존성 생성·`AsyncImage`·강제 언래핑(`!`·`try!`·`as!`, 테스트 제외)을 쓰지 않는다.
- `JGNR-HW.xcodeproj/project.pbxproj`를 직접 편집하지 않는다 — 파일 시스템 동기화 그룹이라 `JGNR-HW/` 아래에 파일을 추가하기만 한다 (편집이 꼭 필요하면 사용자 승인).

## 보호 경로 (하네스 게이트가 쓰기를 취소하는 파일)

- `**/__Snapshots__/**` — 스냅샷 테스트 정답지 (현재 없음)
- `.swiftlint.yml`, `.swiftlint.yaml` — 린트 규칙 (현재 없음 — 생기면 자동 보호)
- `.claude/hooks/**`, `.claude/settings.json` — 하네스 자신
- `.claude/ios-agent-system/protected.yml`, `.claude/ios-agent-system/metrics.jsonl` — 게이트 설정·계측
- `.claude/ios-agent-system/harness/check-protected.sh`, `.claude/ios-agent-system/harness/harness_gate_suite.py` — 훅 밖 검사·게이트 회귀 스위트
- 사용자 승인으로 열리는 파일(ask): `**/*.pbxproj`, `**/*.xcworkspacedata`, `**/*.xib`, `**/*.storyboard`, `**/*.entitlements`, `**/*.xcconfig`, `**/Package.resolved`

## 작업을 끝내기 전에

1. 변경 모듈을 최소 단위로 빌드한다. (이 레포: 앱 스킴 `JGNR-HW`)
2. 변경 모듈의 테스트 타겟을 실행한다 — 0건 실행은 통과가 아니다. (`JGNR-HWTests`)
3. `check-architecture.sh`를 실행한다.
4. `git diff`를 읽고 요청과 무관한 변경이 섞였는지 확인한다.

## 더 알아보기

- 전체 프로필: `.claude/ios-agent-system/PROJECT_PROFILE.md`
- 에이전트별 지침: `architect.md` · `ui.md` · `build.md` · `review-checklist.md` · `verify.md`
- 요구사항 원본(왜 만드나): `.claude/ios-agent-system/intents/` — 작업 전에 관련 intent의 성공 기준·범위 밖·제약을 읽는다. 프론트매터 `audit:`가 그 작업의 AUDIT을 가리킨다
- 진행 중 작업의 SSOT(무엇을 어떤 순서로): `.claude/ios-agent-system/audits/`
- Claude Code에서는 `/ios-agent-system:task-ios <작업>`이 위 규칙을 자동으로 주입·검증합니다.

## 팀 추가 규칙 (update 시 보존)

- 커밋 메시지: 제목은 `feat:`·`fix:`·`chore:`·`docs:`·`style:`·`refactor:`·`test:` 접두사 + **20자 이내 한글** (예: `chore: Xcode 프로젝트 스캐폴드 생성`), 본문은 **4줄 이내** 불릿으로 작업 내역 요약 — 팀원이 로그만 보고 무엇을 했는지 알 수 있게 간결·직관적으로 (2026-09-12 사용자 결정)
