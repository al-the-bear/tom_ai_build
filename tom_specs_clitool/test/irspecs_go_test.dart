/// The Go server mapper (`irspecs_ir.md` §12): the Meridian IR's server
/// written as a Go module that builds, vets and is gofmt-clean, whose sqlc
/// configuration generates and builds, whose back-links are the Dart trio's
/// file by file, whose wire types agree with the JSON Schema, and whose
/// routes answer a not-implemented handler with a transport error.
///
/// Needs the Go toolchain (found on the PATH or where Homebrew and the
/// official tarball put it) and the Go module proxy or its cache; without
/// `go` the tests are skipped with the reason stated.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

import 'support/go_toolchain.dart';

final _meridian = p.absolute(
  '../tom_som_conformance/samples/meridian_codespecs',
);
final _areas = p.absolute(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);
const _module = 'meridian_codespec_server';

final String? _go = findGoToolchain();

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

ProcessResult _run(String executable, List<String> args, String cwd) =>
    Process.runSync(executable, args, workingDirectory: cwd);

void _write(Directory root, Map<String, String> files) {
  for (final MapEntry(key: path, value: text) in files.entries) {
    File(p.joinAll([root.path, ...path.split('/')]))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
  }
}

void _expectOk(ProcessResult r, String what) =>
    expect(r.exitCode, 0, reason: '$what:\n${r.stdout}${r.stderr}');

/// The back-link lines of a declaration and its members, in order.
List<String> _expectedBackLinks(IrFile f) => [
  for (final d in f.file.declarations) ...[
    if (d.codeSpec case final cs?)
      'codeSpec ${cs.id}${cs.source.isEmpty ? '' : ' source: ${cs.source.join(', ')}'}',
    for (final r in d.docSpec ?? const <CsDocRef>[]) 'docSpec ${r.sectionId}',
  ],
];

List<String> _goBackLinks(String go) => [
  for (final m in RegExp(
    r'^\s*// codeSpec: (.+)$',
    multiLine: true,
  ).allMatches(go))
    'codeSpec ${m.group(1)!.trimRight()}',
  for (final m in RegExp(
    r'^\s*// docSpec: (\S+) ',
    multiLine: true,
  ).allMatches(go))
    'docSpec ${m.group(1)!}',
];

/// `lib/src/data_access/order.dart` → `data_access_order.go`, as the mapper
/// names it (Meridian has no name Go reads as build-constrained).
String _goFile(String dartPath) =>
    '${dartPath.replaceFirst('lib/src/', '').replaceFirst(RegExp(r'\.dart$'), '').replaceAll('/', '_')}.go';

