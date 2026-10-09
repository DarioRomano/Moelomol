#!/usr/bin/env python3
"""Release notes from the pull requests merged since the previous release.

Reads JSON on stdin: {"commits": [sha, ...], "prs": [pull request, ...]}.
"commits" are the commits in this release; "prs" are recently merged pull
requests (fields used: number, title, body, merged_at, merge_commit_sha).
Prints Markdown: one section per PR whose merge commit is in this release,
oldest first, each with its Change notes (ADR-0009). Unmerged PRs and
duplicates are dropped. With no such PR it says so, naming the commit.

Matching on merge_commit_sha matters: GitHub links a commit only to the first
PR that brought it to main, so a PR merged as part of another (stacked) PR is
invisible to the per-commit lookup. Found with release v0.1.0-build.1.

    release_notes.py <commit_sha> < input.json

Standard library only.
"""

import json
import sys

from change_notes import extract


def render(prs: list[dict], commits: list[str], commit_sha: str) -> str:
    in_release = set(commits)
    merged: dict[int, dict] = {}
    for pr in prs:
        if (pr.get("merged_at") and pr.get("number") is not None
                and pr.get("merge_commit_sha") in in_release):
            merged[pr["number"]] = pr
    if not merged:
        return (f"## Commit {commit_sha[:7]}\n\n"
                "_No merged pull request is associated with this release; "
                "it was pushed to main directly._\n")
    sections = []
    for pr in sorted(merged.values(), key=lambda p: (p["merged_at"], p["number"])):
        notes = extract(pr.get("body") or "") or "_The pull request had no change notes._"
        sections.append(f"## {pr.get('title', '').strip()} (#{pr['number']})\n\n{notes}\n")
    return "\n".join(sections)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    data = json.load(sys.stdin)
    print(render(data["prs"], data["commits"], argv[1]), end="")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
