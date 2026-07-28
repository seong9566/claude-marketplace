#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
PLUGIN_DIR=$(cd "$TEST_DIR/.." && pwd -P)
FEATURE_HOOK="$PLUGIN_DIR/skills/flutter-project/templates/claude/hooks/check-architecture.sh"
LAYERED_HOOK="$PLUGIN_DIR/skills/flutter-project/templates/claude/hooks/check-architecture-layered.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/check-architecture.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

new_tree() {
  local tree="$1"
  local package_name="${2:-example}"
  mkdir -p "$tree/lib"
  printf 'name: %s\n' "$package_name" > "$tree/pubspec.yaml"
  printf '%s\n' '*.g.dart' '*.freezed.dart' > "$tree/.gitignore"
}

write_source() {
  local tree="$1"
  local source="$2"
  shift 2
  mkdir -p "$tree/$(dirname "$source")"
  printf '%s\n' "$@" > "$tree/$source"
}

run_report() {
  local hook="$1"
  local tree="$2"
  REPORT_OUTPUT=""
  REPORT_STATUS=0
  if REPORT_OUTPUT=$(cd "$tree" && "$hook" --report 2>&1); then
    REPORT_STATUS=0
  else
    REPORT_STATUS=$?
  fi
}

assert_1_2_fails() {
  local name="$1"
  local hook="$2"
  local source="$3"
  local import_line="$4"
  local tree="$TMP_ROOT/$name"

  new_tree "$tree"
  write_source "$tree" "$source" "$import_line"
  run_report "$hook" "$tree"

  [ "$REPORT_STATUS" -eq 1 ] \
    || fail "$name: expected report exit 1, got $REPORT_STATUS
$REPORT_OUTPUT"
  printf '%s\n' "$REPORT_OUTPUT" | grep -Fq "FAIL [1_2]" \
    || fail "$name: expected 1.2 failure
$REPORT_OUTPUT"
  printf '%s\n' "$REPORT_OUTPUT" | grep -Fq "$source:1:$import_line" \
    || fail "$name: expected file:line:content violation output
$REPORT_OUTPUT"
}

assert_1_2_passes() {
  local name="$1"
  local hook="$2"
  local tree="$TMP_ROOT/$name"
  shift 2

  new_tree "$tree"
  while [ "$#" -gt 0 ]; do
    write_source "$tree" "$1" "$2"
    shift 2
  done
  run_report "$hook" "$tree"

  [ "$REPORT_STATUS" -eq 0 ] \
    || fail "$name: expected report exit 0, got $REPORT_STATUS
$REPORT_OUTPUT"
  printf '%s\n' "$REPORT_OUTPUT" | grep -Fq "PASS [1_2]" \
    || fail "$name: expected 1.2 pass
$REPORT_OUTPUT"
}

assert_check_fails() {
  local name="$1"
  local hook="$2"
  local check_id="$3"
  local source="$4"
  local import_line="$5"
  local tree="$TMP_ROOT/$name"

  new_tree "$tree"
  write_source "$tree" "$source" "$import_line"
  run_report "$hook" "$tree"

  [ "$REPORT_STATUS" -eq 1 ] \
    || fail "$name: expected report exit 1, got $REPORT_STATUS
$REPORT_OUTPUT"
  printf '%s\n' "$REPORT_OUTPUT" | grep -Fq "FAIL [$check_id]" \
    || fail "$name: expected $check_id failure
$REPORT_OUTPUT"
}

assert_check_passes() {
  local name="$1"
  local hook="$2"
  local check_ids="$3"
  local check_id
  local tree="$TMP_ROOT/$name"
  shift 3

  new_tree "$tree"
  while [ "$#" -gt 0 ]; do
    write_source "$tree" "$1" "$2"
    shift 2
  done
  run_report "$hook" "$tree"

  [ "$REPORT_STATUS" -eq 0 ] \
    || fail "$name: expected report exit 0, got $REPORT_STATUS
$REPORT_OUTPUT"
  for check_id in $check_ids; do
    printf '%s\n' "$REPORT_OUTPUT" | grep -Fq "PASS [$check_id]" \
      || fail "$name: expected $check_id pass
$REPORT_OUTPUT"
  done
}

