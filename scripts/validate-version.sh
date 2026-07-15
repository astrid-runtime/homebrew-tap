#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <version>" >&2
  exit 2
fi

version="$1"
numeric_identifier='(0|[1-9][0-9]*)'
prerelease='[0-9A-Za-z]+([.-][0-9A-Za-z]+)*'
version_pattern="^${numeric_identifier}\.${numeric_identifier}\.${numeric_identifier}(-${prerelease})?$"

if [[ ! "$version" =~ $version_pattern ]]; then
  echo "Invalid release version: $version" >&2
  exit 1
fi
