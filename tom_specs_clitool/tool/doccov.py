#!/usr/bin/env python3
"""Public-API dartdoc coverage counter for the tsdoc documentation campaign.

    python3 tool/doccov.py <package-root>

Reports `documented/total = NN.N%` over the public declarations in a package's
`lib/`, then lists the undocumented ones by file and line.

WHAT THIS COUNTS, AND WHAT THE BAR IS
-------------------------------------
These are two different sets, and conflating them is the mistake this section
exists to prevent.

**Superseded.** The gate this script prototyped now exists as
`lib/src/doc_coverage.dart` + `bin/check_doc_coverage.dart`, driven by
`tool/doc_coverage_manifest.yaml` and run in the default `dart test`. That one
parses with the analyzer instead of matching text, so it is the authority; this
script survives as a quick per-package reading, nothing more.

Both count every public declaration under `lib/`, which is also what
`public_member_api_docs` checks — verified directly: the lint reports a public
member of a `lib/src/` library that no barrel re-exports. (An earlier version
of this docstring said the lint measured only the *exported* surface. That was
wrong, and wrong for an instructive reason: it was inferred from a count
difference that was this script's own defect, not the lint's narrowness.)

USE BOTH, ALWAYS
----------------
Enable `public_member_api_docs` in the package's `analysis_options.yaml` and
compare `dart analyze` against the UNDOC list below. Neither tool is sufficient
alone:

* the lint gives no denominator, so it can say a package is unfinished and not
  how far along it is;
* this scanner is a text scanner with no semantic model, so it can misread
  code — and has. On `tom_specs_core` (a declarations-only package) the two
  agreed on all 61 misses; on `tom_specs_clitool` an earlier version of this
  script reported roughly three times the real figure, because it counted local
  variables inside function bodies as public declarations. Scope tracking below
  fixes that specific fault, but the general lesson stands: a disagreement with
  the lint means read the code, not adjust the number.

Two blind spots were found by exactly that comparison and are now handled: the
constants of an `enum Kind { a, b, c }` written on one line, and named
constructors (`const Foo.empty()`). Both were invisible to the regex and both
are declarations the lint checks.

Three exclusions, two of them matching the lint and for the lint's reasons:

* `@override` members — dartdoc inherits the supertype's comment, so
  re-documenting an override duplicates a sentence that has one home;
* lines inside a multi-line annotation argument list — not declarations, but
  they parse like one to a line-based scanner;
* anything inside a function or method body — a local is not an API. This is
  the exclusion the first version lacked;
* the members of a private type — `class _Block`'s fields are not public API,
  and the lint does not report them either;
* the setter half of a getter/setter pair, and a top-level `main` — `dart doc`
  renders a pair as one read/write property carrying the getter's comment, and
  an entry point is not API;
* the contents of a multi-line string literal — the bundled BSD licence text in
  `packaging.dart` is 25 lines that otherwise parse as declarations.

Finding a declaration is only half the job; the other half is finding its doc
comment, which means walking back over its annotations. That walk is by bracket
depth, not by line prefix — see `_skip_annotations`.
"""
import os
import re
import sys

DECL = re.compile(
    r'^\s*(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
    r'(?:(?:class|enum|mixin|extension|typedef)\s+(\w+)'
    r'|(?:[\w<>,\s?\[\]$.]+[\s.])?(\w+)\s*[({=;])'
)
# `enum Kind { a, b, c }` — a whole enum on one line. Its constants are
# declarations the lint checks individually, and none of them can carry a `///`
# without the enum first being expanded across lines.
INLINE_ENUM = re.compile(r'^\s*enum\s+\w+[^{]*\{([^}]*)\}')
TYPE_BODY = re.compile(
    r'^\s*(?:(?:abstract|base|final|interface|sealed)\s+)*'
    r'(?:class|enum|mixin|extension)\b')
