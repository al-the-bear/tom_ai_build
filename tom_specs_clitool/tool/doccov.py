#!/usr/bin/env python3
"""Public-API dartdoc coverage counter for the tsdoc documentation campaign.

    python3 tool/doccov.py <package-root>

Reports `documented/total = NN.N%` over every public declaration in the
package's `lib/`, then lists the undocumented ones by file and line.
`tom_specs_documentation_standard.md` §5 sets the bar (95% for libraries,
tools and SOM runtimes; 90% for `tom_specs_reviewer`; generated `tom_som_*_v0`
packages exempt) and defines what counts as documented.

**Interim.** This is a text scanner, not an analyzer pass, and tsdoc18 replaces
it with the real cross-package gate in the default `dart test` run. It exists
because the sweeps need a *denominator*: the `public_member_api_docs` lint
reports which declarations are undocumented but never how many there are, so it
can say a package is not finished and cannot say how far along it is.

**Cross-check it, do not trust it alone.** Enable `public_member_api_docs` in
the package's `analysis_options.yaml` and compare `dart analyze`'s misses
against the UNDOC list — they should agree declaration for declaration. On
`tom_specs_core` they agree on all 61. An earlier version of this script made
neither exclusion below and reported a plausible-looking figure that was wrong
in both directions, which is how the cross-check earned its place here.

Two exclusions, matching the lint and for the lint's reasons:

* `@override` members — dartdoc inherits the supertype's comment, so
  re-documenting an override duplicates a sentence that has one home;
* lines inside a multi-line annotation argument list — not declarations, but
  they parse like one to a line-based scanner.
"""
import os, re, sys

DECL = re.compile(
    r'^\s*(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
    r'(?:(?:class|enum|mixin|extension|typedef)\s+(\w+)'
    r'|(?:[\w<>,\s?\[\]$.]+\s+)?(\w+)\s*[({=;])'
)
KEYWORDS = {'return', 'if', 'for', 'while', 'switch', 'assert', 'import',
            'export', 'part', 'library', 'else', 'throw', 'yield', 'await',
            'super', 'this', 'do', 'try', 'catch', 'finally'}


def public_decls(path):
    lines = open(path).read().split('\n')
    out, depth = [], 0
    for i, ln in enumerate(lines):
        opened = depth
        depth += ln.count('(') - ln.count(')')
        s = ln.strip()
        if opened > 0 or not s or s.startswith(('//', '*', '}', '@')):
            continue
        indent = len(ln) - len(ln.lstrip())
        if indent not in (0, 2):
            continue
        m = DECL.match(ln)
        if m:
            name = m.group(1) or m.group(2)
        else:
            m2 = re.match(r'^  (\w+),\s*$', ln)   # bare enum constant
            if not m2:
                continue
            name = m2.group(1)
        if not name or name.startswith('_') or name in KEYWORDS:
            continue
        # Walk back over the annotation block to the doc comment.
        j, override = i - 1, False
        while j >= 0 and lines[j].strip().startswith(('@', ')', "'", '"')):
            if lines[j].strip().startswith('@override'):
                override = True
            j -= 1
        if override:
            continue
        out.append((name, j >= 0 and lines[j].strip().startswith('///'), i + 1))
    return out


root = sys.argv[1]
tot = doc = 0
undoc = []
for dirpath, _, files in os.walk(os.path.join(root, 'lib')):
    for f in sorted(files):
        if not f.endswith('.dart'):
            continue
        p = os.path.join(dirpath, f)
        for name, d, ln in public_decls(p):
            tot += 1
            if d:
                doc += 1
            else:
                undoc.append(f'{os.path.relpath(p, root)}:{ln} {name}')
print(f'{doc}/{tot} = {100.0 * doc / tot:.1f}%')
for u in undoc:
    print('  UNDOC', u)
