/// Reading back what a Phase-4 run wrote: the per-area **extract** files and
/// the Stage-B **gate record** (`codespecs_mapping.md` §1.1.1,
/// `codespecs_prompt.md` §6.3).
///
/// The extractor ([CodeSpecsExtractor]) writes `<CE-CODE>.extract.yaml`; this
/// library is the other half, so a consumer that did not run the extractor —
/// a validator, an editor tool, an agent asking which areas are in scope —
/// reads the files with the same rules everywhere instead of re-deriving the
/// shape. The gate record has a writer here too, because it is otherwise
/// written by hand and only checked when something reads it.
///
/// Both readers **refuse** an unknown `formatVersion`: a later format that
/// moved a key would otherwise read as an extract with no entries, or a scope
/// with no verdicts, and a check with no input passes.
library;

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'spec_codespecs_extract.dart';

/// The file name of the gate record, written beside the extracts.
///
/// Fixed so a partial pass cannot hide its record under a name no reader
/// looks for.
const String kCodeSpecsGateRecordFile = 'gate.verdicts.yaml';

/// The gate record `formatVersion` this runtime reads and writes.
const int kCodeSpecsGateRecordFormat = 1;

/// The suffix every extract artifact of record carries.
const String kCodeSpecsExtractFileSuffix = '.extract.yaml';

final RegExp _areaCodePattern = RegExp(r'^CE-[A-Z]+$');

/// A malformed or unreadable extract file or gate record.
class CodeSpecsRecordError implements Exception {
  /// What is wrong, naming the file it was read from.
  final String message;

  /// Creates the error.
  const CodeSpecsRecordError(this.message);

  @override
  String toString() => 'CodeSpecsRecordError: $message';
}

// ---------------------------------------------------------------------------
// Extract files
// ---------------------------------------------------------------------------

/// Parses one `<CE-CODE>.extract.yaml`. [source] names the file in errors.
///
/// Only `extract.formatVersion` and `extract.area.code` are required; any
/// other absent key reads as empty (a string as `''`, a list as `[]`), so a
/// hand-written fixture stays readable. A key that is present with the wrong
/// type is an error, and so is a `document.entryCount` that disagrees with
/// the entries.
///
/// The inverse of [CodeSpecsExtract.toYaml]: for any extract the extractor
/// wrote, `parseCodeSpecsExtractYaml(x.toYaml()).toYaml() == x.toYaml()`.
/// `document.entryCount` must agree with the entries — a truncated file would
/// otherwise read as a complete one.
CodeSpecsExtract parseCodeSpecsExtractYaml(String text, {String source = ''}) {
  final name = source.isEmpty ? 'the extract' : source;
  final root = _rootMapping(text, name, 'extract');
  final version = root['formatVersion'];
  if (version != kCodeSpecsExtractFormat) {
    throw CodeSpecsRecordError(
      '$name declares extract format $version; this reader understands '
      '$kCodeSpecsExtractFormat only — reading it would silently drop entries',
    );
  }
  final area = root['area'];
  if (area is! YamlMap) {
    throw CodeSpecsRecordError('$name has no `area:` mapping');
  }
  final code = _str(area['code'], name, 'area.code');
  if (code.isEmpty) throw CodeSpecsRecordError('$name names no area code');
  var part = _str(area['part'], name, 'area.part');
  if (part.startsWith('CodeSpecPart.')) {
    part = part.substring('CodeSpecPart.'.length);
  }
  final documentNode = root['document'];
  if (documentNode != null && documentNode is! YamlMap) {
    throw CodeSpecsRecordError('$name: `document` must be a mapping');
  }
  final entriesNode = root['entries'];
  if (entriesNode != null && entriesNode is! YamlList) {
    throw CodeSpecsRecordError('$name: `entries` must be a list');
  }
  final entries = <CodeSpecsExtractEntry>[];
  for (final raw in (entriesNode as YamlList?) ?? const []) {
    if (raw is! YamlMap) {
      throw CodeSpecsRecordError('$name has an entry that is not a mapping');
    }
    String req(String key) => _str(raw[key], name, 'entries[].$key');
    String? opt(String key) => _optStr(raw[key], name, 'entries[].$key');
    entries.add(
      CodeSpecsExtractEntry(
        areaCode: code,
        sectionId: req('sectionId'),
        headline: opt('headline'),
        instanceId: opt('instanceId'),
        path: req('path'),
        className: req('className'),
        fieldName: req('fieldName'),
        formField: opt('formField'),
        routedBy: req('routedBy'),
        routedAt: req('routedAt'),
        routingNote: opt('routingNote'),
        value: req('value'),
      ),
    );
  }
  final declared = (documentNode as YamlMap?)?['entryCount'];
  if (declared != null && declared != entries.length) {
    throw CodeSpecsRecordError(
      '$name declares entryCount $declared but carries ${entries.length} '
      'entries — a truncated extract must not read as a complete one',
    );
  }
  return CodeSpecsExtract(
    area: CodeSpecsArea(
      code: code,
      canonicalId: _str(area['canonicalId'], name, 'area.canonicalId'),
      part: part,
      annotations: _strList(area['annotations'], name, 'area.annotations'),
      builtOn: _str(area['builtOn'], name, 'area.builtOn'),
      attributeSurface: _str(
        area['attributeSurface'],
        name,
        'area.attributeSurface',
      ),
      slices: _intList(area['slices'], name, 'area.slices'),
      authoringSteps: _intList(
        area['authoringSteps'],
        name,
        'area.authoringSteps',
      ),
    ),
    documentRoot: _str(documentNode?['root'], name, 'document.root'),
    catalogSource: _str(root['catalogSource'], name, 'catalogSource'),
    projects: _strList(area['projects'], name, 'area.projects'),
    citableParts: _strList(area['citableParts'], name, 'area.citableParts'),
    entries: List.unmodifiable(entries),
  );
}