KEYWORDS = {'return', 'if', 'for', 'while', 'switch', 'assert', 'import',
            'export', 'part', 'library', 'else', 'throw', 'yield', 'await',
            'super', 'this', 'do', 'try', 'catch', 'finally', 'new', 'const',
            'final', 'var', 'late', 'rethrow',
            # A function-typed field — `Object? Function() _getNode;` — parses
            # with the TYPE's `Function` as the declaration name, which then
            # hides the real (often private) name. No declaration is ever
            # called `Function`, so excluding it is safe and exact.
            'Function'}

# String literals and trailing line comments carry braces that are not scope.
_STRINGS = re.compile(r'"""(?:.|\n)*?"""|\'\'\'(?:.|\n)*?\'\'\'|'
                      r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')


def _multiline_opener(line):
    """The `\'\'\'`/`\"\"\"` delimiter this line leaves open, or None.

    A line that both opens and closes one is not open, so only an odd count
    counts.
    """
    for delim in ("\'\'\'", '"""'):
        if line.count(delim) % 2 == 1:
            return delim
    return None


def _strip(line):
    line = _STRINGS.sub('""', line)
    return line.split('//')[0]


def _skip_annotations(lines, start):
    """Walk back over a declaration's annotation block to the line before it.

    Returns `(index, saw_override)`.

    A line-prefix test is not enough. A `tom_specs_model` section class carries
    annotation blocks tens of lines long — a `@ContentHelp(\'\'\'…\'\'\')` holding
    markdown, a `@StandardReferences([...])` list, a `@NoArtifact(..., note: …)`
    — whose interior lines start with prose, `note:`, `[`, `],` and anything
    else. Stopping at the first such line reports a documented class as
    undocumented, which it did for 1,249 of them.

    So the walk is by BRACKET DEPTH, closing to opening: from the line above the
    declaration, consume any line that is inside an unbalanced `(`/`[` run, then
    the `@Name` line that opened it, and repeat.
    """
    j, override, depth = start, False, 0
    while j >= 0:
        stripped = lines[j].strip()
        if depth == 0:
            # A doc comment ENDS the walk — it is what the walk is looking for.
            # Tested before the closer heuristic below, because a doc comment
            # line often ends in `)` ("… supplies the default).") and would
            # otherwise be consumed as an annotation's closing line.
            if stripped.startswith('///'):
                break
            # A declaration whose RETURN TYPE wrapped onto the line above it —
            # `static List<({String source, ...})>` then `bridgeReExports() {`.
            # The doc comment sits above the type, so the walk has to cross it.
            # Narrow on purpose: only an unterminated generic type qualifies.
            if stripped.endswith('>'):
                j -= 1
                continue
            # An ORDINARY `//` note may sit between the doc comment and the
            # declaration, or between two annotations. It is not the doc
            # comment and it does not end the block, so consume it — stopping
            # here reports a documented declaration as undocumented, which it
            # did for three classes in `tom_specs_model`.
            if stripped.startswith('//'):
                j -= 1
                continue
            if not stripped.startswith('@'):
                # Not an annotation line. It may still be the CLOSING line of a
                # multi-line annotation, which we detect by its unbalanced
                # closers; anything else ends the walk.
                closing = (stripped.count(')') + stripped.count(']')
                           - stripped.count('(') - stripped.count('['))
                if closing <= 0:
                    break
                depth += closing
                j -= 1
                continue
            if stripped.startswith('@override'):
                override = True
            j -= 1
            continue
        # Inside a multi-line annotation: consume until the openers balance.
        depth += (stripped.count(')') + stripped.count(']')
                  - stripped.count('(') - stripped.count('['))
        if depth <= 0:
            depth = 0
            if stripped.startswith('@override'):
                override = True
        j -= 1
    return j, override


def public_decls(path):
    """Yield (name, documented, line_number) for each public declaration."""
    lines = open(path).read().split('\n')
    # A getter/setter PAIR is ONE member. `dart doc` renders it as a single
    # read/write property carrying the getter's comment, and
    # `public_member_api_docs` agrees — so counting the setter separately
    # invents a member nobody can document. (A write-only setter has no getter
    # to inherit from and is counted.)
    getters = set(re.findall(r'\bget\s+(\w+)', open(path).read()))
    out = []
    # Stack of booleans: is each currently open block a *type* body? A
    # declaration counts only when every enclosing block is one.
    stack = []
    paren = 0
    in_block_comment = False
    multiline_delim = None
    for i, raw in enumerate(lines):
        # A multi-line string ('''…''' / """…""") is data, not code. The
        # bundled BSD licence text is 25 lines that parse as declarations
        # otherwise — `Copyright (c) …` reads exactly like a call.
        if multiline_delim is not None:
            if multiline_delim in raw:
                multiline_delim = None
            continue
        opener = _multiline_opener(raw)
        if opener is not None:
            multiline_delim = opener
            continue
        line = _strip(raw)
        if in_block_comment:
            if '*/' in line:
                in_block_comment = False
                line = line.split('*/', 1)[1]
            else:
                continue
        while '/*' in line:
            head, _, rest = line.partition('/*')
            if '*/' in rest:
                line = head + rest.split('*/', 1)[1]
            else:
                line, in_block_comment = head, True
                break

        opened_paren, in_type_scope = paren, all(stack)
        paren += line.count('(') - line.count(')')
        s = raw.strip()

        declaration = None
        inline_enum = INLINE_ENUM.match(raw) if in_type_scope else None
        if inline_enum:
            for constant in inline_enum.group(1).split(','):
                constant = constant.strip()
                if constant and not constant.startswith('_'):
                    out.append((constant, False, i + 1))
        if opened_paren == 0 and in_type_scope and s and not s.startswith(
                ('//', '*', '}', '@', '..')):
            depth = len(stack)
            indent = len(raw) - len(raw.lstrip())
            if depth in (0, 1) and indent in (0, 2):
                m = DECL.match(raw)
                if m:
                    declaration = m.group(1) or m.group(2)
                elif depth == 1:
                    m2 = re.match(r'^  (\w+),\s*$', raw)  # bare enum constant
                    if m2:
                        declaration = m2.group(1)

        if declaration and re.match(r'^\s*set\s+' + re.escape(declaration or '')
                                    + r'\b', raw) and declaration in getters:
            declaration = None  # the getter of the pair carries the comment
        if declaration == 'main' and not stack:
            declaration = None  # an entry point is not API; the lint agrees
        if declaration and not declaration.startswith('_') \
                and declaration not in KEYWORDS:
            j, override = _skip_annotations(lines, i - 1)
            if not override:
                documented = j >= 0 and lines[j].strip().startswith('///')
                out.append((declaration, documented, i + 1))

        for ch in line:
            if ch == '{':
                # A block counts as a type body only when it opens a *public*
                # type: the members of `class _Block` are not public API, and
                # the lint does not report them either.
                type_match = TYPE_BODY.match(raw)
                is_public_type = bool(type_match) and paren == 0 and not re.search(
                    r'\b(?:class|enum|mixin|extension)\s+_', raw)
                stack.append(is_public_type)
            elif ch == '}' and stack:
                stack.pop()
    return out


def main(root):
    total = documented = 0
    undocumented = []
    for dirpath, _, files in os.walk(os.path.join(root, 'lib')):
        for name in sorted(files):
            if not name.endswith('.dart'):
                continue
            path = os.path.join(dirpath, name)
            for decl, is_doc, line in public_decls(path):
                total += 1
                if is_doc:
                    documented += 1
                else:
                    undocumented.append(
                        f'{os.path.relpath(path, root)}:{line} {decl}')
    if total == 0:
        print('no public declarations found')
        return
    print(f'{documented}/{total} = {100.0 * documented / total:.1f}%')
    for entry in undocumented:
        print('  UNDOC', entry)


if __name__ == '__main__':
    main(sys.argv[1])