assert_demo_app_check_fails() {
  local name="$1"
  local hook="$2"
  local check_id="$3"
  local source="$4"
  local import_line="$5"
  local tree="$TMP_ROOT/$name"

  new_tree "$tree" "demo_app"
  write_source "$tree" "$source" "$import_line"
  run_report "$hook" "$tree"

  [ "$REPORT_STATUS" -eq 1 ] \
    || fail "$name: expected report exit 1, got $REPORT_STATUS
$REPORT_OUTPUT"
  printf '%s\n' "$REPORT_OUTPUT" | grep -Fq "FAIL [$check_id]" \
    || fail "$name: expected $check_id failure
$REPORT_OUTPUT"
  printf '%s\n' "$REPORT_OUTPUT" | grep -Fq "$source:1:$import_line" \
    || fail "$name: expected file:line:content violation output
$REPORT_OUTPUT"
}

assert_demo_app_checks_pass() {
  local name="$1"
  local hook="$2"
  local check_ids="$3"
  local check_id
  local tree="$TMP_ROOT/$name"
  shift 3

  new_tree "$tree" "demo_app"
  while [ "$#" -gt 0 ]; do
    write_source "$tree" "$1" "$2"
    shift 2
  done
  run_report "$hook" "$tree"

  [ "$REPORT_STATUS" -eq 0 ] \
    || fail "$name: expected report exit 0, got $REPORT_STATUS
$REPORT_OUTPUT"
  for check_id in $check_ids; do
    printf '%s\n' "$REPORT_OUTPUT" | grep -Fq "PASS [$check_id]" \
      || fail "$name: expected $check_id pass
$REPORT_OUTPUT"
  done
}

assert_1_2_fails \
  "feature-relative-cross-import" \
  "$FEATURE_HOOK" \
  "lib/features/home/presentation/providers/home_providers.dart" \
  "import '../../../auth/presentation/providers/auth_notifier.dart';"

assert_1_2_fails \
  "feature-explicit-cross-import" \
  "$FEATURE_HOOK" \
  "lib/features/home/presentation/providers/home_providers.dart" \
  "import 'package:example/features/auth/presentation/providers/auth_notifier.dart';"

assert_1_2_passes \
  "feature-allowed-imports" \
  "$FEATURE_HOOK" \
  "lib/features/home/data/repositories/r.dart" \
  "import '../datasources/d.dart';" \
  "lib/features/home/data/repositories/core_r.dart" \
  "import '../../../../core/network/dio_client.dart';" \
  "lib/features/home/data/repositories/shared_r.dart" \
  "import '../../../../shared/value_objects/money.dart';" \
  "lib/features/home/presentation/providers/packages.dart" \
  "import 'package:flutter/widgets.dart';" \
  "lib/features/home/presentation/providers/sdk.dart" \
  "import 'dart:async';" \
  "lib/features/home/data/datasources/dio_source.dart" \
  "import 'package:dio/dio.dart';"

assert_1_2_fails \
  "layered-relative-cross-import" \
  "$LAYERED_HOOK" \
  "lib/presentation/home/screens/home_screen.dart" \
  "import '../../auth/screens/login_screen.dart';"

assert_1_2_fails \
  "layered-explicit-cross-import" \
  "$LAYERED_HOOK" \
  "lib/presentation/home/screens/home_screen.dart" \
  "import 'package:example/presentation/auth/screens/login_screen.dart';"

# presentation/ 의 자식은 예외 없이 전부 기능이다 — shared·common 같은 공용 버킷을
# 그 아래 만들면 그것을 쓰는 모든 화면이 위반으로 잡힌다(골격 §2 변형의 경고).
# 공용 위젯의 자리는 presentation/ 밖 lib/shared/widgets/ 이며, 아래
# layered-shared-widget-imports 케이스가 그쪽이 통과함을 함께 고정한다.
# 이 케이스가 깨지면 1.2′ 에 이름 기반 예외가 뚫린 것이다 — 문서를 먼저 고칠 것.
assert_1_2_fails \
  "layered-presentation-shared-bucket-is-not-exempt" \
  "$LAYERED_HOOK" \
  "lib/presentation/home/screens/home_screen.dart" \
  "import '../../shared/app_dialog.dart';"

