/// The Java + Spring Boot server mapper (`irspecs_ir.md` §13): the Meridian
/// IR's server written as a Gradle project that `./gradlew compileJava`
/// compiles on JDK 21 — openapi-generator writing the HTTP interfaces from the
/// IR's OpenAPI document and nothing the project declares itself — whose
/// back-links are the Dart trio's file by file and whose wire types agree with
/// the JSON Schema.
///
/// Needs a JDK 21 and a Gradle (on the PATH, or a distribution the wrapper has
/// unpacked under `~/.gradle`), and Maven Central or the Gradle cache; without
/// them the compiling tests are skipped with the reason stated.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

import 'support/java_toolchain.dart';

final _meridian = p.absolute(
  '../tom_som_conformance/samples/meridian_codespecs',
);
final _areas = p.absolute(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);
const _project = 'meridian_codespec_server';
const _java = 'src/main/java/meridian_codespec_server';

final String? _jdk = findJdk21();
final String? _gradle = findGradle(version: kJavaSpringVersions['gradle']!);

List<IrDocument> _ir() {
  CsLocusProject read(CsLocus locus) => readCsLocusProjectFromDirectory(
    locus: locus,
    packageName: 'meridian_codespec_${locus.name}',
    root: p.join(_meridian, 'meridian_codespec_${locus.name}'),
  );
  final documents = irFromCsModel(
    shared: read(CsLocus.shared),
    client: read(CsLocus.client),
    server: read(CsLocus.server),
    areas: IrAreaIndex(
      CodeSpecsAreaCatalog.fromJson(
        jsonDecode(File(_areas).readAsStringSync()) as Map<String, dynamic>,
      ),
    ),
  );
  return [for (final d in documents) readIrYaml(writeIrYaml(d))];
}

void _write(Directory root, Map<String, String> files) {
  for (final MapEntry(key: path, value: text) in files.entries) {
    File(p.joinAll([root.path, ...path.split('/')]))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
  }
}

ProcessResult _run(String executable, List<String> args, String cwd) =>
    Process.runSync(
      executable,
      args,
      workingDirectory: cwd,
      environment: {'JAVA_HOME': _jdk!},
    );

void _expectOk(ProcessResult r, String what) =>
    expect(r.exitCode, 0, reason: '$what:\n${r.stdout}${r.stderr}');

/// Completes the project with its wrapper and compiles it with
/// `./gradlew compileJava`, as irspecs_ir.md §13 says a reader does.
void _compile(String project) {
  _expectOk(
    _run(_gradle!, [
      'wrapper',
      '--gradle-version',
      kJavaSpringVersions['gradle']!,
      '--distribution-type',
      'all',
      '--no-daemon',
      '-q',
    ], project),
    'gradle wrapper',
  );
  _expectOk(
    _run(p.join(project, 'gradlew'), [
      'compileJava',
      '--no-daemon',
      '-q',
    ], project),
    './gradlew compileJava',
  );
}

/// The back-link lines of a Dart file's declarations and members.
List<String> _expectedBackLinks(IrFile f) => [
  for (final d in f.file.declarations) ...[
    if (d.codeSpec case final cs?)
      'codeSpec ${cs.id}${cs.source.isEmpty ? '' : ' source: ${cs.source.join(', ')}'}',
    for (final r in d.docSpec ?? const <CsDocRef>[]) 'docSpec ${r.sectionId}',
  ],
];

List<String> _javaBackLinks(String java) => [
  for (final m in RegExp(r'@CodeSpec\(([^)]*)\)').allMatches(java))
    () {
      final args = m.group(1)!;
      final id = RegExp(r'id = "([^"]*)"').firstMatch(args)?.group(1) ?? '';
      final source = [
        for (final s in RegExp(r'"([^"]*)"').allMatches(
          RegExp(r'source = \{([^}]*)\}').firstMatch(args)?.group(1) ?? '',
        ))
          s.group(1)!,
      ];
      return 'codeSpec $id${source.isEmpty ? '' : ' source: ${source.join(', ')}'}';
    }(),
  for (final m in RegExp(r'@DocRef\(sectionId = "([^"]*)"').allMatches(java))
    'docSpec ${m.group(1)!}',
];

IrFile _relocated(IrFile f, CsLocus locus) =>
    IrFile(locus, f.file, f.steps, f.units);

