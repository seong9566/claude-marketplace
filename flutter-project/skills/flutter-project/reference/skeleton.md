# Flutter 프로젝트 골격 (스캐폴딩 정본)

> 새 Flutter 프로젝트가 따르는 표준 구조·규칙. **앞으로 만들 스캐폴딩 Skill이 이 문서를 정본으로 삼는다** — 구조를 바꿀 땐 이 파일만 고친다.
>
> 근거: `Repo A (레이어 우선)`·`Repo B (기능 우선)` 두 repo 실측 비교(2026-07-16). 비교 결과는 [§9 부록](#9-부록--두-repo-실측-비교).
> 같은 날 fresh-eyes 리뷰(서브에이전트, 두 repo 대조)의 발견 16건을 검증 후 반영 — 계층 역전 1건·신작 부품 은폐·§6 도출 규칙 오기 등.

## 1. 한 줄 요약

**분할축은 기능 우선(Repo B), 품질 게이트는 Repo A.** 어느 한쪽도 그대로 베끼지 않는다 — 둘은 유지보수성의 서로 다른 절반을 잘한다.

**분할축을 가르는 건 bounded context 결합도다**: 기능들이 각자 독립이면 feature-first(기본), 하나의 리치 가변 핵심 객체를 모든 화면이 공유하는 단일 bounded context면 §2 말미의 **layer-first 변형**을 쓴다. 기능 수(2~3 고정 vs 4+ 성장)는 이 결합도의 약한 proxy일 뿐 판정 기준이 아니다 — 애매하면 되돌리기 쉬운 feature-first를 기본으로 둔다(전환 비용 비대칭 — §2 변형). 어느 쪽인지는 스캐폴딩 Skill의 판정 인터뷰가 정한다(rubric은 스킬 정본 몫, 이 문서는 두 구조의 정의만 담는다).

- Repo B가 나은 것: `features/` 수직 분할, 구조 검사 7종 자동, 하네스가 git 추적됨. 단 초판이 근거로 삼은 **"교차 결합 0건"은 오측이다** — 검사 1.2가 상대경로 import를 해석하지 못해 실제 11건을 놓쳤다(2026-07-27 재측정, §9)
- Repo A가 나은 것: 테스트 밀도 2배, 커버리지 게이트 90%(UI 제외 기준 — §8), `Result<T>` 실물, `mappers/`, Riverpod 생명주기 검사

## 2. 디렉터리 골격

**출처 태그**: `[T]`=`templates/`에 실물이 동봉됨 — 패키지명만 치환해 복사 · `[신작]`=템플릿 없음 — 골격 문서 §8 결정 표대로 생성. `·개명`/`·이동`/`·수정`/`·축소`/`·재작성`은 실물에서 변형. 신작·수정 항목의 구성은 §8 결정 표가 정본.

```
<app_name>/
├── lib/
│   ├── main.dart                        # 진입점만 — binding + bootstrapApp(). 부트스트랩 로직 금지 [T]
│   │
│   ├── app/                             # ★합성 루트 — feature import 허용(유일한 자리)
│   │   ├── app.dart                     #   MaterialApp.router [T]
│   │   ├── bootstrap.dart               #   ProviderContainer 조립·override·runApp → container 반환 [T]
│   │   ├── router/
│   │   │   └── app_router.dart          #   GoRouter + 라우트 가드(여기서 auth를 본다) [T — Repo B는 평면 router.dart]
│   │   └── theme/
│   │       ├── palette.dart             #   원시 색 — Color 리터럴은 여기서만 [T]
│   │       ├── app_colors_theme.dart    #   시맨틱 토큰 Light/Dark + BuildContext 테마 extension(context.colors) 동거 [T]
│   │       ├── app_dimens.dart          #   [T]
│   │       └── app_theme.dart           #   → ThemeData [T]
│   │
│   ├── core/                            # ★app·feature import 금지(검사 1.1) — 공유가 필요하면 여기로 승격
│   │   ├── errors/                      #   폴더명은 Repo B(복수) — 내용물은 Repo A core/error/에서 이동
│   │   │   ├── result.dart              #   sealed Result<T> — Success | Failure [T·이동]
│   │   │   ├── failures.dart            #   Failure 계층 (freezed) [T·이동]
│   │   │   └── app_exception.dart       #   DataSource가 던지는 예외 계층 [T]
│   │   ├── extensions/                  #   순수 Dart 대상(String·DateTime 등) 전용 — app·feature 참조 금지. 빈 채로 시작 [신작]
│   │   ├── network/
│   │   │   ├── dio_client.dart          #   buildDio() [T]
│   │   │   ├── api_config.dart          #   baseUrl 등 [T]
│   │   │   ├── network_providers.dart   #   dio provider + ★AccessToken 빈 슬롯(이음매 ①) [T]
│   │   │   ├── auth_interceptor.dart    #   accessToken 콜백 주입받음 — auth를 모름 [T]
│   │   │   ├── logging_interceptor.dart #   kDebugMode 한정 — 릴리즈 번들에 로그 미포함 [T]
│   │   │   └── network_exception_mapper.dart   # DioException → AppException [T]
│   │   ├── logging/
│   │   │   └── app_logger.dart          #   print() 금지 → 이걸로(검사 2.2) [T·개명 — Repo B 실물은 logger.dart]
│   │   ├── storage/
│   │   │   ├── app_preferences.dart     #   SharedPreferences wrapper [T]
│   │   │   ├── secure_token_storage.dart#   flutter_secure_storage wrapper [T]
│   │   │   └── storage_providers.dart   #   [T]
│   │   ├── constants/
│   │   │   └── route_path.dart          #   [T]
│   │   └── utils/                       #   top-level 함수만 — XxxUtils 정적 클래스 금지(검사 3.1) [T]
│   │
│   ├── shared/                          # core·features 옆 peer — 스캐폴딩은 widgets/만 만든다 [T]
│   │   └── widgets/                     #   ★공용 UI 위젯의 유일한 자리 — 여기만 Flutter 허용(검사 1.3 예외)
│   │                                    #   공유 도메인(값객체·엔티티)은 미리 만들지 않는다 — 필요해지면 §3③
│   │
│   └── features/<feature>/              # ★수직 슬라이스 — 서로 import 금지(검사 1.2) [T]
│       ├── presentation/                #   Flutter 의존 허용
│       │   ├── screens/                 #     XxxScreen — 라우트 진입점 [T]
│       │   ├── widgets/                 #     그 화면 전용 위젯 [T]
│       │   ├── view_models/             #     XxxViewModel + XxxState(★별도 파일) [T]
│       │   └── providers/               #     DI provider + 앱 전역 Notifier [T]
│       ├── domain/                      #   순수 Dart — Flutter·Riverpod import 금지(검사 1.3) [T]
│       │   ├── entities/                #     비즈니스 객체 [T]
│       │   ├── usecases/                #     단일 작업 · call() [T]
│       │   └── repositories/            #     abstract 인터페이스(검사 3.2) [T]
│       └── data/
│           ├── models/                  #     *_dto — fromJson/toJson만 [T]
│           ├── mappers/                 #     ★dto ↔ entity 변환 전담 [T·재배치 — Repo A 실물은 전역 lib/data/mappers/]
│           ├── datasources/             #     remote/ · local/ [T]
│           └── repositories/            #     XxxRepositoryImpl(검사 3.2) [T]
│
├── test/                                # lib/ 1:1 미러 — mock·헬퍼는 대응 경로 아래 utils/ [T]
├── android/ · ios/                      # 플랫폼은 이 둘만 (§8)
├── docs/
│   ├── ARCHITECTURE.md                  # §번호 규칙 정본 — 검사가 이 §를 인용. 실물 기준으로 새로 쓴다 [T·재작성 — §9 드리프트]
│   └── ARCHITECTURE_AUDIT.md            # 축소 스텁 — baseline 표 + "검사 명령도 검증 대상" 교훈만 [T·축소]
├── .claude/
│   ├── settings.json                    # ★Stop hook 등록 — 없으면 check-architecture.sh가 아예 안 돈다 [T]
│   └── hooks/
│       └── check-architecture.sh        # ★구조 검사 9종 · git 추적 필수 [T·수정 — 1.1 확장 + 1.4·1.5 신작, §4]
├── .githooks/
│   ├── pre-commit                       # ① check-architecture.sh(lib 전체) ② check.mjs --staged [신작 — §8]
│   └── pre-push                         # main 직접 push 차단 [T]
├── tool/
│   ├── review/
│   │   ├── check.mjs                    # CLI 진입점(--staged) — pre-commit이 부른다 [T·개명]
│   │   ├── checks.mjs                   # hardcoded-color · length · codegen-part [T·개명·수정 — 도메인 체크(RemoteViews) 제외]
│   │   └── (lifecycle.mjs)              # ✗ 미채택 — 규칙별 대조 결과 riverpod_lint가 전부 커버(§7). 파일 없음
│   ├── wt.sh                            # 워크트리 생성(base=최신 dev 고정) [T]
│   └── fmt.sh                           # 변경분만 dart format [T]
├── .github/workflows/
│   └── ci.yml                           # analyze + test + 커버리지 게이트(Makefile 재사용) [신작 — §8]
├── Makefile                             # ★커버리지 게이트 — 타겟·제외 정책은 §8 [T]
├── .gitignore                           # flutter create 기본 + *.g.dart·*.freezed.dart 직접 추가 — 검사 4.1 충족 [신작 — §8]
├── README.md                            # 셋업 3줄: pub get → build_runner → hooksPath [신작]
├── CLAUDE.md · AGENTS.md                # 내용 규약은 §8 [신작]
└── analysis_options.yaml                # Repo B strict판 + 생성물 exclude + riverpod_lint plugin [T·수정 — §8]
```

**명명은 복수로 고정**(`screens/`·`view_models/`·`errors/`·`mappers/`). 단수/복수가 섞이면 grep 검사가 양쪽을 훑어야 한다. 파일명이 두 repo에서 갈리면 채택한 쪽을 태그에 표시했다(예: `app_logger.dart`는 Repo A 이름).

### lib 본문 변형 — layer-first (단일 bounded context — 전형적으로 기능 2~3개 고정)

**`core/`·`test/`·하네스·게이트(§3~§8)는 기본형과 그대로 공유한다.** `app/`은 거의 같되 `providers/` 하위가 붙고 provider 배치가 뒤집힌다(아래). 갈리는 본체는 `features/` 자리 — 수직 슬라이스 대신 루트 3레이어를 쓴다(Repo A 방식의 정제판).

```
│   ├── app/                             # 기본형과 동일 + providers/ 추가
│   │   └── providers/                   #   전역 상태·DI provider 집중 [T·개명 — Repo A common_providers/]
│   ├── core/                            # 기본형과 동일
│   ├── shared/
│   │   └── widgets/                     # ★기본형과 동일 — 공용 UI 위젯의 유일한 자리
│   │                                    #   presentation/ 아래에 공용 버킷을 만들지 말 것(아래)
│   ├── data/
│   │   ├── datasources/                 #   remote/ · local/
│   │   ├── models/                      #   *_dto — fromJson/toJson만
│   │   ├── mappers/                     #   dto ↔ entity 변환 전담 [T]
│   │   └── repositories/                #   XxxRepositoryImpl
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/                #   abstract 인터페이스
│   │   └── usecases/<도메인>/           #   도메인별 폴더(auth·card 등) [T]
│   └── presentation/<기능>/             # ★기능 간 직접 import 금지(검사 1.2′)
│       ├── screens/ · widgets/ · view_models/   # 명명·XxxState 분리 규칙은 기본형과 동일
```

- **전환 비용이 비대칭 — 애매하면 feature-first**: feature-first → layer-first는 기계적이다(검사 1.2가 슬라이스 간 결합을 0으로 막아둬 domain/data를 루트 레이어로 합치기만 하면 된다). 반대로 layer-first → feature-first는 아프다 — 평면 레이어가 *허용한* 공유(한 usecase를 두 화면이, 한 엔티티를 여럿이 쓰는 결합)를 뒤늦게 소유 기능별로 가르고 떼어내야 한다. 그래서 이 변형은 "단일 bounded context"가 분명할 때만 고르고, 애매하면 되돌리기 쉬운 feature-first를 기본으로 둔다.
- **provider 배치가 기본형과 반대다**: 화면 전용 ViewModel은 `view_models/` 파일에 두고, 전역 상태·DI는 `app/providers/`에 **집중**한다. 이 변형을 고르는 전제(하나의 핵심 객체를 여러 화면이 공유)에서는 provider 대부분이 전역이라 집중이 자연스럽다 — 기본형의 "기능별 분산" 근거(기능 경계 강화)가 여기선 성립하지 않는다.
- **검사 1.2′ 신설**: `presentation/<기능>` 간 직접 import 금지. Repo A에 이 검사가 없어서 교차 결합 3건이 샜다(§9) — 공유가 필요하면 view_model을 남의 폴더에 두는 게 아니라 `app/providers/`로 승격한다. 1.1(core 최하층)·1.3(domain 순수)·1.4(UI·VM→data 금지 — `presentation/<기능>/{screens,widgets,view_models}` 기준)·1.5(domain→data 금지)·3.2(Repository 배치)는 경로만 바꿔 그대로 적용.
- **이음매 ①·②(§3)는 변형에서도 동일하게 성립** — auth가 `features/auth/`가 아니라 `presentation/auth/` + `app/providers/`로 갈릴 뿐, core 빈 슬롯과 app 합성 루트는 같은 자리다. ③의 **공유 도메인** 부분만 변형엔 불필요하다 — `domain/`이 이미 단일 공유 레이어라 거기 산다.
- **공용 UI 위젯은 변형에서도 `lib/shared/widgets/`다 — `presentation/` 아래에 공용 버킷을 만들지 않는다.** 1.2′는 `presentation/<X>`를 예외 없이 전부 기능으로 취급하므로, `presentation/shared/`·`presentation/common/` 같은 폴더를 만들면 **그것을 쓰는 모든 화면이 위반으로 잡힌다**(Repo A 실측 8건이 정확히 이 형태였다 — §9). 정상 코드를 잡는 게이트는 사람이 꺼버리므로 §7 전체가 무력해진다. 공용 위젯은 `presentation/` **밖**인 `shared/widgets/`에 두고, 거기서만 Flutter import가 허용된다(§4 1.3 예외).

### 모듈화 천장 — 단일 패키지를 넘을 때 (v1 범위 밖)

이 골격은 **단일 패키지**에서 멈춘다. `lib/features/<x>/`는 한 패키지 안의 모듈화라 경계를 컴파일러가 아니라 §4 검사(grep/AST)만 지킨다. 아래 신호 중 하나가 오면 melos 멀티패키지로 졸업한다 — **기능 수 자체는 신호가 아니다**(§1과 동일 철학):

- **컴파일러 강제 경계**가 필요 — grep 드리프트가 실제 유지비가 되면. melos에선 pubspec 의존성이 "feature A는 B의 public API만"을 빌드 단에서 강제한다.
- **core·디자인시스템을 다른 앱과 재사용** — 공유하려면 그게 패키지여야 한다.
- **패키지 단위 독립 릴리즈·팀 소유**.

졸업 형태: `features/<x>/`→`packages/<x>/`, `core/`·`shared/`→각자 패키지, 앱은 얇은 `apps/app/` 셸. 이때 `check-architecture.sh`의 import 검사(1.1~1.5)는 pubspec 의존성이 대신하므로 **부분 은퇴**한다. 두 기준 repo(Repo A·Repo B)가 melos 미사용이라 전체 스펙은 **측정 후 별도**로 둔다(미검증 추정을 골격에 넣지 않는다).

## 3. 이음매 — 공유를 푸는 세 자리

"기능 간 import 금지"는 이음매 없이는 못 지킨다. 기능들은 결국 인증 세션·공용 값객체 같은 걸 공유해야 하기 때문이다. 답은 **공유를 기능 사이가 아니라 위(app)·아래(core)·옆(shared 커널)으로 빼는 것**이다. 공유의 *성격*에 따라 자리가 갈린다: 상태는 ①, 합성은 ②, 도메인은 ③.

### ① `core/`의 빈 상태 슬롯 — feature → core 단방향 push

`core`가 상태 슬롯을 **선언만** 해두고, 소유 기능이 값을 밀어넣는다. core는 그 기능의 존재를 모른 채 값을 읽는다(의존 역전).

```dart
// core/network/network_providers.dart — core는 feature를 모른다
@Riverpod(keepAlive: true)
class AccessToken extends _$AccessToken {
  @override String? build() => null;
  void setToken(String? token) => state = token;   // ← auth feature가 push
}

// core/network/auth_interceptor.dart — 콜백만 받는다
AuthInterceptor({required this.accessToken});
```

```dart
// features/auth/.../auth_providers.dart — 세션이 바뀌면 core로 push
ref.read(accessTokenProvider.notifier).setToken(token);
```

효과: **다른 기능은 auth의 존재조차 모른 채 인증된 요청을 보낸다.** 인터셉터가 모든 요청에 Bearer를 붙이므로 다른 `features/*`가 auth를 import할 이유가 사라진다. (위 코드는 Repo B 실물과 문자 단위 일치 — 리뷰 검증됨.)

### ② `app/` = 합성 루트

`app/`은 어떤 기능이든 import해도 된다. 라우터는 원래 기능들을 알아야 하고, `app/`은 core도 feature도 아니라 검사 1.1·1.2의 대상이 아니다.

```dart
// app/router/app_router.dart — 기능 import는 여기서만 자유롭다
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
```

(파일 경로는 이 골격 기준 — Repo B 실물은 평면 `app/router.dart`. import 목록 자체는 실물 `router.dart:8·10`과 일치.)

### ③ `shared/` = Shared Kernel — 공유 *도메인*의 유일한 자리

feature-first + 클린 아키의 기본값은 공유가 아니라 **기능별 각자 모델링**이다. 같은 실세계 개념도 bounded context가 다르면 모델이 달라야 한다(auth의 `User`=id·token / profile의 `Profile`=닉네임·아바타). "둘 다 User니까 합치자"는 DRY 본능이 god-core를 만든다 — 진짜 *하나의* 모델에 합의해야 할 때만 공유한다.

공유가 정말 필요한 소수의 도메인은 `core/`(인프라)가 아니라 **`shared/`(core·features 옆 peer)**에 둔다. 도메인을 core에 넣으면 core가 인프라 옷 입은 도메인 레이어로 썩는다(§9 채택하지 않은 것).

**골격은 공유 도메인 폴더를 미리 만들지 않는다.** 두 기준 repo가 기능 5개·8개를 굴리면서 한 번도 필요로 하지 않았다 — "미검증 추정을 골격에 넣지 않는다"는 §9 규율이 여기에도 걸린다. 스캐폴딩이 만드는 `shared/`는 `widgets/`뿐이다(공용 UI — 실측 근거 §4).

**승격 규칙(전부 충족해야 그때 만든다):**
- 2개+ 기능이 실제로 참조한다(1개면 그 기능 `domain/`에 둔다).
- 값객체·원시타입(`Money`·`Id`·enum)이거나 read-mostly 참조 엔티티다 — 또는 2개+ 기능이 *하나의* 모델에 반드시 합의해야 한다.
- 아니면 → 각 기능이 각자 모델링(중복 허용). **두 화면이 같은 API를 불러도 domain은 기능별로 갈리는 게 정상이다** — 같은 DTO를 두 번 쓰는 건 결합이 아니라 bounded context의 대가다. 공유 폴더가 필요하다고 느껴지면 먼저 경계를 의심한다.

만들 때도 **`core/`에는 넣지 않는다.** 검사가 `lib/shared/**`를 이미 도메인 레이어로 취급하므로(§4) 나중에 생겨도 게이트는 즉시 적용된다 — 자리를 비워두는 것이 규칙을 약하게 만들지 않는다.

**계약**: `shared/`는 순수 Dart(Flutter·Riverpod import 금지, domain과 동일) — **`shared/widgets/`만 예외**(§4). features는 shared를 import해도 되지만 shared는 app·features·data를 모른다.

**한계 신호 = layer-first**: shared/가 작은 커널을 넘어 **리치 가변 애그리거트**를 담기 시작하거나 어느 기능 `domain/`보다 커지면, "사실 하나의 bounded context"라는 신호다 → 판정 인터뷰에서 layer-first 변형으로 재검토한다(거기선 `domain/`이 설계상 단일 공유 레이어라 이 문제가 없다).

> **공유가 필요할 때 판단 순서**: ⓐ 공유가 *상태*면 core 슬롯으로 push(①) → ⓑ 합성이면 app/에서 조립(②) → ⓒ *인프라*면 core/로, *작은 도메인 커널*이면 shared/로 승격(③ 규칙) → ⓓ **리치 가변 도메인을 여러 기능이 행위까지 소유하면 경계가 틀린 것 = layer-first 재검토**. core/에는 도메인을 넣지 않는다(god-core 방지).

## 4. 강제 규칙 (grep 검사 9종)

`ARCHITECTURE.md`의 §번호를 인용하고, `.claude/hooks/check-architecture.sh`가 매 턴 자동 실행한다. **번호 공백은 정상이다** — 검사 번호 = ARCHITECTURE.md §번호라, 2.1처럼 빠진 자리는 그 §에 규칙은 있으나 자동 grep이 없다는 뜻이다(예: §5 계약의 VM→Repo 직접 호출 금지 — grep이 오탐 없이 못 잡아 계약으로만 남긴다). "빠진 검사"가 아니다. **검사 명령 자체도 검증 대상이다** — 같은 유형의 false negative가 Repo B에서 **두 번** 나왔다. ① `grep -v`가 파일 경로에도 매치돼 위반 3건이 "0건 clean"으로 오기록. ② 검사 1.2가 import 문자열에 `features/`가 드러나는 경우만 봐서, 상대경로로 옆 기능을 부르는 형태(`import '../../../feature_y/…'`)를 전부 놓침 — 위반 11건이 "0건 PASS"로 통과(§9 정정).

**②는 ①의 처방으로 못 막는다.** 아래 하드닝(`^import` 줄로 매치 범위 좁히기)은 *어디를* 볼지의 문제를 고치고, ②는 *무엇으로 판정할지*의 문제다 — 경로를 문자열로 훑는 한 `../`가 어디로 착지하는지 알 수 없다. 그래서 import 경계 검사는 **URI를 파일 위치 기준으로 정규화한 뒤** 판정한다(`..`를 접어 대상 경로를 확정). 파일시스템 존재 여부에 기대지 않는다 — 깨진 import도 위반이면 잡혀야 한다. **검사를 새로 쓰거나 고칠 땐 위반을 심어 실제로 잡히는지 확인한다**(존재 확인은 검증이 아니다).

**grep은 값싼 per-turn smoke check로 쓰되 "0건 clean"의 권위 증명으로는 신뢰하지 않는다.** import 경계(1.1~1.5·3.2)는 AST 사실이라 text-grep으로는 위 false negative가 근절되지 않는다. 그래서 (a) grep은 반드시 **import 구문 줄만**(예: `^import ` 매치) 대상으로 좁혀 파일 경로 매치를 막고, (b) 권위 있는 강제는 analyzer 단으로 옮긴다 — Riverpod 함정은 `riverpod_lint`(§8)가 `flutter analyze`에서 이미 AST로 잡고, **import 경계의 AST 강제(전용 `analysis_server_plugin` 또는 import-linter)는 후속 과제**로 둔다. 당장의 하이브리드 = 매 턴 싼 hardened-grep(Stop hook·pre-commit smoke) + `flutter analyze`의 riverpod_lint(권위 AST). grep의 "9종 PASS"는 게이트 통과가 아니라 smoke 신호로 읽는다.

| #   | 항목                                                |
| --- | ------------------------------------------------- |
| 1.1 | `core/` → **app·feature** import 금지 *(Repo B 원본에서 확장)* |
| 1.2 | feature 간 직접 import 금지                            |
| 1.3 | `domain/`·`shared/` → Flutter import 금지 — **`shared/widgets/`만 예외**(공용 UI) |
| 1.4 | `presentation/`의 `screens·widgets·view_models` → `data/` import 금지 — UI·VM은 domain(usecase·entity·repo 인터페이스)까지만 안다. `presentation/providers/`(DI 배선)만 예외 *(신작)* |
| 1.5 | `domain/` → `data/` import 금지 — 의존 역전(domain은 data를 모른다) *(신작)* |
| 2.2 | `print()` 금지 — `core/logging` 사용                  |
| 3.1 | 정적 헬퍼 클래스(`XxxUtils`) 금지                          |
| 3.2 | Repository 배치 — 인터페이스=domain, Impl=data           |
| 4.1 | `.gitignore`가 생성물(`*.g.dart`·`*.freezed.dart`) 제외 |

**1.1은 Repo B 원본(core→feature만)에서 core→app까지 확장한다.** 이 문서 초판이 core에 테마 extension을 넣었다가 core→app 계층 역전을 만들었는데, 원본 1.1은 그걸 못 잡는 사각이었다(리뷰 발견 — §9 채택하지 않은 것). core는 최하층이므로 위쪽 어디도 import하지 않아야 하고, 검사가 그 전부를 커버해야 규칙이 산다.

**1.4·1.5는 §5 레이어 계약을 강제한다(신작 — Repo B의 7종에도 없다. 골격은 Repo B 7종에 1.1 확장 + 1.4·1.5 신작으로 9종).** 규칙만 있고 검사가 없으면 presentation이 UseCase를 건너뛰고 `data/`의 dto·datasource·repository impl을 직접 만지는 침식이 조용히 통과한다(clean-ish 코드베이스 최다 침식). **1.4는 UI·ViewModel에만 걸고 `presentation/providers/`(impl 배선이 필요한 DI 합성점)는 예외** — 배선까지 막으면 정상 DI가 위반으로 잡힌다. 1.5는 domain이 data를 참조하는 의존 역전을 막는다. (ViewModel이 Repository를 UseCase 없이 직접 호출하는 것까진 grep이 오탐 없이 못 잡아 §5 계약으로 남긴다.)

**`shared/`(Shared Kernel, §3③)는 도메인 레이어로 취급한다** — 1.1과 같은 방식으로 `shared/` → app·feature import를 금지하고, 1.3(Flutter 금지)·1.5(data 금지)를 `domain/`과 동일 적용한다. `features/` → `shared/`는 허용(core처럼 아래 방향 참조).

**단 `shared/widgets/`는 1.3의 유일한 예외다** — 공용 UI 위젯이 갈 자리가 골격에 없으면(core=인프라, shared=순수 Dart, features/*/widgets=그 기능 전용, app=합성 루트) 여러 기능이 쓰는 다이얼로그·스낵바가 기능 간 import로 새고, **검사가 정상 코드를 위반으로 잡는다**(Repo A 실측: 정상 공용 위젯 사용 8건이 1.2′에 걸린다). 정상 코드를 잡는 게이트는 꺼지므로 §7 전체가 무력해진다. 예외는 `shared/widgets/` **경로 세그먼트로 정확히** 끊는다(`shared/widgets_helpers/` 같은 유사 이름이 새지 않게). 1.1·1.5는 `shared/widgets/`에도 그대로 적용된다 — 공용 위젯이 특정 기능이나 `data/`를 참조하면 위반이다.

**`.claude/`는 반드시 git 추적한다.** Repo A는 `.claude/`가 gitignore라 워크트리에서 검사가 미발화한다 — 정작 "코드는 항상 워크트리에서"가 그 repo 규칙인데 검사가 거기서 안 돈다.

## 5. 레이어 계약

- **호출 방향**: `Screen → ViewModel → UseCase → Repository → DataSource`. ViewModel은 **Repository를 직접 호출하지 않는다** — 비즈니스 작업은 UseCase에 위임. UI·VM의 `data/` 침범은 검사 1.4가, domain의 data 의존은 1.5가 강제한다(VM→UseCase 위임 자체는 §4 주석대로 계약으로 남김).
- **모델 3계층**: `*_dto`(data) → `*_entity`(domain) → `*_state`(presentation). 변환은 `mappers/` 전담 — dto나 repository_impl 안에 넣지 않는다(Repo B가 그렇게 해서 변환이 두 곳에 흩어졌다).
- **`Result<T>` 경계 = Repository**. 그 안쪽(DataSource)은 `AppException`을 던지고, Repository가 `Result<T>`로 감싸 밖으로 낸다. sealed라 호출부의 exhaustive switch가 보장된다.
- **상태 클래스 분리**: `XxxState`는 ViewModel과 같은 파일에 두지 않고 `view_models/` 아래 별도 파일로.
- **앱 전역 Notifier**(인증 세션 등)는 `view_models/`가 아니라 소유 기능의 `presentation/providers/`에.
- **test/는 lib/ 1:1 미러** — mock·테스트 헬퍼는 대응 경로 아래 `utils/`에(Repo B `test/features/auth/data/utils/` 방식).

## 6. 의존성

**도출 규칙: 두 repo 교집합 ∪ 이음매 필수품 — 버전은 두 repo 중 높은 쪽.** 단순 "교집합"이 아니다: `flutter_secure_storage`는 Repo B 전용이지만 이음매 ①(토큰)이 요구해서 들어왔고, 버전이 갈리는 6개(go_router·json_annotation·build_runner·json_serializable·mocktail·flutter_lints)는 전부 높은 쪽을 채택했다. **아래 목록이 정본이다 — Skill은 규칙을 재계산하지 말고 이 목록을 쓴다.**

```yaml
environment:
  sdk: ^3.12.0                    # 두 repo 공통 (Flutter 3.44.x)

dependencies:
  flutter_riverpod: ^3.3.1        # 상태관리 + DI (별도 DI 컨테이너 없음)
  riverpod_annotation: ^4.0.2
  go_router: ^17.2.3
  dio: ^5.9.2
  freezed_annotation: ^3.1.0
  json_annotation: ^4.12.0
  shared_preferences: ^2.5.5
  flutter_secure_storage: ^10.3.1 # Repo B 전용 — 이음매 ①(토큰)이 요구하는 교집합 예외
  logger: ^2.7.0
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_lints: ^6.0.0           # Repo A는 ^5.0.0 — 메이저가 갈림. lint 세트가 바뀌므로 analysis_options는 §8이 정본
  build_runner: ^2.15.0
  freezed: ^3.2.5
  json_serializable: ^6.14.0
  riverpod_generator: ^4.0.3
  riverpod_lint: ^3.0.0           # Riverpod 3 native analysis_server_plugin — flutter analyze에 통합(§7·§8). 최신 3.1.4 확인(pub get이 최종 resolved). riverpod_generator/annotation이 4.x여도 riverpod_lint는 3.x가 정상 — 패키지별 독립 버전이라 오타 아님(4.x로 "고치지" 말 것)
  mocktail: ^1.0.5
```

**골격에 넣지 않는 것**(프로젝트별 선택): firebase_* · flutter_local_notifications · permission_handler · drift · geolocator · mobile_scanner · local_auth · home_widget 등. 두 repo 다 firebase를 쓰지만 프로젝트마다 설정(`firebase_options.dart`·`google-services.json`)이 달라 골격에서 제외한다.

> 생성물(`*.g.dart`·`*.freezed.dart`)은 gitignore한다. 새 체크아웃은 `flutter pub get && dart run build_runner build --delete-conflicting-outputs`를 먼저 돌려야 `part` 누락 에러가 안 난다.

## 7. 하네스 — 구조를 유지시키는 절반

구조보다 **이쪽이 구조를 지킨다.** 규칙만 있고 검사가 없으면 위반이 통과한다(Repo B의 `core → feature` 역방향 의존이 한동안 통과한 전례).

| 파일 | 역할 |
|---|---|
| `.claude/settings.json` | Stop hook 등록부 — **이 파일이 없으면 check-architecture.sh가 아예 안 돈다** |
| `.claude/hooks/check-architecture.sh` | 구조 9종 — Stop hook이 매 턴 자동. 위반 시 **차단 + 구체 보고**(규칙#·파일)하고 멈춘다. 경계 검사(1.1~1.5)는 자동 만족 금지 — 설계 신호로 노출. 기계적 검사(2.2·3.1·4.1)만 자동 수정 허용 |
| `.githooks/pre-commit` | ① `check-architecture.sh`(lib 전체) ② `tool/review/check.mjs --staged` — 고신호 위반 차단. **워크트리 포함** 동작 |
| `.githooks/pre-push` | `main` 직접 push 차단 |
| ~~`tool/review/lifecycle.mjs`~~ | **미채택(2026-07-27)** — 규칙별로 대조하니 남는 게 없었다. Riverpod 함정 전부를 `riverpod_lint`가 `flutter analyze`에서 AST로 잡는다. 직접 짠 JS로 lint 엔진을 유지보수하지 않는다는 §7 원칙의 귀결이라, 파일을 만들지 않는 것이 정답이다 |
| `Makefile` | 커버리지 게이트 `MIN_COVERAGE := 90` — **UI 제외 후 기준**(제외 정책은 §8) |
| `.github/workflows/ci.yml` | 원격 게이트 — analyze + test + `make coverage`(Makefile만으론 로컬 한정) |
| `docs/ARCHITECTURE_AUDIT.md` | 축소 스텁 — baseline 표 + 검사 결함 이력("검사 명령도 검증 대상") |

**경계 위반은 설계 질문이다(공유해야 하나? 경계가 맞나?) — 기계적으로 자동 해소하지 않는다.** Stop hook의 일은 위반 규칙 번호·파일을 구체적으로 보고하고 멈추는 것이고, 고치는 건 보이는 별도 단계다. 경계 검사(1.1~1.5)를 파일 이동·re-export로 조용히 만족시키면 §9의 "한 기능의 뷰모델이 다른 기능 폴더에 산다" 같은 신호가 사라진다. 자동 수정은 모호함 없는 기계적 검사(2.2 `print()`·3.1 `XxxUtils`·4.1 gitignore)에 한한다.

Riverpod 함정(build 중 provider 변경·dispose의 `ref.read`·액션 Notifier `keepAlive` 누락)은 **공식 `riverpod_lint`가 1차 담당**한다 — Riverpod 3의 native analysis_server_plugin이라 `flutter analyze`(§6.4 게이트)에 그대로 잡히고 프레임워크 따라 진화한다. 직접 짠 JS(`lifecycle.mjs`)로 lint 엔진을 유지보수하지 않는 게 목적 — `lifecycle.mjs`는 riverpod_lint가 **못 잡는 규칙만** 남긴다(채택 시 규칙별 대조, 없으면 파일 제거). riverpod_lint 규칙은 기본 warning이니 임계 규칙은 `analysis_options`에서 error로 올려 게이트가 실제로 막게 한다.

pre-commit에서 `check-architecture.sh`는 staged가 아니라 **lib 전체**를 훑는다 — 신규 프로젝트는 baseline이 0이므로 "0 유지" 게이트로 그대로 쓸 수 있다(기존 위반이 쌓인 repo에 이식할 때만 staged 한정이 필요해진다).

## 8. 스캐폴딩 결정 표

트리 밖 결정들 — 이 표가 없으면 Skill이 `flutter create`조차 못 부른다(리뷰 지적). 신작·수정 항목의 구성 정본.

| 결정 | 값 | 근거 |
|---|---|---|
| org / bundle id | **Skill 입력 파라미터**(예: `--org com.example`) | 두 기준 repo도 서로 달랐다 — 골격이 정할 문제가 아니다 |
| 플랫폼 | `flutter create --platforms=android,ios` | 두 repo 다 모바일 전용 운영(다른 플랫폼 폴더는 잔재) |
| `analysis_options.yaml` | Repo B strict판: `strict-casts`·`strict-inference`·`strict-raw-types` + `unawaited_futures: error` + 생성물 exclude(`**/*.g.dart`·`**/*.freezed.dart`) + **`plugins: { riverpod_lint: <ver> }`**(Riverpod 함정을 `flutter analyze`가 AST로 잡게 — §7) | Repo A는 flutter_lints 기본 스텁 — §6의 flutter_lints 6 채택과 정합인 쪽은 Repo B |
| `.gitignore` | flutter create 기본 + `*.g.dart`·`*.freezed.dart` 직접 추가(Repo B `.gitignore:76-77` 방식) | 검사 4.1이 이 패턴을 본다 — 없으면 스캐폴딩 직후 FAIL |
| `.claude/settings.json` | **실물 복사 금지 — 최소 구성으로 작성**: Stop hook(`check-architecture.sh`) + PostToolUse(`dart format`) + flutter·dart·git 조회 permissions. 그 이상은 넣지 않는다 | Repo B 실물은 이 트리에 없는 훅 2개를 `PreToolUse`에서 부르고, 플러그인 활성화·언어 같은 **개인 환경 설정**과 새 repo에 없는 추가 안내가 섞여 있다. 그대로 복사하면 매 Bash·Edit마다 없는 파일을 실행한다(2026-07-27 실측) |
| `check-architecture.sh` | Repo B 실물 복사 + 1.1을 core·shared→app·feature로 확장 + 1.4(UI·VM→data 금지, `providers/` 예외)·1.5(domain→data 금지) 신작 + **1.2를 경로 정규화 방식으로 재작성**(실물은 상대경로 미해석 — §4·§9) + 1.3에서 `shared/widgets/` 예외 | §4 |
| `jq` | 하네스 전제 조건. 없으면 **조용히 통과하지 말고 차단**(hook `exit 2` / `--report` `exit 1`)하고 설치법을 안내 | 검사가 사라지는 것이 위반보다 나쁘다(§7). 일반 개발 환경에서 드러나지 않던 의존이다 |
| pre-commit 구성 | ① `check-architecture.sh` ② `node tool/review/check.mjs --staged` | Repo A pre-commit이 함께 부르는 repo 전용 인덱스 가드는 승계하지 않는다 |
| 훅 활성화 | `git config core.hooksPath .githooks` — 클론 후 1회, README에 명시 | 워크트리는 공유 config라 자동 상속 |
| Makefile 타겟 | Repo A 7종 승계: `test`·`coverage`·`coverage-all`·`coverage-open`·`analyze`·`check`·`clean` | |
| 커버리지 제외 | 생성물 + UI(`*/screens/*`·`*/widgets/*`·`*/theme/*`·`*/router/*` — 이 골격 복수형 경로) | 제외 없이 90을 걸면 1일차부터 못 넘긴다(Repo A `LCOV_EXCLUDE` 정책 승계) |
| CI (`ci.yml`) | analyze → test → `make coverage` — **신작이다**(두 repo의 ci.yml엔 커버리지 게이트가 없어 복사하면 §7이 CI에 둔 이유가 사라진다) | 릴리즈 파이프라인은 프로젝트별 |
| 릴리즈 (`release.yml`) | 태그 `v*` → 버전 산출 → 확인용 APK → GitHub Release **까지만**. 서명·스토어 배포는 넣지 않고 `docs/RELEASE.md`가 필요한 시크릿 이름·선택지만 문서화 | Repo A 실물은 대규모 기존 배포 자동화에 여러 타깃의 서명 예외·배포 채널 선택이 얽혀 있다 — 골격이 정할 문제가 아니다. 다만 "나중에 채우세요" 껍데기는 아무도 안 쓰므로 **설정 없이 도는 범위까지는 완결**시킨다 |
| ADR (`docs/adr/`) | `README.md`(ADR vs 반복 코딩 규칙 구분·파일명 규칙·상태 전이) + `_template.md`(맥락·결정·근거·영향·출처). 인덱스는 빈 표로 시작 | Repo A 실물 승계. 반복 코딩 규칙은 ADR이 아니라 `docs/ARCHITECTURE.md` 몫 |
| CLAUDE.md 내용 | 명령어 요약·§4 검사 9종 표·이 문서 링크 + 외부 프로젝트 문서 연동 지침(사용하는 경우). 상세 규칙은 repo의 `docs/ARCHITECTURE.md`로 위임(중복 금지) | CLAUDE.md는 간결하게 유지 |
| `README.md` | 셋업 3줄: `flutter pub get` → `dart run build_runner build --delete-conflicting-outputs` → `git config core.hooksPath .githooks` | 새 클론이 즉시 구르게 |

**커버리지 게이트의 사각 — UI.** UI를 %에서 제외하므로(위 "커버리지 제외" 행) 게이트는 UI 회귀에 침묵한다. 보완은 게이트 %가 아니라 (a) 중요 플로우 **위젯 테스트**(어느 플로우가 중요한지는 프로젝트가 정한다), (b) **골든 테스트는 opt-in**(플랫폼 렌더링 차이로 flaky해 강제하지 않는다)이다. 두 기준 repo의 위젯/골든 실태는 미측정이라 골격은 이 스탠스를 *처방*하지 않고 트레이드오프만 명시한다.

## 9. 부록 — 두 repo 실측 비교

2026-07-16 측정. 같은 날 fresh-eyes 리뷰로 수치·경로 재검증(정정 2건: Repo B 활성 여부·provider 수).

| | Repo A (레이어 우선) | Repo B (기능 우선) |
|---|---|---|
| 분할축 | 레이어 우선(presentation만 기능별) | **기능 우선**(기능마다 3레이어) |
| 구조 검사 | `domain-no-flutter-import` **1종** | **7종 중 4종이 구조** |
| 검사 시점 | pre-commit + PostToolUse(메인트리만) | Stop hook 매 턴 + 수동 audit |
| 하네스 git 추적 | `.claude/` **미추적** → 클론에 안 감 | `.claude/` **추적** |
| 교차 결합 실측 | **3건**(관계 기준, import 4건) | **11건**(2026-07-27 재측정 — 초판의 "0건 PASS"는 검사 결함) |
| 테스트 파일/수기 lib | 142 / 192 = **0.74** | 58 / 152 = 0.38 |
| 커버리지 게이트 | `MIN_COVERAGE := 90`(UI 제외 후) | **없음** |
| 모델 변환 | `mappers/` 전담 5개 | dto·repository_impl에 분산 |
| `Result` | **실물 있음**(sealed `Result<T>`) | 문서에만 있고 실물 없음 |

**Repo A의 교차 결합 3건**(Repo B의 검사 1.2에 해당하는 걸 손으로 대본 결과 — 결합 형태만 익명화):

```
기능X/screen/…                     → 기능Y/screen/…
기능X/screen/…                     → 기능Y/viewmodel/…
기능X/{viewmodel,screen}/…         → 기능Y/viewmodel/…
```

가운데가 이 골격의 핵심 논거다 — **한 기능의 뷰모델이 다른 기능 폴더에 산다.** 기능이 자기 부품을 남의 폴더에 뒀는데 아무것도 이의를 제기하지 않았다. 기능 우선 + 검사 1.2였다면 커밋 전에 잡힌다.

> **정정 (2026-07-27)**: 초판의 "Repo B 0건"은 **검사가 못 본 결과였다.** 검사 1.2가 import 문자열에 `features/`가 드러나는 경우만 매치해서, 기능 경계를 넘는 가장 자연스러운 형태인 상대경로(`import '../../../feature_y/…'`)를 전부 통과시켰다. 경로를 해석하도록 고쳐 재측정하니 **11건 / 기능쌍 5개**, 그중 `기능X → 기능Y → 기능Z → 기능X` **순환 1개**가 나왔다. 독립 계수(스크립트 경로 해석)와 수정된 검사가 같은 11건을 지목한다.
>
> 초판이 이 하향 조정의 이유로 댄 "기능 수가 적어 결합할 기회가 적었다"도 따라서 틀렸다 — 기회는 있었고 결합도 있었다.
>
> **무엇이 무너지고 무엇이 남는가.** 무너지는 건 "0건"을 feature-first의 성과로 쓴 대목뿐이다. 분할축 선택(§1)은 결합도 논거로 서 있지 이 수치에 기대지 않는다. 오히려 §7의 "구조보다 하네스가 구조를 지킨다"는 강해진다 — 다만 따름정리가 붙는다: **하네스가 틀리면 아무것도 안 지키면서 지킨다고 보고한다.** Repo A의 3건이 훅이 없어서 쌓였다면, Repo B의 11건은 훅이 있는데도 쌓였다. 검사의 정확성이 검사의 존재보다 앞선다.

### 채택하지 않은 것 (근거)

- **`Result<S,F>`**(Repo B 문서안) → `Result<T>` 채택. 실패 타입까지 제네릭으로 열면 호출부마다 타입 인자가 둘 붙는 값을 못 한다. Repo A 건 실제로 도는 물건이고 `Failure` 고정이 exhaustive switch에 깔끔하다.
- **`core/result.dart`**(루트 배치, Repo B 문서안) → `core/errors/result.dart`. `Result<T>`가 `Failure`를 참조하니 같이 바뀔 것끼리 모은다.
- **평면 `app/`**(Repo B 실물 6파일) → 폴더 정리(Repo A 방식). Repo B의 평면은 지금 크기라 버티는 것.
- **`app/common_providers/` 집중**(Repo A 19개) → 기능별 `providers/` 분산. 전역 집중은 기능 경계를 흐린다.
- **`core/extensions/`의 테마 extension 시드**(이 문서 초판) → **철회**(fresh-eyes 리뷰 발견). `context.colors`는 `app/theme`의 시맨틱 토큰을 참조해야 해서 core에 두면 core→app 계층 역전인데, 초판의 검사 1.1(core→feature만)은 이 위반을 못 잡는 사각이었다 — 그래서 1.1을 확장했다(§4). 테마 extension은 Repo A 실물이 옳다: `app_colors_theme.dart:256`에 토큰과 동거. `core/extensions/`는 순수 Dart 대상 전용으로 유지하되 빈 채로 시작한다.
- **`core/domain/`(도메인을 core에 두기)** → **철회**, `shared/` peer 채택(§3③). 공유 도메인을 core에 두면 core가 인프라+도메인 혼합 god-layer로 썩는다 — 공유 도메인은 `core/`·`features/` 옆 peer인 `shared/`(Shared Kernel)로 분리하고 core는 순수 인프라로 불변. 리치 가변 공유는 애초에 feature-first가 아니라 layer-first 신호다.
- **`sensitive_field_masker.dart`**(Repo A) → 골격 제외, 프로젝트별 선택. 마스킹할 필드 목록은 프로젝트가 생겨야 정해진다 — 1일차엔 대상이 없고 `app_logger.dart`만으로 검사 2.2를 충족한다.

### 두 repo에서 가져오지 말 것

- Repo A `test/app/di/` — `lib/app/di`가 `common_providers`로 개명됐는데 안 따라간 잔재
- Repo A `Makefile:20`의 `'*/di/*.dart'` — 대상 없는 죽은 커버리지 제외 패턴. 새 프로젝트에서 `di/`를 만들면 조용히 커버리지에서 빠진다
- Repo A pre-commit이 부르는 repo 전용 인덱스 가드 스크립트 — 그 프로젝트에서만 의미가 있다
- Repo B `app/placeholder_screen.dart` — 스캐폴딩 잔재

### 두 문서 다 드리프트가 있다

골격을 뽑을 때 `ARCHITECTURE.md`는 **실물과 맞춰 새로 쓴다**. 베끼면 드리프트도 따라온다.

- Repo A의 아키텍처 가이드 — 디렉터리 트리가 `app/`·`core/` 하위를 "실제 디렉터리 참조"로 미룬다. 정작 복제할 때 제일 필요한 둘인데 문서엔 없다.
- Repo B의 `ARCHITECTURE.md` — 없는 `core/result.dart`·`core/extensions/`를 있다고 적고, 있는 `core/constants/`는 트리에서 빠져 있다.