// ---------------------------------------------------------------------------
// The gate record
// ---------------------------------------------------------------------------

/// One of `codespecs_prompt.md` §6.2's three per-area verdicts.
enum CodeSpecsGateVerdict {
  /// The extract carries every input the derivation contract requires.
  sufficient,

  /// The area does not apply — nothing was routed, with positive evidence of
  /// absence (`codespecs_prompt.md` §6.4).
  notApplicable,

  /// The extract is missing required inputs; only a recorded descope lets a
  /// run continue without the area.
  insufficient;

  /// The verdict word exactly as `codespecs_prompt.md` §6.2 states it.
  String get word => switch (this) {
    sufficient => 'sufficient',
    notApplicable => 'not applicable',
    insufficient => 'insufficient',
  };

  /// The verdict for [word], or `null` for a word `codespecs_prompt.md` §6.2
  /// does not know.
  static CodeSpecsGateVerdict? parse(String word) => switch (word) {
    'sufficient' => sufficient,
    'not applicable' => notApplicable,
    'insufficient' => insufficient,
    _ => null,
  };
}

/// The one resolution a gate record may carry: an insufficient area the user
/// decided to leave out.
const String kCodeSpecsGateDescoped = 'descoped';

/// One gap line of an insufficient area (`codespecs_prompt.md` §6.3): a
/// missing input, and the section field that should have carried it.
///
/// Stage C creates one L0 `csopen` todo per gap line, so two sections missing
/// the same field are two gaps — which is why the record carries them as data
/// rather than leaving them in the note.
class CodeSpecsGateGap {
  /// The section whose content is missing the input.
  final String sectionId;

  /// What the derivation contract required, in one line.
  final String required;

  /// `<section-id>.<field>` — the field that should have carried it.
  final String carrier;

  /// Creates a gap. Shape is checked by [CodeSpecsGateRecord].
  const CodeSpecsGateGap({
    required this.sectionId,
    required this.required,
    required this.carrier,
  });