void main() {
  final skip = _jdk == null
      ? 'no JDK 21 on this host'
      : _gradle == null
      ? 'no Gradle on this host'
      : false;
  final documents = _ir();
  late Map<String, String> files;

  setUpAll(() => files = mapJavaSpring(documents));

  test(
    'IRJV1: the project compiles with ./gradlew compileJava, '
    'openapi-generator writing only the HTTP interfaces and the envelopes',
    () {
      final dir = Directory.systemTemp.createTempSync('irspecs_java');
      try {
        _write(dir, files);
        final project = p.join(dir.path, _project);
        _compile(project);
        final generated = [
          for (final f in Directory(
            p.join(project, 'build', 'generated', 'openapi'),
          ).listSync(recursive: true).whereType<File>())
            if (f.path.endsWith('.java')) p.basename(f.path),
        ];
        expect(
          generated,
          containsAll([
            'AmendOrderLineApi.java',
            'FetchOrderWorkListApi.java',
            'AmendOrderLine200Response.java',
          ]),
        );
        // Every component schema the project declares is the project's own.
        for (final own in [
          'AmendOrderLineRequest.java',
          'ErrorResult.java',
          'OrderDto.java',
          'OrderStatus.java',
          'Order.java',
        ]) {
          expect(generated, isNot(contains(own)), reason: own);
        }
        expect(
          File(
            p.join(
              project,
              'build/classes/java/main/meridian_codespec_server/server/'
              'OrderServiceController.class',
            ),
          ).existsSync(),
          isTrue,
        );
      } finally {
        dir.deleteSync(recursive: true);
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 15)),
  );

  test('IRJV2: the back-links name every section the Dart trio does, file '
      'by file', () {
    var checked = 0;
    for (final d in documents) {
      if (d.area == kIrPackageArea) continue;
      for (final f in d.files) {
        if (f.locus == CsLocus.client) continue;
        final java = [
          for (final decl in f.file.declarations)
            if (decl.owner == null)
              files['$_project/$_java/${f.locus.name}/${decl.name}.java'] ??
                  (throw StateError('no Java file for ${decl.name}')),
        ].join('\n');
        expect(
          _javaBackLinks(java)..sort(),
          _expectedBackLinks(f)..sort(),
          reason: f.file.path,
        );
        checked++;
      }
    }
    expect(checked, 23);
  });

  test('IRJV3: the wire types and the entities agree with the JSON Schema', () {
    final schema =
        jsonDecode(emitJsonSchema(documents).files.values.single)
            as Map<String, dynamic>;
    final defs = schema[r'$defs'] as Map<String, dynamic>;
    var compared = 0;
    for (final MapEntry(key: name, value: def) in defs.entries) {
      if ((def as Map)['type'] != 'object') continue;
      final path = [
        '$_project/$_java/shared/$name.java',
        '$_project/$_java/server/$name.java',
      ].firstWhere(files.containsKey);
      final java = files[path]!;
      final List<String> names;
      final record = RegExp(
        'public record $name(?:<[^>]*>)?\\(([\\s\\S]*?)\\n\\) \\{\\}',
      ).firstMatch(java);
      if (record != null) {
        names = [
          for (final m in RegExp(
            r'^ {8}[\w<>, ]+ (\w+),?$',
            multiLine: true,
          ).allMatches(record.group(1)!))
            m.group(1)!,
        ];
      } else {
        // An entity's columns are the fields its @Column marks; a foreign
        // key's read-only association (@ManyToOne) is not a property.
        names = [
          for (final m in RegExp(
            java.contains('@Entity')
                ? r'^ {4}@Column\([^\n]*\)\n {4}private [\w<>, ]+ (\w+);$'
                : r'^ {4}private [\w<>, ]+ (\w+);$',
            multiLine: true,
          ).allMatches(java))
            m.group(1)!,
        ];
      }
      expect(names, (def['properties'] as Map).keys.toList(), reason: name);
      compared++;
    }
    expect(compared, 12);
  });

  test('IRJV4: the shapes — records with Bean Validation, enums, JPA '
      'entities and repositories, a @Service whose handlers throw, a '
      'controller on the generated interfaces, the Flyway migration', () {
    String file(String path) => files['$_project/$_java/$path']!;
    final request = file('shared/AmendOrderLineRequest.java');
    expect(request, contains('public record AmendOrderLineRequest('));
    expect(
      request,
      contains(
        '        @NotNull\n        @Min(1)\n        Integer newQuantity,',
      ),
    );
    expect(file('shared/Result.java'), contains('public record Result<T>('));
    expect(
      file('shared/OrderStatus.java'),
      contains('public enum OrderStatus {'),
    );
    expect(
      file('shared/SbpRoles.java'),
      contains('public static final String orderClerk = "orderClerk";'),
    );
    final order = file('server/Order.java');
    expect(
      order,
      contains('@Entity\n@Table(name = "mom_order")\npublic class Order {'),
    );
    expect(
      order,
      contains(
        '    @Enumerated(EnumType.STRING)\n'
        '    @Column(name = "channel", columnDefinition = "varchar(8)", '
        'nullable = false)\n'
        '    private OrderChannel channel;',
      ),
    );
    expect(
      file('server/OrderRepository.java'),
      contains(
        'public interface OrderRepository extends JpaRepository<Order, String> {',
      ),
    );
    final service = file('server/OrderService.java');
    expect(service, contains('@Service\npublic class OrderService {'));
    expect(
      service,
      contains(
        '    public Result<AmendOrderLineResponse> amendOrderLine('
        'AmendOrderLineRequest request) {\n'
        '        throw new UnsupportedOperationException("Applies',
      ),
    );
    expect(
      file('server/OrderServiceController.java'),
      contains(
        'public class OrderServiceController implements AmendOrderLineApi, '
        'FetchOrderWorkListApi {',
      ),
    );
    expect(
      files['$_project/src/main/resources/db/migration/V1__ce_db_tables.sql'],
      contains('CREATE TABLE mom_order ('),
    );
    final gradle = files['$_project/build.gradle.kts']!;
    expect(gradle, contains('JavaLanguageVersion.of(21)'));
    expect(gradle, contains('id("org.springframework.boot") version "3.5.16"'));
    expect(gradle, contains('"interfaceOnly" to "true"'));
    expect(
      gradle,
      contains(
        '"AmendOrderLineRequest" to '
        '"meridian_codespec_server.shared.AmendOrderLineRequest",',
      ),
    );
    expect(files.keys.where((k) => k.contains('Layout')), isEmpty);
  });

  test('IRJV5: a body with steps is printed from them, and compiles', () {
    // Meridian's server bodies are all 3a; its 3b bodies are the client's
    // server calls (CE-SC), read here as if they were the server's.
    final asServer = [
      for (final d in documents)
        if (d.area == 'CE-SC')
          IrDocument(
            area: d.area,
            projects: d.projects,
            files: [for (final f in d.files) _relocated(f, CsLocus.server)],
          )
        else
          d,
    ];
    final mapped = mapJavaSpring(asServer);
    expect(
      mapped['$_project/$_java/server/AmendOrderLineCall.java'],
      contains(
        '    public void assembleRequest(AmendOrderLineRequest request) {\n'
        '        collaborator.assembleRequestStageTheCoreFields(request);\n'
        '        if (collaborator.'
        'assembleRequestAttachTheJustificationApplies(request)) {\n'
        '            collaborator.assembleRequestAttachTheJustification('
        'request);\n'
        '        }\n'
        '    }',
      ),
    );
    expect(
      mapped['$_project/$_java/server/AmendOrderLineCallCollaborator.java'],
      contains('public interface AmendOrderLineCallCollaborator {'),
    );
    if (skip is String) return;
    final dir = Directory.systemTemp.createTempSync('irspecs_java_steps');
    try {
      _write(dir, mapped);
      _compile(p.join(dir.path, _project));
    } finally {
      dir.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('IRJV6: a server unit is written, and compiles, as the project of its '
      'id', () {
    const unitId = 'meridian_java_server';
    final unit = IrUnit(
      unitId: unitId,
      locus: CsLocus.server,
      mappings: {
        for (final d in documents)
          if (d.area != kIrPackageArea) d.area: kJavaSpringServerMapper,
      },
    );
    final unitFiles = mapJavaSpring(
      irDocumentsForUnit(documents, unit, mapper: kJavaSpringServerMapper),
      all: documents,
    );
    String rename(String k) => k
        .substring(k.indexOf('/') + 1)
        .replaceAll(unitId, '<unit>')
        .replaceAll(_project, '<unit>')
        .replaceAll('MeridianJavaServerApplication', '<App>')
        .replaceAll('MeridianCodespecServerApplication', '<App>');
    expect(unitFiles.keys.map(rename).toSet(), files.keys.map(rename).toSet());
    expect(
      unitFiles['$unitId/settings.gradle.kts'],
      contains('rootProject.name = "$unitId"'),
    );
    if (skip is String) return;
    final dir = Directory.systemTemp.createTempSync('irspecs_java_unit');
    try {
      _write(dir, unitFiles);
      _compile(p.join(dir.path, unitId));
    } finally {
      dir.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('IRJV7: a construct with no Java rule is refused, naming the file', () {
    final withLayout = [
      for (final d in documents)
        if (d.area == 'CE-LO')
          IrDocument(
            area: d.area,
            projects: d.projects,
            files: [for (final f in d.files) _relocated(f, CsLocus.shared)],
          )
        else
          d,
    ];
    expect(
      () => mapJavaSpring(withLayout),
      throwsA(
        isA<IrMapException>().having(
          (e) => e.message,
          'message',
          allOf(contains('lib/src/layout/'), contains('writes no client')),
        ),
      ),
    );
  });
}
