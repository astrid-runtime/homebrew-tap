from __future__ import annotations

import copy
import datetime as dt
import importlib.util
import pathlib
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "resolve_stable_channel", ROOT / "scripts" / "resolve-stable-channel.py"
)
assert SPEC is not None and SPEC.loader is not None
resolver = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(resolver)

NOW = dt.datetime(2026, 7, 17, 12, 0, 0, tzinfo=dt.timezone.utc)


def pointer(version: str = "1.2.3", generation: int = 7) -> dict:
    tag = f"v{version}"
    targets = []
    for index, triple in enumerate(resolver.TARGETS, 1):
        asset = f"astrid-{version}-{triple}.tar.gz"
        targets.append(
            {
                "triple": triple,
                "asset": asset,
                "size": index * 100,
                "blake3": f"{index:064x}",
                "sha256": f"{index + 8:064x}",
                "sigstore-bundle": f"{asset}.sigstore.json",
            }
        )
    return {
        "schema-version": 1,
        "kind": "astrid-channel",
        "product": "astrid-runtime",
        "repository": "astrid-runtime/astrid",
        "channel": "stable",
        "generation": generation,
        "published-at": "2026-07-17T11:00:00Z",
        "expires-at": "2026-07-18T11:00:00Z",
        "release": {
            "version": version,
            "tag": tag,
            "source-commit": "a" * 40,
            "metadata-asset": f"astrid-{version}-release.toml",
            "metadata-blake3": "b" * 64,
            "release-workflow-identity": (
                "https://github.com/astrid-runtime/astrid/"
                f".github/workflows/release.yml@refs/tags/{tag}"
            ),
        },
        "targets": targets,
    }


def quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def render(data: dict) -> str:
    release = data["release"]
    lines = [
        f'schema-version = {str(data["schema-version"]).lower()}',
        f'kind = {quote(data["kind"])}',
        f'product = {quote(data["product"])}',
        f'repository = {quote(data["repository"])}',
        f'channel = {quote(data["channel"])}',
        f'generation = {str(data["generation"]).lower()}',
        f'published-at = {quote(data["published-at"])}',
        f'expires-at = {quote(data["expires-at"])}',
        "",
        "[release]",
    ]
    for key in (
        "version",
        "tag",
        "source-commit",
        "metadata-asset",
        "metadata-blake3",
        "release-workflow-identity",
    ):
        lines.append(f"{key} = {quote(release[key])}")
    for target in data["targets"]:
        lines.extend(
            [
                "",
                "[[targets]]",
                f'triple = {quote(target["triple"])}',
                f'asset = {quote(target["asset"])}',
                f'size = {str(target["size"]).lower()}',
                f'blake3 = {quote(target["blake3"])}',
                f'sha256 = {quote(target["sha256"])}',
                f'sigstore-bundle = {quote(target["sigstore-bundle"])}',
            ]
        )
    return "\n".join(lines) + "\n"


def checksum_text(data: dict) -> str:
    return "".join(f'{target["sha256"]}  {target["asset"]}\n' for target in data["targets"])


class StablePointerValidationTests(unittest.TestCase):
    def test_accepts_complete_stable_pointer(self) -> None:
        resolver.validate_pointer(pointer(), now=NOW)

    def test_rejects_wrong_root_identity(self) -> None:
        for key, value in (
            ("kind", "other-channel"),
            ("product", "other-product"),
            ("repository", "other/repository"),
            ("channel", "dev"),
        ):
            with self.subTest(key=key):
                candidate = pointer()
                candidate[key] = value
                with self.assertRaises(ValueError):
                    resolver.validate_pointer(candidate, now=NOW)

    def test_rejects_bool_integer_fields(self) -> None:
        for path in ("schema", "generation", "size"):
            with self.subTest(path=path):
                candidate = pointer()
                if path == "schema":
                    candidate["schema-version"] = True
                elif path == "generation":
                    candidate["generation"] = True
                else:
                    candidate["targets"][0]["size"] = True
                with self.assertRaises(ValueError):
                    resolver.validate_pointer(candidate, now=NOW)

    def test_rejects_non_stable_version_and_release_identity(self) -> None:
        candidates = []
        prerelease = pointer()
        prerelease["release"]["version"] = "1.2.3-rc.1"
        candidates.append(prerelease)
        wrong_tag = pointer()
        wrong_tag["release"]["tag"] = "v1.2.4"
        candidates.append(wrong_tag)
        wrong_workflow = pointer()
        wrong_workflow["release"]["release-workflow-identity"] = "https://example.invalid"
        candidates.append(wrong_workflow)
        for candidate in candidates:
            with self.subTest(candidate=candidate["release"]):
                with self.assertRaises(ValueError):
                    resolver.validate_pointer(candidate, now=NOW)

    def test_rejects_unknown_key(self) -> None:
        candidate = pointer()
        candidate["trusted"] = True
        with self.assertRaises(ValueError):
            resolver.validate_pointer(candidate, now=NOW)

    def test_rejects_expired_future_and_overlong_pointer(self) -> None:
        expired = pointer()
        expired["expires-at"] = "2026-07-17T11:59:59Z"
        future = pointer()
        future["published-at"] = "2026-07-17T12:06:00Z"
        future["expires-at"] = "2026-07-18T12:06:00Z"
        overlong = pointer()
        overlong["expires-at"] = "2026-08-17T11:00:01Z"
        for candidate in (expired, future, overlong):
            with self.assertRaises(ValueError):
                resolver.validate_pointer(candidate, now=NOW)

    def test_rejects_bad_target_set_and_fields(self) -> None:
        missing = pointer()
        missing["targets"].pop()
        duplicate = pointer()
        duplicate["targets"][1]["triple"] = duplicate["targets"][0]["triple"]
        bad_asset = pointer()
        bad_asset["targets"][0]["asset"] = "../astrid.tar.gz"
        bad_digest = pointer()
        bad_digest["targets"][0]["sha256"] = "A" * 64
        for candidate in (missing, duplicate, bad_asset, bad_digest):
            with self.assertRaises(ValueError):
                resolver.validate_pointer(candidate, now=NOW)


