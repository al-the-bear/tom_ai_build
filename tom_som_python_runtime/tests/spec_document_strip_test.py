#!/usr/bin/env python3
"""Stripped renditions (SOM §11.10, ``spec_document_strip.py``) beyond the
shared corpus. The strip of one value: UTF-16 offsets around supplementary
characters (the corpus has none), the option sets' derived forms, a refused
value and ``count_annotations_text``. The strip of a document, over a model
nine sections deep: styled-div headings written, escaped and read back, the
readable header, the appendix, a refused value, the report and
``SpecReviewAnnotations.stripped()`` (headlines included).

Each expected result of the strip of one value was produced by the JavaScript
runtime (the port of the TypeScript reference) for the same input; the
document checks are the port of Java's ``SpecDocumentStripTest``.

Plain-script style like the sibling tests: run with
``python3 tests/spec_document_strip_test.py``; exit code 0 == all green.
"""

from __future__ import annotations

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG_ROOT = os.path.dirname(_HERE)  # tom_som_python_runtime
sys.path.insert(0, _PKG_ROOT)

from tom_som_runtime import (  # noqa: E402
    DocSpecsDocument,
    SpecDocument,
    SpecDocumentMarkdown,
    SpecDocumentStrip,
    SpecModel,
    SpecReadableHeader,
    SpecReadableSource,
    SpecReviewAnnotations,
    SpecStripOptions,
    SpecStripUsageError,
    count_annotations_text,
    spec_strip_kind_names,
    spec_strip_notation_kinds,
    strip_notation_text,
)
from tom_som_runtime.spec_document_strip import (  # noqa: E402
    _DEL,
    _INS,
    _KEEP,
    _lines,
    _myers,
    _tokens,
)

_passed = 0
_failed: list[str] = []


def _check(name: str, condition: bool, detail: str = "") -> None:
    global _passed
    if condition:
        _passed += 1
    else:
        _failed.append(f"{name}: {detail}" if detail else name)


def _eq(name: str, got: object, want: object) -> None:
    _check(name, got == want, f"got {got!r}, want {want!r}")


def _strip(text: str, **names) -> dict:
    return strip_notation_text(text, SpecStripOptions.from_names(**names)).to_json()


def test_utf16_offsets() -> None:
    _eq(
        "astral before a dropped span",
        _strip("😀 [x]{.aside} end", drop=["aside"]),
        {
            "text": "😀 end",
            "dropped": {"aside": 1},
            "unmarked": {},
            "appended": {},
            "marksDropped": 0,
            "appendix": [],
            "pieces": [
                {
                    "anchor": 2,
                    "origin": 2,
                    "removed": " [x]{.aside}",
                    "inserted": "",
                    "labels": ["aside:drop"],
                }
            ],
            "refused": [],
        },
    )
    note1 = '<a id="note-1-ref"></a>[\\[1\\]](#note-1)'
    note2 = '<a id="note-2-ref"></a>[\\[2\\]](#note-2)'
    _eq(
        "astral with comments dropped and appendix references",
        _strip(
            "😀 a\n\n::: {.provenance}\n𝔸 p\n:::\n\n> ⬆️ **C-1** (al): 𝔹 note\n\n"
            "b {++𝔸++} c [t]{.trace}",
            drop=["comments"],
            appendix=["provenance", "trace"],
            appendix_references=True,
        ),
        {
            "text": f"😀 a\n\n{note1}\n\nb 𝔸 c{note2}",
            "dropped": {"comments": 2},
            "unmarked": {},
            "appended": {"provenance": 1, "trace": 1},
            "marksDropped": 0,
            "appendix": [
                {"number": 1, "kind": "provenance", "text": "𝔸 p"},
                {"number": 2, "kind": "trace", "text": "t"},
            ],
            "pieces": [
                {
                    "anchor": 6,
                    "origin": 6,
                    "removed": "::: {.provenance}\n𝔸 p\n:::",
                    "inserted": note1,
                    "labels": ["provenance:appendix"],
                },
                {
                    "anchor": 47,
                    "origin": 34,
                    "removed": "> ⬆️ **C-1** (al): 𝔹 note\n\n",
                    "inserted": "",
                    "labels": ["comments"],
                },
                {"anchor": 49, "origin": 64, "removed": "{++", "inserted": "",
                 "labels": ["comments"]},
                {"anchor": 51, "origin": 69, "removed": "++}", "inserted": "",
                 "labels": ["comments"]},
                {
                    "anchor": 53,
                    "origin": 74,
                    "removed": " [t]{.trace}",
                    "inserted": note2,
                    "labels": ["trace:appendix"],
                },
            ],
            "refused": [],
        },
    )
    _eq(
        "astral inside review marks",
        _strip("x {--😀 [y]{.aside}--} z {~~𝔸 [q]{.aside}~>new~~}", drop=["aside"]),
        {
            "text": "x {--😀--} z {~~𝔸~>new~~}",
            "dropped": {"aside": 2},
            "unmarked": {},
            "appended": {},
            "marksDropped": 0,
            "appendix": [],
            "pieces": [
                {"anchor": 7, "origin": 7, "removed": " [y]{.aside}", "inserted": "",
                 "labels": ["aside:drop"]},
                {"anchor": 18, "origin": 30, "removed": " [q]{.aside}", "inserted": "",
                 "labels": ["aside:drop"]},
            ],
            "refused": [],
        },
    )


