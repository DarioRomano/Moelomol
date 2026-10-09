#!/usr/bin/env python3
"""Repository check for Git LFS (ADR-0011).

Fails if, in what git has staged/committed (the index, not the working tree):
1. a file larger than the limit is not stored through Git LFS, or
2. a file whose path matches an LFS pattern in .gitattributes was committed
   as its raw content instead of an LFS pointer (someone committed it on a
   machine without `git lfs install`).

    check_large_files.py [repo_dir]

Reads blobs from the index, so it works with or without git-lfs installed and
with or without the LFS files downloaded. Standard library only.
"""

import subprocess
import sys
from pathlib import Path

LIMIT_BYTES = 1024 * 1024  # 1 MiB
POINTER_PREFIX = b"version https://git-lfs.github.com/spec/v1"
POINTER_MAX_BYTES = 1024  # real pointers are about 130 bytes


def _git(repo: Path, *args: str, stdin: bytes | None = None) -> bytes:
    return subprocess.run(["git", "-C", str(repo), *args], input=stdin,
                          check=True, capture_output=True).stdout


def problems(repo: Path) -> list[str]:
    """Human-readable problems, empty if the repository is fine."""
    entries = _git(repo, "ls-files", "-s", "-z").split(b"\0")
    blobs: list[tuple[str, str]] = []
    for entry in entries:
        if not entry:
            continue
        meta, path = entry.split(b"\t", 1)
        mode, sha, _stage = meta.split(b" ")
        if mode == b"160000":  # submodule
            continue
        blobs.append((path.decode(), sha.decode()))
    if not blobs:
        return []

    paths = "\0".join(p for p, _ in blobs).encode() + b"\0"
    attrs = _git(repo, "check-attr", "-z", "--stdin", "filter", stdin=paths).split(b"\0")
    lfs_paths = {attrs[i].decode() for i in range(0, len(attrs) - 2, 3)
                 if attrs[i + 2] == b"lfs"}

    sizes_out = _git(repo, "cat-file", "--batch-check=%(objectsize)",
                     stdin="".join(f"{sha}\n" for _, sha in blobs).encode()).split()
    found: list[str] = []
    for (path, sha), size_bytes in zip(blobs, sizes_out):
        size = int(size_bytes)
        is_pointer = False
        if size <= POINTER_MAX_BYTES:
            head = _git(repo, "cat-file", "blob", sha)[: len(POINTER_PREFIX)]
            is_pointer = head == POINTER_PREFIX
        if path in lfs_paths and not is_pointer:
            found.append(f"{path}: matches an LFS pattern but was committed without LFS "
                         f"({size} bytes); run `git lfs install`, then remove and re-add it")
        elif path not in lfs_paths and size > LIMIT_BYTES:
            found.append(f"{path}: {size / 1048576:.1f} MiB is over the 1 MiB limit for plain "
                         f"git; add its file type to the LFS patterns in .gitattributes")
    return found


def main(argv: list[str]) -> int:
    repo = Path(argv[1] if len(argv) > 1 else ".")
    found = problems(repo)
    for problem in found:
        print(f"::error title=Large file check::{problem}")
    if found:
        print(f"{len(found)} large-file problem(s); see ADR-0011.", file=sys.stderr)
        return 1
    print("Large file check: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
