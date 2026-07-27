#!/bin/bash
# layer-first용 docs/ARCHITECTURE.md 빠른 grep 점검(9종)의 단일 출처 — Stop hook + 수동 리포트 겸용
# - hook 모드(기본): Stop 이벤트에서 stdin으로 JSON을 받아 위반 시 block JSON 출력
# - --report 모드: 항목별 PASS/FAIL 표 출력, FAIL 있으면 exit 1
set -u

mode="hook"
[ "${1:-}" = "--report" ] && mode="report"

if ! command -v jq >/dev/null 2>&1; then
  echo "오류: 아키텍처 검사에 jq가 필요합니다. 설치: brew install jq (Debian/Ubuntu: sudo apt-get install jq)" >&2
  [ "$mode" = "report" ] && exit 1
  exit 2
fi

# ---------- 점검 항목 ----------
# check_<id>: 위반 내용을 stdout으로 출력한다. 출력이 없으면 통과.

check_1_1() { # core/shared → app·3레이어 import 금지
  grep -rnE "^[[:space:]]*import[[:space:]].*(app|data|domain|presentation)/" \
    lib/core lib/shared --include="*.dart" 2>/dev/null
  return 0
}

check_1_2() { # presentation 기능 간 직접 import 금지(1.2′)
  local f fname
  for f in lib/presentation/*/; do
    [ -d "$f" ] || continue
    fname=$(basename "$f")
    # import URI를 파일 디렉터리 기준으로 문자열 정규화해 존재하지 않는 상대 경로도 판정한다.
    find "$f" -type f -name "*.dart" -exec awk -v current="$fname" -v boundary="presentation" '
      function normalize(path, count, depth, i, segment, result) {
        split("", path_parts)
        count = split(path, path_parts, "/")
        split("", normalized_parts)
        depth = 0

        for (i = 1; i <= count; i++) {
          segment = path_parts[i]
          if (segment == "" || segment == ".") {
            continue
          }
          if (segment == "..") {
            if (depth > 0 && normalized_parts[depth] != "..") {
              depth--
            } else {
              normalized_parts[++depth] = segment
            }
            continue
          }
          normalized_parts[++depth] = segment
        }

        result = ""
        for (i = 1; i <= depth; i++) {
          result = result (i > 1 ? "/" : "") normalized_parts[i]
        }
        return result
      }

      function resolve_import(uri, package_path, slash, source_dir) {
        if (index(uri, "package:") == 1) {
          package_path = substr(uri, length("package:") + 1)
          slash = index(package_path, "/")
          if (slash == 0) {
            return ""
          }
          return normalize("lib/" substr(package_path, slash + 1))
        }
        if (uri ~ /^[A-Za-z][A-Za-z0-9+.-]*:/) {
          return ""
        }

        source_dir = FILENAME
        sub("/[^/]*$", "", source_dir)
        return normalize(source_dir "/" uri)
      }

      /^[[:space:]]*import[[:space:]]/ {
        import_text = $0
        sub(/^[[:space:]]*import[[:space:]]+/, "", import_text)
        quote = substr(import_text, 1, 1)
        if (quote != sprintf("%c", 39) && quote != "\"") {
          next
        }

        import_text = substr(import_text, 2)
        quote_end = index(import_text, quote)
        if (quote_end == 0) {
          next
        }

        target = resolve_import(substr(import_text, 1, quote_end - 1))
        split("", target_parts)
        target_count = split(target, target_parts, "/")
        if (target_count >= 3 &&
            target_parts[1] == "lib" &&
            target_parts[2] == boundary &&
            target_parts[3] != current) {
          print FILENAME ":" FNR ":" $0
        }
      }
    ' {} + 2>/dev/null
  done
  return 0
}

check_1_3() { # domain/shared → Flutter import 금지(shared/widgets 제외)
  find lib/domain lib/shared -type f -name "*.dart" \
    ! -path "lib/shared/widgets/*" \
    -exec grep -lE "^[[:space:]]*import[[:space:]].*package:flutter/" {} + 2>/dev/null
  return 0
}

check_1_4() { # presentation UI·VM → data import 금지(providers 제외)
  grep -rnE "^[[:space:]]*import[[:space:]].*data/" \
    lib/presentation/*/screens \
    lib/presentation/*/widgets \
    lib/presentation/*/view_models \
    --include="*.dart" 2>/dev/null
  return 0
}

check_1_5() { # domain/shared → data import 금지
  grep -rnE "^[[:space:]]*import[[:space:]].*data/" \
    lib/domain lib/shared --include="*.dart" 2>/dev/null
  return 0
}

check_2_2() { # print() 금지
  # 단어 경계로 sprint( 등 오탐을 막고, 전체 주석 줄만 제외한다(후행 주석 뒤의 실제 print는 잡음).
  grep -rnE "(^|[^A-Za-z0-9_])print\(" lib --include="*.dart" 2>/dev/null \
    | grep -vE "^[^:]*:[0-9]+:[[:space:]]*//|\.g\.dart|\.freezed\.dart|debugPrint"
  return 0
}