def test_refused() -> None:
    r = strip_notation_text(
        "a\n::: {.aside}\nunclosed", SpecStripOptions.from_names(drop=["aside"])
    )
    _check("refused", r.refused)
    _eq("refused.text", r.text, "a\n::: {.aside}\nunclosed")
    _eq("refused.codes", r.to_json()["refused"], ["unclosedDiv"])
    _eq("refused.pieces", r.pieces, [])


def test_options() -> None:
    _eq("kind names", list(spec_strip_kind_names)[-1], "comments")
    _eq("notation kinds", len(spec_strip_notation_kinds), 4)
    o = SpecStripOptions.from_names(drop=["all"], appendix=["trace"], unmark=["aside"])
    _eq("all skips explicit names", SpecStripOptions.ordered(o.drop),
        ["provenance", "editorial", "linked", "derived", "comments"])
    _check("writes no linked markers", o.writes_no_linked_markers)
    _check("writes no generated parts", o.writes_no_generated_parts)
    k = o.keeping
    _eq("keeping.drop", sorted(k.drop), ["comments"])
    _eq("keeping.unmark", sorted(k.unmark),
        ["aside", "derived", "editorial", "linked", "provenance", "trace"])
    _eq("keeping.appendix", k.appendix, set())
    e = o.in_entry
    _check("in_entry keeps comments", "comments" not in e.drop)
    _eq("in_entry.unmark", sorted(e.unmark), ["aside", "trace"])
    _check("plain options write the markers", not SpecStripOptions().writes_no_linked_markers)
    try:
        SpecStripOptions.from_names(appendix=["linked"])
        _check("linked to the appendix raises", False)
    except SpecStripUsageError as err:
        _check("linked to the appendix raises", str(err).startswith("linked cannot"))


def test_count_annotations() -> None:
    _eq("count_annotations_text",
        count_annotations_text("> ⬆️ **C-1** (al): n\n\nx {++a++} {>>c<<}"), 3)
    _eq("count_annotations_text none", count_annotations_text("plain"), 0)


def test_internals() -> None:
    _eq("lines", _lines("a\nb\n\nc"), ["a\n", "b\n", "\n", "c"])
    _eq("tokens", _tokens("ab, c_d  é!"), ["ab", ",", " ", "c_d", "  ", "é", "!"])
    _eq(
        "myers",
        _myers(["a", "b", "c"], ["a", "x", "c"]),
        [(_KEEP, "a"), (_DEL, "b"), (_INS, "x"), (_KEEP, "c")],
    )
    _eq("myers empty", _myers([], []), [])


# ---------------------------------------------------------------------------
# The strip of a document: styled-div headings, the readable header and the
# document strip's checks, over a model nine sections deep (the port of
# Java's SpecDocumentStripTest / Dart's spec_document_strip_test.dart). The
# corpus documents are the conformance runner's ``documentCases``.


def _deep_model() -> SpecModel:
    """A model nine sections deep: ``L<n>`` holds content ``T<n>`` and section
    ``L<n+1>``, so ``T<n>`` stands at depth n + 1."""
    classes = {}
    for n in range(1, 10):
        cls = {"name": f"L{n}", "sectionId": f"L{n}"}
        if n == 1:
            cls["annotations"] = [
                {"name": "Document", "arguments": {"title": "Deep"}},
                {"name": "SectionId", "arguments": {"id": "L1"}},
            ]
        fields = [{"name": "text", "kind": "content", "sectionId": f"T{n}",
                   "contentType": "text"}]
        if n < 9:
            fields.append({"name": "next", "kind": "complex",
                           "sectionId": f"L{n + 1}", "type": f"L{n + 1}"})
        cls["fields"] = fields
        classes[f"L{n}"] = cls
    return SpecModel.from_json({
        "modelVersion": 1,
        "modelVersionLabel": "0.1.0+1",
        "roots": [{"type": "L1", "title": "Deep", "sectionId": "L1"}],
        "classes": classes,
    })


