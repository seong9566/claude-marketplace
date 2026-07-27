#!/usr/bin/env node
import { execFileSync, execSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

import { runDeterministicChecks } from './checks.mjs';

const DART = /(^|\/)lib\/.+\.dart$/;

function stagedTargetFiles() {
  const out = execSync('git diff --cached --name-only --diff-filter=ACM', {
    encoding: 'utf8',
  });
  return out
    .split('\n')
    .filter((file) => DART.test(file) && !/\.(g|freezed)\.dart$/.test(file));
}

function stagedContent(file) {
  return execFileSync('git', ['show', `:${file}`], { encoding: 'utf8' });
}

function runStagedMode() {
  const files = stagedTargetFiles();
  if (files.length === 0) return 0;

  const violations = files.flatMap((file) =>
    runDeterministicChecks(`/${file}`, stagedContent(file)).map((violation) => ({
      ...violation,
      file,
    })));
  const blocks = violations.filter((violation) => violation.severity === 'block');
  const warns = violations.filter((violation) => violation.severity === 'warn');

  for (const violation of [...blocks, ...warns]) {
    process.stdout.write(
      `  [${violation.severity}] ${violation.file}:${violation.line} ` +
        `${violation.check} — ${violation.message}\n`,
    );
  }
  if (blocks.length > 0) {
    process.stderr.write(
      '\n❌ 결정론 차단 위반 — 커밋 중단 (긴급 시 git commit --no-verify)\n',
    );
    return 1;
  }
  return 0;
}

function main() {
  if (process.argv[2] === '--staged') return runStagedMode();
  process.stderr.write('usage: check.mjs --staged\n');
  return 0;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  process.exit(main());
}
