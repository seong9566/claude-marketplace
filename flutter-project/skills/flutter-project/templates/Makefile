.PHONY: test coverage coverage-all coverage-open analyze check clean

MIN_COVERAGE := 90
COVERAGE_TITLE := __APP_NAME__ Coverage
LCOV_RAW := coverage/lcov.info
LCOV_FILTERED := coverage/lcov_filtered.info
COVERAGE_HTML := coverage/html
COVERAGE_HELPER := test/coverage_helper_test.dart

# 생성 파일 + UI 제외 패턴 (한 곳에서 관리)
LCOV_EXCLUDE := \
	'*.g.dart' \
	'*.freezed.dart' \
	'*/screens/*' \
	'*/widgets/*' \
	'*/theme/*' \
	'*/router/*'

# ─── 개별 타겟 ─────────────────────────────────

## 전체 테스트 실행
test:
	flutter test

## 정적 분석
analyze:
	flutter analyze

## 커버리지 측정 + HTML 리포트 + 90% 게이트
coverage:
	flutter test --coverage
	@$(MAKE) --no-print-directory _filter_and_report

## 미테스트 파일 포함한 정확한 커버리지 (CI용)
coverage-all:
	@find lib -name '*.dart' \
		! -name '*.g.dart' \
		! -name '*.freezed.dart' \
		| sort \
		| sed "s|lib/|import 'package:__APP_NAME__/|;s|$$|';|" \
		> $(COVERAGE_HELPER)
	@echo "void main() {}" >> $(COVERAGE_HELPER)
	@flutter test --coverage
	@rm -f $(COVERAGE_HELPER)
	@$(MAKE) --no-print-directory _filter_and_report

## 커버리지 HTML 브라우저에서 열기 (90% 게이트 없이 — 미달이어도 리포트를 연다)
## 게이트만 빼고 _report로 생성: flutter test·lcov·genhtml 실패는 그대로 전파돼 stale 리포트를 열지 않는다.
coverage-open:
	flutter test --coverage
	@$(MAKE) --no-print-directory _report
	open $(COVERAGE_HTML)/index.html

## 분석 + 테스트 + 커버리지 한번에 (PR 전 점검용)
check: analyze coverage-all

## 커버리지 산출물 정리
clean:
	rm -rf coverage/
	rm -f $(COVERAGE_HELPER)

# ─── 내부 타겟 (직접 호출하지 마세요) ──────────

_filter_and_report:
	@$(MAKE) --no-print-directory _report
	@$(MAKE) --no-print-directory _gate

## 리포트 생성만 (게이트 없음)
_report:
	@lcov --remove $(LCOV_RAW) $(LCOV_EXCLUDE) \
		--ignore-errors unused \
		-o $(LCOV_FILTERED)
	@genhtml $(LCOV_FILTERED) \
		--output-directory $(COVERAGE_HTML) \
		--title "$(COVERAGE_TITLE)" \
		--quiet

## 90% 게이트 (미달 시 exit 1)
_gate:
	@RATE=$$(lcov --summary $(LCOV_FILTERED) 2>&1 \
		| grep 'lines' | awk '{print $$2}' | cut -d'%' -f1); \
	echo ""; \
	echo "──────────────────────────────────"; \
	echo "  Coverage: $${RATE}% (minimum: $(MIN_COVERAGE)%)"; \
	if [ $$(echo "$${RATE} < $(MIN_COVERAGE)" | bc) -eq 1 ]; then \
		echo "  ❌ 커버리지 미달"; \
		echo "──────────────────────────────────"; \
		exit 1; \
	else \
		echo "  ✅ 커버리지 통과"; \
		echo "──────────────────────────────────"; \
	fi