def _path_to(n: int, text: bool) -> str:
    """``L1/…/L<n>[/T<n>]``."""
    p = "/".join(f"L{k}" for k in range(1, n + 1))
    return f"{p}/T{n}" if text else p


def _deep_document() -> SpecDocument:
    d = SpecDocument()
    for n in range(1, 10):
        d.set_content(_path_to(n, True), f"Text {n} [an aside]{{.aside}}.")
    d.set_headline(_path_to(7, False), "Seven & <more>\nsecond line")
    d.set_content(
        _path_to(8, True),
        'Before.\n\n<div class="heading9" style="x">Not a heading</div>'
        '\n\n\\<div class="heading7" style="x">Escaped once</div>',
    )
    return d


def _has_line(md: str, line: str) -> bool:
    return line in md.split("\n")


def _check_reads_back(name: str, md: str, model: SpecModel, want: SpecDocument) -> None:
    back = SpecDocument.from_markdown(md, model)
    _check(f"{name}: no rejections", not back.rejections, repr(back.rejections))
    _check(f"{name}: reads back", back.document.to_json() == want.to_json(),
           repr(back.document.to_json()))


def test_heading_divs(model: SpecModel) -> None:
    root = model.root_by_type("L1")
    doc = _deep_document()
    r = SpecDocumentMarkdown(model, doc, heading_divs=True).export_root_with_map(root)
    _check("divs: no # heading deeper than 6",
           not any(line.startswith("#######") for line in r.markdown.split("\n")))
    _check(
        "divs: level 7 with the title escaped",
        _has_line(
            r.markdown,
            '<div class="heading7" style="margin:1em 0 0.5em;padding-left:'
            '0.75em;font-weight:bold"><!--[L7]--> <a id="L7"></a> '
            "Seven &amp; &lt;more&gt;<br>second line</div>",
        ),
        r.markdown,
    )
    _check("divs: level 10 indent",
           '<div class="heading10" style="margin:1em 0 0.5em;padding-left:3em;' in r.markdown)
    _check("divs: a div-shaped value line is escaped",
           _has_line(r.markdown, '\\<div class="heading9" style="x">Not a heading</div>'))
    _check("divs: an escaped one once more",
           _has_line(r.markdown, '\\\\<div class="heading7" style="x">Escaped once</div>'))
    headings = 0
    mapped = 0
    for i, line in enumerate(r.markdown.split("\n")):
        if (line.startswith("#") or line.startswith('<div class="heading')) and "<!--[" in line:
            headings += 1
            if (i + 1) in r.heading_paths:
                mapped += 1
    _check("divs: the heading map holds the div headings",
           headings > 9 and mapped == headings and mapped == len(r.heading_paths),
           f"{headings}/{mapped}")
    _check_reads_back("divs", r.markdown, model, doc)

    plain = SpecDocumentMarkdown(model, doc).export_root(root)
    _check("no divs: # headings",
           "####### <!--[L7]-->" in plain and '\n<div class="heading7"' not in plain)
    _check("no divs: the value line is still escaped",
           _has_line(plain, '\\<div class="heading9" style="x">Not a heading</div>'))
    _check_reads_back("no divs", plain, model, doc)

    for d, want in zip(range(7, 13), ["0.75", "1.5", "2.25", "3", "3.75", "4.5"]):
        _eq(f"divs: indent {d}", SpecDocumentMarkdown.heading_div_indent(d), want)
    _eq("divs: a heading6 div is content",
        SpecDocumentMarkdown.heading_div('<div class="heading6">x</div>'), None)
    _eq("divs: a heading7 div is a heading",
        SpecDocumentMarkdown.heading_div('<div class="heading7">a &amp;lt;</div>'), (7, "a &lt;"))


def _has_notes(sections) -> bool:
    return any(s.title == "Notes" or _has_notes(s.children) for s in sections)