  /// The gap as the `codespecs_prompt.md` §6.3 output line, without its
  /// indentation.
  String get line =>
      '$sectionId — $required — should have been carried by $carrier';
}

/// `<section-id>.<field>`: one or more dot-separated parts, none empty, no
/// whitespace.
final RegExp _carrierPattern = RegExp(r'^[^\s.]+(\.[^\s.]+)+$');

/// One area's recorded verdict.
class CodeSpecsGateEntry {
  /// The area's `CE-*` code.
  final String area;

  /// The verdict.
  final CodeSpecsGateVerdict verdict;

  /// `descoped`, on an insufficient area only; otherwise `null`.
  final String? resolution;

  /// A free-text note — why the verdict was taken. Never read as data.
  final String? note;

  /// The gap lines of an insufficient area, in the order Stage B found them;
  /// empty for every other verdict, and for an insufficient area recorded
  /// before its gaps were.
  final List<CodeSpecsGateGap> gaps;

  /// Creates an entry. Shape is checked by [CodeSpecsGateRecord], which is the
  /// only thing that reads or writes entries.
  const CodeSpecsGateEntry({
    required this.area,
    required this.verdict,
    this.resolution,
    this.note,
    this.gaps = const [],
  });

  /// Whether this is an insufficient area resolved by descoping.
  bool get descoped => resolution == kCodeSpecsGateDescoped;
}

/// The Stage-B gate record, `gate.verdicts.yaml` (`codespecs_prompt.md` §6.3).
///
/// Constructing one checks it: every area is a `CE-*` code named once, and a
/// `resolution:` appears only as `descoped` on an insufficient area. So a
/// record that exists is a record of the checked shape, whether it was read
/// or built to be written.
class CodeSpecsGateRecord {
  /// The verdicts, in the order they were recorded.
  final List<CodeSpecsGateEntry> verdicts;

  /// Creates and checks a record; throws [CodeSpecsRecordError] on a shape
  /// `codespecs_prompt.md` §6.3 does not allow. [source] names it in errors.
  CodeSpecsGateRecord(
    List<CodeSpecsGateEntry> verdicts, {
    String source = kCodeSpecsGateRecordFile,
  }) : verdicts = List.unmodifiable(verdicts) {
    _check(source);
  }

  /// Parses `gate.verdicts.yaml`. [source] names the file in errors.
  factory CodeSpecsGateRecord.fromYaml(
    String text, {
    String source = kCodeSpecsGateRecordFile,
  }) {
    final root = _rootMapping(text, source, 'gate');
    for (final key in root.keys) {
      if (key != 'formatVersion' && key != 'verdicts') {
        throw CodeSpecsRecordError(
          '$source has an unknown key `gate.$key` — the record knows '
          '`formatVersion` and `verdicts` only',
        );
      }
    }
    final version = root['formatVersion'];
    if (version != kCodeSpecsGateRecordFormat) {
      throw CodeSpecsRecordError(
        '$source declares gate record format $version; this reader '
        'understands $kCodeSpecsGateRecordFormat only — reading it would '
        'silently change the scope',
      );
    }
    final list = root['verdicts'];
    if (list is! YamlList) {
      throw CodeSpecsRecordError('$source has no `verdicts:` list');
    }
    final entries = <CodeSpecsGateEntry>[];
    for (final raw in list) {
      if (raw is! YamlMap) {
        throw CodeSpecsRecordError(
          '$source has a verdict that is not a mapping',
        );
      }
      for (final key in raw.keys) {
        if (!const [
          'area',
          'verdict',
          'resolution',
          'gaps',
          'note',
        ].contains(key)) {
          throw CodeSpecsRecordError(
            '$source has an unknown key `$key` in a verdict — an entry knows '
            '`area`, `verdict`, `resolution`, `gaps` and `note` only',
          );
        }
      }
      final area = _str(raw['area'], source, 'verdicts[].area');
      final word = _str(raw['verdict'], source, 'verdicts[].verdict');
      final verdict = CodeSpecsGateVerdict.parse(word);
      if (verdict == null) {
        throw CodeSpecsRecordError(
          '$source gives $area the verdict `$word` — codespecs_prompt.md '
          '§6.2 knows `sufficient`, `not applicable` and `insufficient` only',
        );
      }
      entries.add(
        CodeSpecsGateEntry(
          area: area,
          verdict: verdict,
          resolution: _optStr(
            raw['resolution'],
            source,
            'verdicts[].resolution',
          ),
          note: _optStr(raw['note'], source, 'verdicts[].note'),
          gaps: _gaps(raw['gaps'], source, area),
        ),
      );
    }
    return CodeSpecsGateRecord(entries, source: source);
  }