assert_1_2_passes \
  "layered-allowed-imports" \
  "$LAYERED_HOOK" \
  "lib/presentation/home/widgets/home_card.dart" \
  "import '../screens/home_screen.dart';" \
  "lib/presentation/home/widgets/core_card.dart" \
  "import '../../../core/network/dio_client.dart';" \
  "lib/presentation/home/widgets/shared_card.dart" \
  "import '../../../shared/value_objects/money.dart';" \
  "lib/presentation/home/widgets/flutter_card.dart" \
  "import 'package:flutter/widgets.dart';" \
  "lib/presentation/home/widgets/async_card.dart" \
  "import 'dart:async';" \
  "lib/presentation/home/widgets/dio_card.dart" \
  "import 'package:dio/dio.dart';"

assert_check_passes \
  "feature-shared-widget-imports" \
  "$FEATURE_HOOK" \
  "1_2 1_3" \
  "lib/shared/widgets/app_dialog.dart" \
  "import 'package:flutter/material.dart';" \
  "lib/features/home/presentation/widgets/home_card.dart" \
  "import '../../../../shared/widgets/app_dialog.dart';"

assert_check_fails \
  "feature-shared-value-object-flutter-import" \
  "$FEATURE_HOOK" \
  "1_3" \
  "lib/shared/value_objects/money.dart" \
  "import 'package:flutter/material.dart';"

assert_check_fails \
  "feature-domain-flutter-import" \
  "$FEATURE_HOOK" \
  "1_3" \
  "lib/features/home/domain/entities/e.dart" \
  "import 'package:flutter/material.dart';"

assert_check_fails \
  "feature-similar-widget-directory-flutter-import" \
  "$FEATURE_HOOK" \
  "1_3" \
  "lib/shared/widgets_helpers/bad.dart" \
  "import 'package:flutter/material.dart';"

assert_check_fails \
  "feature-shared-widget-feature-import" \
  "$FEATURE_HOOK" \
  "1_1" \
  "lib/shared/widgets/bad.dart" \
  "import 'package:example/features/home/presentation/widgets/home_card.dart';"

assert_check_fails \
  "feature-shared-widget-data-import" \
  "$FEATURE_HOOK" \
  "1_5" \
  "lib/shared/widgets/bad2.dart" \
  "import 'package:example/features/home/data/repositories/r.dart';"

assert_check_passes \
  "layered-shared-widget-imports" \
  "$LAYERED_HOOK" \
  "1_2 1_3" \
  "lib/shared/widgets/app_dialog.dart" \
  "import 'package:flutter/material.dart';" \
  "lib/presentation/home/widgets/home_card.dart" \
  "import '../../../shared/widgets/app_dialog.dart';"

assert_check_fails \
  "layered-shared-value-object-flutter-import" \
  "$LAYERED_HOOK" \
  "1_3" \
  "lib/shared/value_objects/money.dart" \
  "import 'package:flutter/material.dart';"

assert_check_fails \
  "layered-domain-flutter-import" \
  "$LAYERED_HOOK" \
  "1_3" \
  "lib/domain/entities/e.dart" \
  "import 'package:flutter/material.dart';"

assert_check_fails \
  "layered-similar-widget-directory-flutter-import" \
  "$LAYERED_HOOK" \
  "1_3" \
  "lib/shared/widgets_helpers/bad.dart" \
  "import 'package:flutter/material.dart';"

assert_check_fails \
  "layered-shared-widget-feature-import" \
  "$LAYERED_HOOK" \
  "1_1" \
  "lib/shared/widgets/bad.dart" \
  "import 'package:example/presentation/home/widgets/home_card.dart';"

assert_check_fails \
  "layered-shared-widget-data-import" \
  "$LAYERED_HOOK" \
  "1_5" \
  "lib/shared/widgets/bad2.dart" \
  "import 'package:example/data/repositories/r.dart';"

