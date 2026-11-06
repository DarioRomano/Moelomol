#!/usr/bin/env python3
"""Tests for pr_artifacts.py. Run: python3 -m unittest discover -s tools/ci"""

import unittest

from pr_artifacts import select


def artifact(artifact_id, branch, repo_id=1, expired=False):
    return {"id": artifact_id, "expired": expired,
            "workflow_run": {"head_branch": branch, "head_repository_id": repo_id}}


class SelectTest(unittest.TestCase):
    def test_only_this_branch_in_this_repository(self) -> None:
        artifacts = [artifact(1, "pause-menu"), artifact(2, "clear-spell"), artifact(3, "pause-menu"),
                     artifact(4, "pause-menu", repo_id=99), artifact(5, "main")]
        self.assertEqual(select(artifacts, "pause-menu", 1), [1, 3])

    def test_expired_artifacts_are_left_alone(self) -> None:
        self.assertEqual(select([artifact(1, "b", expired=True), artifact(2, "b")], "b", 1), [2])

    def test_artifacts_without_a_run_are_left_alone(self) -> None:
        self.assertEqual(select([{"id": 7, "workflow_run": None}, {"id": 8}], "b", 1), [])


if __name__ == "__main__":
    unittest.main()
