#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 6 ]]; then
  echo "usage: $0 <owner/repository> <expected-head-oid> <version> <formula> <channel-pointer> <channel-bundle>" >&2
  exit 2
fi

repository=$1
head=$2
version=$3
formula=$4
channel_pointer=$5
channel_bundle=$6
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "invalid GitHub repository: $repository" >&2
  exit 1
fi
if [[ ! "$head" =~ ^[0-9a-f]{40}$ ]]; then
  echo "invalid expected head oid" >&2
  exit 1
fi
"${script_dir}/validate-version.sh" "$version"
for file in "$formula" "$channel_pointer" "$channel_bundle"; do
  if [[ ! -f "$file" || -L "$file" ]]; then
    echo "commit input is not a regular file: $file" >&2
    exit 1
  fi
done

# GraphQL variable syntax is literal.
# shellcheck disable=SC2016
query='mutation($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid url signature { isValid wasSignedByGitHub } } } }'
formula_contents="$(base64 < "$formula" | tr -d '\n')"
pointer_contents="$(base64 < "$channel_pointer" | tr -d '\n')"
bundle_contents="$(base64 < "$channel_bundle" | tr -d '\n')"

jq -n \
  --arg query "$query" \
  --arg repository "$repository" \
  --arg head "$head" \
  --arg headline "chore: follow Astrid stable v${version}" \
  --arg formula_contents "$formula_contents" \
  --arg pointer_contents "$pointer_contents" \
  --arg bundle_contents "$bundle_contents" \
  '{
    query: $query,
    variables: {
      input: {
        branch: {
          repositoryNameWithOwner: $repository,
          refName: "refs/heads/main"
        },
        expectedHeadOid: $head,
        message: { headline: $headline },
        fileChanges: {
          additions: [
            { path: "Formula/astrid.rb", contents: $formula_contents },
            { path: "state/channel-stable.toml", contents: $pointer_contents },
            {
              path: "state/channel-stable.toml.sigstore.json",
              contents: $bundle_contents
            }
          ]
        }
      }
    }
  }'
