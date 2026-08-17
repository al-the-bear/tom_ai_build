import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Covers the decision procedure behind `index.md`'s citation convention
/// (`lib/src/section_citations.dart`).
///
/// The convention's load-bearing clause is the self-reference carve-out: a bare
/// `§N` means *this* document. The tests below fix that clause and the five ways
/// a document name may override it, because each of the five was added against a
/// real site in the doc set and each widens what the checker accepts — a widening
/// nobody notices going wrong is a widening that eventually excuses a real
/// defect. Three of them (the run, the table row and the table column) are
/// therefore tested as much for where they **stop** as for where they fire.
///
/// Fixtures are hand-written, not drawn from the live corpus, so they keep
/// testing the same thing after the documents move on. One test does read the
/// real doc folder, and asserts only what must stay true of it regardless of how
/// many citations it grows.
void main() {
  final clitoolRoot = Directory.current.path;
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  final docDir = p.normalize(p.join(clitoolRoot, '..', 'tom_specs_model', 'doc'));

  /// A corpus of documents named `<name>` declaring `<ids>` as headings.
  SectionCorpus corpusOf(Map<String, List<String>> documents) => SectionCorpus([
        for (final entry in documents.entries)
          DocumentSections.parse(
            [for (final id in entry.value) '## $id Title'].join('\n\n'),
            path: p.join('/docs', entry.key),
          ),
      ]);

  /// Classifies [markdown] as if it were `own.md`, against [corpus].
  List<SectionCitation> classify(
    String markdown, {
    required SectionCorpus corpus,
    List<String> ownSections = const [],
    String own = 'own.md',
  }) =>
      classifySectionCitations(
        markdown,
        path: p.join('/docs', own),
        corpus: corpus,
        own: DocumentSections.parse(
          [for (final id in ownSections) '## $id Title'].join('\n\n'),
          path: p.join('/docs', own),
        ),
      );

  group('SCC1: the self-reference carve-out', () {
    test('a bare citation that resolves in its own document is self', () {
      final citations = classify(
        'The rule is stated in §4.1.',
        corpus: corpusOf({'other.md': ['4.1']}),
        ownSections: ['4.1'],
      );

      expect(citations, hasLength(1));
      expect(citations.single.verdict, SectionCitationVerdict.self);
      expect(citations.single.source, SectionQualifierSource.bare);
      expect(citations.single.document, isNull);
      expect(citations.single.isViolation, isFalse);
    });

    test('a bare citation its own document does not declare is dangling', () {
      // The whole point of the carve-out: it is not a blanket amnesty. A bare
      // §N that resolves nowhere in its own file has lost its document name.
      final citations = classify(
        'See §9.2 for the details.',
        corpus: corpusOf({'other.md': ['9.2']}),
        ownSections: ['1', '2'],
      );

      expect(citations.single.verdict, SectionCitationVerdict.dangling);
      expect(citations.single.isViolation, isTrue);
    });

    test('the failure message names the document that would fix it', () {
      final citations = classify(
        'See §9.2.',
        corpus: corpusOf({'other.md': ['9.2']}),
      );

      expect(citations.single.describe(), contains('own.md:1'));
      expect(citations.single.describe(), contains('§9.2'));
      expect(citations.single.describe(), contains('DANGLING'));
    });
  });

  group('SCC2: the five ways a document name governs a citation', () {
    final corpus = corpusOf({
      'other.md': ['9.2', '4.1', '4.2', '4.3'],
      'som_multiplatform_spec_model.md': ['11.4'],
    });

    test('a leading name qualifies, in backticks or bare', () {
      for (final written in [
        'as `other.md` §9.2 says',
        'as other.md §9.2 says',
        'as **other.md** §9.2 says',
      ]) {
        final citations = classify(written, corpus: corpus);
        expect(citations.single.source, SectionQualifierSource.leading,
            reason: written);
        expect(citations.single.document, 'other.md', reason: written);
        expect(citations.single.verdict, SectionCitationVerdict.crossDocument,
            reason: written);
      }
    });

    test('a leading name reaches across a soft line wrap', () {
      // Prose wraps between the name and the section far too often for the
      // lookback to stop at the newline.
      final citations = classify(
        'The layout rule lives in `other.md`\n§9.2 and is normative.',
        corpus: corpus,
      );

      expect(citations.single.source, SectionQualifierSource.leading);
      expect(citations.single.verdict, SectionCitationVerdict.crossDocument);
      expect(citations.single.line, 2);
    });

    test('a leading name may be the tail of a markdown link', () {
      final citations = classify(
        'see [other.md](other.md) §9.2 for that',
        corpus: corpus,
      );

      expect(citations.single.document, 'other.md');
      expect(citations.single.verdict, SectionCitationVerdict.crossDocument);
    });

    test('`SOM` is the short form for som_multiplatform_spec_model.md', () {
      final citations = classify('SOM §11.4 states it.', corpus: corpus);

      expect(citations.single.document, somDocument);
      expect(citations.single.viaShortForm, isTrue);
      expect(citations.single.verdict, SectionCitationVerdict.crossDocument);
    });

    test('a trailing name qualifies — `§N of <file>.md`', () {
      final citations = classify(
        'stated in §9.2 of [`other.md`](other.md)',
        corpus: corpus,
      );

      expect(citations.single.source, SectionQualifierSource.trailing);
      expect(citations.single.document, 'other.md');
      expect(citations.single.verdict, SectionCitationVerdict.crossDocument);
    });

    test('a run inherits the name its first member carries', () {
      final citations = classify(
        'see `other.md` §4.1 / §4.2 and §4.3',
        corpus: corpus,
      );

      expect(citations, hasLength(3));
      expect(citations.first.source, SectionQualifierSource.leading);
      expect(citations[1].source, SectionQualifierSource.run);
      expect(citations[2].source, SectionQualifierSource.run);
      expect(citations.map((c) => c.document), everyElement('other.md'));
    });

    test('prose between two citations ends the run', () {
      // The guard against a name mentioned two clauses earlier vouching for a
      // citation that has nothing to do with it.
      final citations = classify(
        'see `other.md` §4.1, but the shape itself is fixed by §9.9',
        corpus: corpus,
        ownSections: ['4.1'],
      );

      expect(citations[1].source, SectionQualifierSource.bare);
      expect(citations[1].verdict, SectionCitationVerdict.dangling);
    });

    test('a document-map row scopes every citation in it', () {
      final citations = classify(
        '| Document | Authority for |\n'
        '|----------|---------------|\n'
        '| [other.md](other.md) | Field shapes (§4.1) and forms (§4.2). |',
        corpus: corpus,
      );

      expect(citations, hasLength(2));
      expect(citations.map((c) => c.source),
          everyElement(SectionQualifierSource.tableRow));
      expect(citations.map((c) => c.verdict),
          everyElement(SectionCitationVerdict.crossDocument));
    });

    test('a first cell that mixes prose with a citation does not scope the row',
        () {
      // The near-miss this narrowness was written for: a serialization table
      // whose column one cites another document and whose column two cites the
      // table's own. An unrestricted row scope resolves column two against the
      // wrong file and reports nothing.
      final citations = classify(
        '| Stored `codeSpec` (`other.md` §9.2) | Emitted per §7.7 |',
        corpus: corpus,
        ownSections: ['7.7'],
      );

      expect(citations, hasLength(2));
      expect(citations.first.document, 'other.md');
      expect(citations[1].source, SectionQualifierSource.bare);
      expect(citations[1].verdict, SectionCitationVerdict.self);
    });

    test('a column headed by a document scopes the cells beneath it', () {
      // The transpose of the row rule, written for a table that indexes a
      // companion document section by section. Without it the table repeats a
      // 21-character filename once per row.
      final citations = classify(
        '| Area | `other.md` § |\n'
        '|------|--------------|\n'
        '| Scripting | §4.1 |\n'
        '| Search | §4.2 |',
        corpus: corpus,
      );

      expect(citations, hasLength(2));
      expect(citations.map((c) => c.source),
          everyElement(SectionQualifierSource.tableColumn));
      expect(citations.map((c) => c.document), everyElement('other.md'));
      expect(citations.map((c) => c.verdict),
          everyElement(SectionCitationVerdict.crossDocument));
    });

    test('only the headed column is scoped', () {
      // The guard that keeps this rule from becoming a whole-table scope: a
      // sibling column citing the table's own document must stay self.
      final citations = classify(
        '| Own | `other.md` § |\n'
        '|-----|--------------|\n'
        '| §7.7 | §4.1 |',
        corpus: corpus,
        ownSections: ['7.7'],
      );

      expect(citations, hasLength(2));
      expect(citations.first.source, SectionQualifierSource.bare);
      expect(citations.first.verdict, SectionCitationVerdict.self);
      expect(citations[1].source, SectionQualifierSource.tableColumn);
    });

    test('a header cell that merely mentions a document does not scope it', () {
      // The trailing `§` is what makes the header *say* the column holds
      // sections. Without it the same "and nothing else" guard applies as to the
      // row rule, so a header naming a document in passing scopes nothing.
      final citations = classify(
        '| Area | Where `other.md` says so |\n'
        '|------|--------------------------|\n'
        '| Scripting | §9.9 |',
        corpus: corpus,
      );

      expect(citations.single.source, SectionQualifierSource.bare);
      expect(citations.single.verdict, SectionCitationVerdict.dangling);
    });

    test('the column scope ends with the table', () {
      // A table row is its own block, so the scope has to be carried across
      // blocks explicitly — and dropped again the moment a non-table block
      // arrives, or it reaches into unrelated prose below.
      final citations = classify(
        '| Area | `other.md` § |\n'
        '|------|--------------|\n'
        '| Scripting | §4.1 |\n'
        '\n'
        'Unrelated prose citing §9.9.',
        corpus: corpus,
      );

      expect(citations, hasLength(2));
      expect(citations.first.source, SectionQualifierSource.tableColumn);
      expect(citations[1].source, SectionQualifierSource.bare);
      expect(citations[1].verdict, SectionCitationVerdict.dangling);
    });

    test('a leading name in the cell still beats the column', () {
      // Precedence: leading > trailing > run > row > column. The column is the
      // weakest because it is the furthest from the citation.
      final citations = classify(
        '| Area | `other.md` § |\n'
        '|------|--------------|\n'
        '| Scripting | `third.md` §5.5 |',
        corpus: corpusOf({'other.md': ['4.1'], 'third.md': ['5.5']}),
      );

      expect(citations.single.source, SectionQualifierSource.leading);
      expect(citations.single.document, 'third.md');
    });
  });

  group('SCC3: resolution is exact', () {
    final corpus = corpusOf({'other.md': ['12.3']});

    test('a child id does not resolve through its parent heading', () {
      // Rejected deliberately: relaxing to the ancestor excuses a hundred
      // citations that belong to a different document, and nothing a parser can
      // see tells that case from the genuine "rule 6 inside §12.3" one.
      final citations = classify('see §12.3.6', corpus: corpus,
          ownSections: ['12.3']);

      expect(citations.single.verdict, SectionCitationVerdict.dangling);
    });

    test('a parent id does not resolve through a child heading', () {
      final citations =
          classify('see §12', corpus: corpus, ownSections: ['12.3']);

      expect(citations.single.verdict, SectionCitationVerdict.dangling);
    });

    test('a qualified citation the named document lacks is wrongSection', () {
      final citations = classify('see `other.md` §99.9', corpus: corpus);

      expect(citations.single.verdict, SectionCitationVerdict.wrongSection);
      expect(citations.single.isViolation, isTrue);
    });

    test('a citation of a document outside the corpus is unverifiable', () {
      // Not a defect: the checker cannot see the file, which is not the same as
      // the citation being wrong.
      final citations = classify('see `elsewhere.md` §3', corpus: corpus);

      expect(citations.single.verdict, SectionCitationVerdict.unverifiable);
      expect(citations.single.isViolation, isFalse);
    });
  });

  group('SCC4: what counts as a citation', () {
    final corpus = corpusOf({'other.md': ['4.1']});

    test('symbolic heading ids are citations too', () {
      final citations = classify('see §PF-FLW-OVE', corpus: corpus,
          ownSections: ['PF-FLW-OVE']);

      expect(citations.single.verdict, SectionCitationVerdict.self);
    });

    test('a §-prefixed word is not a citation', () {
      // §oneof / §item / §content are DocSpecs section-type names, and §N is the
      // convention's own metavariable. Keying on the id's shape rather than on an
      // exception list covers a name nobody has coined yet.
      final citations = classify(
        'A §oneof holds a §item; a bare §N means this document.',
        corpus: corpus,
      );

      expect(citations, isEmpty);
    });

    test('citations inside a fenced block are not scanned', () {
      final citations = classify(
        'Real: §4.1\n\n```\n// SOM §99.9 in a code sample\n```\n',
        corpus: corpus,
        ownSections: ['4.1'],
      );

      expect(citations, hasLength(1));
      expect(citations.single.id, '4.1');
    });

    test('a heading inside a fenced block does not declare a section', () {
      final sections = DocumentSections.parse(
        '## 1 Real\n\n```\n## 99 Sample\n```\n',
        path: '/docs/own.md',
      );

      expect(sections.declares('1'), isTrue);
      expect(sections.declares('99'), isFalse);
    });

    test('a heading id is recognised with or without its trailing dot', () {
      final sections = DocumentSections.parse(
        '## 4. Parts\n\n### 4.1 Catalogue\n\n## PF-DOC Document Information\n',
        path: '/docs/own.md',
      );

      expect(sections.byId.keys, containsAll(['4', '4.1', 'PF-DOC']));
      expect(sections.byId['4.1']!.level, 3);
      expect(sections.byId['PF-DOC']!.title, 'Document Information');
    });
  });

  group('SCC5: the doc-folder gate', () {
    test('every document in the folder is scanned and resolved', () {
      final report = checkSectionCitations(docDir: docDir);

      // The corpus is the folder itself, flat by design — generated output lives
      // in a sibling tree and must not be scanned.
      expect(report.corpus.length, report.files.length);
      expect(report.citations, isNotEmpty);
      expect(report.countOf(SectionCitationVerdict.wrongSection), 0,
          reason: 'a citation naming a document that lacks the section is a '
              'defect the doc set has never had');
    });

    test('the self-reference carve-out is what the doc set actually does', () {
      // The empirical case for the rule: self-citation is not an exception in
      // these documents, it is the overwhelming majority of how they cite.
      final report = checkSectionCitations(docDir: docDir);
      final self = report.countOf(SectionCitationVerdict.self);

      expect(self, greaterThan(report.citations.length ~/ 2));
    });

    test('index.md itself obeys the convention it states', () {
      final report = checkSectionCitations(docDir: docDir);
      final offenders = report.violations
          .where((c) => p.basename(c.file) == 'index.md')
          .map((c) => c.describe(relativeTo: docDir));

      expect(offenders, isEmpty);
    });

    test('every § citation in the doc folder and its READMEs resolves', () {
      // The gate proper, and the reason the checker exists. A `§` citation is
      // the one cross-reference in these documents that decays in total silence:
      // a section is renumbered, the citation still reads like a citation, and
      // nothing but a resolver notices. So the corpus is held at zero
      // violations rather than at "no new ones".
      //
      // The READMEs are in because they cite the doc set by section exactly as
      // the documents do, and a reader following one does not care which side of
      // the folder boundary it was written on.
      final extras = [
        for (final readme in defaultCitedReadmes)
          p.normalize(p.join(containerRoot, readme)),
      ];
      final missing = extras.where((f) => !File(f).existsSync());
      if (missing.isNotEmpty) {
        markTestSkipped('cited READMEs are not checked out: $missing');
        return;
      }

      final report = checkSectionCitations(docDir: docDir, extraFiles: extras);

      expect(
        report.violations.map((c) => c.describe(relativeTo: containerRoot)),
        isEmpty,
      );

      // Anti-vacuity, on the scan rather than on the result: an empty folder or
      // an unresolved corpus would pass the assertion above having checked
      // nothing.
      expect(report.files.length, greaterThan(defaultCitedReadmes.length));
      expect(report.countOf(SectionCitationVerdict.crossDocument),
          greaterThan(0),
          reason: 'a corpus in which nothing cites anything else would make the '
              'whole resolver vacuous');
    });
  });

  group('SCC6: Dart doc-comments are held to the same convention', () {
    test('a doc comment is lifted to markdown, and code is not', () {
      const source = '''
/// Cites `x.md` §1.
class A {
  // A plain comment mentioning §2 is not documentation.
  final String s = 'a literal §3';
}

/// Cites `x.md` §4.
class B {}
''';

      final lifted = dartDocComments(source);

      // Line numbers survive, because a violation is reported at one.
      expect(lifted.split('\n').length, source.split('\n').length);
      expect(lifted.split('\n')[0], 'Cites `x.md` §1.');
      expect(lifted.split('\n')[6], 'Cites `x.md` §4.');

      // Only `///` carries documentation. A `//` comment is a note to the next
      // maintainer and a string literal is data; neither is read by a reader
      // following a citation, so neither is held to the convention.
      expect(lifted, isNot(contains('§2')));
      expect(lifted, isNot(contains('§3')));
    });

    test('the lookback crosses a `///` wrap, as it does a soft wrap', () {
      // The reason lifting beats scanning the raw file: doc comments wrap, and
      // the document name lands on the line above its `§`. Scanning raw text
      // would see a bare citation and call a correct line dangling.
      const source = '''
/// The framework carries annotations only (`codespecs_mapping.md`
/// §1.1 pillar (a)).
class A {}
''';

      final citations = classifySectionCitations(
        dartDocComments(source),
        path: '/pkg/lib/a.dart',
        corpus: corpusOf({
          'codespecs_mapping.md': ['1.1'],
        }),
        own: DocumentSections.parse('', path: '/pkg/lib/a.dart'),
      );

      expect(citations, hasLength(1));
      expect(citations.single.document, 'codespecs_mapping.md');
      expect(citations.single.source, SectionQualifierSource.leading);
      expect(citations.single.verdict, SectionCitationVerdict.crossDocument);
      expect(citations.single.line, 2);
    });

    test('a bare citation in a source file is dangling, always', () {
      // A Dart file declares no sections, so the self-reference carve-out has
      // nothing to resolve against: every citation in source must name its
      // document. This is what makes `§0` catchable at all.
      const source = '''
/// The framework carries annotations only (§0).
class A {}
''';

      final citations = classifySectionCitations(
        dartDocComments(source),
        path: '/pkg/lib/a.dart',
        corpus: corpusOf({
          'codespecs_mapping.md': ['1.1'],
        }),
        own: DocumentSections.parse('', path: '/pkg/lib/a.dart'),
      );

      expect(citations.single.verdict, SectionCitationVerdict.dangling);
    });

    test('every § citation in the CodeSpecs source packages resolves', () {
      // The gate this group exists for. The doc-folder gate above reads `.md`
      // only, which is why four `codespecs_mapping.md §0` citations sat in the
      // annotation packages unnoticed while the doc folder was clean — and a
      // package's doc comments are the first thing a reader of that package
      // sees, so they decay in exactly the same silence.
      final roots = [
        for (final root in defaultCitedSourceRoots)
          p.normalize(p.join(containerRoot, root)),
      ];
      final missing = roots.where((d) => !Directory(d).existsSync());
      if (missing.isNotEmpty) {
        markTestSkipped('CodeSpecs source packages are not checked out: '
            '$missing');
        return;
      }

      final sources = [for (final root in roots) ...listDartSources(root)];
      final report = checkSectionCitations(docDir: docDir, extraSources: sources);

      expect(
        report.violations
            .where((c) => p.extension(c.file) == '.dart')
            .map((c) => c.describe(relativeTo: containerRoot)),
        isEmpty,
      );

      // Anti-vacuity: a root that resolved to nothing, or sources that cite
      // nothing, would pass the assertion above having checked nothing.
      expect(sources, isNotEmpty);
      expect(
        report.citations.where((c) => p.extension(c.file) == '.dart'),
        isNotEmpty,
      );
    });
  });

  group('SCC7: citations of public standards are not citations of this set',
      () {
    test('a standard designator qualifies the citation that follows it', () {
      final citations = classify(
        'The suite maps onto ISO/IEC/IEEE 29148 §6 front matter.',
        corpus: corpusOf({'own.md': ['6']}),
        ownSections: ['6'],
      );

      expect(citations, hasLength(1));
      expect(citations.single.document, 'ISO/IEC/IEEE 29148');
      expect(
          citations.single.source, SectionQualifierSource.externalStandard);
      expect(citations.single.verdict, SectionCitationVerdict.unverifiable);
    });

    test('without the rule the citation would pass as a correct self-reference',
        () {
      // Why this rule is not a tolerance widening but a defect fix. The citing
      // document declares a §6 of its own, so reading the ISO citation as bare
      // resolved it — silently, to the wrong document. A false alarm is
      // findable; this was not.
      final citations = classify(
        'ISO/IEC/IEEE 29148 §6 front matter, and §6 of this document.',
        corpus: corpusOf({'own.md': ['6']}),
        ownSections: ['6'],
      );

      expect(citations, hasLength(2));
      expect(citations.first.verdict, SectionCitationVerdict.unverifiable);
      // The second is a genuine self-reference and must stay one: the rule
      // qualifies the citation the designator stands before, not the sentence.
      expect(citations.last.verdict, SectionCitationVerdict.self);
    });

    test('a bare body name does not qualify — the standard number is required',
        () {
      // `ISO §4` names no standard. Admitting it would let the mere mention of
      // an organisation vouch for a citation, which is the silent
      // mis-resolution the convention exists to prevent.
      final citations = classify(
        'Nothing in ISO §4 applies here.',
        corpus: corpusOf({'own.md': ['9']}),
        ownSections: ['9'],
      );

      expect(citations.single.source, SectionQualifierSource.bare);
      expect(citations.single.verdict, SectionCitationVerdict.dangling);
    });

    test('an unrecognised body does not qualify', () {
      // The body list is closed. Keying on the shape "capitals then a number"
      // instead would let a CodeSpecs part code do the qualifying.
      final citations = classify(
        'The part CE-ER 5 §4 is not a standard.',
        corpus: corpusOf({'own.md': ['9']}),
        ownSections: ['9'],
      );

      expect(citations.single.source, SectionQualifierSource.bare);
      expect(citations.single.verdict, SectionCitationVerdict.dangling);
    });

    test('a run inherits the designator, as it inherits a document name', () {
      final citations = classify(
        'See ISO/IEC 25010:2023 §4.2, §4.3.',
        corpus: corpusOf({'own.md': ['4.2']}),
        ownSections: ['4.2'],
      );

      expect(citations, hasLength(2));
      expect(citations.last.source, SectionQualifierSource.run);
      expect(citations.last.document, 'ISO/IEC 25010:2023');
      // Notably `§4.2` does exist in the citing document — inheritance is what
      // stops the second member of an external run resolving locally too.
      expect(citations.first.verdict, SectionCitationVerdict.unverifiable);
      expect(citations.last.verdict, SectionCitationVerdict.unverifiable);
    });

    test('a TomSpecs document name still wins over an adjacent designator', () {
      // Ordering matters: `.md` adjacency is checked first, so a designator
      // earlier in the line cannot capture a properly qualified citation.
      final citations = classify(
        'Derived from ISO 9241 and stated in `x.md` §2.',
        corpus: corpusOf({'x.md': ['2']}),
      );

      expect(citations.single.source, SectionQualifierSource.leading);
      expect(citations.single.document, 'x.md');
      expect(citations.single.verdict, SectionCitationVerdict.crossDocument);
    });
  });
}
