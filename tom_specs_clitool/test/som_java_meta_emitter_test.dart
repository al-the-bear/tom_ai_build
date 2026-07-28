import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The same hand-built spec-model the Dart/Python/JavaScript/TypeScript/Go
/// meta-emitter tests pin — every field kind **plus recursion**
/// (`Risk.mitigation: Risk`) and an id-less section (`details`) so the
/// ID-tree hoisting rule is exercised.
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
            {
              // Id-less section: the ID-tree hoists through it (its target's
              // id-bearing fields surface at the root, path-prefixed).
              'name': 'details',
              'kind': 'section',
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
            {
              // Recursive: Risk inside Risk — becomes a terminal re-entry.
              'name': 'mitigation',
              'kind': 'complex',
              'sectionId': 'mitigation',
              'type': 'Risk',
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

/// The functional agreement program run against the generated module: it
/// compares the generated tree against `SomMetaBridge.buildSomMetaTree`
/// (field for field via `SpecMetaDiff.somMetaNodeDiff`) and asserts the
/// dot-notation and ID-tree surfaces agree — the Java port of the Go
/// meta-emitter check program. It lives in the generated module's own
/// `tom_som_java_v0` package, prints `OK` on success and exits non-zero on
/// the first failed assertion.
const String _checkProgram = r'''
package tom_som_java_v0;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

import tom_som_runtime.Json;
import tom_som_runtime.SomMetaBridge;
import tom_som_runtime.SomMetaNode;
import tom_som_runtime.SomMetaRef;
import tom_som_runtime.SomMetaTree;
import tom_som_runtime.SpecMetaDiff;
import tom_som_runtime.SpecModel;

public final class MetaCheck {
  private MetaCheck() {}

  private static void fail(String msg) {
    System.err.println("CHECK FAILED: " + msg);
    System.exit(1);
  }

  private static void expectEq(Object a, Object b, String what) {
    if (a == null ? b != null : !a.equals(b)) {
      fail(what + ": " + a + " != " + b);
    }
  }

  private static SomMetaNode mustMeta(SomMetaRef r, String what) {
    try {
      return r.meta();
    } catch (IllegalStateException e) {
      fail(what + ": " + e.getMessage());
      throw e; // unreachable
    }
  }

  public static void main(String[] args) throws Exception {
    String raw =
        new String(Files.readAllBytes(Paths.get("fixture.json")), StandardCharsets.UTF_8);
    SpecModel model = SpecModel.fromJson(Json.parseObject(raw));
    SomMetaTree bridge = SomMetaBridge.buildSomMetaTree(model, null);

    // (a) generated tree == bridge tree, field for field.
    String diff =
        SpecMetaDiff.somMetaNodeDiff(TomSomV0Meta.SolutionBlueprintMetaTree.root, bridge.root);
    if (!diff.isEmpty()) {
      fail("generated tree != bridge tree: " + diff);
    }

    // (b) dot-notation paths.
    TomSomV0Meta.SolutionBlueprintNav nav = TomSomV0Meta.SolutionBlueprintMeta;
    expectEq(nav.path, "PD00", "root path");
    expectEq(nav.vision().path, "PD00/vision", "vision path");
    expectEq(nav.owner().path, "PD00/owner", "owner path");
    expectEq(nav.risks().path, "PD00/risks", "risks path");
    expectEq(nav.risks().item(2).title().path, "PD00/risks-2/title", "list item path");
    expectEq(nav.situation().summary().path, "PD00/situation/summary",
        "collapsed complex path");
    expectEq(nav.details().summary().path, "PD00/details/summary", "id-less section path");

    // (b) .meta() resolves to the same nodes the dynamic lookups find.
    SomMetaNode vision = mustMeta(nav.vision(), "vision .meta()");
    if (vision != TomSomV0Meta.SolutionBlueprintMetaTree.byPath("PD00/vision")) {
      fail("vision .meta() is not the byPath node");
    }
    expectEq(vision.sectionId, "vision", "vision id");
    SomMetaNode risks = mustMeta(nav.risks(), "risks .meta()");
    if (risks.min == null || risks.min != 2) {
      fail("risks @Min must be 2");
    }
    expectEq(risks.sectionIdPattern, "RISK-ITEM-xxx", "risks pattern");
    SomMetaNode owner = mustMeta(nav.owner(), "owner .meta()");
    if (owner.form == null || owner.form.fields.size() != 2) {
      fail("owner form must carry 2 fields");
    }

    // (b) recursion: `.path` chains stay valid past the re-entry, `.meta()`
    // resolves at the re-entry itself and throws beyond it (SOM §8).
    TomSomV0Meta.RiskNav mitigation = nav.risks().item(0).mitigation();
    expectEq(mitigation.path, "PD00/risks-0/mitigation", "recursive path");
    if (!mustMeta(mitigation, "mitigation .meta()").recursive) {
      fail("mitigation node must be recursive");
    }
    TomSomV0Meta.RiskNav beyond = mitigation.mitigation();
    expectEq(beyond.path, "PD00/risks-0/mitigation/mitigation", "path beyond re-entry");
    boolean threw = false;
    try {
      beyond.meta();
    } catch (IllegalStateException e) {
      threw = true;
    }
    if (!threw) {
      fail(".meta() beyond a recursive re-entry must throw");
    }

    // (c) ID-tree agrees with dot-notation for every surfaced position.
    TomSomV0Meta.SolutionBlueprintId id = TomSomV0Meta.PD00;
    expectEq(id.path, nav.path, "root id path");
    expectEq(id.vision().path, nav.vision().path, "vision id path");
    expectEq(id.owner().path, nav.owner().path, "owner id path");
    expectEq(id.risks().path, nav.risks().path, "risks id path");
    expectEq(id.risks().item(2).title().path, nav.risks().item(2).title().path,
        "item id path");
    expectEq(id.situation().summary().path, nav.situation().summary().path,
        "situation id path");
    // Hoisted through the id-less `details` section.
    expectEq(id.summary().path, nav.details().summary().path, "hoisted id path");
    if (mustMeta(id.vision(), "id vision .meta()") != vision) {
      fail("id-tree and dot-notation .meta() must be the same node");
    }

    System.out.print("OK");
  }
}
''';

/// Locates a `javac` compiler, or `null` when none is on PATH.
String? _javac() {
  try {
    final r = Process.runSync('javac', ['-version']);
    if (r.exitCode == 0) return 'javac';
  } on ProcessException {
    // none on PATH
  }
  return null;
}

/// The `tom_som_java_runtime/src` directory, relative to the clitool root the
/// test runs from, or `null` when it cannot be located.
String? _runtimeSrc() {
  final candidate = p.normalize(
      p.join(Directory.current.path, '..', 'tom_som_java_runtime', 'src'));
  return Directory(candidate).existsSync() ? candidate : null;
}

void main() {
  group('SomJavaMetaEmitter', () {
    late String source;

    setUpAll(() {
      source = SomJavaMetaEmitter(_fixtureModel()).generateLibrary();
    });

    test('emits per-root tree, dot-notation and ID-tree entry points', () {
      expect(
          source,
          contains('public static final SomMetaTree '
              'SolutionBlueprintMetaTree = buildSolutionBlueprintMetaTree();'));
      expect(source,
          contains('public static final SolutionBlueprintNav SolutionBlueprintMeta ='));
      expect(source,
          contains('new SolutionBlueprintNav(SolutionBlueprintMetaTree, "PD00");'));
      expect(source, contains('public static final SolutionBlueprintId PD00 ='));
      expect(source,
          contains('new SolutionBlueprintId(SolutionBlueprintMetaTree, "PD00");'));
    });

    test('emits one Nav class per model class with member-named accessors',
        () {
      expect(source,
          contains('class SolutionBlueprintNav extends SomMetaRef {'));
      expect(source, contains('class RiskNav extends SomMetaRef {'));
      expect(source,
          contains('class CurrentLandscapeAssessmentNav extends SomMetaRef {'));
      // A list accessor is a SomListMetaRef parameterised by an element
      // factory lambda.
      expect(
          source,
          contains('return new SomListMetaRef<>(tree, path + "/risks", '
              '(t, p) -> new RiskNav(t, p));'));
      // A scalar list's items are plain refs (no element accessor class).
      expect(
          source,
          contains('return new SomListMetaRef<>(tree, path + "/tags", '
              '(t, p) -> new SomMetaRef(t, p));'));
    });

    test('ID-tree accessors are named by section id and hoist through '
        'id-less members', () {
      expect(source,
          contains('class SolutionBlueprintId extends SomMetaRef {'));
      expect(source, contains('class RiskId extends SomMetaRef {'));
      // Hoisted: CurrentLandscapeAssessment.summary surfaces on the root's
      // ID class through the id-less `details` section.
      expect(source, contains('path + "/details/summary"'));
    });

    test('cycle handling emits the metaCx re-entry helper and uses it for '
        'complex fields', () {
      expect(source, contains('private static SomMetaNode metaCx('));
      expect(source, contains('if (stack.contains(cls)) {'));
      expect(source, contains('return build.apply(true, new ArrayList<>());'));
      // Risk.mitigation (recursive) goes through metaCx like any complex
      // field, wired to the target class's builder by method reference.
      expect(source, contains('metaCx("Risk", s, RiskNav::metaChildren,'));
    });

    test('per-class metadata builders live inside their Nav class '
        '(constant-pool isolation)', () {
      // Each class's string constants must land in that nested class's own
      // class file, keeping every constant pool under Java's 64k cap.
      expect(
          source,
          contains('class RiskNav extends SomMetaRef {\n'
              '    public RiskNav(SomMetaTree tree, String path) {\n'
              '      super(tree, path);\n'
              '    }\n'
              '\n'
              '    // The metadata children of `Risk` (SOM §7.2), '
              'bridge-identical.\n'
              '    static List<SomMetaNode> metaChildren(Set<String> s) {'));
    });

    test('generated tree == bridge tree; dot-notation and ID-tree agree '
        '(functional, javac + java)', () async {
      final javac = _javac();
      if (javac == null) {
        markTestSkipped('no javac on PATH');
        return;
      }
      final runtimeSrc = _runtimeSrc();
      if (runtimeSrc == null) {
        markTestSkipped('tom_som_java_runtime/src not found');
        return;
      }
      final dir = await Directory.systemTemp.createTemp('som_java_meta_emit_');
      try {
        final pkgDir = Directory(p.join(dir.path, 'src', 'tom_som_java_v0'))
          ..createSync(recursive: true);
        File(p.join(pkgDir.path, 'TomSomV0Meta.java'))
            .writeAsStringSync(source);
        File(p.join(pkgDir.path, 'MetaCheck.java'))
            .writeAsStringSync(_checkProgram);
        File(p.join(dir.path, 'fixture.json'))
            .writeAsStringSync(jsonEncode(_fixtureJson()));
        final outDir = Directory(p.join(dir.path, 'out'))..createSync();
        final sep = Platform.isWindows ? ';' : ':';

        final compile = await Process.run(javac, [
          '-Xlint:all',
          '-d',
          outDir.path,
          '-sourcepath',
          '${p.join(dir.path, 'src')}$sep$runtimeSrc',
          p.join(pkgDir.path, 'TomSomV0Meta.java'),
          p.join(pkgDir.path, 'MetaCheck.java'),
        ]);
        expect(compile.exitCode, 0,
            reason: 'javac reported errors:\n'
                '${compile.stdout}\n${compile.stderr}');

        final run = await Process.run(
            'java', ['-cp', outDir.path, 'tom_som_java_v0.MetaCheck'],
            workingDirectory: dir.path);
        expect(run.exitCode, 0,
            reason: 'check program failed:\n${run.stdout}\n${run.stderr}');
        expect(run.stdout.toString().trim(), 'OK');
      } finally {
        dir.deleteSync(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('a reserved member name in the model is rejected loudly', () {
      final bad = SpecModel.fromJson({
        'modelVersion': 0,
        'roots': [
          {'type': 'Root', 'title': 'Root', 'sectionId': 'R0'},
        ],
        'classes': {
          'Root': {
            'name': 'Root',
            'sectionId': 'R0',
            'fields': [
              {'name': 'path', 'kind': 'content', 'sectionId': 'p'},
            ],
          },
        },
      });
      expect(
          () => SomJavaMetaEmitter(bad).generateLibrary(), throwsStateError);
    });

    test('documentRoots subsets the emitted roots but accessor classes stay '
        'complete', () {
      final all = SomJavaMetaEmitter(_fixtureModel()).generateLibrary();
      final subset = SomJavaMetaEmitter(_fixtureModel(),
          documentRoots: ['SolutionBlueprint']).generateLibrary();
      expect(all, contains('SolutionBlueprintMetaTree'));
      expect(subset, contains('SolutionBlueprintMetaTree'));
    });
  });
}