  static List<CodeSpecsGateGap> _gaps(Object? raw, String source, String area) {
    if (raw == null) return const [];
    if (raw is! YamlList) {
      throw CodeSpecsRecordError(
        '$source: `$area` has `gaps:` that is not a list',
      );
    }
    return [
      for (final g in raw)
        if (g is! YamlMap)
          throw CodeSpecsRecordError(
            '$source: `$area` has a gap that is not a mapping',
          )
        else ...[
          for (final key in g.keys)
            if (!const ['sectionId', 'required', 'carrier'].contains(key))
              throw CodeSpecsRecordError(
                '$source has an unknown key `$key` in a gap of $area — a gap '
                'knows `sectionId`, `required` and `carrier` only',
              ),
          CodeSpecsGateGap(
            sectionId: _str(g['sectionId'], source, 'gaps[].sectionId'),
            required: _str(g['required'], source, 'gaps[].required'),
            carrier: _str(g['carrier'], source, 'gaps[].carrier'),
          ),
        ],
    ];
  }

  void _check(String source) {
    final seen = <String>{};
    for (final e in verdicts) {
      if (e.area.isEmpty) {
        throw CodeSpecsRecordError('$source has a verdict that names no area');
      }
      if (!_areaCodePattern.hasMatch(e.area)) {
        throw CodeSpecsRecordError(
          '$source names the area `${e.area}`, which is not a CE-* code',
        );
      }
      if (!seen.add(e.area)) {
        throw CodeSpecsRecordError(
          '$source carries two verdicts for ${e.area} — a scope with two '
          'answers for one area is no scope',
        );
      }
      if (e.gaps.isNotEmpty && e.verdict != CodeSpecsGateVerdict.insufficient) {
        throw CodeSpecsRecordError(
          '$source gives ${e.area} gap lines on verdict `${e.verdict.word}` — '
          'only an insufficient area has missing inputs',
        );
      }
      for (final g in e.gaps) {
        for (final (name, value) in [
          ('sectionId', g.sectionId),
          ('required', g.required),
          ('carrier', g.carrier),
        ]) {
          if (value.trim().isEmpty) {
            throw CodeSpecsRecordError(
              '$source has a gap of ${e.area} with no `$name` — a gap line '
              'names the section, what was required and its carrier',
            );
          }
        }
        if (!_carrierPattern.hasMatch(g.carrier)) {
          throw CodeSpecsRecordError(
            '$source gives a gap of ${e.area} the carrier `${g.carrier}` — a '
            'carrier is `<section-id>.<field>`',
          );
        }
      }
      final resolution = e.resolution;
      if (resolution == null) continue;
      if (e.verdict != CodeSpecsGateVerdict.insufficient) {
        throw CodeSpecsRecordError(
          '$source gives ${e.area} a `resolution:` on verdict '
          '`${e.verdict.word}` — only an insufficient area has an L0 decision '
          'to resolve',
        );
      }
      if (resolution != kCodeSpecsGateDescoped) {
        throw CodeSpecsRecordError(
          '$source gives ${e.area} the resolution `$resolution` — `descoped` '
          'is the one resolution that admits a partial pass; any other '
          'resolution means the area was completed and its verdict re-taken',
        );
      }
    }
  }

