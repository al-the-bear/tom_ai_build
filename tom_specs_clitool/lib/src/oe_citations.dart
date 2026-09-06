/// Checks that every `OE-` id cited anywhere in the TomSpecs corpus resolves to
/// a row in the Open-Ends Register.
///
/// ## Why this exists
///
/// `index.md` owns the citation convention, and its rule is not about `§` in
/// particular: a citation that cannot be looked up promises a referent that does
/// not exist, and is always a defect. `OE-` ids are cited from **shipped
/// source** — comments in the editor's `lib/` and `test/`, notes in
/// `pubspec.yaml` and `buildkit.yaml` — as durable handles on seams and drop-in
/// points. "Fill the marked call site; that is `OE-3a`" is only worth writing if
/// `OE-3a` can be looked up.
///
/// The register was once two quest documents. Consolidating the editor
/// specification deleted them without folding them in, and 71 citations across
/// 16 distinct ids went on pointing at nothing for as long as nobody happened to
/// try one. Three `deferred.tom_specs.md` entries paid for it by restating in
/// prose what an id meant. This gate makes the next such deletion fail a build
/// step instead of decaying quietly.
///
/// ## Direction
///
/// **One direction only: cited → defined.** The register deliberately keeps rows
/// nothing cites any more — an id is allocated once and never reused, so a
/// retired row is what reserves its number. Checking the reverse direction would
/// turn that invariant into a failure.
///
/// ## What it does *not* do
///
/// Like the todo- and section-citation gates, this checks that a citation
/// **resolves**, never that the sentence around it is still true. The mechanical
/// half is the half that decays silently.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// The shape of an `OE-` id: a number, optionally suffixed by a single letter
/// for a sub-item (`OE-1a`, `OE-24a`).
///
/// Matched in raw text rather than only in inline code, because source comments
/// write the id bare — `// OE-3a: the live render drops in here`.
final RegExp oeIdPattern = RegExp(r'\bOE-([0-9]{1,3}[a-z]?)\b');

/// The heading that opens the register, at whatever section number it carries.
///
/// Keyed on the title, not the number: the register is appended after the last
/// section today, and a future document may renumber it.
final RegExp oeRegisterHeading =
    RegExp(r'^##\s+[0-9]+\.\s+Open-Ends Register\b', multiLine: false);

/// The document that owns the register, relative to the container root.
const oeRegisterDocument =
    'tom_ai/ai_build/tom_specs_model/doc/tom_specs_editor_specification.md';

/// Project folders and files whose `OE-` citations are checked.
///
/// Named explicitly rather than "the whole workspace" for the same reason the
/// todo gate scopes its quests: a corpus that wide would spend most of its time
/// reading code that has never heard of the register, and one accidental match
/// in an unrelated package would make the gate look unreliable.
const defaultCitingRoots = [
  'tom_forge/tom_specs_editor/lib',
  'tom_forge/tom_specs_editor/test',
  'tom_forge/tom_specs_editor/pubspec.yaml',
  'tom_forge/tom_specs_editor/buildkit.yaml',
  'tom_ai/ai_build/tom_specs_model/doc',
  // The package-tier `doc/` folders. A package guide cites an `OE-` id for the
  // same reason the editor's source does — to name an open end rather than
  // silently work around it — and until the tsdoc series wrote them there was
  // nothing here to hold. Only the folders that actually cite one are listed:
  // the membership rule is *citing*, not *kind*.
  'tom_ai/ai_build/tom_specs_clitool/doc',
  'tom_ai/ai_build/tom_specs_model/README.md',
  '_ai/quests/tom_specs/deferred.tom_specs.md',
  '_ai/quests/tom_specs/overview.tom_specs.md',
];

/// Extensions scanned when a citing root is a folder.
///
/// An allow-list, not a deny-list: a build folder can hold `.dill` snapshots
/// that contain the byte sequence `OE-3` inside unrelated data, and reporting
/// those as citations would be worse than missing a citation in a file type
/// nobody writes prose in.
const _scannedExtensions = {'.dart', '.md', '.yaml', '.yml', '.json'};

/// Folder names never descended into: generated or downloaded, never authored.
const _skippedDirectories = {
  'build',
  '.dart_tool',
  '.git',
  'generated-doc',
  'node_modules',
};

/// The ids the register defines, in the order the table declares them.
class OeRegister {
  const OeRegister._(this.ids, this.sourcePath, this.duplicates);

  /// Every defined id, e.g. `OE-3a`.
  final Set<String> ids;

  /// The document the register was read from.
  final String sourcePath;

  /// Ids that appeared as a definition more than once.
  ///
  /// A duplicate is a defect in the register itself: two rows claiming one id
  /// means the id has two meanings, which is exactly what "never reused"
  /// forbids.
  final List<String> duplicates;

  bool defines(String id) => ids.contains(id);

  int get length => ids.length;