def test_readable(model: SpecModel) -> None:
    source = SpecReadableSource("deep.tomspecs.yaml", "r3", "8e1d2a7", True)
    o = SpecStripOptions.from_names(drop=["aside"], heading_divs=True)
    doc = _deep_document()
    r = SpecDocumentStrip.strip(doc, o, model=model, source=source)
    _check("readable: no findings", r.ok, repr(r.findings))
    _eq("readable: the header", r.readable_header,
        "<!-- readable: drop=aside; headings=divs; "
        "of=deep.tomspecs.yaml@r3; commit=8e1d2a7+dirty -->")
    readable = r.readable or ""
    lines = readable.split("\n")
    _check("readable: the header follows the docspec line",
           len(lines) > 1 and lines[0].startswith("<!-- docspec: ")
           and lines[1] == r.readable_header, readable)
    _check("readable: divs and no aside",
           '<div class="heading8"' in readable and "{.aside}" not in readable)
    parsed = SpecDocumentMarkdown(model, SpecDocument()).parse(readable)
    _eq("readable: the parse reads the header", parsed.readable_header, r.readable_header)
    h = SpecReadableHeader.parse(parsed.readable_header or "")
    _check("readable: the header parses", h is not None)
    if h is not None:
        _eq("readable: format and parse are inverse", h.format(), r.readable_header)
        _check("readable: the header's switches and source",
               h.options.drop == {"aside"} and h.options.heading_divs
               and h.source is not None and h.source.dirty)
    _check_reads_back("readable", readable, model, r.document)

    # The appendix lists the moved prose under its section titles.
    a = SpecStripOptions.from_names(appendix=["aside"], appendix_references=True,
                                    heading_divs=True)
    r = SpecDocumentStrip.strip(doc, a, model=model)
    _check("appendix: no findings", r.ok, repr(r.findings))
    _eq("appendix: eight entries", len(r.appendix), 8)
    for i, e in enumerate(r.appendix):
        n = i + 1 + (1 if i >= 7 else 0)  # T8 holds no aside
        p = _path_to(n, True)
        _check("appendix: numbered in order, one value each",
               e.number == i + 1 and e.value is not None and e.value.path == p, p)
    text = r.readable or ""
    marker = SpecDocumentMarkdown.appendix_marker + "\n"
    at = text.find(marker)
    _check("appendix: after the marker", at >= 0)
    if at >= 0:
        notes = text[at + len(marker):]
        _check("appendix: the Notes heading", notes.startswith("\n## Notes\n"), notes)
        _eq("appendix: a section each", notes.count("### Text\n"), 8)
        _check("appendix: the entry with its back link",
               '<a id="note-1"></a>**[1]** an aside [↩](#note-1-ref)' in notes, notes)
    _eq("appendix: the reference in the value", r.document.content(_path_to(1, True)),
        'Text 1<a id="note-1-ref"></a>[\\[1\\]](#note-1).')
    _check("appendix: the validator does not read it",
           not _has_notes(DocSpecsDocument.parse(text).sections))

    # A value with a notation error is refused and reported.
    doc.set_content(_path_to(2, True), "::: {.aside}\nopen")
    r = SpecDocumentStrip.strip(doc, o, model=model)
    _check("refused: not ok", not r.ok)
    _check("refused: one notation finding",
           len(r.findings) == 1 and r.findings[0].kind == "notation"
           and r.findings[0].ref is not None, repr(r.findings))
    _eq("refused: the value is kept", r.document.content(_path_to(2, True)),
        "::: {.aside}\nopen")

    # Without a model nothing is rendered or checked.
    every = SpecStripOptions.from_names(drop=["all"])
    r = SpecDocumentStrip.strip(_deep_document(), every)
    _eq("no model: no rendition", r.readable, None)
    _eq("no model: stripped", r.document.content(_path_to(1, True)), "Text 1.")
    _eq("no model: the report", r.report, ["aside: 8 dropped, 0 unmarked, 0 moved"])


def test_stripped() -> None:
    doc = SpecDocument()
    doc.set_content("L1/T1", "Keep {++this++}.\n\n> ⬆️ **C-1** (Al): ok")
    doc.set_headline("L1/L2", "Two {--old--}")
    s = SpecReviewAnnotations(doc).stripped()
    _eq("stripped(): content", s.content("L1/T1"), "Keep this.")
    _eq("stripped(): headlines too", s.headline("L1/L2"), "Two")
    _eq("stripped(): the document is unchanged", doc.headline("L1/L2"), "Two {--old--}")


def main() -> int:
    test_utf16_offsets()
    test_refused()
    test_options()
    test_count_annotations()
    test_internals()
    model = _deep_model()
    test_heading_divs(model)
    test_readable(model)
    test_stripped()
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