  /// The entry for [area], or `null` when the record says nothing about it.
  CodeSpecsGateEntry? verdictFor(String area) {
    for (final e in verdicts) {
      if (e.area == area) return e;
    }
    return null;
  }

  /// Throws [CodeSpecsRecordError] when an area is not an active area of
  /// [catalog] — a verdict for an area that does not exist scopes nothing.
  void checkAgainst(
    CodeSpecsAreaCatalog catalog, {
    String source = kCodeSpecsGateRecordFile,
  }) {
    for (final e in verdicts) {
      final area = catalog.byCode(e.area);
      if (area == null || !area.active) {
        throw CodeSpecsRecordError(
          '$source gives a verdict for ${e.area}, which is not an active '
          'area of the catalogue',
        );
      }
    }
  }

  /// A copy with [entry] recorded — replacing the area's earlier verdict in
  /// place, or appended when the area had none.
  CodeSpecsGateRecord withVerdict(CodeSpecsGateEntry entry) {
    final out = <CodeSpecsGateEntry>[];
    var replaced = false;
    for (final e in verdicts) {
      if (e.area == entry.area) {
        out.add(entry);
        replaced = true;
      } else {
        out.add(e);
      }
    }
    if (!replaced) out.add(entry);
    return CodeSpecsGateRecord(out);
  }

  /// The record as `gate.verdicts.yaml`. Byte-stable: the same record always
  /// writes the same text, and `fromYaml(r.toYaml()).toYaml() == r.toYaml()`.
  ///
  /// `area` and `verdict` are written plain, as `codespecs_prompt.md` §6.3
  /// shows them — both are from a closed vocabulary the constructor checked —
  /// and a note and every gap field as double-quoted scalars, the extract's one
  /// escaping rule.
  String toYaml() {
    final b = StringBuffer()
      ..writeln('gate:')
      ..writeln('  formatVersion: $kCodeSpecsGateRecordFormat');
    if (verdicts.isEmpty) {
      b.writeln('  verdicts: []');
      return b.toString();
    }
    b.writeln('  verdicts:');
    for (final e in verdicts) {
      b.writeln('    - area: ${e.area}');
      b.writeln('      verdict: ${e.verdict.word}');
      if (e.resolution != null) b.writeln('      resolution: ${e.resolution}');
      if (e.gaps.isNotEmpty) {
        b.writeln('      gaps:');
        for (final g in e.gaps) {
          b
            ..writeln(
              '        - sectionId: ${codeSpecsYamlString(g.sectionId)}',
            )
            ..writeln('          required: ${codeSpecsYamlString(g.required)}')
            ..writeln('          carrier: ${codeSpecsYamlString(g.carrier)}');
        }
      }
      if (e.note != null) {
        b.writeln('      note: ${codeSpecsYamlString(e.note!)}');
      }
    }
    return b.toString();
  }
}

// ---------------------------------------------------------------------------
// A tree of extracts, scoped by its gate record
// ---------------------------------------------------------------------------

/// One area the gate record left out of scope.
///
/// Kept visible rather than dropped, so a consumer can say so: a scoped-out
/// area must never read as a covered one.
class CodeSpecsExcludedArea {
  /// The `CE-*` code.
  final String area;

  /// `notApplicable`, or `insufficient` with a recorded descope.
  final CodeSpecsGateVerdict verdict;

  /// Whether an insufficient verdict was resolved by descoping.
  final bool descoped;

  /// How many routed entries the excluded extract carried (0 with no file).
  final int entryCount;

  /// The file the excluded extract was read from, or '' when there was none.
  final String source;

  /// Creates the record.
  const CodeSpecsExcludedArea({
    required this.area,
    required this.verdict,
    this.descoped = false,
    this.entryCount = 0,
    this.source = '',
  });
}

/// Every extract one run produced, read back and scoped by its gate record.
class CodeSpecsExtractSet {
  /// The in-scope extracts, in source order. With a gate record: the areas it
  /// marks `sufficient`, in the record's order. Without: every extract.
  final List<CodeSpecsExtract> extracts;