assert_demo_app_checks_pass \
  "feature-demo-app-allowed-imports" \
  "$FEATURE_HOOK" \
  "1_1 1_4 1_5" \
  "lib/core/errors/result.dart" \
  "import 'package:demo_app/core/errors/failures.dart';" \
  "lib/core/network/client.dart" \
  "import '../logging/app_logger.dart';" \
  "lib/shared/widgets/dialog.dart" \
  "import 'package:demo_app/shared/widgets/button.dart';" \
  "lib/core/network/dio_client.dart" \
  "import 'package:dio/dio.dart';" \
  "lib/core/network/features_client.dart" \
  "import 'package:features_client/features/y.dart';" \
  "lib/features/auth/presentation/screens/external.dart" \
  "import 'package:external_package/data/y.dart';" \
  "lib/shared/async/runner.dart" \
  "import 'dart:async';" \
  "lib/features/auth/domain/entities/session.dart" \
  "import 'package:demo_app/features/auth/domain/entities/user.dart';"

assert_demo_app_check_fails \
  "feature-demo-app-core-to-feature" \
  "$FEATURE_HOOK" \
  "1_1" \
  "lib/core/x.dart" \
  "import 'package:demo_app/features/auth/y.dart';"

assert_demo_app_check_fails \
  "feature-relative-core-to-app" \
  "$FEATURE_HOOK" \
  "1_1" \
  "lib/core/x.dart" \
  "import '../app/y.dart';"

assert_demo_app_check_fails \
  "feature-demo-app-screen-to-data" \
  "$FEATURE_HOOK" \
  "1_4" \
  "lib/features/auth/presentation/screens/s.dart" \
  "import 'package:demo_app/features/auth/data/y.dart';"

assert_demo_app_check_fails \
  "feature-demo-app-view-model-to-data" \
  "$FEATURE_HOOK" \
  "1_4" \
  "lib/features/auth/presentation/view_models/v.dart" \
  "import 'package:demo_app/features/auth/data/y.dart';"

assert_demo_app_check_fails \
  "feature-demo-app-domain-to-data" \
  "$FEATURE_HOOK" \
  "1_5" \
  "lib/features/auth/domain/x.dart" \
  "import 'package:demo_app/features/auth/data/y.dart';"

assert_demo_app_checks_pass \
  "layered-demo-app-allowed-imports" \
  "$LAYERED_HOOK" \
  "1_1 1_4 1_5" \
  "lib/core/errors/result.dart" \
  "import 'package:demo_app/core/errors/failures.dart';" \
  "lib/core/network/client.dart" \
  "import '../logging/app_logger.dart';" \
  "lib/shared/widgets/dialog.dart" \
  "import 'package:demo_app/shared/widgets/button.dart';" \
  "lib/core/network/dio_client.dart" \
  "import 'package:dio/dio.dart';" \
  "lib/core/network/presentation_client.dart" \
  "import 'package:presentation_client/presentation/y.dart';" \
  "lib/presentation/auth/screens/external.dart" \
  "import 'package:external_package/data/y.dart';" \
  "lib/shared/async/runner.dart" \
  "import 'dart:async';" \
  "lib/domain/entities/session.dart" \
  "import 'package:demo_app/domain/entities/user.dart';"

assert_demo_app_check_fails \
  "layered-demo-app-core-to-presentation" \
  "$LAYERED_HOOK" \
  "1_1" \
  "lib/core/x.dart" \
  "import 'package:demo_app/presentation/auth/y.dart';"

assert_demo_app_check_fails \
  "layered-relative-core-to-app" \
  "$LAYERED_HOOK" \
  "1_1" \
  "lib/core/x.dart" \
  "import '../app/y.dart';"

assert_demo_app_check_fails \
  "layered-demo-app-screen-to-data" \
  "$LAYERED_HOOK" \
  "1_4" \
  "lib/presentation/auth/screens/s.dart" \
  "import 'package:demo_app/data/y.dart';"

assert_demo_app_check_fails \
  "layered-demo-app-view-model-to-data" \
  "$LAYERED_HOOK" \
  "1_4" \
  "lib/presentation/auth/view_models/v.dart" \
  "import 'package:demo_app/data/y.dart';"

assert_demo_app_check_fails \
  "layered-demo-app-domain-to-data" \
  "$LAYERED_HOOK" \
  "1_5" \
  "lib/domain/x.dart" \
  "import 'package:demo_app/data/y.dart';"

echo "PASS: check-architecture import boundary regression tests"
