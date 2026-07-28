# Flutter 하네스·게이트 템플릿

새 Flutter repo를 만들 때 복사하거나 덧붙이는 하네스·게이트 실물이다.
스킬 패키지 안에서는 숨김 디렉터리로 취급되지 않도록 `claude/`와
`githooks/`처럼 점 없는 이름을 사용한다.

| 템플릿 | 생성된 repo의 대상 | 적용 방식 |
|---|---|---|
| `claude/settings.json` | `.claude/settings.json` | 복사 |
| `claude/hooks/check-architecture.sh` | `.claude/hooks/check-architecture.sh` | feature-first 판정일 때만 복사 |
| `claude/hooks/check-architecture-layered.sh` | `.claude/hooks/check-architecture.sh` | layer-first 판정일 때만 복사하고 파일명을 표준 이름으로 바꿈 |
| `githooks/` | `.githooks/` | 디렉터리 복사 |
| `tool/review/` | `tool/review/` | 디렉터리 복사 |
| `Makefile` | `Makefile` | 복사 후 플레이스홀더 치환 |
| `analysis_options.yaml` | `analysis_options.yaml` | 복사 |
| `gitignore-additions.txt` | `.gitignore` | 파일 복사가 아니라 기존 파일 끝에 append |

구조 판정 결과에 따라 두 `check-architecture` 판 중 하나만 생성된 repo에
들어간다. Git 훅을 활성화하려면 repo 루트에서
`git config core.hooksPath .githooks`를 한 번 실행한다.

아키텍처 Stop hook과 pre-commit 검사는 `jq`를 전제 조건으로 사용한다.
없으면 macOS에서는 `brew install jq` 등으로 먼저 설치한다.

`__APP_NAME__`은 생성된 Flutter 패키지명으로 치환한다.

## Dart 소스 템플릿

아래 파일은 새 repo의 `lib/`로 복사한다. Repo A의 `core/error/`에서 온
파일도 생성 대상에서는 `core/errors/` 복수형으로 고정한다.

| 템플릿 | 출처 | 템플릿에서의 처리 |
|---|---|---|
| `lib/main.dart` | Repo B `lib/main.dart` | `bootstrapApp()` 진입점에 맞춰 연결 |
| `lib/app/app.dart` | Repo B `lib/app/app.dart` | 회사 기능 구독 제거, 중립 앱 셸로 개명 |
| `lib/app/bootstrap.dart` | Repo A `lib/app/bootstrap.dart` | 사업 초기화 제거, prefs override와 컨테이너 수명주기 보존 |
| `lib/app/router/app_router.dart` | Repo A `lib/app/router/app_router.dart` | 회사 화면·경로 제거, auth guard 합성 자리와 빈 routes 보존 |
| `lib/core/errors/app_exception.dart` | Repo B 동명 | 복사 |
| `lib/core/errors/result.dart` | Repo A `lib/core/error/result.dart` | 복수형 폴더로 이동하고 import 치환 |
| `lib/core/errors/failures.dart` | Repo A `lib/core/error/failures.dart` | 복수형 폴더로 이동 |
| `lib/core/network/dio_client.dart` | Repo B 동명 | 골격 제외 인터셉터 연결 제거 |
| `lib/core/network/api_config.dart` | Repo B 동명 | 회사 URL을 dart-define 기본형으로 교체 |
| `lib/core/network/network_providers.dart` | Repo B 동명 | AccessToken 슬롯·콜백 주입 보존, 제외된 refresh 연결 제거 |
| `lib/core/network/auth_interceptor.dart` | Repo B 동명 | 복사 |
| `lib/core/network/logging_interceptor.dart` | Repo B 동명 | `AppLogger` 이름에 맞춰 연결 |
| `lib/core/network/network_exception_mapper.dart` | Repo B 동명 | 복사 |
| `lib/core/logging/app_logger.dart` | Repo A 동명 | 프로젝트별 출력 제거, 콘솔 출력만 유지 |
| `lib/core/storage/app_preferences.dart` | Repo B 동명 | 복사 |
| `lib/core/storage/secure_token_storage.dart` | Repo B 동명 | 복사 |
| `lib/core/storage/storage_providers.dart` | Repo B 동명 | 복사 |
| `lib/core/constants/route_path.dart` | Repo B 동명 | 회사 경로를 비우고 명명 규약만 유지 |

내부 `package:` import의 `__APP_NAME__`은 생성된 Flutter 패키지명으로
치환한다. `*.g.dart`·`*.freezed.dart`는 동봉하지 않으며, 남겨 둔 `part`
선언을 바탕으로 스캐폴딩 후 `build_runner`가 생성한다.

## 채워 쓰는 자리

| 템플릿 | 출처 | 용도 |
|---|---|---|
| `lib/app/theme/palette.dart` | 신작 | 원시 색 리터럴의 유일한 자리 — 브랜드 팔레트로 교체 |
| `lib/app/theme/app_colors_theme.dart` | 신작 | Light/Dark 시맨틱 색과 `context.colors` 확장 |
| `lib/app/theme/app_dimens.dart` | 신작 | 프로젝트 간격·반경 토큰 |
| `lib/app/theme/app_theme.dart` | 신작 | 위 토큰을 조립하는 Light/Dark `ThemeData` |
| `lib/core/extensions/` | 신작 | app·feature를 참조하지 않는 순수 Dart 대상 extension |
| `lib/core/utils/` | 신작 | `XxxUtils` 클래스가 아닌 top-level 함수 |
| `lib/shared/widgets/` | 신작 | 둘 이상 기능이 실제로 쓰는 표현 전용 공용 UI 위젯 |

`shared/`는 순수 Dart를 유지하되, Flutter import는 `shared/widgets/` 하위만 예외로 허용한다.

**공유 도메인 폴더(`shared/value_objects/`·`shared/entities/`)는 동봉하지 않는다.**
기본은 기능별 각자 모델링이고, 두 화면이 같은 API를 불러도 domain은 기능별로
갈리는 게 정상이다. 승격 규칙(골격 §3③)을 전부 충족하는 공유 도메인이 실제로
생기면 그때 `shared/` 아래 만든다 — `core/`에는 넣지 않는다. 검사는 이미
`lib/shared/**`를 도메인 레이어로 취급하므로 나중에 만들어도 게이트가 바로 걸린다.

빈 디렉터리 세 곳(`core/extensions/`·`core/utils/`·`shared/widgets/`)에는 용도를
적은 짧은 `README.md`와 디렉터리 보존용 `.gitkeep`만 둔다. 실제 feature와
`test/` 미러, `docs/ARCHITECTURE.md`, `pubspec.yaml`은 스캐폴딩 시 PRD와 골격
정본에 맞춰 생성한다.

## CI·릴리즈·결정 기록 템플릿

| 템플릿 | 생성된 repo의 대상 | 적용 방식 |
|---|---|---|
| `github/workflows/` | `.github/workflows/` | 디렉터리 복사 |
| `docs/adr/` | `docs/adr/` | 디렉터리 복사 |
| `docs/RELEASE.md` | `docs/RELEASE.md` | 복사 |

`ci.yml`은 `make coverage`를 실행해 Makefile의 커버리지 게이트를 원격에서도
강제한다.

`release.yml`은 확인용 APK와 GitHub Release까지만 만들며, 배포 서명과 스토어
업로드는 포함하지 않는다.
