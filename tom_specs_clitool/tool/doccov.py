#!/usr/bin/env python3
"""Public-API dartdoc coverage counter for the tsdoc documentation campaign.

    python3 tool/doccov.py <package-root>

Reports `documented/total = NN.N%` over the public declarations in a package's
`lib/`, then lists the undocumented ones by file and line.

WHAT THIS COUNTS, AND WHAT THE BAR IS
-------------------------------------
These are two different sets, and conflating them is the mistake this section
exists to prevent.

`tom_specs_documentation_standard.md` §5 defines the bar over **exported**
declarations: "every exported declaration and every public member of one". The
`public_member_api_docs` analyzer lint implements exactly that — it stays quiet
about a `lib/src/` library that no public barrel re-exports. **The lint is the
authority for whether a package has met its bar.**

This script counts every public declaration in `lib/`, exported or not. That is
a **superset**, and deliberately: a package can meet its bar while an
undocumented 3,500-line internal module sits behind it, and the sweeps want to
see that module. Read this number as a maintainability figure, never as the
bar. The two sets can differ by a lot — on `tom_specs_clitool` the lint sees
373 undocumented declarations and this script sees ~1,000, because 70 of its
130 `lib/src/` files are not exported.

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
* the contents of a multi-line string literal — the bundled BSD licence text in
  `packaging.dart` is 25 lines that otherwise parse as declarations.
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
            'final', 'var', 'late', 'rethrow'}

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


def public_decls(path):
    """Yield (name, documented, line_number) for each public declaration."""
    lines = open(path).read().split('\n')
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
                ('//', '*', '}', '@')):
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

        if declaration and not declaration.startswith('_') \
                and declaration not in KEYWORDS:
            j, override = i - 1, False
            while j >= 0 and lines[j].strip().startswith(('@', ')', "'", '"')):
                if lines[j].strip().startswith('@override'):
                    override = True
                j -= 1
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
