#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixtures="${repo_root}/test/fixtures"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

expect_version_failure() {
  local version="$1"
  if "${repo_root}/scripts/validate-version.sh" "$version" >/dev/null 2>&1; then
    fail "version unexpectedly accepted: $version"
  fi
}

expect_generation_failure() {
  local fixture="$1"
  if "${repo_root}/scripts/generate-formula.sh" \
    1.2.3 \
    "${fixtures}/${fixture}" \
    "${tmpdir}/${fixture}.rb" >/dev/null 2>&1; then
    fail "fixture unexpectedly generated a formula: $fixture"
  fi
}

for version in 1.2.3 2026.1.0 1.2.3-alpha 1.2.3-rc.1 1.2.3-alpha-beta.1 1.2.3-0.3.7; do
  "${repo_root}/scripts/validate-version.sh" "$version"
done

for version in \
  v1.2.3 \
  1.2 \
  1.2.3/asset \
  ../1.2.3 \
  1.2.3- \
  1.2.3-. \
  1.2.3-.. \
  1.2.3-rc..1 \
  1.2.3-01 \
  01.2.3 \
  1.02.3 \
  1.2.03 \
  1.2.3+ \
  1.2.3+build.7 \
  1.2.3-rc.1+build.7; do
  expect_version_failure "$version"
done

generated="${tmpdir}/astrid.rb"
"${repo_root}/scripts/generate-formula.sh" \
  1.2.3 \
  "${fixtures}/valid.txt" \
  "$generated"

ruby -c "$generated" >/dev/null
if grep -Eq '^[[:space:]]*version ' "$generated"; then
  fail "generated formula contains a redundant explicit version"
fi
grep -Fq '/releases/download/v1.2.3/astrid-1.2.3-aarch64-apple-darwin.tar.gz' "$generated" \
  || fail "generated versioned archive URL is missing"
grep -Fq 'sha256 "1111111111111111111111111111111111111111111111111111111111111111"' "$generated" \
  || fail "macOS ARM checksum is missing"
grep -Fq 'sha256 "2222222222222222222222222222222222222222222222222222222222222222"' "$generated" \
  || fail "macOS x86 checksum is missing"
grep -Fq 'sha256 "3333333333333333333333333333333333333333333333333333333333333333"' "$generated" \
  || fail "Linux ARM checksum is missing"
grep -Fq 'sha256 "4444444444444444444444444444444444444444444444444444444444444444"' "$generated" \
  || fail "Linux x86 checksum is missing"

expect_generation_failure missing.txt
expect_generation_failure duplicate.txt
expect_generation_failure malformed.txt

echo "Formula generation tests passed"
