#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

formula="$work/astrid.rb"
pointer="$work/channel-stable.toml"
bundle="$work/channel-stable.toml.sigstore.json"
payload="$work/payload.json"
printf 'class Astrid < Formula\nend\n' > "$formula"
printf 'generation = 7\n' > "$pointer"
printf '{"bundle":"signed"}\n' > "$bundle"

"$repo_root/scripts/create-signed-commit-payload.sh" \
  astrid-runtime/homebrew-tap \
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
  1.2.3-rc.1 \
  "$formula" \
  "$pointer" \
  "$bundle" > "$payload"

expected_formula="$(base64 < "$formula" | tr -d '\n')"
expected_pointer="$(base64 < "$pointer" | tr -d '\n')"
expected_bundle="$(base64 < "$bundle" | tr -d '\n')"
jq -e \
  --arg formula "$expected_formula" \
  --arg pointer "$expected_pointer" \
  --arg bundle "$expected_bundle" \
  '.variables.input == {
    branch: {
      repositoryNameWithOwner: "astrid-runtime/homebrew-tap",
      refName: "refs/heads/main"
    },
    expectedHeadOid: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    message: { headline: "chore: follow Astrid stable v1.2.3-rc.1" },
    fileChanges: {
      additions: [
        { path: "Formula/astrid.rb", contents: $formula },
        { path: "state/channel-stable.toml", contents: $pointer },
        {
          path: "state/channel-stable.toml.sigstore.json",
          contents: $bundle
        }
      ]
    }
  }' "$payload" > /dev/null
jq -e \
  '.query | contains("signature { isValid wasSignedByGitHub }")' \
  "$payload" > /dev/null

if "$repo_root/scripts/create-signed-commit-payload.sh" \
  astrid-runtime/homebrew-tap not-a-commit 1.2.3 \
  "$formula" "$pointer" "$bundle" > /dev/null 2>&1; then
  echo "payload builder accepted an invalid expected head" >&2
  exit 1
fi

if "$repo_root/scripts/create-signed-commit-payload.sh" \
  astrid-runtime/homebrew-tap \
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
  1.2.3+build.7 \
  "$formula" \
  "$pointer" \
  "$bundle" > /dev/null 2>&1; then
  echo "payload builder accepted an unsupported version" >&2
  exit 1
fi

ln -s "$pointer" "$work/pointer-link"
if "$repo_root/scripts/create-signed-commit-payload.sh" \
  astrid-runtime/homebrew-tap \
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
  1.2.3 \
  "$formula" \
  "$work/pointer-link" \
  "$bundle" > /dev/null 2>&1; then
  echo "payload builder accepted a symlinked state input" >&2
  exit 1
fi
