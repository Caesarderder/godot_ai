#!/usr/bin/env python3
"""Focused standard-library tests for the Web rollback package boundary."""

from __future__ import annotations

import json
from pathlib import Path
import tarfile
import tempfile
import unittest

from package_web_rollback import Candidate, _archive_bytes, _safe_member_path


class RollbackArchiveTests(unittest.TestCase):
    def test_member_path_accepts_regular_web_payload(self) -> None:
        member = tarfile.TarInfo("web/index.html")
        member.type = tarfile.REGTYPE
        self.assertEqual(_safe_member_path(member).as_posix(), "web/index.html")

    def test_member_path_rejects_unsafe_entries(self) -> None:
        unsafe = [
            tarfile.TarInfo("/web/index.html"),
            tarfile.TarInfo("web/../escape"),
            tarfile.TarInfo("other/index.html"),
            tarfile.TarInfo("web"),
        ]
        link = tarfile.TarInfo("web/link")
        link.type = tarfile.SYMTYPE
        unsafe.append(link)
        for member in unsafe:
            with self.subTest(name=member.name):
                with self.assertRaises(ValueError):
                    _safe_member_path(member)

    def test_archive_is_byte_deterministic_and_normalized(self) -> None:
        with tempfile.TemporaryDirectory(prefix="project-a-rollback-unit-") as temporary:
            directory = Path(temporary)
            (directory / "index.html").write_text("<canvas></canvas>\n", encoding="utf-8")
            (directory / "nested").mkdir()
            (directory / "nested/data.json").write_text(
                json.dumps({"value": 1}) + "\n",
                encoding="utf-8",
            )
            files = {
                "index.html": {"bytes": 18, "sha256": "unused"},
                "nested/data.json": {"bytes": 13, "sha256": "unused"},
            }
            candidate = Candidate(directory=directory, metadata={}, files=files)
            first = _archive_bytes(candidate)
            second = _archive_bytes(candidate)
            self.assertEqual(first, second)

            archive_path = directory / "rollback.tar.gz"
            archive_path.write_bytes(first)
            with tarfile.open(archive_path, mode="r:gz") as archive:
                members = archive.getmembers()
                self.assertEqual(
                    [member.name for member in members],
                    ["web/index.html", "web/nested/data.json"],
                )
                for member in members:
                    self.assertEqual(member.mode, 0o644)
                    self.assertEqual(member.mtime, 0)
                    self.assertEqual(member.uid, 0)
                    self.assertEqual(member.gid, 0)
                    self.assertTrue(member.isfile())


if __name__ == "__main__":
    unittest.main()
