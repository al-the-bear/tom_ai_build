#!/usr/bin/env python3
"""The merge back (SOM §11.10, ``spec_document_merge.py``): properties over
the strip corpus, the report lines of a conflict, text beyond ASCII and the
base read from git — what ``strip_merge_cases.json`` (run by
``conformance_runner.py``) does not reach. The port of Java's
``SpecDocumentMergeTest`` (itself the port of
``tom_som_typescript_runtime/tests/spec_document_merge_test.ts``, with the
non-ASCII cases of the C++ runtime's test, whose expectations were computed
with the TypeScript runtime: offsets and excerpts in UTF-16 code units).

The git checks build their own scratch repository in the system temp
directory, delete it afterwards and are skipped when no ``git`` can be run.

Plain-script style like the sibling tests: run with
``python3 tests/spec_document_merge_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    SpecStripMerge,
    SpecStripOptions,
    SpecStripValueRef,
    annotation_issues_text,
    merge_stripped_value,
    spec_strip_merge_label,
    strip_notation_text,
)

_CORPUS = os.path.normpath(
    os.path.join(_PKG_ROOT, "..", "tom_som_conformance", "corpus")
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}: {detail}" if detail else name)


def _options(case: dict) -> SpecStripOptions:
    return SpecStripOptions.from_names(
        drop=case.get("drop") or [],
        unmark=case.get("unmark") or [],
        appendix=case.get("appendix") or [],
        appendix_references=case.get("appendixReferences") is True,
        heading_divs=case.get("headingDivs") is True,
    )


def test_over_strip_cases() -> None:
    """Every value case of the strip corpus merges back unchanged, and with a
    paragraph added."""
    with open(os.path.join(_CORPUS, "strip_cases.json"), encoding="utf-8") as f:
        cases = json.load(f)["cases"]
    _check("strip cases read", len(cases) > 0)
    for case in cases:
        o = case["text"]
        opts = _options(case)
        s = strip_notation_text(o, opts)
        if s.refused:
            continue
        same = merge_stripped_value(o, s.text, s.text, s.pieces)
        _check(
            f"unchanged[{case['name']}]",
            same.text == o and same.restored == len(s.pieces) and not same.placed,
        )
        e = "An added paragraph." if s.text == "" else s.text + "\n\nAn added paragraph."
        r = merge_stripped_value(o, s.text, e, s.pieces)
        _check(
            f"addedParagraph[{case['name']}]",
            r.ok and strip_notation_text(r.text, opts).text == e,
            json.dumps(r.to_json(), ensure_ascii=False),
        )


def test_values() -> None:
    trace = SpecStripOptions.from_names(drop=["trace"])
    o = "Keep this. Gone here (-> C1). Tail."
    s = strip_notation_text(o, trace)
    r = merge_stripped_value(o, s.text, "Keep this. Tail.", s.pieces)
    _check("conflict.ok", not r.ok and r.text is None)
    _check(
        "conflict.code",
        len(r.conflicts) == 1 and r.conflicts[0].code == "sentenceRemoved",
    )
    if r.conflicts:
        lines = r.conflicts[0].about(SpecStripValueRef("DEMO/SUM")).report_lines
        want = [
            "CONFLICT DEMO/SUM — the edit removed the whole sentence holding the piece",
            "  O: «Keep this. Gone here (-> C1). Tail.»",
            "  B: «Keep this. Gone here. Tail.»",
            "  E: «Keep this. Tail.»",
            "  piece: « (-> C1)»",
        ]
        _check("conflict.reportLines", lines == want, repr(lines))

    o2 = "Alpha (-> A1). Beta [aside]{.aside} gamma (-> B2)."
    opts = SpecStripOptions.from_names(drop=["trace", "aside"])
    s2 = strip_notation_text(o2, opts)
    e2 = s2.text.replace("Alpha", "First")
    r2 = merge_stripped_value(o2, s2.text, e2, s2.pieces)
    _check(
        "several pieces",
        r2.text == "First (-> A1). Beta [aside]{.aside} gamma (-> B2)."
        and r2.restored == 3
        and strip_notation_text(r2.text, opts).text == e2,
        json.dumps(r2.to_json(), ensure_ascii=False),
    )


# A value beyond ASCII, one edit, and what the merge gives: (original, list,
# name, find, replace, text or None, restored, placed at or -1, placed
# removed, conflict code or None, the conflict's report lines).
_NON_ASCII = [
    (
        "Die Größe ist hoch (-> C2.1).",
        "drop", "trace", "hoch", "stark gestiegen \U0001F600",
        "Die Größe ist stark gestiegen \U0001F600 (-> C2.1).",
        1, 32, " (-> C2.1)", None, [],
    ),
    (
        "Ein \U0001F600 [schnelles braunes]{.aside} Tier läuft.",
        "unmark", "aside", "braunes Tier", "Wesen",
        None, 0, -1, None, "crossesBoundary",
        [
            "CONFLICT (document) — an edit crosses the boundary of an unmarked element",
            "  O: «Ein \U0001F600 [schnelles braunes]{.aside} Tier läuft.»",
            "  B: «Ein \U0001F600 schnelles braunes Tier läuft.»",
            "  E: «Ein \U0001F600 schnelles Wesen läuft.»",
            "  piece: «]{.aside}»",
        ],
    ),
    (
        "Ä Wort{>>Bemerkung über Öl<<} hier.",
        "drop", "comments", "Wort", "Begriff",
        "Ä Begriff{>>Bemerkung über Öl<<} hier.",
        2, -1, None, None, [],
    ),
    (
        "Größe [weil \U0001F600 so]{.aside} gilt.\n\nZweiter Absatz.",
        "drop", "aside", "gilt", "bleibt",
        "Größe [weil \U0001F600 so]{.aside} bleibt.\n\nZweiter Absatz.",
        1, -1, None, None, [],
    ),
    (
        "Ein äöüäöüäöüäöüäöüäöü langer Satz mit [schnelles braunes]{.aside} Tier "
        "und noch viel mehr Text danach äöü.",
        "unmark", "aside", "braunes Tier", "Wesen",
        None, 0, -1, None, "crossesBoundary",
        [
            "CONFLICT (document) — an edit crosses the boundary of an unmarked element",
            "  O: «er Satz mit [schnelles braunes]{.aside} Tier und noch viel m»",
            "  B: «ger Satz mit schnelles braunes Tier und noch viel mehr Text »",
            "  E: «äöü langer Satz mit schnelles Wesen und noch viel mehr Text »",
            "  piece: «]{.aside}»",
        ],
    ),
]


def test_non_ascii() -> None:
    for i, c in enumerate(_NON_ASCII):
        (original, lst, name, find, replace, text, restored, placed_at,
         placed_removed, conflict, lines) = c
        tag = f"nonAscii {i}: "
        o = (
            SpecStripOptions.from_names(drop=[name])
            if lst == "drop"
            else SpecStripOptions.from_names(unmark=[name])
        )
        st = strip_notation_text(original, o)
        at = st.text.find(find)
        _check(tag + "the edit applies", at >= 0)
        if at < 0:
            continue
        edited = st.text[:at] + replace + st.text[at + len(find):]
        m = merge_stripped_value(original, st.text, edited, st.pieces)
        _check(tag + "text", m.text == text, repr(m.text))
        _check(tag + "restored", m.restored == restored, str(m.restored))
        if placed_at < 0:
            _check(tag + "placed", not m.placed)
        else:
            _check(
                tag + "placed",
                len(m.placed) == 1
                and m.placed[0].at == placed_at
                and m.placed[0].piece.removed == placed_removed,
                "none" if not m.placed else str(m.placed[0].at),
            )
        if conflict is None:
            _check(tag + "conflicts", not m.conflicts)
        else:
            _check(
                tag + "conflicts",
                len(m.conflicts) == 1 and m.conflicts[0].code == conflict,
            )
            if len(m.conflicts) == 1:
                got = m.conflicts[0].report_lines
                _check(tag + "report lines", got == lines, repr(got))


def test_labels() -> None:
    _check("label", spec_strip_merge_label(SpecStripValueRef("A/B")) == "A/B")
    _check("label.field", spec_strip_merge_label(SpecStripValueRef("A/B", "f")) == "A/B / f")
    _check(
        "label.headline",
        spec_strip_merge_label(SpecStripValueRef("A/B", None, True)) == "A/B (headline)",
    )


def test_annotation_issues() -> None:
    _check("annotationIssues.clean", annotation_issues_text("A {++b++} c.") == [])
    _check(
        "annotationIssues.malformed",
        annotation_issues_text("x {++ open")
        == ['line 0: inline mark "{++" is not closed in its paragraph (SOM §11.9.3)'],
        repr(annotation_issues_text("x {++ open")),
    )


def _git(folder: str, *args: str) -> bool:
    """Runs git in *folder*; false when it fails or cannot be run."""
    try:
        done = subprocess.run(
            ["git", *args],
            cwd=folder,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except OSError:
        return False
    return done.returncode == 0


def test_git_show_file() -> None:
    """The base read from git, in a scratch repository of the test's own."""
    repo = tempfile.mkdtemp(prefix="tom_som_python_merge_test")
    try:
        doc = os.path.join(repo, "doc.md")
        inner = os.path.join(repo, "sub", "inner.md")
        os.makedirs(os.path.dirname(inner))
        with open(doc, "w", encoding="utf-8") as f:
            f.write("first ä\n")
        with open(inner, "w", encoding="utf-8") as f:
            f.write("inner\n")
        made = (
            _git(repo, "init", "-q")
            and _git(repo, "add", "doc.md", "sub/inner.md")
            and _git(
                repo,
                "-c", "user.name=test",
                "-c", "user.email=test@example.invalid",
                "-c", "commit.gpgsign=false",
                "-c", "core.hooksPath=/dev/null",
                "commit", "-q", "-m", "first",
            )
        )
        if not made:
            print("SKIP: git_show_file (no git, or the scratch repository could not be made)")
            return
        with open(doc, "w", encoding="utf-8") as f:
            f.write("second\n")
        got = SpecStripMerge.git_show_file("HEAD", doc)
        _check(
            "git_show_file: the committed text, not the working tree's",
            got == "first ä\n",
            repr(got),
        )
        _check(
            "git_show_file: a file in a folder is read from its folder",
            SpecStripMerge.git_show_file("HEAD", inner) == "inner\n",
        )
        _check(
            "git_show_file: an unknown commit gives none",
            SpecStripMerge.git_show_file("0" * 40, doc) is None,
        )
        _check(
            "git_show_file: an unknown file gives none",
            SpecStripMerge.git_show_file("HEAD", doc + "x") is None,
        )
        _check(
            "git_show_file: a missing folder gives none",
            SpecStripMerge.git_show_file("HEAD", os.path.join(repo, "none", "doc.md")) is None,
        )
        _check(
            "git_show_file: a commit that reads as an option gives none",
            SpecStripMerge.git_show_file("--stat", doc) is None,
        )
        _check(
            "git_show_file: no commit gives none",
            SpecStripMerge.git_show_file("", doc) is None
            and SpecStripMerge.git_show_file(None, doc) is None,
        )
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def main() -> int:
    test_over_strip_cases()
    test_values()
    test_non_ascii()
    test_labels()
    test_annotation_issues()
    test_git_show_file()
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