  /// The file each in-scope extract was read from, parallel to [extracts].
  final List<String> sources;

  /// The areas the gate record excluded — empty without a record.
  final List<CodeSpecsExcludedArea> excluded;

  /// The gate record, when one was among the sources.
  final CodeSpecsGateRecord? gate;

  CodeSpecsExtractSet._(this.extracts, this.sources, this.excluded, this.gate);

  /// Reads [files] — file name → text — into a scoped set.
  ///
  /// The file whose basename is [kCodeSpecsGateRecordFile] is the gate
  /// record; every other file is an extract. The area code comes from the
  /// file's content, never its name. With a record, an area is in scope
  /// **iff** its verdict is `sufficient`, and:
  ///
  /// * the record must carry a verdict for every extract supplied — a scope
  ///   silent about an area would let a skipped area read as a passed one;
  /// * a `not applicable` area whose extract has entries is an error — a
  ///   routed value is evidence the area applies (`codespecs_prompt.md` §6.4);
  /// * an `insufficient` area without `resolution: descoped` is an error —
  ///   the run may not have continued past it (`codespecs_prompt.md` §6.2).
  ///
  /// Two extracts for one area, or two gate records, are errors.
  factory CodeSpecsExtractSet.fromFiles(Map<String, String> files) {
    String? gateName;
    final extracts = <CodeSpecsExtract>[];
    final sources = <String>[];
    for (final entry in files.entries) {
      final basename = entry.key.split('/').last;
      if (basename == kCodeSpecsGateRecordFile) {
        if (gateName != null) {
          throw CodeSpecsRecordError(
            'both $gateName and ${entry.key} are gate records — the scope '
            'must have one author',
          );
        }
        gateName = entry.key;
        continue;
      }
      final x = parseCodeSpecsExtractYaml(entry.value, source: entry.key);
      final earlier = extracts.indexWhere((e) => e.area.code == x.area.code);
      if (earlier >= 0) {
        throw CodeSpecsRecordError(
          '${sources[earlier]} and ${entry.key} are both extracts for '
          '${x.area.code}',
        );
      }
      extracts.add(x);
      sources.add(entry.key);
    }
    if (gateName == null) {
      return CodeSpecsExtractSet._(
        List.unmodifiable(extracts),
        List.unmodifiable(sources),
        const [],
        null,
      );
    }
    final gate = CodeSpecsGateRecord.fromYaml(
      files[gateName]!,
      source: gateName,
    );
    for (var i = 0; i < extracts.length; i++) {
      if (gate.verdictFor(extracts[i].area.code) == null) {
        throw CodeSpecsRecordError(
          '$gateName carries no verdict for ${extracts[i].area.code} '
          '(${sources[i]}) — the gate record must be total over the supplied '
          'extracts',
        );
      }
    }
    final inScope = <CodeSpecsExtract>[];
    final inScopeSources = <String>[];
    final excluded = <CodeSpecsExcludedArea>[];
    for (final v in gate.verdicts) {
      final i = extracts.indexWhere((e) => e.area.code == v.area);
      final x = i < 0 ? null : extracts[i];
      final src = i < 0 ? '' : sources[i];
      switch (v.verdict) {
        case CodeSpecsGateVerdict.sufficient:
          if (x != null) {
            inScope.add(x);
            inScopeSources.add(src);
          }
        case CodeSpecsGateVerdict.notApplicable:
          if (x != null && x.entries.isNotEmpty) {
            final n = x.entries.length;
            throw CodeSpecsRecordError(
              '$gateName marks ${v.area} `not applicable`, but $src carries '
              '$n routed entr${n == 1 ? 'y' : 'ies'} — a routed value is '
              'evidence the area applies (codespecs_prompt.md §6.4)',
            );
          }
          excluded.add(
            CodeSpecsExcludedArea(
              area: v.area,
              verdict: v.verdict,
              entryCount: x?.entries.length ?? 0,
              source: src,
            ),
          );
        case CodeSpecsGateVerdict.insufficient:
          if (!v.descoped) {
            throw CodeSpecsRecordError(
              '$gateName marks ${v.area} `insufficient` without `resolution: '
              'descoped` — codespecs_prompt.md §6.2 says the run does not '
              'continue past an unresolved insufficient area; recording the '
              'descope is what legitimizes a partial pass',
            );
          }
          excluded.add(
            CodeSpecsExcludedArea(
              area: v.area,
              verdict: v.verdict,
              descoped: true,
              entryCount: x?.entries.length ?? 0,
              source: src,
            ),
          );
      }
    }
    return CodeSpecsExtractSet._(
      List.unmodifiable(inScope),
      List.unmodifiable(inScopeSources),
      List.unmodifiable(excluded),
      gate,
    );
  }

