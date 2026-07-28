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
          'type': 'SolutionBlueprint',
          'title': 'Project Definition',
          'sectionId': 'PD00',
          'description': 'The structured project overview.',
        },
      ],
      'classes': {
        'SolutionBlueprint': {
          'name': 'SolutionBlueprint',
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
              'sectionIdPattern': 'RISK-ITEM-xxx',
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
              'type': 'CurrentLandscapeAssessment',
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
        'CurrentLandscapeAssessment': {
          'name': 'CurrentLandscapeAssessment',
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

/// [_fixtureJson] plus a **second** document root, so an assertion about the
/// generated root registry (SOM §8) proves it carries one entry *per root*
/// rather than a single hard-wired one.
Map<String, dynamic> _twoRootJson() {
  final json = _fixtureJson();
  (json['roots'] as List)
      .add({'type': 'Aux', 'title': 'Aux', 'sectionId': 'AX00'});
  (json['classes'] as Map<String, dynamic>)['Aux'] = {
    'name': 'Aux',
    'sectionId': 'AX00',
    'fields': [
      {
        'name': 'note',
        'kind': 'content',
        'sectionId': 'note',
        'contentType': 'text',
      },
    ],
  };
  return json;
}

/// A spec-model whose field name is a **C++ keyword** (`int`) — the hazard the
/// emitter guards against by appending a trailing underscore to the member-
/// function accessor. `type` is *not* a C++ keyword (unlike C's typedef-free
/// world it still isn't reserved), so it stays untouched; the stored path
/// segments are preserved throughout.
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

/// A spec-model where two distinct (class, form-field) pairs derive the same
/// generated form-class name, identical to the other emitters' collision case.
/// C++ scopes member functions per class, so accessor names never need global
/// de-duplication — only the generated **type names** (form classes) do.
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

/// A spec-model whose fields are named `doc` / `path` — the C++-specific hazard
/// where a generated getter would shadow the inherited `som::SomNode::doc()` /
/// `path()` and (since the body calls them) recurse infinitely. The emitter
/// reserves them with a trailing underscore. A form field named `path` is the
/// same hazard on the form facade.
Map<String, dynamic> _shadowJson() => {
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
              'name': 'path',
              'kind': 'content',
              'sectionId': 'pth',
              'contentType': 'text',
            },
            {
              'name': 'doc',
              'kind': 'content',
              'sectionId': 'dc',
              'contentType': 'text',
            },
            {
              'name': 'endpoint',
              'kind': 'form',
              'sectionId': 'ep',
              'formFields': [
                {'name': 'path', 'label': 'Path', 'type': 'String'},
              ],
            },
          ],
        },
      },
    };

/// Locates a `g++` (or `clang++`/`c++`) toolchain on PATH. Returns `null` when
/// none.
String? _cxx() {
  for (final cand in ['g++', 'c++', 'clang++']) {
    try {
      final r = Process.runSync(cand, ['--version']);
      if (r.exitCode == 0) return cand;
    } on ProcessException {
      // not on PATH — try the next candidate
    }
  }
  return null;
}

/// The `tom_som_cpp_runtime` dir, relative to the clitool root the test runs
/// from, or `null` when it cannot be located.
String? _runtimeDir() {
  final candidate = p.normalize(
      p.join(Directory.current.path, '..', 'tom_som_cpp_runtime'));
  return Directory(p.join(candidate, 'include')).existsSync()
      ? candidate
      : null;
}

