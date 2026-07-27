// 결정론 체크 — 순수 함수. (filePath, content) → Violation[].
// Violation = { check, severity: 'block'|'warn', line, message }

const COLOR_LITERAL = /Color\(0x/;
const RAW_PALETTE = /\bAppPalette\./;

export function checkHardcodedColor(filePath, content) {
  if (!filePath.includes('/presentation/')) return [];
  const out = [];
  content.split('\n').forEach((line, index) => {
    if (COLOR_LITERAL.test(line) || RAW_PALETTE.test(line)) {
      out.push({
        check: 'hardcoded-color',
        severity: 'block',
        line: index + 1,
        message:
          '위젯에서 하드코딩 색(Color(0x…))·raw AppPalette 금지 — context.colors 시맨틱 토큰 사용',
      });
    }
  });
  return out;
}

const MAX_FILE_LINES = 300;

export function checkLength(filePath, content) {
  if (!/\/lib\/.*\.dart$/.test(filePath)) return [];
  const lines = content.split('\n').length;
  if (lines > MAX_FILE_LINES) {
    return [
      {
        check: 'length-warn',
        severity: 'warn',
        line: lines,
        message: `파일 ${lines}줄 > ${MAX_FILE_LINES}줄 — 위젯/책임 분리 검토`,
      },
    ];
  }
  return [];
}

const ANNOTATION = /@(freezed\b|riverpod\b|Riverpod\(|JsonSerializable\b)/;
const PART_DIRECTIVE = /^\s*part\s+['"]/;

export function checkCodegenPartMissing(filePath, content) {
  if (!/\/lib\/.*\.dart$/.test(filePath)) return [];
  if (!ANNOTATION.test(content)) return [];
  const lines = content.split('\n');
  if (lines.some((line) => PART_DIRECTIVE.test(line))) return [];
  const index = lines.findIndex((line) => ANNOTATION.test(line));
  return [
    {
      check: 'codegen-part-missing',
      severity: 'block',
      line: index + 1,
      message:
        '@freezed/@riverpod/@JsonSerializable 있는데 part 선언 없음 — build_runner 생성 part 필요',
    },
  ];
}

const CHECKS = [checkHardcodedColor, checkLength, checkCodegenPartMissing];
const GENERATED = /\.(g|freezed)\.dart$/;

export function runDeterministicChecks(filePath, content) {
  if (GENERATED.test(filePath)) return [];
  return CHECKS.flatMap((check) => check(filePath, content));
}
