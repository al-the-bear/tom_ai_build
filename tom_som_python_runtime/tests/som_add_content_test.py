#!/usr/bin/env python3
"""Behavioural test for the § item 9 content-only list conveniences
(:meth:`SomList.add_content` and the :attr:`SomList.contents` view).

Exercises the runtime base directly (no golden facade needed) against a
content-only element facade — a list whose element carries a single ``content``
leaf at ``<item>/content`` — mirroring the runtime's own fixture style. Proves:

  * ``add_content`` appends the item and sets its nested ``content`` leaf,
    visible both through the returned handle and the generic document;
  * ``add_content`` honours the section-id pattern like ``add``;
  * ``add_content`` accepts a section-id override;
  * ``contents`` yields every item's content in order;
  * ``contents`` coalesces a missing content leaf to ``''``.

Run with ``python3 tests/som_add_content_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import datetime as _dt
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SomList,
    SomNode,
    SpecDocument,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}{(': ' + detail) if detail else ''}")


class _Note(SomNode):
    """A content-only element facade: a single ``content`` leaf at
    ``<path>/content`` (the shape ``add_content``/``contents`` target)."""

    @property
    def content(self) -> str:
        return self.doc.content(f"{self.path}/content") or ""

    @content.setter
    def content(self, v: str) -> None:
        self.doc.set_content(f"{self.path}/content", v)


def _notes(doc: SpecDocument, pattern=None) -> SomList[_Note]:
    return SomList(doc, "PD00/notes", lambda d, p: _Note(d, p), pattern=pattern)


def test_add_content_sets_leaf() -> None:
    """(a) add_content appends the item and sets its nested content leaf,
    visible through the returned handle and the generic document."""
    doc = SpecDocument()
    notes = _notes(doc)
    note = notes.add_content("hello world")
    _check("add_content.len", notes.length == 1, str(notes.length))
    # Visible through the returned handle.
    _check("add_content.handle", note.content == "hello world", note.content)
    # Visible through the generic document at the nested content leaf.
    item_path = doc.list_items("PD00/notes")[0]
    _check(
        "add_content.generic",
        doc.content(f"{item_path}/content") == "hello world",
        str(doc.content(f"{item_path}/content")),
    )
    # NOT written to the item path itself (nested-leaf semantics).
    _check(
        "add_content.not-item-path",
        doc.content(item_path) is None,
        str(doc.content(item_path)),
    )


def test_add_content_honours_pattern() -> None:
    """(b) add_content honours the section-id pattern like add."""
    date = _dt.date(2026, 1, 2)  # month 1 → A, day 2 → B ⇒ "AB"
    doc = SpecDocument()
    notes = _notes(doc, pattern="NOTE-ITEM-xxx")
    note = notes.add_content("first", date=date)
    _check(
        "add_content.pattern",
        note.spec_section_id == "NOTE-ITEM-AB1",
        str(note.spec_section_id),
    )
    _check("add_content.pattern.content", note.content == "first", note.content)


def test_add_content_override() -> None:
    """(c) add_content accepts a section-id override."""
    doc = SpecDocument()
    notes = _notes(doc, pattern="NOTE-ITEM-xxx")
    note = notes.add_content("body", section_id="NOTE-ITEM-CUSTOM")
    _check(
        "add_content.override",
        notes.section_ids == ["NOTE-ITEM-CUSTOM"],
        str(notes.section_ids),
    )
    _check("add_content.override.content", note.content == "body", note.content)


def test_contents_in_order() -> None:
    """(d) contents yields every item's content in order."""
    doc = SpecDocument()
    notes = _notes(doc)
    notes.add_content("one")
    notes.add_content("two")
    notes.add_content("three")
    _check(
        "contents.order",
        list(notes.contents) == ["one", "two", "three"],
        str(list(notes.contents)),
    )


def test_contents_coalesces_missing() -> None:
    """(e) contents coalesces a missing content leaf to ''."""
    doc = SpecDocument()
    notes = _notes(doc)
    notes.add_content("filled")
    notes.add()  # no content leaf written
    notes.add_content("also filled")
    _check(
        "contents.coalesce",
        list(notes.contents) == ["filled", "", "also filled"],
        str(list(notes.contents)),
    )


def main() -> int:
    test_add_content_sets_leaf()
    test_add_content_honours_pattern()
    test_add_content_override()
    test_contents_in_order()
    test_contents_coalesces_missing()

    total = _passed + len(_failed)
    if _failed:
        print(f"FAIL: {len(_failed)}/{total} checks failed")
        for f in _failed:
            print(f"  - {f}")
        return 1
    print(f"OK: {total} checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