/// Compiles the generated facade [header] + [source] as a `tom_som_cpp_v0`
/// translation unit against the local runtime headers, asserting the compile
/// succeeds. The facade source now `#include`s the generated metadata module and
/// its load functions reference `tom_som_v0_meta::<root>MetaTree()`, so the meta
/// module header (and, when [metaEmitter] is supplied, its source) is emitted
/// alongside the facade so the reference resolves. A no-op (with a skip note)
/// when the toolchain or runtime cannot be located.
void _expectCppBuilds(String header, String source,
    {SomCppMetaEmitter? metaEmitter}) {
  final cxx = _cxx();
  if (cxx == null) {
    markTestSkipped('no C++ compiler (g++/c++/clang++) found');
    return;
  }
  final runtimeDir = _runtimeDir();
  if (runtimeDir == null) {
    markTestSkipped('tom_som_cpp_runtime not found');
    return;
  }
  final dir = Directory.systemTemp.createTempSync('som_cpp_emit_');
  try {
    File(p.join(dir.path, 'tom_som_cpp_v0.hpp')).writeAsStringSync(header);
    File(p.join(dir.path, 'tom_som_cpp_v0.cpp')).writeAsStringSync(source);
    // The facade source #includes the meta module header (its load functions
    // thread the per-root tree from it). Always emit the header; emit the meta
    // source too when the caller wants the symbols to link.
    final meta = metaEmitter;
    File(p.join(dir.path, 'tom_som_cpp_v0_meta.hpp'))
        .writeAsStringSync(meta?.generateHeader() ?? _metaHeaderFor(source));
    final runtimeInclude = p.join(runtimeDir, 'include');
    final build = Process.runSync(cxx, [
      '-std=c++17',
      '-Wall',
      '-Wextra',
      '-Werror',
      '-c',
      '-I',
      dir.path,
      '-I',
      runtimeInclude,
      p.join(dir.path, 'tom_som_cpp_v0.cpp'),
      '-o',
      p.join(dir.path, 'tom_som_cpp_v0.o'),
    ]);
    expect(build.exitCode, 0,
        reason: 'C++ facade compile failed:\n${build.stdout}\n${build.stderr}');
    if (meta != null) {
      File(p.join(dir.path, 'tom_som_cpp_v0_meta.cpp'))
          .writeAsStringSync(meta.generateSource());
      final metaBuild = Process.runSync(cxx, [
        '-std=c++17',
        '-Wall',
        '-Wextra',
        '-Werror',
        '-c',
        '-I',
        dir.path,
        '-I',
        runtimeInclude,
        p.join(dir.path, 'tom_som_cpp_v0_meta.cpp'),
        '-o',
        p.join(dir.path, 'tom_som_cpp_v0_meta.o'),
      ]);
      expect(metaBuild.exitCode, 0,
          reason:
              'C++ meta compile failed:\n${metaBuild.stdout}\n${metaBuild.stderr}');
    }
  } finally {
    dir.deleteSync(recursive: true);
  }
}

/// Derives a minimal stand-in meta-module header declaring just the tree
/// accessor(s) the facade [source] references (its load functions call
/// `tom_som_v0_meta::<camel>MetaTree()`), so a facade-only compile test (no
/// [SomCppMetaEmitter] supplied) still resolves the declaration without emitting
/// the whole metadata module.
String _metaHeaderFor(String source) {
  final fns = RegExp(r'tom_som_v0_meta::(\w+MetaTree)\(\)')
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
  final b = StringBuffer()
    ..writeln('#ifndef TOM_SOM_CPP_V0_META_HPP')
    ..writeln('#define TOM_SOM_CPP_V0_META_HPP')
    ..writeln('#include "tom_som_cpp_runtime.hpp"')
    ..writeln('namespace tom_som_v0_meta {');
  for (final fn in fns) {
    b.writeln('const som::SomMetaTree& $fn();');
  }
  b
    ..writeln('}  // namespace tom_som_v0_meta')
    ..writeln('#endif  // TOM_SOM_CPP_V0_META_HPP');
  return b.toString();
}

