#!/usr/bin/env python3
"""Tests for change_notes.py. Run: python3 -m unittest discover -s tools/ci"""

import unittest

from change_notes import extract

TEMPLATE = """## Summary
Adds a thing.

## Change notes
<!-- What changed, for players and the lead. One bullet per change. -->

## Checks
- [ ] tests
"""


class ExtractTest(unittest.TestCase):
    def test_filled_section_is_returned(self) -> None:
        body = TEMPLATE.replace("## Checks", "- Added the test card.\n\n## Checks")
        self.assertEqual(extract(body), "- Added the test card.")

    def test_untouched_template_is_empty(self) -> None:
        self.assertEqual(extract(TEMPLATE), "")

    def test_missing_section_is_empty(self) -> None:
        self.assertEqual(extract("## Summary\nNothing else."), "")

    def test_section_at_end_of_body(self) -> None:
        self.assertEqual(extract("## Change notes\n- Last thing.\n"), "- Last thing.")

    def test_windows_line_endings(self) -> None:
        self.assertEqual(extract("## Change notes\r\n- CRLF note.\r\n## Next\r\n"), "- CRLF note.")

    def test_heading_case_does_not_matter(self) -> None:
        self.assertEqual(extract("## change notes\n- lower.\n"), "- lower.")

    def test_subheadings_stay_inside_section(self) -> None:
        body = "## Change notes\n### Added\n- One.\n## Checks\n"
        self.assertEqual(extract(body), "### Added\n- One.")


if __name__ == "__main__":
    unittest.main()