check_3_1() { # 정적 헬퍼 클래스 금지
  grep -rn "class [A-Z][A-Za-z]*Utils" lib --include="*.dart" 2>/dev/null
  return 0
}

check_3_2() { # Repository 인터페이스/구현 배치
  grep -rn "class .*RepositoryImpl" lib/domain --include="*.dart" 2>/dev/null
  grep -rn "abstract .*Repository" lib/data --include="*.dart" 2>/dev/null
  return 0
}

check_4_1() { # .gitignore가 생성물을 제외함
  grep -qE "\*\.g\.dart" .gitignore 2>/dev/null && grep -qE "\*\.freezed\.dart" .gitignore 2>/dev/null \
    || echo ".gitignore에 *.g.dart / *.freezed.dart 패턴이 없음"
  return 0
}

item_title() {
  case "$1" in
    1_1) echo "core/shared → app·data·domain·presentation import 금지" ;;
    1_2) echo "presentation 기능 간 직접 import 금지" ;;
    1_3) echo "domain/shared → Flutter import 금지(shared/widgets만 예외)" ;;
    1_4) echo "presentation UI·ViewModel → data import 금지" ;;
    1_5) echo "domain/shared → data import 금지" ;;
    2_2) echo "print() 금지 — core/logging logger 사용" ;;
    3_1) echo "정적 헬퍼 클래스(XxxUtils) 금지" ;;
    3_2) echo "Repository 배치 — 인터페이스는 domain, Impl은 data" ;;
    4_1) echo ".gitignore가 *.g.dart/*.freezed.dart를 제외함" ;;
  esac
}

item_fix() {
  case "$1" in
    1_1) echo "공유 대상이면 core/shared 인프라로 끌어올리고, 아니면 소유 레이어로 되돌린다. core/shared 함수가 상위 레이어 타입을 받지 않게 한다." ;;
    1_2) echo "공유 대상을 core/shared로 끌어올리거나 조립을 app 레이어로 옮긴다." ;;
    1_3) echo "Flutter 타입은 domain과 shared/widgets 밖의 shared에서 제거하고, 둘 이상 기능이 쓰는 표현 위젯만 shared/widgets에 둔다." ;;
    1_4) echo "UI·ViewModel은 domain의 UseCase·Entity·Repository 인터페이스만 참조한다. 구현 배선은 presentation/<기능>/providers로 옮긴다." ;;
    1_5) echo "domain/shared의 data 참조를 제거하고 Repository 인터페이스를 domain에 둔다." ;;
    2_2) echo "core/logging의 logger로 교체한다." ;;
    3_1) echo "Extension(<receiver>_extensions.dart) 또는 top-level 함수(<category>_utils.dart)로 변환한다. 정적 멤버 없는 인스턴스 클래스 오탐이면 사용자에게 보고." ;;
    3_2) echo "인터페이스는 domain/repositories/로, 구현은 data/repositories/로 이동한다." ;;
    4_1) echo ".gitignore에 *.g.dart / *.freezed.dart를 추가하고 생성물을 git rm --cached 한다." ;;
  esac
}

# 새 항목 추가 시 4곳 갱신: check_<id> 함수, item_title, item_fix, ITEMS
ITEMS="1_1 1_2 1_3 1_4 1_5 2_2 3_1 3_2 4_1"

# ---------- 실행 컨텍스트 ----------
stop_active="false"
if [ "$mode" = "hook" ]; then
  input=$(cat)
  stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
  proj="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$input" | jq -r '.cwd // "."')}"
else
  proj="${CLAUDE_PROJECT_DIR:-.}"
fi
cd "$proj" 2>/dev/null || exit 0
[ -d lib ] || exit 0

# ---------- 점검 실행 ----------
violations=""
fail=0
for id in $ITEMS; do
  out=$("check_$id")
  if [ "$mode" = "report" ]; then
    if [ -n "$out" ]; then
      fail=$((fail + 1))
      echo "FAIL [$id] $(item_title "$id")"
      printf '%s\n' "$out" | sed 's/^/      /'
      echo "      → 조치: $(item_fix "$id")"
    else
      echo "PASS [$id] $(item_title "$id")"
    fi
  elif [ -n "$out" ]; then
    violations="${violations}[${id}] $(item_title "$id")
${out}
→ 조치: $(item_fix "$id")

"
  fi
done

if [ "$mode" = "report" ]; then
  [ "$fail" -gt 0 ] && exit 1
  exit 0
fi

[ -z "$violations" ] && exit 0

if [ "$stop_active" = "true" ]; then
  jq -cn --arg msg "⚠️ 아키텍처 위반 잔존 (자동 수정 1회 후에도 미해결) — 수동 확인 필요:

$violations" '{systemMessage:$msg}'
  exit 0
fi

jq -cn --arg reason "docs/ARCHITECTURE.md 위반이 감지되었습니다. 아래 항목을 수정한 뒤 작업을 마치세요. 오탐으로 판단되면(예: 3.1에 정적 멤버 없는 인스턴스 클래스가 매치) 수정하지 말고 사용자에게 보고하세요.

$violations" '{decision:"block", reason:$reason}'
exit 0
