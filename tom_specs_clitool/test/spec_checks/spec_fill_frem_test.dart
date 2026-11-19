// Tests of `tomspecs :spec-fill-frem` (lib/src/spec_checks_cli.dart over the
// runtime's planFremFill): every functional requirement's FREM is filled with
// the document revision of the git revision that last changed it.
//
// The sample is the shipped Meridian Solution Blueprint
// (tom_som_dart_v0/documents/), given revision entries and requirement changes
// commit by commit in a scratch git repository under the workspace's ztmp/.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_specs_clitool/src/spec_checks_cli.dart';

const _meridian =
    '../tom_som_dart_v0/documents/meridian_order_management.tomspecs.yaml';
const _revisions = 'SBP/documentControl/RVENT-REVS-LST';
const _requirements =
    'SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST';

final SomMetaTree _tree = buildSomMetaTree(
  somSpecModel,
  rootType: 'D00SolutionBlueprint',
);

/// A sink collecting what a run writes.
class _Sink implements IOSink {
  final _buffer = StringBuffer();
  String get text => _buffer.toString();
  @override
  Encoding encoding = utf8;
  @override
  void write(Object? object) => _buffer.write(object);
  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);
  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      _buffer.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _buffer.writeCharCode(charCode);
  @override
  void add(List<int> data) => _buffer.write(utf8.decode(data));
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> get done async {}
  @override
  Future<void> flush() async {}
}

/// One run of the command.
class _Run {
  _Run(List<String> args) {
    code = runSpecChecks(['fill-frem', ...args], out: _out, err: _err);
  }
  final _out = _Sink(), _err = _Sink();
  late final int code;
  String get out => _out.text;
  String get err => _err.text;
}

/// The document as decoded, with helpers to change it.
class _Doc {
  _Doc(String text) : contents = SpecDocumentYaml.decode(text, _tree);
  final SpecYamlContents contents;
  SpecDocument get doc => contents.document;

  String item(String id) => doc
      .listItems(_requirements)
      .firstWhere((i) => doc.itemSectionId(i) == id);

  void addRevision(String id, String version, String date, String author) {
    final item = doc.addListItem(_revisions, sectionId: id);
    doc
      ..setFormField('$item/content', 'version', version)
      ..setFormField('$item/content', 'date', date)
      ..setFormField('$item/content', 'author', author);
  }

  void retitle(String id, String headline) =>
      doc.setHeadline(item(id), headline);

  List<String?> frem(String id) => [
    for (final f in ['version', 'lastModified', 'modifiedBy'])
      doc.formField('${item(id)}/FREM', f),
  ];

  String get text => SpecDocumentYaml.encode(
    document: doc,
    tree: _tree,
    modelVersion: contents.modelVersion,
    review: contents.review,
  );
}

