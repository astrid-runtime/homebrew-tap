#!/usr/bin/env python3
"""Validate Astrid's signed stable pointer and Homebrew checksum manifest."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import re
import sys
import tomllib
from typing import Any, NoReturn


PRODUCT = "astrid-runtime"
REPOSITORY = "astrid-runtime/astrid"
TARGETS = (
    "aarch64-apple-darwin",
    "aarch64-unknown-linux-gnu",
    "x86_64-apple-darwin",
    "x86_64-unknown-linux-gnu",
)
MAX_GENERATION = (1 << 63) - 1
MAX_LIFETIME = dt.timedelta(days=30)
MAX_FUTURE_SKEW = dt.timedelta(minutes=5)
HEX_40 = re.compile(r"[0-9a-f]{40}")
HEX_64 = re.compile(r"[0-9a-f]{64}")
VERSION = re.compile(
    r"(0|[1-9][0-9]*)\."
    r"(0|[1-9][0-9]*)\."
    r"(0|[1-9][0-9]*)"
)
ROOT_KEYS = {
    "schema-version",
    "kind",
    "product",
    "repository",
    "channel",
    "generation",
    "published-at",
    "expires-at",
    "release",
    "targets",
}
RELEASE_KEYS = {
    "version",
    "tag",
    "source-commit",
    "metadata-asset",
    "metadata-blake3",
    "release-workflow-identity",
}
TARGET_KEYS = {
    "triple",
    "asset",
    "size",
    "blake3",
    "sha256",
    "sigstore-bundle",
}


def fail(message: str) -> NoReturn:
    raise ValueError(message)


def exact_table(value: Any, keys: set[str], label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail(f"{label} must be a TOML table")
    missing = keys - set(value)
    unknown = set(value) - keys
    if missing or unknown:
        fail(f"{label} keys differ: missing={sorted(missing)}, unknown={sorted(unknown)}")
    return value


def string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value or "\n" in value or "\r" in value:
        fail(f"{label} must be a non-empty, single-line string")
    return value


def timestamp(value: Any, label: str) -> dt.datetime:
    text = string(value, label)
    if re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z", text) is None:
        fail(f"{label} must use canonical UTC RFC3339 seconds")
    try:
        return dt.datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError as error:
        fail(f"{label} is not a real timestamp: {error}")


def load_pointer(path: pathlib.Path) -> dict[str, Any]:
    if not path.is_file() or path.is_symlink():
        fail(f"channel pointer is not a regular file: {path}")
    try:
        with path.open("rb") as file:
            data = tomllib.load(file)
    except (OSError, tomllib.TOMLDecodeError) as error:
        fail(f"could not parse channel pointer {path}: {error}")
    if not isinstance(data, dict):
        fail("channel pointer root must be a TOML table")
    return data


def validate_pointer(
    data: dict[str, Any], *, now: dt.datetime | None, allow_expired: bool = False
) -> None:
    exact_table(data, ROOT_KEYS, "channel root")
    if type(data["schema-version"]) is not int or data["schema-version"] != 1:
        fail("channel schema-version must be integer 1")
    if (
        data["kind"] != "astrid-channel"
        or data["product"] != PRODUCT
        or data["repository"] != REPOSITORY
        or data["channel"] != "stable"
    ):
        fail("channel identity is not Astrid stable")
    for key in ("kind", "product", "repository", "channel", "published-at", "expires-at"):
        string(data[key], f"channel {key}")

    generation = data["generation"]
    if type(generation) is not int or not 1 <= generation <= MAX_GENERATION:
        fail("channel generation must be an integer from 1 through 2^63-1")
    published = timestamp(data["published-at"], "channel published-at")
    expires = timestamp(data["expires-at"], "channel expires-at")
    if expires <= published:
        fail("channel expires-at must be after published-at")
    if expires - published > MAX_LIFETIME:
        fail("stable channel lifetime exceeds 30 days")
    if now is not None:
        if now.tzinfo is None:
            fail("validation time must be timezone-aware")
        if published > now + MAX_FUTURE_SKEW:
            fail("channel published-at is unreasonably far in the future")
        if not allow_expired and now > expires:
            fail("stable channel pointer has expired")

    release = exact_table(data["release"], RELEASE_KEYS, "channel release")
    for key in RELEASE_KEYS:
        string(release[key], f"channel release {key}")
    version = release["version"]
    if VERSION.fullmatch(version) is None:
        fail("stable release version must be canonical X.Y.Z")
    tag = release["tag"]
    if tag != f"v{version}":
        fail("stable release tag does not match its version")
    if HEX_40.fullmatch(release["source-commit"]) is None:
        fail("stable release source commit is invalid")
    if release["metadata-asset"] != f"astrid-{version}-release.toml":
        fail("stable release metadata asset is not canonical")
    if HEX_64.fullmatch(release["metadata-blake3"]) is None:
        fail("stable release metadata BLAKE3 digest is invalid")
    expected_release_identity = (
        f"https://github.com/{REPOSITORY}/.github/workflows/release.yml@refs/tags/{tag}"
    )
    if release["release-workflow-identity"] != expected_release_identity:
        fail("stable release workflow identity is invalid")

    targets = data["targets"]
    if not isinstance(targets, list) or len(targets) != len(TARGETS):
        fail("stable pointer must contain exactly four target entries")
    seen: set[str] = set()
    for entry in targets:
        entry = exact_table(entry, TARGET_KEYS, "channel target")
        triple = entry["triple"]
        if not isinstance(triple, str) or triple not in TARGETS or triple in seen:
            fail("stable pointer target set is invalid")
        seen.add(triple)
        asset = f"astrid-{version}-{triple}.tar.gz"
        if entry["asset"] != asset or entry["sigstore-bundle"] != f"{asset}.sigstore.json":
            fail(f"stable pointer asset identity is invalid for {triple}")
        if type(entry["size"]) is not int or entry["size"] <= 0:
            fail(f"stable pointer asset size is invalid for {triple}")
        for key in ("blake3", "sha256"):
            value = entry[key]
            if not isinstance(value, str) or HEX_64.fullmatch(value) is None:
                fail(f"stable pointer {key} digest is invalid for {triple}")
    if seen != set(TARGETS):
        fail("stable pointer target set is incomplete")


def read_checksums(path: pathlib.Path) -> dict[str, str]:
    if not path.is_file() or path.is_symlink():
        fail(f"checksum manifest is not a regular file: {path}")
    entries: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        fail(f"could not read checksum manifest {path}: {error}")
    for number, raw in enumerate(lines, 1):
        parts = raw.split("  ")
        if len(parts) != 2 or HEX_64.fullmatch(parts[0]) is None:
            fail(f"{path}:{number}: malformed SHA-256 checksum entry")
        asset = parts[1]
        if not asset or pathlib.PurePosixPath(asset).name != asset or any(ch.isspace() for ch in asset):
            fail(f"{path}:{number}: unsafe asset name {asset!r}")
        if asset in entries:
            fail(f"{path}:{number}: duplicate checksum for {asset}")
        entries[asset] = parts[0]
    return entries


def verify_checksums(pointer: dict[str, Any], path: pathlib.Path) -> None:
    checksums = read_checksums(path)
    expected = {entry["asset"]: entry["sha256"] for entry in pointer["targets"]}
    if checksums != expected:
        missing = sorted(set(expected) - set(checksums))
        unexpected = sorted(set(checksums) - set(expected))
        mismatched = sorted(
            asset
            for asset in set(expected) & set(checksums)
            if expected[asset] != checksums[asset]
        )
        fail(
            "signed SHA256SUMS.txt differs from the stable pointer: "
            f"missing={missing}, unexpected={unexpected}, mismatched={mismatched}"
        )


def resolve(
    pointer_path: pathlib.Path,
    checksum_path: pathlib.Path | None,
    current_path: pathlib.Path | None,
    now: dt.datetime,
) -> dict[str, Any]:
    pointer = load_pointer(pointer_path)
    validate_pointer(pointer, now=now)
    if checksum_path is not None:
        verify_checksums(pointer, checksum_path)

    state_changed = True
    if current_path is not None:
        current = load_pointer(current_path)
        validate_pointer(current, now=now, allow_expired=True)
        candidate_generation = pointer["generation"]
        current_generation = current["generation"]
        if candidate_generation < current_generation:
            fail("stable channel generation is older than the accepted generation")
        if candidate_generation == current_generation:
            if pointer_path.read_bytes() != current_path.read_bytes():
                fail("stable channel equivocated at an accepted generation")
            state_changed = False

    release = pointer["release"]
    return {
        "version": release["version"],
        "tag": release["tag"],
        "generation": pointer["generation"],
        "state-changed": state_changed,
    }


def parse_now(value: str) -> dt.datetime:
    parsed = timestamp(value, "validation time")
    return parsed


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pointer", type=pathlib.Path, required=True)
    parser.add_argument("--checksums", type=pathlib.Path)
    parser.add_argument("--current-pointer", type=pathlib.Path)
    parser.add_argument("--now", required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args()

    try:
        result = resolve(
            args.pointer,
            args.checksums,
            args.current_pointer,
            parse_now(args.now),
        )
        args.output.write_text(json.dumps(result, sort_keys=True) + "\n", encoding="utf-8")
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from None


if __name__ == "__main__":
    main()