  /// Reads the register out of [markdown].
  ///
  /// A row **defines** its id by carrying it in the row's **first inline-code
  /// span**. That single rule gives the checker one place to read and makes it
  /// impossible to define a row by accident in running prose.
  ///
  /// Throws [StateError] when the section heading is absent — a register that
  /// cannot be found would make every citation look undefined, which is a tool
  /// failure and not a corpus defect.
  static OeRegister parse(String markdown, {required String path}) {
    final lines = markdown.split('\n');
    var start = -1;
    for (var i = 0; i < lines.length; i++) {
      if (oeRegisterHeading.hasMatch(lines[i].trimRight())) {
        start = i;
        break;
      }
    }
    if (start < 0) {
      throw StateError(
        'no "## <n>. Open-Ends Register" heading found in $path — the register '
        'has been renamed, moved or removed.',
      );
    }

    final ids = <String>{};
    final duplicates = <String>[];
    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('## ')) break;
      if (!line.trimLeft().startsWith('|')) continue;
      final id = firstInlineCodeOf(line);
      if (id == null || !_isWholeOeId(id)) continue;
      if (!ids.add(id)) duplicates.add(id);
    }

    return OeRegister._(ids, path, duplicates);
  }

  /// Reads the register from the document that owns it.
  static OeRegister read(String path) =>
      parse(File(path).readAsStringSync(), path: path);
}

/// The content of the first inline-code span on [line], or `null`.
String? firstInlineCodeOf(String line) =>
    RegExp(r'`([^`\n]{1,80})`').firstMatch(line)?.group(1)?.trim();

/// True when [token] is an `OE-` id and nothing else.
bool _isWholeOeId(String token) =>
    RegExp(r'^OE-[0-9]{1,3}[a-z]?$').hasMatch(token);

/// One `OE-` citation found in one line of one file.
class OeCitation {
  const OeCitation({
    required this.id,
    required this.file,
    required this.line,
    required this.defined,
  });

  /// The id exactly as written, e.g. `OE-24a`.
  final String id;

  /// Path of the file the citation is in.
  final String file;

  /// 1-based line number.
  final int line;

  /// True when the register carries a row for [id].
  final bool defined;

  bool get isViolation => !defined;

  /// A one-line, `file:line`-prefixed description suitable for a build log.
  String describe({String? relativeTo}) {
    final where = relativeTo == null ? file : p.relative(file, from: relativeTo);
    final reason = defined
        ? 'OK'
        : 'UNDEFINED — no row in the Open-Ends Register '
            '($oeRegisterDocument) defines it; add the row, or cite the id '
            'that does';
    return '$where:$line: $id — $reason';
  }
}

/// Finds every `OE-` citation in [text].
///
/// [inRegisterDocument] suppresses the **definitions** themselves: in the
/// register's own document, the first inline-code token of a table row is what
/// creates the id, not a citation of it. Every other mention in that document —
/// including prose elsewhere in the file — is still a citation and is still
/// checked.
List<OeCitation> findOeCitations(
  String text, {
  required String path,
  required OeRegister register,
  bool inRegisterDocument = false,
}) {
  final citations = <OeCitation>[];
  final lines = text.split('\n');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final skip =
        inRegisterDocument && line.trimLeft().startsWith('|')
            ? firstInlineCodeOf(line)
            : null;

    var suppressed = skip != null && _isWholeOeId(skip);
    for (final match in oeIdPattern.allMatches(line)) {
      final id = match.group(0)!;
      if (suppressed && id == skip) {
        // Only the first occurrence is the definition; a row that cites another
        // id in its prose ("superseded with `OE-24`") is checked normally.
        suppressed = false;
        continue;
      }
      citations.add(OeCitation(
        id: id,
        file: path,
        line: i + 1,
        defined: register.defines(id),
      ));
    }
  }

  return citations;
}

/// The result of checking a whole corpus.
class OeCitationReport {
  const OeCitationReport({
    required this.citations,
    required this.fileCount,
    required this.register,
  });

  /// Every citation found, in file then line order.
  final List<OeCitation> citations;

  /// Files scanned.
  final int fileCount;

  final OeRegister register;

  List<OeCitation> get violations =>
      [for (final c in citations) if (c.isViolation) c];

  /// The distinct ids cited anywhere in the corpus.
  Set<String> get citedIds => {for (final c in citations) c.id};

  bool get isClean => violations.isEmpty && register.duplicates.isEmpty;
}

/// Scans [roots] — each a file or a folder, absolute — against [register].
OeCitationReport checkOeCitations({
  required List<String> roots,
  required OeRegister register,
}) {
  final files = <String>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (dir.existsSync()) {
      files.addAll(_scannableFilesIn(dir));
      continue;
    }
    final file = File(root);
    if (file.existsSync()) {
      files.add(file.path);
      continue;
    }
    throw ArgumentError.value(root, 'roots', 'citing root not found');
  }
  files.sort();

  final citations = <OeCitation>[];
  for (final path in files) {
    citations.addAll(findOeCitations(
      File(path).readAsStringSync(),
      path: path,
      register: register,
      inRegisterDocument: p.equals(path, register.sourcePath),
    ));
  }

  return OeCitationReport(
    citations: citations,
    fileCount: files.length,
    register: register,
  );
}

List<String> _scannableFilesIn(Directory dir) {
  final found = <String>[];
  for (final entity in dir.listSync()) {
    if (entity is Directory) {
      if (_skippedDirectories.contains(p.basename(entity.path))) continue;
      found.addAll(_scannableFilesIn(entity));
    } else if (entity is File &&
        _scannedExtensions.contains(p.extension(entity.path))) {
      found.add(entity.path);
    }
  }
  return found;
}