void main() {
  late Directory repo;
  late String path;

  String git(List<String> args) {
    final r = Process.runSync('git', args, workingDirectory: repo.path);
    if (r.exitCode != 0) fail('git ${args.join(' ')}: ${r.stderr}');
    return '${r.stdout}'.trim();
  }

  /// Writes [text] and commits it; returns the commit.
  String commit(String text, String message) {
    File(path).writeAsStringSync(text);
    git(['add', 'sbp.tomspecs.yaml']);
    git(['commit', '-q', '-m', message]);
    return git(['rev-parse', 'HEAD']);
  }

  _Doc current() => _Doc(File(path).readAsStringSync());

  setUp(() {
    final scratch = Directory('../../../ztmp')..createSync(recursive: true);
    repo = scratch.createTempSync('tom_specs_clitool_fill_frem_');
    path = '${repo.path}/sbp.tomspecs.yaml';
    git(['init', '-q']);
    git(['config', 'user.email', 'test@example.invalid']);
    git(['config', 'user.name', 'Test']);
    git(['config', 'commit.gpgsign', 'false']);
  });
  tearDown(() => repo.deleteSync(recursive: true));

  /// Revision 0.1 (the document as shipped) and 0.2 (order capture changed).
  void twoRevisions() {
    final d = _Doc(File(_meridian).readAsStringSync())
      ..addRevision('RVENT-REVS-ONE', '0.1', '2026-01-01', 'Alice');
    commit(d.text, 'one');
    d
      ..retitle('FRE-REQU-ORDER-CAPTURE', 'Order capture, revised')
      ..addRevision('RVENT-REVS-TWO', '0.2', '2026-02-01', 'Bob');
    commit(d.text, 'two');
  }

  test('FF-1 each requirement gets the revision that last changed it', () {
    twoRevisions();
    final r = _Run([path]);
    expect(r.code, 0, reason: r.out + r.err);
    final d = current();
    expect(d.frem('FRE-REQU-ORDER-CAPTURE'), ['0.2', '2026-02-01', 'Bob']);
    expect(d.frem('FRE-REQU-SYNC-PRICING'), ['0.1', '2026-01-01', 'Alice']);
    expect(d.frem('FRE-REQU-HOLD-RELEASE'), ['0.1', '2026-01-01', 'Alice']);
    expect(r.out, contains('FREM      FRE-REQU-ORDER-CAPTURE  0.2 2026-02-01'));
    expect(r.out, contains('(re-encoded)'));
    expect(r.out, contains('written   $path'));
    expect(File('$path.fill-frem.stage').existsSync(), isFalse);
  });

  test('FF-2 a fill changes no other value and runs again as a no-op', () {
    twoRevisions();
    final before = current();
    expect(_Run([path]).code, 0);
    final after = current();
    for (final item in before.doc.listItems(_requirements)) {
      for (final f in ['version', 'lastModified', 'modifiedBy']) {
        before.doc.setFormField(
          '$item/FREM',
          f,
          after.doc.formField('$item/FREM', f)!,
        );
      }
    }
    expect(
      jsonEncode(after.doc.toJson()),
      jsonEncode(before.doc.toJson()),
      reason: 'only FREM values differ',
    );
    final filled = File(path).readAsStringSync();
    final again = _Run([path]);
    expect(again.code, 0, reason: again.out + again.err);
    expect(again.out, contains('0 to change'));
    expect(again.out, isNot(contains('REVISION')));
    expect(File(path).readAsStringSync(), filled);
  });

  test('FF-3 uncommitted changes are the working tree revision, in place', () {
    twoRevisions();
    expect(_Run([path]).code, 0);
    final d = current()
      ..addRevision('RVENT-REVS-THREE', '0.3', '2026-03-01', 'Carol');
    commit(d.text, 'three: the fill');
    final committed = File(path).readAsStringSync();
    d
      ..retitle('FRE-REQU-SYNC-PRICING', 'Pricing sync, revised')
      ..addRevision('RVENT-REVS-FOUR', '0.4', '2026-04-01', 'Dan');
    File(path).writeAsStringSync(d.text);
    final edited = File(path).readAsStringSync();
    final r = _Run([path]);
    expect(r.code, 0, reason: r.out + r.err);
    expect(r.out, contains('(in place)'));
    expect(r.out, contains('(RVENT-REVS-FOUR, working tree)'));
    final after = current();
    expect(after.frem('FRE-REQU-SYNC-PRICING'), ['0.4', '2026-04-01', 'Dan']);
    expect(after.frem('FRE-REQU-ORDER-CAPTURE'), ['0.2', '2026-02-01', 'Bob']);
    // In place: only the three value lines of the one requirement change.
    final a = edited.split('\n'), b = File(path).readAsStringSync().split('\n');
    expect(b.length, a.length);
    final changed = [
      for (var i = 0; i < a.length; i++)
        if (a[i] != b[i]) b[i].trim(),
    ];
    expect(changed, ['0.4', '2026-04-01', 'Dan']);
    expect(committed, isNot(edited));
  });

  test('FF-4 a commit without a revision entry of its own is a finding', () {
    twoRevisions();
    final d = current()..retitle('FRE-REQU-HOLD-RELEASE', 'Hold, revised');
    final third = commit(d.text, 'three, no revision entry');
    final r = _Run([path]);
    expect(r.code, 1);
    expect(
      r.out,
      contains(
        'REVISION  ${third.substring(0, 8)} changed the document without a '
        'revision entry of its own; its changes are attributed to '
        'RVENT-REVS-TWO',
      ),
    );
    expect(current().frem('FRE-REQU-HOLD-RELEASE'), [
      '0.2',
      '2026-02-01',
      'Bob',
    ]);
  });

  test('FF-5 --dry-run writes nothing; --rendition writes the rendition', () {
    twoRevisions();
    final text = File(path).readAsStringSync();
    final dry = _Run(['--dry-run', path]);
    expect(dry.code, 0);
    expect(dry.out, contains('dry run   nothing written'));
    expect(File(path).readAsStringSync(), text);
    final md = '${repo.path}/sbp.tomspecs.md';
    final r = _Run(['--rendition', md, path]);
    expect(r.code, 0);
    expect(File(md).readAsStringSync(), contains('Bob'));
  });

  test('FF-6 a file outside git is a usage error', () {
    final outside =
        '${repo.path}/../${repo.uri.pathSegments.where((s) => s.isNotEmpty).last}.yaml';
    File(_meridian).copySync(outside);
    addTearDown(() => File(outside).deleteSync());
    final r = _Run([outside]);
    expect(r.code, 2);
    expect(r.err, contains('usage: tomspecs :spec-fill-frem'));
  });
}