class ChecksumTests(unittest.TestCase):
    def test_signed_checksums_must_equal_pointer_targets(self) -> None:
        candidate = pointer()
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "SHA256SUMS.txt"
            path.write_text(checksum_text(candidate), encoding="utf-8")
            resolver.verify_checksums(candidate, path)
            path.write_text(checksum_text(candidate) + f'{"f" * 64}  unexpected.tar.gz\n', encoding="utf-8")
            with self.assertRaises(ValueError):
                resolver.verify_checksums(candidate, path)

    def test_rejects_mismatched_duplicate_and_malformed_checksums(self) -> None:
        candidate = pointer()
        valid = checksum_text(candidate)
        cases = (
            valid.replace(candidate["targets"][0]["sha256"], "f" * 64, 1),
            valid + valid.splitlines(keepends=True)[0],
            valid.replace("  ", " ", 1),
        )
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "SHA256SUMS.txt"
            for contents in cases:
                with self.subTest(contents=contents):
                    path.write_text(contents, encoding="utf-8")
                    with self.assertRaises(ValueError):
                        resolver.verify_checksums(candidate, path)


class ReplayTests(unittest.TestCase):
    def resolve_pair(self, candidate: dict, current: dict | None) -> dict:
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            candidate_path = root / "candidate.toml"
            checksums = root / "SHA256SUMS.txt"
            candidate_path.write_text(render(candidate), encoding="utf-8")
            checksums.write_text(checksum_text(candidate), encoding="utf-8")
            current_path = None
            if current is not None:
                current_path = root / "current.toml"
                current_path.write_text(render(current), encoding="utf-8")
            return resolver.resolve(candidate_path, checksums, current_path, NOW)

    def test_first_pointer_changes_state(self) -> None:
        self.assertTrue(self.resolve_pair(pointer(), None)["state-changed"])

    def test_same_generation_same_bytes_is_idempotent(self) -> None:
        candidate = pointer()
        self.assertFalse(self.resolve_pair(candidate, copy.deepcopy(candidate))["state-changed"])

    def test_rejects_lower_generation_replay(self) -> None:
        with self.assertRaises(ValueError):
            self.resolve_pair(pointer(generation=6), pointer(generation=7))

    def test_rejects_same_generation_equivocation(self) -> None:
        with self.assertRaises(ValueError):
            self.resolve_pair(pointer(version="1.2.4"), pointer(version="1.2.3"))

    def test_accepts_higher_generation_signed_rollback(self) -> None:
        result = self.resolve_pair(
            pointer(version="1.2.3", generation=8),
            pointer(version="1.2.4", generation=7),
        )
        self.assertTrue(result["state-changed"])
        self.assertEqual(result["version"], "1.2.3")

    def test_expired_history_still_establishes_generation_floor(self) -> None:
        current = pointer(generation=7)
        current["expires-at"] = "2026-07-17T11:59:59Z"
        result = self.resolve_pair(pointer(generation=8), current)
        self.assertTrue(result["state-changed"])


class WorkflowContractTests(unittest.TestCase):
    def test_updater_pulls_only_the_signed_stable_channel(self) -> None:
        workflow = (ROOT / ".github" / "workflows" / "update-formula.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn("schedule:", workflow)
        self.assertIn("workflow_dispatch:", workflow)
        self.assertNotIn("repository_dispatch", workflow)
        self.assertNotIn("client_payload", workflow)
        self.assertNotIn("TAP_DISPATCH_TOKEN", workflow)
        self.assertIn("CHANNEL_TAG=channel-stable", workflow)
        self.assertIn("--use-signed-timestamps", workflow)
        self.assertIn("state/channel-stable.toml", workflow)
        self.assertIn("persist-credentials: false", workflow)


if __name__ == "__main__":
    unittest.main()