void main() {
  final skip = _go == null ? 'no `go` toolchain on this host' : false;
  final documents = _ir();
  late Directory out;
  late Map<String, String> files;

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('irspecs_go');
    files = mapGoServer(documents);
    _write(out, files);
  });
  tearDownAll(() => out.deleteSync(recursive: true));

  String moduleDir() => p.join(out.path, _module);

  test(
    'IRGO1: the module builds, vets and is gofmt-clean',
    () {
      _expectOk(_run(_go!, ['build', './...'], moduleDir()), 'go build');
      _expectOk(_run(_go!, ['vet', './...'], moduleDir()), 'go vet');
      final gofmt = _run(p.join(p.dirname(_go!), 'gofmt'), [
        '-l',
        '.',
      ], moduleDir());
      _expectOk(gofmt, 'gofmt');
      expect('${gofmt.stdout}'.trim(), isEmpty, reason: 'gofmt -l');
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'IRGO2: the routes answer a not-implemented handler with a 5xx, '
    'executing nothing else',
    () {
      final probe = File(p.join(moduleDir(), 'server', 'router_probe_test.go'))
        ..writeAsStringSync('''
package server

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"$_module/tom"
)

func TestNotImplemented(t *testing.T) {
	_, err := UnimplementedOrderService{}.AmendOrderLine(t.Context(), shared_request())
	if !errors.Is(err, tom.ErrNotImplemented) {
		t.Fatalf("err = %v", err)
	}
	router := NewRouter(Services{OrderService: UnimplementedOrderService{}})
	w := httptest.NewRecorder()
	router.ServeHTTP(w, httptest.NewRequest(http.MethodPost, "/amendOrderLine",
		strings.NewReader(`{"orderId":"o","lineId":"l","newQuantity":2,"orderVersion":1}`)))
	if w.Code != http.StatusInternalServerError ||
		!strings.Contains(w.Body.String(), "not implemented: Applies a quantity change") {
		t.Fatalf("%d %s", w.Code, w.Body.String())
	}
	w = httptest.NewRecorder()
	router.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/amendOrderLine", nil))
	if w.Code != http.StatusMethodNotAllowed {
		t.Fatalf("GET answered %d", w.Code)
	}
}
''');
      File(
        p.join(moduleDir(), 'server', 'router_probe_helper_test.go'),
      ).writeAsStringSync('''
package server

import "$_module/shared"

func shared_request() shared.AmendOrderLineRequest {
	return shared.AmendOrderLineRequest{OrderId: "o", LineId: "l", NewQuantity: 2}
}
''');
      try {
        _expectOk(_run(_go!, ['test', './server/'], moduleDir()), 'go test');
      } finally {
        probe.deleteSync();
        File(
          p.join(moduleDir(), 'server', 'router_probe_helper_test.go'),
        ).deleteSync();
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'IRGO3: sqlc generates typed queries from the schema, and the module '
    'still builds and vets',
    () {
      final copy = Directory.systemTemp.createTempSync('irspecs_go_sqlc');
      try {
        _write(copy, files);
        final dir = p.join(copy.path, _module);
        _expectOk(
          _run(_go!, [
            'run',
            'github.com/sqlc-dev/sqlc/cmd/sqlc@$kSqlcVersion',
            'generate',
          ], dir),
          'sqlc generate',
        );
        for (final table in [
          'mom_customer',
          'mom_order',
          'mom_order_line',
          'mom_product',
        ]) {
          expect(
            File(p.join(dir, 'db', '$table.sql.go')).existsSync(),
            isTrue,
            reason: table,
          );
        }
        _expectOk(_run(_go!, ['build', './...'], dir), 'go build');
        _expectOk(_run(_go!, ['vet', './...'], dir), 'go vet');
      } finally {
        copy.deleteSync(recursive: true);
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test('IRGO4: the back-links name every section the Dart trio does, file '
      'by file', () {
    var checked = 0;
    for (final d in documents) {
      if (d.area == kIrPackageArea) continue;
      for (final f in d.files) {
        if (f.locus == CsLocus.client) continue;
        final path = '$_module/${f.locus.name}/${_goFile(f.file.path)}';
        final go = files[path];
        expect(go, isNotNull, reason: path);
        final expected = _expectedBackLinks(f)..sort();
        final actual = _goBackLinks(go!)..sort();
        expect(actual, expected, reason: path);
        checked++;
      }
    }
    expect(checked, 23);
  });

  test('IRGO5: the wire types and the entities agree with the JSON Schema', () {
    final schema =
        jsonDecode(emitJsonSchema(documents).files.values.single)
            as Map<String, dynamic>;
    final defs = schema[r'$defs'] as Map<String, dynamic>;
    final go = files.entries
        .where((e) => e.key.endsWith('.go'))
        .map((e) => e.value)
        .join('\n');
    var compared = 0;
    for (final MapEntry(key: name, value: def) in defs.entries) {
      if ((def as Map)['type'] != 'object') continue;
      final block = RegExp(
        'type $name(?:\\[[^\\]]*\\])? struct \\{\\n([\\s\\S]*?)\\n\\}',
      ).firstMatch(go);
      expect(block, isNotNull, reason: name);
      final props = [
        for (final m in RegExp(
          r'json:"(\w+)(,omitempty)?"',
        ).allMatches(block!.group(1)!))
          m.group(1)!,
      ];
      expect(props, (def['properties'] as Map).keys.toList(), reason: name);
      final required = {...(def['required'] as List? ?? const [])};
      for (final m in RegExp(
        r'json:"(\w+)(,omitempty)?"',
      ).allMatches(block.group(1)!)) {
        expect(
          m.group(2) == null,
          required.contains(m.group(1)),
          reason: '$name.${m.group(1)}: omitempty exactly when not required',
        );
      }
      compared++;
    }
    expect(compared, 12);
  });

  test(
    'IRGO6: the shapes — enum consts, a service unit as an interface and '
    'its Unimplemented stub, a repository on tom.Repository, a POST route',
    () {
      final status = files['$_module/shared/domain_enum_order_status.go']!;
      expect(status, contains('type OrderStatus string'));
      expect(
        status,
        contains('\tOrderStatusCaptured OrderStatus = "captured"'),
      );
      final service = files['$_module/server/service_unit_order_service.go']!;
      expect(service, contains('type OrderService interface {'));
      expect(
        service,
        contains(
          '\tAmendOrderLine(ctx context.Context, request '
          'shared.AmendOrderLineRequest) '
          '(shared.Result[shared.AmendOrderLineResponse], error)',
        ),
      );
      expect(service, contains('type UnimplementedOrderService struct{}'));
      expect(service, contains('return zero, tom.NotImplemented("Applies'));
      final repository =
          files['$_module/server/data_access_order_repository.go']!;
      expect(repository, contains('\ttom.Repository[Order, string]'));
      final order = files['$_module/server/data_access_order.go']!;
      expect(
        order,
        contains('\tChannel shared.OrderChannel `db:"channel" json:"channel"`'),
      );
      expect(order, contains('const OrderTable = "mom_order"'));
      expect(
        files['$_module/server/router.go'],
        contains('r.Post("/amendOrderLine", '),
      );
      expect(
        files['$_module/db/schema.sql'],
        contains('CREATE TABLE mom_order ('),
      );
      expect(
        files['$_module/go.mod'],
        contains('require github.com/go-chi/chi/v5'),
      );
      // The client is not the Go server's to write.
      expect(files.keys.where((k) => k.contains('layout')), isEmpty);
    },
  );

  test('IRGO7: a body with steps is printed from them, and builds', () {
    // Meridian's server bodies are all 3a; its 3b bodies are the client's
    // server calls (CE-SC), read here as if they were the server's.
    final asServer = [
      for (final d in documents)
        if (d.area == 'CE-SC')
          IrDocument(
            area: d.area,
            projects: d.projects,
            files: [
              for (final f in d.files)
                IrFile(CsLocus.server, f.file, f.steps, f.units),
            ],
          )
        else
          d,
    ];
    final mapped = mapGoServer(asServer);
    final call =
        mapped['$_module/server/server_call_amend_order_line_call.go']!;
    expect(
      call,
      contains(
        '\tif err := s.Collaborator.AssembleRequestStageTheCoreFields(ctx, '
        'request); err != nil {\n'
        '\t\treturn err\n'
        '\t}\n'
        '\tapplies1, err := s.Collaborator.'
        'AssembleRequestAttachTheJustificationApplies(ctx, request)\n'
        '\tif err != nil {\n'
        '\t\treturn err\n'
        '\t}\n'
        '\tif applies1 {\n'
        '\t\tif err := s.Collaborator.'
        'AssembleRequestAttachTheJustification(ctx, request); err != nil {\n'
        '\t\t\treturn err\n'
        '\t\t}\n'
        '\t}\n'
        '\treturn nil\n',
      ),
    );
    expect(
      mapped['$_module/server/server_call_amend_order_line_call_collaborator.go'],
      contains('type AmendOrderLineCallCollaborator interface {'),
    );
    if (_go == null) return;
    final dir = Directory.systemTemp.createTempSync('irspecs_go_steps');
    try {
      _write(dir, mapped);
      _expectOk(
        _run(_go!, ['vet', './...'], p.join(dir.path, _module)),
        'go vet',
      );
    } finally {
      dir.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('IRGO8: a server unit is written as the module of its id', () {
    const unitId = 'meridian_go_server';
    final unit = IrUnit(
      unitId: unitId,
      locus: CsLocus.server,
      mappings: {
        for (final d in documents)
          if (d.area != kIrPackageArea) d.area: kGoServerMapper,
      },
    );
    final share = irDocumentsForUnit(documents, unit, mapper: kGoServerMapper);
    final unitFiles = mapGoServer(share, all: documents);
    expect(
      unitFiles.keys.map((k) => k.substring(unitId.length + 1)).toSet(),
      files.keys.map((k) => k.substring(_module.length + 1)).toSet(),
    );
    expect(unitFiles['$unitId/go.mod'], contains('module $unitId\n'));
    expect(unitFiles['$unitId/server/router.go'], contains('"$unitId/shared"'));
    if (_go == null) return;
    final dir = Directory.systemTemp.createTempSync('irspecs_go_unit');
    try {
      _write(dir, unitFiles);
      final module = p.join(dir.path, unitId);
      _expectOk(_run(_go!, ['build', './...'], module), 'go build');
      _expectOk(_run(_go!, ['vet', './...'], module), 'go vet');
    } finally {
      dir.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('IRGO9: a construct with no Go rule is refused, naming the file', () {
    final withLayout = [
      for (final d in documents)
        if (d.area == 'CE-LO')
          IrDocument(
            area: d.area,
            projects: d.projects,
            files: [
              for (final f in d.files)
                IrFile(CsLocus.shared, f.file, f.steps, f.units),
            ],
          )
        else
          d,
    ];
    expect(
      () => mapGoServer(withLayout),
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