  /// Reads a directory of extracts — `<CE-CODE>.extract.yaml` plus an
  /// optional `gate.verdicts.yaml`; other files (the `.extract.md` views) are
  /// ignored. Files are read in name order, so the set is the same on every
  /// file system.
  factory CodeSpecsExtractSet.fromDirectory(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw CodeSpecsRecordError('extract directory not found: $path');
    }
    final names =
        [
              for (final f in dir.listSync().whereType<File>())
                f.uri.pathSegments.last,
            ]
            .where(
              (n) =>
                  n.endsWith(kCodeSpecsExtractFileSuffix) ||
                  n == kCodeSpecsGateRecordFile,
            )
            .toList()
          ..sort();
    return CodeSpecsExtractSet.fromFiles({
      for (final n in names) n: File('${dir.path}/$n').readAsStringSync(),
    });
  }

  /// The in-scope extract for [area], or `null`.
  CodeSpecsExtract? byArea(String area) {
    for (final x in extracts) {
      if (x.area.code == area) return x;
    }
    return null;
  }

  /// Every in-scope entry routed from [sectionId] — the back-link token a
  /// `DocRef` names — across every area, in extract order.
  List<CodeSpecsExtractEntry> entriesForSection(String sectionId) => [
    for (final x in extracts)
      for (final e in x.entries)
        if (e.sectionId == sectionId) e,
  ];

  /// Every in-scope entry read from document [path], in extract order.
  List<CodeSpecsExtractEntry> entriesAtPath(String path) => [
    for (final x in extracts)
      for (final e in x.entries)
        if (e.path == path) e,
  ];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

YamlMap _rootMapping(String text, String name, String key) {
  final Object? document;
  try {
    document = loadYaml(text);
  } on YamlException catch (e) {
    throw CodeSpecsRecordError('$name is not valid YAML: ${e.message}');
  }
  if (document is! YamlMap) {
    throw CodeSpecsRecordError('$name does not hold a YAML mapping');
  }
  final root = document[key];
  if (root is! YamlMap) {
    throw CodeSpecsRecordError('$name has no top-level `$key:` mapping');
  }
  return root;
}

String _str(Object? v, String name, String key) {
  if (v == null) return '';
  if (v is String) return v;
  throw CodeSpecsRecordError('$name: `$key` must be a string');
}

String? _optStr(Object? v, String name, String key) {
  if (v == null) return null;
  if (v is String) return v;
  throw CodeSpecsRecordError('$name: `$key` must be a string or null');
}

List<String> _strList(Object? v, String name, String key) {
  if (v == null) return const [];
  if (v is! YamlList) {
    throw CodeSpecsRecordError('$name: `$key` must be a list');
  }
  return [for (final e in v) _str(e, name, key)];
}

List<int> _intList(Object? v, String name, String key) {
  if (v == null) return const [];
  if (v is! YamlList) {
    throw CodeSpecsRecordError('$name: `$key` must be a list');
  }
  return [
    for (final e in v)
      if (e is int)
        e
      else
        throw CodeSpecsRecordError('$name: `$key` must hold integers'),
  ];
}