void main() {
  final goldenDir = p.join(Directory.current.path, 'test', 'golden');
  final headerGolden = p.join(goldenDir, 'som_cpp_v0_fixture.hpp.golden');
  final sourceGolden = p.join(goldenDir, 'som_cpp_v0_fixture.cpp.golden');

  void maybeWriteGolden(String path, String content) {
    if (Platform.environment['UPDATE_GOLDEN'] == '1') {
      final f = File(path);
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(content);
    }
  }

  group('SomCppEmitter', () {
    test('emitted header matches the committed golden file', () {
      final header = SomCppEmitter(_fixtureModel()).generateHeader();
      maybeWriteGolden(headerGolden, header);
      final golden = File(headerGolden);
      expect(golden.existsSync(), isTrue,
          reason: 'run with UPDATE_GOLDEN=1 to create the golden file');
      expect(header, golden.readAsStringSync());
    });

    test('emitted source matches the committed golden file', () {
      final source = SomCppEmitter(_fixtureModel()).generateSource();
      maybeWriteGolden(sourceGolden, source);
      final golden = File(sourceGolden);
      expect(golden.existsSync(), isTrue,
          reason: 'run with UPDATE_GOLDEN=1 to create the golden file');
      expect(source, golden.readAsStringSync());
    });

    test('the generated translation unit compiles clean against the runtime',
        () {
      final emitter = SomCppEmitter(_fixtureModel());
      _expectCppBuilds(emitter.generateHeader(), emitter.generateSource());
    });

    test('forward class declarations are unique', () {
      final header = SomCppEmitter(_fixtureModel()).generateHeader();
      final names = RegExp(r'^class (\w+);', multiLine: true)
          .allMatches(header)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final n in names) {
        if (!seen.add(n)) dupes.add(n);
      }
      expect(dupes, isEmpty, reason: 'duplicate class declarations: $dupes');
    });

    test('a typed mutation is visible through the generic path and vice-versa',
        () {
      // Mirror the generated facade's path derivation against a live document —
      // the behavioural contract the C++ facade encodes (pure-Dart variant).
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
      final emitter = SomCppEmitter(_fixtureModel());
      expect(emitter.modelVersionString, '0.0');
      // The generated root class pins the same value as a constexpr constant.
      expect(emitter.generateHeader(),
          contains('static constexpr const char* kModelVersion = "0.0";'));
    });

    test('the model version comes from the model stamp, not the version label',
        () {
      // A stamped model reports its real major.minor (SOM §4.2) regardless of
      // the project version label — the label only names the output project.
      final stamped = SpecModel.fromJson({
        ..._fixtureJson(),
        'modelVersion': 1,
        'modelVersionLabel': '1.3.0+7.abc1234',
      });
      expect(
          SomCppEmitter(stamped, versionLabel: 'v0').modelVersionString, '1.3');
      expect(
          SomCppEmitter(stamped, versionLabel: 'v9').modelVersionString, '1.3');
    });

    test('C++-keyword field names gain a trailing underscore, '
        'but path segments are preserved', () {
      final emitter = SomCppEmitter(SpecModel.fromJson(_keywordJson()));
      final header = emitter.generateHeader();
      final source = emitter.generateSource();
      // Field `int` → accessor `int_()` (`int` is a C++ keyword); the setter is
      // `set` + Pascal(name) so it is keyword-safe by construction.
      expect(header, contains('std::string int_() const;'));
      expect(header, contains('void setInt(const std::string& value);'));
      expect(source, contains('"integ"'));
      // `type` is *not* a C++ keyword, so it stays untouched.
      expect(header, contains('std::string type() const;'));
      expect(header, contains('void setType(const std::string& value);'));
      expect(source, contains('"typ"'));
      // A plain field is untouched.
      expect(header, contains('std::string summary() const;'));
    });

    test('enum tokens are preserved as constexpr constants', () {
      final header = SomCppEmitter(_fixtureModel()).generateHeader();
      // Token stays byte-identical; only the member identifier is derived.
      expect(header,
          contains('static constexpr const char* low = "low";'));
      expect(header,
          contains('static constexpr const char* medium = "medium";'));
      expect(header,
          contains('static constexpr const char* high = "high";'));
      // Enum struct + parse declaration.
      expect(header, contains('struct Probability {'));
      expect(
          header,
          contains('static std::optional<std::string> parse('
              'const std::string& token);'));
    });

    test('enum-typed field accessors return std::optional', () {
      final header = SomCppEmitter(_fixtureModel()).generateHeader();
      expect(
          header, contains('std::optional<std::string> probability() const;'));
    });

    test('colliding form-class names are disambiguated (no duplicates)', () {
      final header = SomCppEmitter(SpecModel.fromJson(_formCollisionJson()))
          .generateHeader();
      final decls = RegExp(r'^class (\w+);', multiLine: true)
          .allMatches(header)
          .map((m) => m.group(1)!)
          .toList();
      final seen = <String>{};
      final dupes = <String>[];
      for (final name in decls) {
        if (!seen.add(name)) dupes.add(name);
      }
      expect(dupes, isEmpty, reason: 'duplicate class declarations: $dupes');
      expect(
          header, contains('class MigrationRisksGovernanceContentForm;'));
      expect(
          header, contains('class MigrationRisksGovernanceContentForm2;'));
    });

    test('fields named doc/path do not shadow the SomNode base accessors', () {
      final emitter = SomCppEmitter(SpecModel.fromJson(_shadowJson()));
      final header = emitter.generateHeader();
      final source = emitter.generateSource();
      // The class getters are reserved with a trailing underscore so the
      // inherited som::SomNode::doc()/path() stay reachable.
      expect(header, contains('std::string path_() const;'));
      expect(header, contains('std::string doc_() const;'));
      // The form getter named `path` is reserved the same way; its body calls
      // the inherited path()/doc() (no recursion).
      expect(header, contains('std::string path_() const;'));
      // Setters use set + Pascal(name) so they are unaffected.
      expect(header, contains('void setPath(const std::string& value);'));
      expect(header, contains('void setDoc(const std::string& value);'));
      // Stored segments / form-field keys stay byte-identical.
      expect(source, contains('"pth"'));
      expect(source, contains('"dc"'));
      expect(source, contains('formField(path(), "path")'));
      // The generated translation unit must compile (the recursion bug was a
      // compile-time -Winfinite-recursion under -Werror).
      _expectCppBuilds(header, source);
    });

    test('a pattern-bearing list emits its @SectionIdPattern; a scalar list '
        'does not (AA1 criteria 3–5)', () {
      final source = SomCppEmitter(_fixtureModel()).generateSource();
      // The complex `risks` list carries a pattern → SomList is constructed with
      // the trailing pattern argument so the facade can generate ids.
      expect(
          RegExp(r'som::SomList SolutionBlueprint::risks\(\) const \{[\s\S]*?'
                  r'return som::SomList\(doc\(\), [\s\S]*?'
                  r'"RISK-ITEM-xxx"\);')
              .hasMatch(source),
          isTrue,
          reason: 'risks getter must pass the pattern to som::SomList');
      // The pattern-less scalar `tags` list must pass an empty pattern string.
      final tagsBody = RegExp(
              r'som::SomList SolutionBlueprint::tags\(\) const \{[\s\S]*?'
              r'return som::SomList\(doc\(\), [\s\S]*?, ""\);')
          .firstMatch(source);
      expect(tagsBody, isNotNull,
          reason: 'scalar tags list must pass an empty pattern string');
      expect(tagsBody!.group(0)!, isNot(contains('RISK-ITEM-xxx')));
    });

    test('documentRoots subsets the generated classes', () {
      final all = SomCppEmitter(_fixtureModel()).generateHeader();
      expect(all, contains('class CurrentLandscapeAssessment : public som::SomNode {'));

      final justRoot = SomCppEmitter(_fixtureModel(),
              documentRoots: ['SolutionBlueprint'])
          .generateHeader();
      // CurrentLandscapeAssessment is reachable from SolutionBlueprint, so it stays.
      expect(justRoot,
          contains('class CurrentLandscapeAssessment : public som::SomNode {'));
    });

    test('no flat path-constant holder is emitted (SOM §8)', () {
      // Path addressing lives solely in the generated metadata module's
      // populated trees + dot-notation / ID-tree access surfaces. No
      // `<Code>Paths` constexpr holder struct and no path constant may leak
      // into the facade header.
      final header = SomCppEmitter(_fixtureModel()).generateHeader();
      expect(header, isNot(contains('struct Pd00Paths')),
          reason: 'no `<Code>Paths` holder struct may be emitted');
      expect(header, isNot(contains('Paths {')),
          reason: 'no `<Code>Paths` holder may remain');
      expect(header, isNot(contains('= "PD00/')),
          reason: 'no flat path constants may remain');
    });

    test('the facade threads the metadata module into its load functions '
        '(SOM §8)', () {
      final emitter = SomCppEmitter(_fixtureModel());
      final source = emitter.generateSource();
      // The source pulls in the generated metadata module …
      expect(source, contains('#include "tom_som_cpp_v0_meta.hpp"'));
      // … and loadYaml/loadFile thread the per-root tree from it into the
      // generic runtime decoder (the root type SolutionBlueprint → camel
      // `solutionBlueprint`).
      expect(
          source,
          contains('som::SpecDocument::fromYaml(yaml, '
              'tom_som_v0_meta::solutionBlueprintMetaTree(), &err)'));
      expect(
          source,
          contains('som::SpecDocument::fromFile(path, '
              'tom_som_v0_meta::solutionBlueprintMetaTree(), &err)'));
      // The facade + meta module compile and link together (the threaded
      // tree accessor is defined by the generated meta module).
      _expectCppBuilds(emitter.generateHeader(), source,
          metaEmitter: SomCppMetaEmitter(_fixtureModel()));
    });
    // The nine v0 meta-agreement suites read their root set from this
    // registry instead of hand-listing it, so an emitter that drops it
    // silently un-gates fourteen roots in nine languages at once.
    test('the document-root registry carries one entry per root (SOM §8)',
        () {
      final all = SomCppMetaEmitter(SpecModel.fromJson(_twoRootJson()))
          .generateSource();
      expect(all, contains('"SolutionBlueprint",'));
      expect(all, contains('&solutionBlueprintMetaTree(),'));
      expect(all, contains('solutionBlueprintMetaNav(solutionBlueprintMetaTree()).ref,'));
      expect(all, contains('"Aux",'));
      expect(all, contains('auxMetaId(auxMetaTree()).ref,'));

      final subset = SomCppMetaEmitter(SpecModel.fromJson(_twoRootJson()),
              documentRoots: ['SolutionBlueprint'])
          .generateSource();
      expect(subset, isNot(contains('&auxMetaTree(),')));
    });
  });
}
