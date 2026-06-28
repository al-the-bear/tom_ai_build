import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model meta-data the other emitter tests pin, reused
/// here so every emitter is exercised against an identical model covering every
/// field kind. `modelVersion` is `0` so the generated `v0` model version is the
/// clean `0.0`.
Map<String, dynamic> _fixtureJson() => {
      'modelVersion': 0,
      'roots': [
        {
          'type': 'ProjectDefinition',
          'title': 'Project Definition',
          'sectionId': 'PD00',
          'description': 'The structured project overview.',
        },
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'doc': 'Root of a project definition document.',
          'fields': [
            {
              'name': 'vision',
              'kind': 'content',
              'sectionId': 'vision',
              'contentType': 'text',
              'doc': 'Why the system exists.',
            },
            {
              'name': 'owner',
              'kind': 'form',
              'sectionId': 'owner',
              'formFields': [
                {'name': 'name', 'label': 'Name', 'type': 'String'},
                {'name': 'role', 'label': 'Role', 'type': 'String'},
              ],
            },
            {
              'name': 'risks',
              'kind': 'list',
              'sectionId': 'risks',
              'elementType': 'Risk',
              'elementIsComplex': true,
              'min': 2,
            },
            {
              'name': 'tags',
              'kind': 'list',
              'sectionId': 'tags',
              'elementType': 'String',
              'elementIsComplex': false,
            },
            {
              'name': 'situation',
              'kind': 'complex',
              'sectionId': 'situation',
              'type': 'CurrentSituation',
            },
          ],
        },
        'Risk': {
          'name': 'Risk',
          'sectionId': 'RISK',
          'fields': [
            {
              'name': 'title',
              'kind': 'content',
              'sectionId': 'title',
              'contentType': 'text',
            },
            {
              'name': 'probability',
              'kind': 'enum',
              'sectionId': 'prob',
              'enumType': 'Probability',
              'enumValues': ['low', 'medium', 'high'],
            },
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'fields': [
            {
              'name': 'summary',
              'kind': 'content',
              'sectionId': 'summary',
              'contentType': 'text',
            },
          ],
        },
      },
    };

SpecModel _fixtureModel() => SpecModel.fromJson(_fixtureJson());

/// A spec-model whose field name snake-cases onto a **C keyword** (`type`) — the
/// C-specific hazard the emitter guards against by appending a trailing
/// underscore. `match`/`move` are *not* C keywords (unlike Rust), so they stay
/// untouched; the path segments are preserved throughout.
Map<String, dynamic> _keywordJson() => {
      'modelVersion': 0,
      'roots': [
        {'type': 'Root', 'title': 'Root', 'sectionId': 'ROOT'},
      ],
      'classes': {
        'Root': {
          'name': 'Root',
          'sectionId': 'ROOT',
          'fields': [
            {
              'name': 'type',
              'kind': 'content',
              'sectionId': 'typ',
              'contentType': 'text',
            },
            {
              'name': 'int',
              'kind': 'content',
              'sectionId': 'integ',
              'contentType': 'text',
            },
            {
              'name': 'summary',
              'kind': 'content',
              'sectionId': 'sum',
              'contentType': 'text',
            },
          ],
        },
      },
    };

/// A spec-model where two distinct field names snake-case to the same accessor
/// (`my_field` and `myField` → `my_field`) — exercising the global function-name
/// de-duplication (C has a single flat function namespace).
Map<String, dynamic> _accessorCollisionJson() => {
      'modelVersion': 0,
      'roots': [
        {'type': 'Root', 'title': 'Root', 'sectionId': 'ROOT'},
      ],
      'classes': {
        'Root': {
          'name': 'Root',
          'sectionId': 'ROOT',
          'fields': [
            {
              'name': 'my_field',
              'kind': 'content',
              'sectionId': 'mf1',
              'contentType': 'text',
            },
            {
              'name': 'myField',
              'kind': 'content',
              'sectionId': 'mf2',
              'contentType': 'text',
            },
          ],
        },
      },
    };

/// A spec-model where two distinct (class, form-field) pairs derive the same
/// generated form-struct name, identical to the other emitters' collision case.
Map<String, dynamic> _formCollisionJson() => {
      'modelVersion': 0,
      'roots': [
        {'type': 'Root', 'title': 'Root', 'sectionId': 'ROOT'},
      ],
      'classes': {
        'Root': {
          'name': 'Root',
          'sectionId': 'ROOT',
          'fields': [
            {
              'name': 'a',
              'kind': 'complex',
              'sectionId': 'a',
              'type': 'MigrationRisks',
            },
            {
              'name': 'b',
              'kind': 'complex',
              'sectionId': 'b',
              'type': 'MigrationRisksGovernance',
            },
          ],
        },
        'MigrationRisks': {
          'name': 'MigrationRisks',
          'sectionId': 'MR00',
          'fields': [
            {
              'name': 'governanceContent',
              'kind': 'form',
              'sectionId': 'gc',
              'formFields': [
                {'name': 'model', 'label': 'Model', 'type': 'String'},
              ],
            },
          ],
        },
        'MigrationRisksGovernance': {
          'name': 'MigrationRisksGovernance',
          'sectionId': 'MRG0',
          'fields': [
            {
              'name': 'content',
              'kind': 'form',
              'sectionId': 'c',
              'formFields': [
                {'name': 'escalation', 'label': 'Escalation', 'type': 'String'},
              ],
            },
          ],
        },
      },
    };

