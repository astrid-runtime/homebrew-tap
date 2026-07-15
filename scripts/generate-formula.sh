#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <version> <SHA256SUMS.txt> <output.rb>" >&2
  exit 2
fi

version="$1"
manifest="$2"
output="$3"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${script_dir}/validate-version.sh" "$version"

if [[ ! -r "$manifest" ]]; then
  echo "Checksum manifest is not readable: $manifest" >&2
  exit 1
fi

checksum_for() {
  local asset="$1"
  local matches
  local match_count
  local digest
  local field_count

  matches="$(awk -v asset="$asset" '$2 == asset { print $1 "|" NF }' "$manifest")"
  match_count="$(printf '%s\n' "$matches" | awk 'NF { count++ } END { print count + 0 }')"

  if [[ "$match_count" -ne 1 ]]; then
    echo "Expected exactly one SHA-256 entry for $asset; found $match_count" >&2
    return 1
  fi

  digest="${matches%%|*}"
  field_count="${matches##*|}"
  if [[ "$field_count" -ne 2 || ! "$digest" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Expected one lowercase 64-character SHA-256 entry for $asset" >&2
    return 1
  fi

  printf '%s' "$digest"
}

sha_arm_mac="$(checksum_for "astrid-${version}-aarch64-apple-darwin.tar.gz")"
sha_x86_mac="$(checksum_for "astrid-${version}-x86_64-apple-darwin.tar.gz")"
sha_arm_linux="$(checksum_for "astrid-${version}-aarch64-unknown-linux-gnu.tar.gz")"
sha_x86_linux="$(checksum_for "astrid-${version}-x86_64-unknown-linux-gnu.tar.gz")"

cat > "$output" <<FORMULA
class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/astrid-runtime/astrid"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v${version}/astrid-${version}-aarch64-apple-darwin.tar.gz"
      sha256 "${sha_arm_mac}"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v${version}/astrid-${version}-x86_64-apple-darwin.tar.gz"
      sha256 "${sha_x86_mac}"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v${version}/astrid-${version}-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "${sha_arm_linux}"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v${version}/astrid-${version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "${sha_x86_linux}"
    end
  end

  def install
    bin.install "astrid"
    bin.install "astrid-daemon"
    bin.install "astrid-build"
    bin.install "astrid-emit"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/astrid --version")
  end
end
FORMULA
