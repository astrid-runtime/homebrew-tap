#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

formula="$work/astrid.rb"
payload="$work/payload.json"
printf 'class Astrid < Formula\nend\n' > "$formula"

"$repo_root/scripts/create-signed-commit-payload.sh" \
  astrid-runtime/homebrew-tap \
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
  1.2.3-rc.1 \
  "$formula" > "$payload"

expected_contents="$(base64 < "$formula" | tr -d '\n')"
jq -e \
  --arg contents "$expected_contents" \
  '.variables.input == {
    branch: {
      repositoryNameWithOwner: "astrid-runtime/homebrew-tap",
      refName: "refs/heads/main"
    },
    expectedHeadOid: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    message: { headline: "chore: bump astrid to v1.2.3-rc.1" },
    fileChanges: {
      additions: [{ path: "Formula/astrid.rb", contents: $contents }]
    }
  }' "$payload" > /dev/null
jq -e \
  '.query | contains("signature { isValid wasSignedByGitHub }")' \
  "$payload" > /dev/null

if "$repo_root/scripts/create-signed-commit-payload.sh" \
  astrid-runtime/homebrew-tap not-a-commit 1.2.3 "$formula" > /dev/null 2>&1; then
  echo "payload builder accepted an invalid expected head" >&2
  exit 1
fi

if "$repo_root/scripts/create-signed-commit-payload.sh" \
  astrid-runtime/homebrew-tap \
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
  1.2.3+build.7 \
  "$formula" > /dev/null 2>&1; then
  echo "payload builder accepted an unsupported version" >&2
  exit 1
fi
