#!/usr/bin/env python3
"""Deletes the workflow artifacts (runnable builds, renders) of a pull request
once it is merged or closed (Q40, ADR-0009 amendment, 2026-11-06). The release
holds the lasting copy of every merged build, so a PR's builds only matter
while it is open.

Usage: pr_artifacts.py <owner/repo> <head branch> <head repository id>
Needs GH_TOKEN with actions: write. Prints ::error annotations on failure
(CLAUDE.md: Actions logs cannot be read from the engineer's environment).
"""

import json
import subprocess
import sys


def select(artifacts, head_branch, head_repo_id):
    """Ids of the artifacts made by runs of this PR's branch in this repository."""
    chosen = []
    for artifact in artifacts:
        run = artifact.get("workflow_run") or {}
        if run.get("head_branch") == head_branch and run.get("head_repository_id") == head_repo_id \
                and not artifact.get("expired", False):
            chosen.append(artifact["id"])
    return chosen


def _gh(*args):
    return subprocess.run(["gh", "api", *args], check=True, capture_output=True, text=True).stdout


def main(argv):
    if len(argv) != 4:
        print("::error::usage: pr_artifacts.py <owner/repo> <head branch> <head repository id>")
        return 2
    repo, branch, repo_id = argv[1], argv[2], int(argv[3])
    pages = _gh("--paginate", "--slurp", f"repos/{repo}/actions/artifacts?per_page=100")
    artifacts = [a for page in json.loads(pages) for a in page.get("artifacts", [])]
    ids = select(artifacts, branch, repo_id)
    failed = 0
    for artifact_id in ids:
        try:
            _gh("-X", "DELETE", f"repos/{repo}/actions/artifacts/{artifact_id}")
        except subprocess.CalledProcessError as e:
            failed += 1
            print(f"::error::could not delete artifact {artifact_id}: {e.stderr.strip()}")
    print(f"Deleted {len(ids) - failed} of {len(ids)} artifacts of branch {branch}.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
