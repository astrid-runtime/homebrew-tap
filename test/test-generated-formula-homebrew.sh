#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tap="astrid-ci-generated/tap"
tmpdir="$(mktemp -d)"

cleanup() {
  brew untap "$tap" >/dev/null 2>&1 || true
  rm -rf "$tmpdir"
}
trap cleanup EXIT

brew untap "$tap" >/dev/null 2>&1 || true
brew tap-new --no-git "$tap" >/dev/null

for version in 1.2.3 1.2.3-alpha 1.2.3-alpha.1 1.2.3-beta.1 1.2.3-rc.1; do
  manifest="${tmpdir}/SHA256SUMS-${version}.txt"
  sed "s/astrid-1.2.3-/astrid-${version}-/g" \
    "${repo_root}/test/fixtures/valid.txt" > "$manifest"
  formula="$(brew --repository "$tap")/Formula/astrid.rb"
  "${repo_root}/scripts/generate-formula.sh" "$version" "$manifest" "$formula"

  actual_version="$(
    brew info --json=v2 "$tap/astrid" |
      ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("formulae").first.fetch("versions").fetch("stable")'
  )"
  if [[ "$actual_version" != "$version" ]]; then
    echo "Expected Homebrew to infer version $version; found $actual_version" >&2
    exit 1
  fi

  brew audit --strict "$tap/astrid"
done
