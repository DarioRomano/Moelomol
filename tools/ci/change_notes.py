#!/usr/bin/env python3
"""Pull-request change notes (ADR-0009).

Every pull request description has a "## Change notes" section (see
.github/pull_request_template.md). CI fails a PR whose section is missing or
empty, and the release workflow publishes the section as the release notes.

    change_notes.py check    < pr_body.md   # exit 1 if missing or empty
    change_notes.py extract  < pr_body.md   # print the notes

Standard library only.
"""

import re
import sys

HEADING = re.compile(r"^##\s+Change notes\s*$", re.IGNORECASE | re.MULTILINE)
# The section ends at the next level-2 heading or at a horizontal rule
# (tools append footers after "---", which must not count as notes).
NEXT_HEADING = re.compile(r"^(##\s|(-{3,}|\*{3,}|_{3,})\s*$)", re.MULTILINE)
COMMENT = re.compile(r"<!--.*?-->", re.DOTALL)


def extract(body: str) -> str:
    """Return the text of the Change notes section, without HTML comments."""
    body = body.replace("\r\n", "\n")
    match = HEADING.search(body)
    if match is None:
        return ""
    rest = body[match.end():]
    end = NEXT_HEADING.search(rest)
    section = rest[: end.start()] if end else rest
    section = COMMENT.sub("", section)
    return section.strip()


def main(argv: list[str]) -> int:
    if len(argv) != 2 or argv[1] not in ("check", "extract"):
        print(__doc__, file=sys.stderr)
        return 2
    notes = extract(sys.stdin.read())
    if argv[1] == "extract":
        print(notes)
        return 0
    if not notes:
        print("::error title=Change notes::The PR description needs a filled-in "
              "'## Change notes' section (see .github/pull_request_template.md).")
        return 1
    print("Change notes found:\n" + notes)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
