#!/usr/bin/env python3
"""Tests for release_notes.py. Run: python3 -m unittest discover -s tools/ci"""

import unittest

from release_notes import render


def pr(number: int, merged_at: str | None, notes: str = "- A change.", title: str = "",
       merge_sha: str = "") -> dict:
    return {
        "number": number,
        "title": title or f"PR {number}",
        "merged_at": merged_at,
        "merge_commit_sha": merge_sha or f"sha{number}",
        "body": f"## Summary\nx\n\n## Change notes\n{notes}\n\n## Checklist\n- [x] y\n",
    }


class RenderTest(unittest.TestCase):
    def test_every_merged_pr_is_listed_oldest_first(self) -> None:
        # Found with release v0.1.0-build.1: PR #3 carried PR #1 inside it and
        # only #3's notes were published.
        out = render([pr(3, "2026-10-09T20:29:54Z"), pr(1, "2026-10-09T20:29:55Z")],
                     ["sha1", "sha3"], "0c10df6abc")
        self.assertIn("(#1)", out)
        self.assertIn("(#3)", out)
        self.assertLess(out.index("(#3)"), out.index("(#1)"))

    def test_order_follows_merge_time_not_number(self) -> None:
        # With the case above, this covers both directions: a sort by PR
        # number (either way) fails one of the two.
        out = render([pr(11, "2026-10-10T00:02:00Z"), pr(10, "2026-10-10T00:01:00Z")],
                     ["sha10", "sha11"], "abc")
        self.assertLess(out.index("(#10)"), out.index("(#11)"))

    def test_duplicates_appear_once(self) -> None:
        out = render([pr(5, "2026-10-10T00:00:00Z"), pr(5, "2026-10-10T00:00:00Z")], ["sha5"], "abc")
        self.assertEqual(out.count("(#5)"), 1)

    def test_unmerged_prs_are_dropped(self) -> None:
        out = render([pr(2, None), pr(4, "2026-10-10T00:00:00Z")], ["sha2", "sha4"], "abc")
        self.assertNotIn("(#2)", out)
        self.assertIn("(#4)", out)

    def test_change_notes_are_used(self) -> None:
        out = render([pr(6, "2026-10-10T00:00:00Z", notes="- Started fullscreen.")], ["sha6"], "abc")
        self.assertIn("- Started fullscreen.", out)
        self.assertNotIn("Checklist", out)

    def test_missing_notes_are_said_plainly(self) -> None:
        out = render([pr(7, "2026-10-10T00:00:00Z", notes="<!-- nothing -->")], ["sha7"], "abc")
        self.assertIn("no change notes", out)

    def test_prs_merged_outside_this_release_are_dropped(self) -> None:
        # A PR merged after this commit (its merge commit is not in the range)
        # belongs to the next release.
        out = render([pr(8, "2026-10-10T00:00:00Z"), pr(9, "2026-10-10T00:01:00Z")], ["sha8"], "abc")
        self.assertIn("(#8)", out)
        self.assertNotIn("(#9)", out)

    def test_no_prs_names_the_commit(self) -> None:
        out = render([], ["4ae4f197196253d8"], "4ae4f197196253d8")
        self.assertIn("4ae4f19", out)
        self.assertIn("pushed to main directly", out)


if __name__ == "__main__":
    unittest.main()
