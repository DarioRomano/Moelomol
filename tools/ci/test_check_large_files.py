#!/usr/bin/env python3
"""Tests for check_large_files.py. Run: python3 -m unittest discover -s tools/ci

Each test builds a throwaway git repository with global and system git config
switched off, so no LFS filter runs and the test controls exactly which blobs
are committed (raw content, or a hand-written LFS pointer).
"""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from check_large_files import LIMIT_BYTES, problems

ATTRIBUTES = "*.wav filter=lfs diff=lfs merge=lfs -text\n*.png binary\n"
POINTER = ("version https://git-lfs.github.com/spec/v1\n"
           "oid sha256:" + "a" * 64 + "\nsize 5000000\n")


class LargeFileTest(unittest.TestCase):
    def setUp(self) -> None:
        self._saved = {k: os.environ.get(k) for k in ("GIT_CONFIG_GLOBAL", "GIT_CONFIG_NOSYSTEM")}
        os.environ["GIT_CONFIG_GLOBAL"] = os.devnull
        os.environ["GIT_CONFIG_NOSYSTEM"] = "1"
        self._tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self._tmp.name)
        self._git("init", "-q")
        (self.repo / ".gitattributes").write_text(ATTRIBUTES)
        self._git("add", ".gitattributes")

    def tearDown(self) -> None:
        self._tmp.cleanup()
        for key, value in self._saved.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value

    def _git(self, *args: str) -> None:
        subprocess.run(["git", "-C", str(self.repo), *args], check=True, capture_output=True)

    def _add(self, name: str, content: bytes) -> None:
        (self.repo / name).write_bytes(content)
        self._add_path(name)

    def _add_path(self, name: str) -> None:
        self._git("add", name)

    def test_small_files_pass(self) -> None:
        self._add("icon.png", b"\x89PNG" + b"x" * 1000)
        self._add("notes.md", b"hello\n")
        self.assertEqual(problems(self.repo), [])

    def test_large_file_outside_lfs_fails(self) -> None:
        self._add("concept.png", b"x" * (LIMIT_BYTES + 1))
        found = problems(self.repo)
        self.assertEqual(len(found), 1)
        self.assertIn("concept.png", found[0])
        self.assertIn("over the 1 MiB limit", found[0])

    def test_file_exactly_at_limit_passes(self) -> None:
        self._add("sheet.png", b"x" * LIMIT_BYTES)
        self.assertEqual(problems(self.repo), [])

    def test_lfs_pattern_committed_as_pointer_passes(self) -> None:
        self._add("theme.wav", POINTER.encode())
        self.assertEqual(problems(self.repo), [])

    def test_lfs_pattern_committed_raw_fails(self) -> None:
        # A small raw .wav must fail too: size is not the point, the pattern is.
        self._add("click.wav", b"RIFF" + b"\0" * 200)
        found = problems(self.repo)
        self.assertEqual(len(found), 1)
        self.assertIn("committed without LFS", found[0])

    def test_large_raw_lfs_file_reported_once(self) -> None:
        self._add("theme.wav", b"RIFF" + b"\0" * (LIMIT_BYTES + 10))
        self.assertEqual(len(problems(self.repo)), 1)

    def test_paths_with_spaces(self) -> None:
        self._add("base theme take 1.wav", b"RIFF raw")
        found = problems(self.repo)
        self.assertEqual(len(found), 1)
        self.assertIn("base theme take 1.wav", found[0])


if __name__ == "__main__":
    unittest.main()