/// Locates a `gcc` (or `cc`) toolchain on PATH. Returns `null` when none.
String? _cc() {
  for (final cand in ['gcc', 'cc', 'clang']) {
    try {
      final r = Process.runSync(cand, ['--version']);
      if (r.exitCode == 0) return cand;
    } on ProcessException {
      // not on PATH — try the next candidate
    }
  }
  return null;
}

/// The `tom_som_c_runtime` dir, relative to the clitool root the test runs from,
/// or `null` when it cannot be located.
String? _runtimeDir() {
  final candidate = p.normalize(
      p.join(Directory.current.path, '..', 'tom_som_c_runtime'));
  return Directory(p.join(candidate, 'include')).existsSync()
      ? candidate
      : null;
}

/// Compiles the generated [header] + [source] as a `tom_som_c_v0` translation
/// unit against the local runtime headers, asserting the compile succeeds. A
/// no-op (with a skip note) when the toolchain or runtime cannot be located.
void _expectCBuilds(String header, String source) {
  final cc = _cc();
  if (cc == null) {
    markTestSkipped('no C compiler (gcc/cc/clang) found');
    return;
  }
  final runtimeDir = _runtimeDir();
  if (runtimeDir == null) {
    markTestSkipped('tom_som_c_runtime not found');
    return;
  }
  final dir = Directory.systemTemp.createTempSync('som_c_emit_');
  try {
    File(p.join(dir.path, 'tom_som_c_v0.h')).writeAsStringSync(header);
    File(p.join(dir.path, 'tom_som_c_v0.c')).writeAsStringSync(source);
    final runtimeInclude = p.join(runtimeDir, 'include');
    final build = Process.runSync(cc, [
      '-std=c11',
      '-Wall',
      '-Wextra',
      '-Werror',
      '-c',
      '-I',
      dir.path,
      '-I',
      runtimeInclude,
      p.join(dir.path, 'tom_som_c_v0.c'),
      '-o',
      p.join(dir.path, 'tom_som_c_v0.o'),
    ]);
    expect(build.exitCode, 0,
        reason: 'C compile failed:\n${build.stdout}\n${build.stderr}');
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void main() {
  final goldenDir = p.join(Directory.current.path, 'test', 'golden');
  final headerGolden = p.join(goldenDir, 'som_c_v0_fixture.h.golden');
  final sourceGolden = p.join(goldenDir, 'som_c_v0_fixture.c.golden');

  void maybeWriteGolden(String path, String content) {
    if (Platform.environment['UPDATE_GOLDEN'] == '1') {
      final f = File(path);
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(content);
    }
  }

  group('SomCEmitter', () {
    test('emitted header matches the committed golden file', () {
      final header = SomCEmitter(_fixtureModel()).generateHeader();
      maybeWriteGolden(headerGolden, header);
      final golden = File(headerGolden);
      expect(golden.existsSync(), isTrue,
          reason: 'run with UPDATE_GOLDEN=1 to create the golden file');
      expect(header, golden.readAsStringSync());
    });

    test('emitted source matches the committed golden file', () {
      final source = SomCEmitter(_fixtureModel()).generateSource();
      maybeWriteGolden(sourceGolden, source);
      final golden = File(sourceGolden);
      expect(golden.existsSync(), isTrue,
          reason: 'run with UPDATE_GOLDEN=1 to create the golden file');
      expect(source, golden.readAsStringSync());
    });

    test('the generated translation unit compiles clean against the runtime',
        () {
      final emitter = SomCEmitter(_fixtureModel());
      _expectCBuilds(emitter.generateHeader(), emitter.generateSource());
    });

    test('struct typedef declarations are unique', () {
      final header = SomCEmitter(_fixtureModel()).generateHeader();
      final names = RegExp(r'^typedef struct \{ SomNode node; \} (\w+);',
              multiLine: true)
          .allMatches(header)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final n in names) {
        if (!seen.add(n)) dupes.add(n);
      }
      expect(dupes, isEmpty, reason: 'duplicate typedef declarations: $dupes');
    });

    test('every function declaration name is globally unique', () {
      final header = SomCEmitter(_fixtureModel()).generateHeader();
      // Function declarations are the non-typedef, non-#define lines ending `);`.
      final decls = RegExp(r'^[A-Za-z_].*\b(\w+)\(.*\);$', multiLine: true)
          .allMatches(header)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final n in decls) {
        if (!seen.add(n)) dupes.add(n);
      }
      expect(dupes, isEmpty, reason: 'duplicate function names: $dupes');
    });

    test('a typed mutation is visible through the generic path and vice-versa',
        () {
      // Mirror the generated facade's path derivation against a live document —
      // the behavioural contract the C facade encodes (pure-Dart variant).
      final doc = SpecDocument();
      final ref = SpecReflection(_fixtureModel());
      final root = ref.model.roots.single;
      final rootSeg = ref.rootSegment(root);

      doc.setContent('$rootSeg/vision', 'A clear vision');
      expect(doc.content('$rootSeg/vision'), 'A clear vision');

      final itemPath = doc.addListItem('$rootSeg/risks');
      doc.setContent('$itemPath/title', 'Schedule slip');
      expect(doc.listItemCount('$rootSeg/risks'), 1);
      expect(doc.content('${doc.listItems('$rootSeg/risks').single}/title'),
          'Schedule slip');
    });

    test('the model-version accessor returns the generated v0 version', () {
      final emitter = SomCEmitter(_fixtureModel());
      expect(emitter.modelVersionString, '0.0');
      // The generated header pins the same value as a #define.
      expect(emitter.generateHeader(),
          contains('#define PROJECT_DEFINITION_MODEL_VERSION "0.0"'));
    });

    test('v1 label yields major 1', () {
      final emitter = SomCEmitter(_fixtureModel(), versionLabel: 'v1');
      expect(emitter.modelVersionString, '1.0');
    });

    test('C-keyword field names gain a trailing underscore, '
        'but path segments are preserved', () {
      final emitter = SomCEmitter(SpecModel.fromJson(_keywordJson()));
      final header = emitter.generateHeader();
      final source = emitter.generateSource();
      // Field `int` → accessor `root_int_` (`int` is a C keyword); path segment
      // `integ` is untouched.
      expect(header, contains('char *root_int_(const Root *self);'));
      expect(header,
          contains('void root_set_int_(Root *self, const char *value);'));
      expect(source, contains('"integ"'));
      // `type` is *not* a C keyword (unlike Rust), so it stays untouched.
      expect(header, contains('char *root_type(const Root *self);'));
      expect(source, contains('"typ"'));
      // A plain field is untouched.
      expect(header, contains('char *root_summary(const Root *self);'));
    });

    test('accessors colliding under snake-casing are de-duplicated', () {
      final emitter = SomCEmitter(SpecModel.fromJson(_accessorCollisionJson()));
      final header = emitter.generateHeader();
      final source = emitter.generateSource();
      // `my_field` and `myField` both snake-case to `root_my_field`; the second
      // gets a numeric suffix so the two getters never collide.
      expect(header, contains('char *root_my_field(const Root *self);'));
      expect(header, contains('char *root_my_field_2(const Root *self);'));
      // Both stored segments are preserved verbatim.
      expect(source, contains('"mf1"'));
      expect(source, contains('"mf2"'));
    });

    test('enum tokens are preserved as #define constants', () {
      final header = SomCEmitter(_fixtureModel()).generateHeader();
      // Token stays byte-identical; only the macro identifier is derived.
      expect(header, contains('#define PROBABILITY_LOW "low"'));
      expect(header, contains('#define PROBABILITY_MEDIUM "medium"'));
      expect(header, contains('#define PROBABILITY_HIGH "high"'));
      expect(header, contains('char *parse_probability(const char *token);'));
    });

    test('colliding form-struct names are disambiguated (no duplicates)', () {
      final header =
          SomCEmitter(SpecModel.fromJson(_formCollisionJson())).generateHeader();
      final decls = RegExp(r'typedef struct \{ SomNode node; \} (\w+);',
              multiLine: true)
          .allMatches(header)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final name in decls) {
        if (!seen.add(name)) dupes.add(name);
      }
      expect(dupes, isEmpty, reason: 'duplicate typedef declarations: $dupes');
      expect(header,
          contains('typedef struct { SomNode node; } '
              'MigrationRisksGovernanceContentForm;'));
      expect(header,
          contains('typedef struct { SomNode node; } '
              'MigrationRisksGovernanceContentForm_2;'));
    });

    test('documentRoots subsets the generated structs', () {
      final all = SomCEmitter(_fixtureModel()).generateHeader();
      expect(all,
          contains('typedef struct { SomNode node; } CurrentSituation;'));

      final justRoot = SomCEmitter(_fixtureModel(),
              documentRoots: ['ProjectDefinition'])
          .generateHeader();
      expect(justRoot,
          contains('typedef struct { SomNode node; } CurrentSituation;'));
    });
  });
}
