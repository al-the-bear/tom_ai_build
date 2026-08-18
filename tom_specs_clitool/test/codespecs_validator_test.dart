/// Fixtures for the thirty-six `codespecs_derivation_contract.md` §6 checks.
///
/// Every check gets **two** fixtures: one that violates the rule and one that
/// satisfies it. A check exercised only against clean input is
/// indistinguishable from a check that is not wired at all, so the red fixture
/// is the one that proves the check fires — and the green one proves it fires
/// for the rule rather than for the shape of the fixture.
///
/// The fixtures are in-memory Dart sources: the validator reads syntax, so a
/// fixture needs no package resolution and no filesystem. Checks 32–36 read a
/// second input, so their fixtures are a pair — a trio and the extract it claims
/// to have been written from.
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

const _sharedPackage = 'app_codespec_shared';
const _clientPackage = 'app_codespec_client';
const _serverPackage = 'app_codespec_server';

CodeSpecsValidationInput _input({
  Map<String, String> shared = const {},
  Map<String, String> client = const {},
  Map<String, String> server = const {},
  Map<String, String> migrations = const {},
  List<CsEnumMirror> mirrors = const [],
  Map<String, String>? againShared,
  Map<String, String>? againClient,
  Map<String, String>? againServer,
  CsExtractSet? extracts,
}) =>
    CodeSpecsValidationInput(
      shared: readCsLocusProject(
        locus: CsLocus.shared,
        packageName: _sharedPackage,
        sources: shared,
      ),
      client: readCsLocusProject(
        locus: CsLocus.client,
        packageName: _clientPackage,
        sources: client,
      ),
      server: readCsLocusProject(
        locus: CsLocus.server,
        packageName: _serverPackage,
        sources: server,
      ),
      migrations: migrations,
      enumMirrors: mirrors,
      extracts: extracts,
      regeneration:
          againShared == null && againClient == null && againServer == null
              ? null
              : CodeSpecsRegeneration(
                  shared: readCsLocusProject(
                    locus: CsLocus.shared,
                    packageName: _sharedPackage,
                    sources: againShared ?? shared,
                  ),
                  client: readCsLocusProject(
                    locus: CsLocus.client,
                    packageName: _clientPackage,
                    sources: againClient ?? client,
                  ),
                  server: readCsLocusProject(
                    locus: CsLocus.server,
                    packageName: _serverPackage,
                    sources: againServer ?? server,
                  ),
                ),
    );

/// One `<CE-CODE>.extract.yaml`, in the shape `spec_codespecs_extract` emits.
///
/// Scalars are written as JSON string literals, which is what the emitter does
/// and what makes a value carrying an em dash, a `#` or a newline survive the
/// round trip as one scalar — the verbatimness checks 32 and 34 depend on.
String _extractYaml(
  String areaCode,
  List<(String section, String field, String value)> entries, {
  String documentRoot = 'IMO',
  String className = 'DataEntityEntry',
}) {
  final buffer = StringBuffer()
    ..writeln('extract:')
    ..writeln('  formatVersion: $kCsExtractFormat')
    ..writeln('  area:')
    ..writeln('    code: ${jsonEncode(areaCode)}')
    ..writeln('  document:')
    ..writeln('    root: ${jsonEncode(documentRoot)}')
    ..writeln('  entries:');
  for (final (section, field, value) in entries) {
    buffer
      ..writeln('    - sectionId: ${jsonEncode(section)}')
      ..writeln('      className: ${jsonEncode(className)}')
      ..writeln('      fieldName: ${jsonEncode(field)}')
      ..writeln('      value: ${jsonEncode(value)}');
  }
  return '$buffer';
}

/// A one-area extract set holding [entries], the usual shape for a comment
/// fixture: one area is all a single declaration's sections can be routed to.
CsExtractSet _extract(List<(String, String, String)> entries) =>
    readCsExtracts({'CE-DB.extract.yaml': _extractYaml('CE-DB', entries)});

/// `IMO-014`'s `content` from the §4 worked example — carried as a constant so
/// the fixture's Dart source and the extract it is checked against cannot drift
/// apart in the one character that matters, the em dash C4.5 leaves alone.
const _customerContent =
    'Customers are never deleted — a closed account keeps its orders.';

/// The two values §2.8 P1 turns into the class doc comment of the §4 example.
const _customerEntries = <(String, String, String)>[
  ('IMO-014', 'description', 'A person or organisation that places orders.'),
  ('IMO-014', 'content', _customerContent),
];

/// The violations of §6 check [number] raised by [input].
List<CodeSpecsViolation> _forCheck(int number, CodeSpecsValidationInput input) =>
    runCodeSpecsChecks(input).forCheck(number);

/// Declares the pair of tests every check gets: [red] must break it and
/// [green] must not, and the failure must name the rule.
void _redGreen(
  int number,
  String definedIn, {
  required CodeSpecsValidationInput red,
  required CodeSpecsValidationInput green,
  required Matcher says,
}) {
  test('fires on a violating fixture, naming the rule', () {
    final raised = _forCheck(number, red);
    expect(
      raised,
      isNotEmpty,
      reason: 'check $number did not fire on its red fixture',
    );
    expect(raised.first.check, number);
    expect(raised.first.definedIn, definedIn);
    expect(raised.map((v) => v.message).join('\n'), says);
  });

  test('passes a conforming fixture', () {
    expect(
      _forCheck(number, green),
      isEmpty,
      reason: 'check $number fired on its green fixture',
    );
  });
}

void main() {
  group('§6 check catalogue', () {
    test('names the thirty-six checks in table order', () {
      expect(
        codeSpecsChecks.map((c) => c.number),
        [for (var i = 1; i <= 36; i++) i],
      );
    });

    test('every check carries the section that defines its rule', () {
      for (final check in codeSpecsChecks) {
        expect(check.definedIn, startsWith('§'), reason: 'check ${check.number}');
        expect(check.title, isNotEmpty, reason: 'check ${check.number}');
      }
    });

    test('a violation names its check number and defining section', () {
      const violation = CodeSpecsViolation(
        check: 3,
        definedIn: '§2.1 N1',
        message: 'no name',
      );
      expect('$violation', 'codespecs check 3 [§2.1 N1]: no name');
    });
  });

  group('1 — identifier collisions (§2.1 N4)', () {
    _redGreen(
      1,
      '§2.1 N4',
      says: contains('derived twice'),
      red: _input(
        client: {
          'lib/a.dart': '''
@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1'])
@DocSpec([DocRef('SBP.4.1', 'the order form')])
@CsForm()
class orderForm {}
''',
          'lib/b.dart': '''
@CodeSpec('ce-fm.orderForm', source: ['SBP.9.2'])
@DocSpec([DocRef('SBP.9.2', 'the other order form')])
@CsForm()
class orderForm {}
''',
        },
      ),
      green: _input(
        client: {
          'lib/a.dart': '''
@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1'])
@DocSpec([DocRef('SBP.4.1', 'the order form')])
@CsForm()
class orderForm {}
''',
          'lib/b.dart': '''
@CodeSpec('ce-fm.returnForm', source: ['SBP.9.2'])
@DocSpec([DocRef('SBP.9.2', 'the return form')])
@CsForm()
class returnForm {}
''',
        },
      ),
    );
  });

  group('2 — reference resolution (§2.1 N9)', () {
    _redGreen(
      2,
      '§2.1 N9',
      says: contains('resolves to no declaration'),
      red: _input(
        client: {
          'lib/a.dart': '''
@CsTrigger(kind: CsTriggerKind.userGesture, action: CsActionRef('placeOrder'))
class submitButton {}
''',
        },
      ),
      green: _input(
        client: {
          'lib/a.dart': '''
const placeOrder = CsActionRef('placeOrder');

@CsTrigger(kind: CsTriggerKind.userGesture, action: CsActionRef('placeOrder'))
class submitButton {}
''',
        },
      ),
    );

    test('a reference resolves only in the locus that declares its kind', () {
      // CsActionRef is client-owned (§2.6): a declaration of the same id in the
      // server project must not satisfy it.
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsTrigger(kind: CsTriggerKind.userGesture, action: CsActionRef('placeOrder'))
class submitButton {}
''',
        },
        server: {'lib/a.dart': "const placeOrder = CsActionRef('placeOrder');"},
      );
      expect(_forCheck(2, input), isNotEmpty);
    });
  });

  group('3 — missing designated name (§2.1 N1)', () {
    _redGreen(
      3,
      '§2.1 N1',
      says: contains('no designated name field and no headline'),
      red: _input(
        client: {
          'lib/a.dart': '''
@CodeSpec('', source: ['SBP.4.1'])
@DocSpec([DocRef('SBP.4.1', 'a section with no name field')])
@CsForm()
class Unnamed {}
''',
        },
      ),
      green: _input(
        client: {
          'lib/a.dart': '''
@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1'])
@DocSpec([DocRef('SBP.4.1', 'the order form')])
@CsForm()
class orderForm {}
''',
        },
      ),
    );

    test('the failure names the section, not the symbol', () {
      final raised = _forCheck(
        3,
        _input(
          client: {
            'lib/a.dart': '''
@CodeSpec('', source: ['SBP.4.1', 'SBP.4.2'])
@DocSpec([DocRef('SBP.4.1', 'a'), DocRef('SBP.4.2', 'b')])
class Unnamed {}
''',
          },
        ),
      );
      expect(raised.single.message, contains('SBP.4.1, SBP.4.2'));
    });
  });

  group('4 — missing authored key (§2.1 N5)', () {
    _redGreen(
      4,
      '§2.1 N5',
      says: contains('carries no table'),
      red: _input(
        server: {'lib/a.dart': "@CsTable('') class Order {}"},
      ),
      green: _input(
        server: {'lib/a.dart': "@CsTable('orders') class Order {}"},
      ),
    );

    test('an absent key is as missing as a blank one', () {
      final input = _input(client: {'lib/a.dart': '@CsClient() class Shell {}'});
      expect(_forCheck(4, input).single.message, contains('no clientId'));
    });

    test('a ref const declared with no key fails at its declaration site', () {
      final input = _input(
        shared: {'lib/a.dart': "const shipped = CsMessageKey('');"},
      );
      expect(_forCheck(4, input).single.message, contains('CsMessageKey'));
    });
  });

  group('5 — empty explication (§2.4)', () {
    _redGreen(
      5,
      '§2.4',
      says: contains('throws with no explication'),
      red: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  void place() {
    throw UnsupportedError();
  }
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  void place() {
    throw UnsupportedError('Places the order and returns its confirmation.');
  }
}
''',
        },
      ),
    );

    test('an empty explication string fails as surely as an absent one', () {
      final input = _input(
        server: {
          'lib/a.dart': "class S { void f() { throw UnsupportedError('  '); } }",
        },
      );
      expect(_forCheck(5, input), isNotEmpty);
    });
  });

  group('6 — fabricated values (§2.4 invariant 2)', () {
    _redGreen(
      6,
      '§2.4 invariant 2',
      says: contains('could the generator have made this value up'),
      red: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  int total() {
    return 0;
  }
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  int total() {
    throw UnsupportedError('Sums the order lines.');
  }
}
''',
        },
      ),
    );

    test('an arrow getter that throws is a stub, not a fabricated value', () {
      // The idiomatic generated getter stub — misreading it as a return would
      // make the check fire on every emitted accessor.
      final input = _input(
        server: {
          'lib/a.dart':
              "class S { String get name => throw UnsupportedError('The name.'); }",
        },
      );
      expect(_forCheck(6, input), isEmpty);
    });

    test('an arrow getter that returns a literal is fabricated', () {
      final input = _input(
        server: {'lib/a.dart': "class S { String get name => 'Order'; }"},
      );
      expect(_forCheck(6, input), isNotEmpty);
    });

    test('a 3b body returns the last step\'s collaborator call', () {
      // §2.4 B3's own shape. Reading "returns a value" as the offence would
      // reject every form-3b body the derivation produces.
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  late final OrderServiceCollaborator collaborator;
  Future<int> total(String orderId) async {
    await collaborator.totalGathersTheLines(orderId);
    return collaborator.totalSumsThem(orderId);
  }
}
''',
        },
      );
      expect(_forCheck(6, input), isEmpty);
    });

    test('a return of a final local bound from a call is not fabricated', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  int total(String orderId) {
    final lines = query.select(orderId);
    return lines;
  }
}
''',
        },
      );
      expect(_forCheck(6, input), isEmpty);
    });

    test('a return of a value the body composed is fabricated', () {
      // The shape §2.4 invariant 2 exists for: the value looks obtained, and
      // every part of it came out of the generator.
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  String label(String orderId) {
    final lines = query.select(orderId);
    return 'Order ' + orderId;
  }
}
''',
        },
      );
      expect(_forCheck(6, input), isNotEmpty);
    });

    test('a bare return returns nothing, so it fabricates nothing', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  void cancel(String orderId) {
    collaborator.cancelReleasesTheHold(orderId);
    return;
  }
}
''',
        },
      );
      expect(_forCheck(6, input), isEmpty);
    });
  });

  group('7 — back-link set equality (§2.5 rules 4–5)', () {
    _redGreen(
      7,
      '§2.5 rules 4–5',
      says: contains('differs from the @DocSpec section ids'),
      red: _input(
        client: {
          'lib/a.dart': '''
@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1', 'SBP.4.2'])
@DocSpec([DocRef('SBP.4.1', 'the order form')])
class orderForm {}
''',
        },
      ),
      green: _input(
        client: {
          'lib/a.dart': '''
@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1', 'SBP.4.2'])
@DocSpec([DocRef('SBP.4.2', 'the lines'), DocRef('SBP.4.1', 'the order form')])
class orderForm {}
''',
        },
      ),
    );

    test('rule 6: a member adding no section carries neither back-link', () {
      final input = _input(
        client: {'lib/a.dart': 'class orderForm { String? note; }'},
      );
      expect(_forCheck(7, input), isEmpty);
    });

    test('one back-link without the other fails', () {
      final input = _input(
        client: {
          'lib/a.dart':
              "@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1']) class orderForm {}",
        },
      );
      expect(
        _forCheck(7, input).single.message,
        contains('@CodeSpec without @DocSpec'),
      );
    });

    test('a member carrying @DocSpec alone is the normal case', () {
      final input = _input(
        client: {
          'lib/a.dart': '''
@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1', 'SBP.4.2'])
@DocSpec([DocRef('SBP.4.1', 'the order form'), DocRef('SBP.4.2', 'the lines')])
class orderForm {
  @DocSpec([DocRef('SBP.4.2', 'the lines')])
  late final String lines;
}
''',
        },
      );
      expect(_forCheck(7, input), isEmpty);
    });

    test('@CodeSpec on a member fails — it belongs to the emission unit', () {
      final input = _input(
        client: {
          'lib/a.dart': '''
@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1', 'SBP.4.2'])
@DocSpec([DocRef('SBP.4.1', 'the order form'), DocRef('SBP.4.2', 'the lines')])
class orderForm {
  @CodeSpec('ce-fm.orderForm.lines', source: ['SBP.4.2'])
  @DocSpec([DocRef('SBP.4.2', 'the lines')])
  late final String lines;
}
''',
        },
      );
      expect(
        _forCheck(7, input).single.message,
        allOf(
          contains('orderForm.lines carries @CodeSpec'),
          contains('belongs to the emission unit'),
        ),
      );
    });

    test('rule 5: a section only a member cites must reach the unit', () {
      final input = _input(
        client: {
          'lib/a.dart': '''
@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1'])
@DocSpec([DocRef('SBP.4.1', 'the order form')])
class orderForm {
  @DocSpec([DocRef('SBP.4.2', 'the lines')])
  late final String lines;
}
''',
        },
      );
      expect(
        _forCheck(7, input).single.message,
        allOf(
          contains('the emission unit omits SBP.4.2 (from orderForm.lines)'),
          contains('@CodeSpec.source'),
        ),
      );
    });
  });

  group('8 — per-kind slot exclusivity (§2.3)', () {
    _redGreen(
      8,
      '§2.3',
      says: contains("fills the 'channel' slot"),
      red: _input(
        client: {
          'lib/a.dart': '''
const enter = CsActionRef('enter');

@CsTrigger(
  kind: CsTriggerKind.lifecycle,
  action: CsActionRef('enter'),
  scope: CsLifecycleScope.screen,
  phase: CsLifecyclePhase.enter,
  channel: 'orders',
)
class orderScreen {}
''',
        },
      ),
      green: _input(
        client: {
          'lib/a.dart': '''
const enter = CsActionRef('enter');

@CsTrigger(
  kind: CsTriggerKind.lifecycle,
  action: CsActionRef('enter'),
  scope: CsLifecycleScope.screen,
  phase: CsLifecyclePhase.enter,
)
class orderScreen {}
''',
        },
      ),
    );

    test('@CsAuthorize slots are exclusive per requirement', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsAuthorize(requirement: CsAuthRequirement.role, roles: [], groups: ['ops'])
class Reports {}
''',
        },
      );
      expect(_forCheck(8, input).single.message, contains("'groups' slot"));
    });

    test('an empty list is an unfilled slot, not a filled one', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsAuthorize(requirement: CsAuthRequirement.role, roles: [], groups: [])
class Reports {}
''',
        },
      );
      expect(_forCheck(8, input), isEmpty);
    });

    test('@CsJob slots are exclusive per trigger', () {
      final input = _input(
        server: {
          'lib/a.dart':
              "@CsJob(trigger: CsJobTrigger.cron, cron: '0 * * * *', event: 'x') "
                  'class Nightly {}',
        },
      );
      expect(_forCheck(8, input).single.message, contains("'event' slot"));
    });
  });

  group('9 — mirrored catalogues (§5.3)', () {
    _redGreen(
      9,
      '§5.3',
      says: contains('does not mirror'),
      red: _input(
        mirrors: const [
          CsEnumMirror(
            csEnumName: 'CsErrorSeverity',
            coreEnumName: 'TomErrorSeverity',
            csValues: ['info', 'warning', 'error'],
            coreValues: ['info', 'warning', 'error', 'fatal'],
          ),
        ],
      ),
      green: _input(
        mirrors: const [
          CsEnumMirror(
            csEnumName: 'CsErrorSeverity',
            coreEnumName: 'TomErrorSeverity',
            csValues: ['info', 'warning', 'error', 'fatal'],
            coreValues: ['info', 'warning', 'error', 'fatal'],
          ),
        ],
      ),
    );

    test('order is part of the mirror, not only membership', () {
      final input = _input(
        mirrors: const [
          CsEnumMirror(
            csEnumName: 'CsErrorSeverity',
            coreEnumName: 'TomErrorSeverity',
            csValues: ['warning', 'info'],
            coreValues: ['info', 'warning'],
          ),
        ],
      );
      expect(_forCheck(9, input), isNotEmpty);
    });

    test('readCsEnumMirrors pairs the two packages as source text', () {
      final mirrors = readCsEnumMirrors(
        csSources: ['enum CsErrorSeverity { info, warning, error, fatal }'],
        coreSources: ['enum TomErrorSeverity { info, warning, error, fatal }'],
      );
      expect(mirrors.single.csValues, ['info', 'warning', 'error', 'fatal']);
      expect(_forCheck(9, _input(mirrors: mirrors)), isEmpty);
    });

    test('an undeclared counterpart reports rather than passing silently', () {
      final mirrors = readCsEnumMirrors(
        csSources: ['enum CsErrorSeverity { info, warning, error, fatal }'],
        coreSources: const ['class Nothing {}'],
      );
      expect(mirrors.single.coreValues, isEmpty);
      expect(_forCheck(9, _input(mirrors: mirrors)), isNotEmpty);
    });

    test('only pairs with a declared counterpart are checkable', () {
      // §5.3 lists fourteen mirror rows; the rest mirror a document section,
      // which no value-for-value comparison can reach.
      expect(csMirroredEnumPairs, {'CsErrorSeverity': 'TomErrorSeverity'});
    });
  });

  group('10 — error copy category (§3.1.3)', () {
    _redGreen(
      10,
      '§3.1.3',
      says: contains('role error but category uiCopy'),
      red: _input(
        shared: {
          'lib/a.dart': '''
@CsText(
  baseCopy: 'The order could not be placed.',
  role: CsTextRole.error,
  category: CsTextCategory.uiCopy,
)
class orderFailed {}
''',
        },
      ),
      green: _input(
        shared: {
          'lib/a.dart': '''
@CsText(
  baseCopy: 'The order could not be placed.',
  role: CsTextRole.error,
  category: CsTextCategory.errorCopy,
)
class orderFailed {}
''',
        },
      ),
    );

    test('the default category is uiCopy, so an error role must say so', () {
      final input = _input(
        shared: {
          'lib/a.dart':
              "@CsText(baseCopy: 'x', role: CsTextRole.error) class e {}",
        },
      );
      expect(_forCheck(10, input), isNotEmpty);
    });
  });

  group('11 — locus dependency arrow (§2.2)', () {
    _redGreen(
      11,
      '§2.2',
      says: contains('only client and server may depend on shared'),
      red: _input(
        shared: {
          'lib/a.dart': "import 'package:$_clientPackage/a.dart';\nclass A {}",
        },
      ),
      green: _input(
        client: {
          'lib/a.dart': "import 'package:$_sharedPackage/a.dart';\nclass A {}",
        },
      ),
    );

    test('client and server may not see each other either', () {
      final input = _input(
        server: {
          'lib/a.dart': "import 'package:$_clientPackage/a.dart';\nclass A {}",
        },
      );
      expect(_forCheck(11, input), isNotEmpty);
    });
  });

  group('12 — operation agreement (§3.4.2)', () {
    _redGreen(
      12,
      '§3.4.2',
      says: contains('which the shared project does not declare'),
      red: _input(
        server: {'lib/a.dart': "@CsEndpoint('order.place') class PlaceOrder {}"},
      ),
      green: _input(
        shared: {
          'lib/a.dart': "@CsEndpoint('order.place') class PlaceOrderContract {}",
        },
        server: {'lib/a.dart': "@CsEndpoint('order.place') class PlaceOrder {}"},
      ),
    );

    test('a shared CsOperationRef const also declares the operation', () {
      final input = _input(
        shared: {'lib/a.dart': "const place = CsOperationRef('order.place');"},
        server: {'lib/a.dart': "@CsEndpoint('order.place') class PlaceOrder {}"},
      );
      expect(_forCheck(12, input), isEmpty);
    });
  });

  group('13 — cumulative DDL convergence (§3.3.5)', () {
    const model = '''
@CsTable('orders')
class Order {
  @CsColumn(column: 'id')
  String id;

  @CsColumn(column: 'total')
  double total;
}
''';

    _redGreen(
      13,
      '§3.3.5',
      says: contains("@CsColumn 'total'"),
      red: _input(
        server: {'lib/a.dart': model},
        migrations: const {
          '001_initial.sql': 'CREATE TABLE orders (id TEXT PRIMARY KEY);',
        },
      ),
      green: _input(
        server: {'lib/a.dart': model},
        migrations: const {
          '001_initial.sql': 'CREATE TABLE orders (id TEXT PRIMARY KEY);',
          '002_total.sql': 'ALTER TABLE orders ADD COLUMN total REAL;',
        },
      ),
    );

    test('a DDL column no @CsColumn declares fails the other way too', () {
      final input = _input(
        server: {'lib/a.dart': model},
        migrations: const {
          '001_initial.sql':
              'CREATE TABLE orders (id TEXT, total REAL, legacy TEXT);',
        },
      );
      expect(
        _forCheck(13, input).single.message,
        contains("leaves column 'legacy'"),
      );
    });

    test('migrations apply in version order, so a later drop wins', () {
      final applied = applyMigrations(const {
        '002_drop.sql': 'ALTER TABLE orders DROP COLUMN legacy;',
        '001_initial.sql': 'CREATE TABLE orders (id TEXT, legacy TEXT);',
      });
      expect(applied, {
        'orders': {'id'},
      });
    });

    test('a table constraint is not a column', () {
      final applied = applyMigrations(const {
        '001.sql': 'CREATE TABLE orders (id TEXT, customer TEXT, '
            'PRIMARY KEY (id), FOREIGN KEY (customer) REFERENCES c(id));',
      });
      expect(applied['orders'], {'id', 'customer'});
    });

    test('no migrations means nothing to converge on', () {
      expect(_forCheck(13, _input(server: {'lib/a.dart': model})), isEmpty);
    });
  });

  group('14 — the non-declarable compose token (§3.2.2)', () {
    _redGreen(
      14,
      '§3.2.2',
      says: contains("declares 'compose'"),
      red: _input(
        shared: {
          'lib/a.dart':
              "@CsValidation(rules: 'required,compose') class amount {}",
        },
      ),
      green: _input(
        shared: {
          'lib/a.dart':
              "@CsValidation(rules: 'required,range:0..100') class amount {}",
        },
      ),
    );

    test('a rule whose name merely contains compose is not the token', () {
      final input = _input(
        shared: {
          'lib/a.dart': "@CsValidation(rules: 'composedOf:a') class amount {}",
        },
      );
      expect(_forCheck(14, input), isEmpty);
    });
  });

  group('15 — overridableBy scope narrowing (§3.3.6, §5.3)', () {
    _redGreen(
      15,
      '§3.3.6, §5.3',
      says: contains('which is not strictly narrower than its own'),
      red: _input(
        client: {
          'lib/a.dart': "@CsUserSetting('theme', "
              'overridableBy: CsOverridableBy.client) class theme {}',
        },
      ),
      green: _input(
        client: {
          'lib/a.dart': "@CsUserSetting('theme', "
              'overridableBy: CsOverridableBy.device) class theme {}',
        },
      ),
    );

    test('a server config may open any narrower scope', () {
      final input = _input(
        server: {
          'lib/a.dart': "@CsServerConfig('db.pool', "
              'overridableBy: CsOverridableBy.device) class dbPool {}',
        },
      );
      expect(_forCheck(15, input), isEmpty);
    });

    test('none is always valid', () {
      final input = _input(
        client: {
          'lib/a.dart': "@CsClientConfig('api.base', "
              'overridableBy: CsOverridableBy.none) class apiBase {}',
        },
      );
      expect(_forCheck(15, input), isEmpty);
    });
  });

  group('16 — a secret carries no default (§3.3.6)', () {
    _redGreen(
      16,
      '§3.3.6',
      says: contains('a credential in the source tree'),
      red: _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @CsServerConfig('db.password',
      overridableBy: CsOverridableBy.none, secret: true)
  static const String dbPassword = 'changeit';
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @CsServerConfig('db.password',
      overridableBy: CsOverridableBy.none, secret: true)
  static late final String dbPassword;
}
''',
        },
      ),
    );

    test('a non-secret setting may carry its default', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @CsServerConfig('db.pool', overridableBy: CsOverridableBy.none)
  static const int dbPool = 8;
}
''',
        },
      );
      expect(_forCheck(16, input), isEmpty);
    });
  });

  group('17 — notification fallback channel (§3.2.9)', () {
    _redGreen(
      17,
      '§3.2.9',
      says: contains('which the catalogue'),
      red: _input(
        server: {
          'lib/a.dart': '''
class Channels {
  static const all = [
    TomNotificationChannelDeclaration(
        channelId: 'push', fallbackChannelId: 'sms'),
  ];
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class Channels {
  static const all = [
    TomNotificationChannelDeclaration(
        channelId: 'push', fallbackChannelId: 'sms'),
    TomNotificationChannelDeclaration(channelId: 'sms'),
  ];
}
''',
        },
      ),
    );

    test('a fallback cycle is membership, not a violation', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class Channels {
  static const all = [
    TomNotificationChannelDeclaration(
        channelId: 'push', fallbackChannelId: 'sms'),
    TomNotificationChannelDeclaration(
        channelId: 'sms', fallbackChannelId: 'push'),
  ];
}
''',
        },
      );
      expect(_forCheck(17, input), isEmpty);
    });

    test('a channel of another catalogue does not satisfy the fallback', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class Alerts {
  static const all = [
    TomNotificationChannelDeclaration(
        channelId: 'push', fallbackChannelId: 'sms'),
  ];
}

class Digests {
  static const all = [TomNotificationChannelDeclaration(channelId: 'sms')];
}
''',
        },
      );
      expect(_forCheck(17, input), isNotEmpty);
    });
  });

  group('18 — report drill-through route (§3.3.9)', () {
    _redGreen(
      18,
      '§3.3.9',
      says: contains('which the client project does not declare'),
      red: _input(
        server: {
          'lib/a.dart': '''
class SalesReport {
  static const columns = [
    TomReportColumn(key: 'order', drillThroughRouteId: 'orderDetail'),
  ];
}
''',
        },
      ),
      green: _input(
        client: {'lib/a.dart': "const orderDetail = CsRouteRef('orderDetail');"},
        server: {
          'lib/a.dart': '''
class SalesReport {
  static const columns = [
    TomReportColumn(key: 'order', drillThroughRouteId: 'orderDetail'),
  ];
}
''',
        },
      ),
    );

    test('a route declared in the server does not satisfy a drill-through', () {
      // The check looks across projects in the direction generated code may not
      // take; resolving it locally would defeat the point.
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsRoute()
class orderDetail {}

class SalesReport {
  static const columns = [
    TomReportColumn(key: 'order', drillThroughRouteId: 'orderDetail'),
  ];
}
''',
        },
      );
      expect(_forCheck(18, input), isNotEmpty);
    });

    test('a @CsRoute declaration in the client satisfies it', () {
      final input = _input(
        client: {'lib/a.dart': '@CsRoute() class orderDetail {}'},
        server: {
          'lib/a.dart': '''
class SalesReport {
  static const columns = [
    TomReportColumn(key: 'order', drillThroughRouteId: 'orderDetail'),
  ];
}
''',
        },
      );
      expect(_forCheck(18, input), isEmpty);
    });
  });

  group('19 — a secret is only ever declared (§3.3.6)', () {
    _redGreen(
      19,
      '§3.3.6',
      says: contains('rather than SCSET'),
      red: _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @DocSpec([DocRef('LOSTPO', 'the audit sink storage policy')])
  @CsServerConfig('logStorage.sinkPassword',
      overridableBy: CsOverridableBy.none, secret: true)
  static late final String sinkPassword;
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @DocSpec([DocRef('SCSET', 'declares the audit sink credential')])
  @CsServerConfig('audit.sink.password',
      overridableBy: CsOverridableBy.none, secret: true)
  static late final String sinkPassword;
}
''',
        },
      ),
    );

    test('a fixed-band setting that is not secret is untouched', () {
      // The fixed shape is the majority of CE-CF; the check must not fire on
      // the 41 bands merely for being fixed.
      final input = _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @DocSpec([DocRef('LOREPO', 'the audit sink retention policy')])
  @CsServerConfig('logRetention.minimumRetention',
      overridableBy: CsOverridableBy.none)
  static const String minimumRetention = 'P1Y';
}
''',
        },
      );
      expect(_forCheck(19, input), isEmpty);
    });

    test('a secret with no back-link at all fires', () {
      // An untraceable secret is the same defect seen from further away: the
      // back-link is what says which shape authored it.
      final input = _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @CsServerConfig('audit.sink.password',
      overridableBy: CsOverridableBy.none, secret: true)
  static late final String sinkPassword;
}
''',
        },
      );
      expect(_forCheck(19, input), isNotEmpty);
      expect(
        _forCheck(19, input).first.message,
        contains('no @DocSpec back-link'),
      );
    });
  });

  group('20 — setting keys share one namespace (§2.1 N10)', () {
    _redGreen(
      20,
      '§2.1 N10',
      says: contains('claimed twice'),
      red: _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @DocSpec([DocRef('LOREPO', 'the audit sink retention policy')])
  @CsServerConfig('logRetention.minimumRetention',
      overridableBy: CsOverridableBy.none)
  static const String minimumRetention = 'P1Y';

  @DocSpec([DocRef('SCSET', 'the application retention floor')])
  @CsServerConfig('logRetention.minimumRetention',
      overridableBy: CsOverridableBy.none)
  static const String retentionFloor = 'P30D';
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @DocSpec([DocRef('LOREPO', 'the audit sink retention policy')])
  @CsServerConfig('logRetention.minimumRetention',
      overridableBy: CsOverridableBy.none)
  static const String minimumRetention = 'P1Y';

  @DocSpec([DocRef('SCSET', 'the application retention floor')])
  @CsServerConfig('audit.retentionFloor', overridableBy: CsOverridableBy.none)
  static const String retentionFloor = 'P30D';
}
''',
        },
      ),
    );

    test('the message names both contributing sections', () {
      // The collision is between two *shapes*, so a message naming only the
      // symbols would leave the author guessing which band derived the key.
      final input = _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @DocSpec([DocRef('LOREPO', 'the audit sink retention policy')])
  @CsServerConfig('logRetention.minimumRetention',
      overridableBy: CsOverridableBy.none)
  static const String minimumRetention = 'P1Y';

  @DocSpec([DocRef('SCSET', 'the application retention floor')])
  @CsServerConfig('logRetention.minimumRetention',
      overridableBy: CsOverridableBy.none)
  static const String retentionFloor = 'P30D';
}
''',
        },
      );
      final message = _forCheck(20, input).single.message;
      expect(message, contains('LOREPO'));
      expect(message, contains('SCSET'));
    });

    test('a blank key is check 4, not this one', () {
      // Two blank keys are indistinguishable as keys; reporting them as a
      // collision would name the wrong rule.
      final input = _input(
        server: {
          'lib/a.dart': '''
class ServerConfig {
  @CsServerConfig('', overridableBy: CsOverridableBy.none)
  static const String one = 'a';

  @CsServerConfig('', overridableBy: CsOverridableBy.none)
  static const String two = 'b';
}
''',
        },
      );
      expect(_forCheck(20, input), isEmpty);
      expect(_forCheck(4, input), isNotEmpty);
    });
  });

  group('21 — the graded depth is exactly one level (§3.4.3)', () {
    _redGreen(
      21,
      '§3.4.3',
      says: contains('graded depth is exactly one level'),
      red: _input(
        server: {
          'lib/a.dart': '''
@DocSpec([DocRef('AZREQ', 'the requirement this operation is gated by')])
@CsEndpoint('customer.save')
@CsAuthorize(
  requirement: CsAuthRequirement.graded,
  graded: CsGradedAccess(
    full: CsAuthorize(
      requirement: CsAuthRequirement.graded,
      graded: CsGradedAccess(
        full: CsAuthorize(
          requirement: CsAuthRequirement.role,
          roles: [CsRoleRef('sales')],
        ),
      ),
    ),
  ),
)
class customerSave {}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
@DocSpec([DocRef('AZREQ', 'the requirement this operation is gated by')])
@CsEndpoint('customer.save')
@CsAuthorize(
  requirement: CsAuthRequirement.graded,
  graded: CsGradedAccess(
    full: CsAuthorize(
      requirement: CsAuthRequirement.role,
      roles: [CsRoleRef('salesManager')],
    ),
    read: CsAuthorize(
      requirement: CsAuthRequirement.role,
      roles: [CsRoleRef('sales')],
    ),
    disabled: CsAuthorize(requirement: CsAuthRequirement.authenticated),
  ),
)
class customerSave {}
''',
        },
      ),
    );

    test('names the slot the nested grading sits in', () {
      // Three slots look alike in a wrapped annotation; without the slot name
      // the author has to re-read the whole tree to find the one that broke.
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsEndpoint('customer.save')
@CsAuthorize(
  requirement: CsAuthRequirement.graded,
  graded: CsGradedAccess(
    full: CsAuthorize(
      requirement: CsAuthRequirement.role,
      roles: [CsRoleRef('salesManager')],
    ),
    read: CsAuthorize(
      requirement: CsAuthRequirement.graded,
      graded: CsGradedAccess(
        full: CsAuthorize(requirement: CsAuthRequirement.authenticated),
      ),
    ),
  ),
)
class customerSave {}
''',
        },
      );
      expect(_forCheck(21, input).single.message, contains("'read' slot"));
    });

    test('a non-graded requirement with no graded slot is not this check', () {
      // The overwhelming majority of requirements are a single kind with no
      // grading at all; the check must not have an opinion about them.
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsEndpoint('customer.save')
@CsAuthorize(
  requirement: CsAuthRequirement.role,
  roles: [CsRoleRef('sales')],
)
class customerSave {}
''',
        },
      );
      expect(_forCheck(21, input), isEmpty);
    });

    test('reports every nested grading, not only the outermost', () {
      // Dart puts no depth limit on the nesting, so stopping at the first
      // violation would send the author round the loop once per level.
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsEndpoint('customer.save')
@CsAuthorize(
  requirement: CsAuthRequirement.graded,
  graded: CsGradedAccess(
    full: CsAuthorize(
      requirement: CsAuthRequirement.graded,
      graded: CsGradedAccess(
        full: CsAuthorize(
          requirement: CsAuthRequirement.graded,
          graded: CsGradedAccess(
            full: CsAuthorize(requirement: CsAuthRequirement.authenticated),
          ),
        ),
      ),
    ),
  ),
)
class customerSave {}
''',
        },
      );
      expect(_forCheck(21, input), hasLength(2));
    });
  });

  group('22 — a persisted column is never an observable (§3.3.2)', () {
    _redGreen(
      22,
      '§3.3.2',
      says: contains('plain Dart field'),
      red: _input(
        server: {
          'lib/a.dart': '''
@CsTable('customer', datasource: 'core')
class Customer {
  @CsColumn(column: 'cust_name', columnType: 'VARCHAR', length: 80)
  TomNString name = TomNString(null);
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
@CsTable('customer', datasource: 'core')
class Customer {
  @CsColumn(column: 'cust_name', columnType: 'VARCHAR', length: 80)
  String? name;
}
''',
        },
      ),
    );

    test('catches the inferred spelling, which names no type at all', () {
      // `final name = TomNString(null);` is the commoner way to write an
      // observable member, and it is exactly the one a declared-type rule
      // would miss — so the check reads the initialiser too.
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsTable('customer', datasource: 'core')
class Customer {
  @CsColumn(column: 'cust_name')
  final name = TomNString(null);
}
''',
        },
      );
      expect(_forCheck(22, input).single.message, contains('TomNString'));
    });

    test('a non-nullable observable is caught by the same rule', () {
      // The defect is the observable, not the nullability: a `TomString`
      // column cannot be written either.
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsTable('customer', datasource: 'core')
class Customer {
  @CsColumn(column: 'cust_name')
  TomString name = TomString('');
}
''',
        },
      );
      expect(_forCheck(22, input), hasLength(1));
    });

    test('TomZonedDate is a value type and stays a legal column', () {
      // Why the family is a closed list rather than a `Tom` prefix rule: the
      // zoned *value* types are not observables and are persisted directly.
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsTable('event', datasource: 'core')
class Event {
  @CsColumn(column: 'tag_day')
  TomZonedDate? tagDay;
}
''',
        },
      );
      expect(_forCheck(22, input), isEmpty);
    });

    test('an observable outside a @CsColumn is not this check', () {
      // CE-ST is where the family belongs; the check must have no opinion
      // about a view-state member.
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsViewModel()
class CustomerState {
  final name = TomNString(null);
}
''',
        },
      );
      expect(_forCheck(22, input), isEmpty);
    });
  });

  group('23 — every collaborator call resolves (§2.4, §3.0.1)', () {
    _redGreen(
      23,
      '§2.4, §3.0.1',
      says: contains('does not declare'),
      red: _input(
        client: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class CustomerActionControllerCollaborator {
  Future<void> saveCustomerCheckTheEditedValues(Object context);
}

@CsAction()
class CustomerActionController {
  late final CustomerActionControllerCollaborator collaborator;

  Future<void> saveCustomer(Object context) async {
    await collaborator.saveCustomerCheckTheEditedValues(context);
    await collaborator.saveCustomerStoreTheRecord(context);
  }
}
''',
        },
      ),
      green: _input(
        client: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class CustomerActionControllerCollaborator {
  Future<void> saveCustomerCheckTheEditedValues(Object context);
  Future<void> saveCustomerStoreTheRecord(Object context);
}

@CsAction()
class CustomerActionController {
  late final CustomerActionControllerCollaborator collaborator;

  Future<void> saveCustomer(Object context) async {
    await collaborator.saveCustomerCheckTheEditedValues(context);
    await collaborator.saveCustomerStoreTheRecord(context);
  }
}
''',
        },
      ),
    );

    test('a collaborator call with no collaborator field at all', () {
      // The call resolves against nothing: §3.0.1 injects through one field, so
      // a body that reaches for `collaborator` on a declaration that has none
      // is a statement written against something never emitted.
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsAction()
class CustomerActionController {
  Future<void> saveCustomer(Object context) async {
    await collaborator.saveCustomerStoreTheRecord(context);
  }
}
''',
        },
      );
      expect(_forCheck(23, input).first.message, contains('declares no'));
    });

    test('a collaborator field whose type names no emitted collaborator', () {
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsAction()
class CustomerActionController {
  late final CustomerActionControllerCollaborator collaborator;

  Future<void> saveCustomer(Object context) async {
    await collaborator.saveCustomerStoreTheRecord(context);
  }
}
''',
        },
      );
      expect(
        _forCheck(23, input).first.message,
        contains('names no emitted @CsCollaborator class'),
      );
    });

    test('the reverse half: a collaborator method nothing calls', () {
      // The defect the compiler never catches — a step whose behaviour was
      // lifted out of the body and then dropped, leaving Phase 6 a method that
      // runs nowhere.
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class CustomerActionControllerCollaborator {
  Future<void> saveCustomerCheckTheEditedValues(Object context);
  Future<void> saveCustomerStoreTheRecord(Object context);
}

@CsAction()
class CustomerActionController {
  late final CustomerActionControllerCollaborator collaborator;

  Future<void> saveCustomer(Object context) async {
    await collaborator.saveCustomerCheckTheEditedValues(context);
  }
}
''',
        },
      );
      expect(
        _forCheck(23, input).single.message,
        contains('saveCustomerStoreTheRecord is declared but no body calls it'),
      );
    });

    test('a substrate call is left to the compiler, not to this check', () {
      // The §6 division: a call on the `tom_core`-family substrate needs the
      // resolved element model and is a compile error in the emitted trio
      // anyway, so the syntax pass must have no opinion about it.
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsViewModel()
class CustomerState {
  Future<void> reload() async {
    await repository.selectAll();
  }
}
''',
        },
      );
      expect(_forCheck(23, input), isEmpty);
    });

    test('a declaration whose 3b bodies all fell back to 3a emits none', () {
      // §3.0: no calls, so no collaborator — and the check must not read the
      // absence as a defect.
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsAction()
class CustomerActionController {
  Future<void> saveCustomer(Object context) async {
    throw UnsupportedError('The customer record is saved.');
  }
}
''',
        },
      );
      expect(_forCheck(23, input), isEmpty);
    });
  });

  group('24 — a collaborator holds abstract methods and nothing else (§3.0.1)',
      () {
    _redGreen(
      24,
      '§3.0.1',
      says: contains('a field on a @CsCollaborator class'),
      red: _input(
        client: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class CustomerActionControllerCollaborator {
  final Object cache = Object();

  Future<void> saveCustomerStoreTheRecord(Object context);
}
''',
        },
      ),
      green: _input(
        client: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class CustomerActionControllerCollaborator {
  Future<void> saveCustomerStoreTheRecord(Object context);
}
''',
        },
      ),
    );

    test('a non-abstract collaborator class', () {
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsCollaborator()
class CustomerActionControllerCollaborator {
  Future<void> saveCustomerStoreTheRecord(Object context) async {}
}
''',
        },
      );
      expect(
        _forCheck(24, input).map((v) => v.message).join('\n'),
        contains('is not declared abstract'),
      );
    });

    test('an implemented method pre-empts the Phase-6 implementation', () {
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class CustomerActionControllerCollaborator {
  Future<void> saveCustomerStoreTheRecord(Object context) async {}
}
''',
        },
      );
      expect(
        _forCheck(24, input).single.message,
        contains('an implemented method'),
      );
    });

    test('a constructor makes the seam constructible', () {
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class CustomerActionControllerCollaborator {
  CustomerActionControllerCollaborator();

  Future<void> saveCustomerStoreTheRecord(Object context);
}
''',
        },
      );
      expect(
        _forCheck(24, input).single.message,
        contains('a constructor'),
      );
    });

    test('a static member hides logic no step maps to', () {
      final input = _input(
        client: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class CustomerActionControllerCollaborator {
  static Object build() => Object();

  Future<void> saveCustomerStoreTheRecord(Object context);
}
''',
        },
      );
      expect(
        _forCheck(24, input).single.message,
        contains('a static member'),
      );
    });

    test('an ordinary abstract class without the marker is not this check', () {
      final input = _input(
        client: {
          'lib/a.dart': '''
abstract class Something {
  final Object cache = Object();
}
''',
        },
      );
      expect(_forCheck(24, input), isEmpty);
    });
  });

  group('25 — every form-3 method carries a doc comment (§2.8 C2 P3)', () {
    _redGreen(
      25,
      '§2.8 C2 P3, §3.0.1',
      says: contains('carries no doc comment'),
      red: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  void place() {
    throw UnsupportedError('Places the order.');
  }
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  void place() {
    throw UnsupportedError('Places the order.');
  }
}
''',
        },
      ),
    );

    test('a collaborator method has no body, so the comment is all there is',
        () {
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class OrderServiceCollaborator {
  Future<void> placeReservesTheStock(String orderId);
}
''',
        },
      );
      expect(_forCheck(25, input), isNotEmpty);
    });

    test('a form-1 or form-2 declaration is covered by P2, not by this rule',
        () {
      // No body anywhere, so the declaration is not form-3 and its members are
      // not held to P3.
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsTable('orders')
class Order {
  String? reference;
}
''',
        },
      );
      expect(_forCheck(25, input), isEmpty);
    });

    test('every method of a form-3 declaration, not only the form-3 ones', () {
      // P3 attaches to the declaration: one method that throws makes the whole
      // declaration form-3, and a second method without a comment is a step
      // whose description was dropped just the same.
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  void place() {
    throw UnsupportedError('Places the order.');
  }

  String get reference => throw UnsupportedError('The order reference.');
}
''',
        },
      );
      expect(_forCheck(25, input), hasLength(1));
      expect(_forCheck(25, input).single.message, contains('reference'));
    });

    test('an empty doc comment is as absent as none at all', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  ///
  void place() {
    throw UnsupportedError('Places the order.');
  }
}
''',
        },
      );
      expect(_forCheck(25, input), isNotEmpty);
    });
  });

  group('26 — no in-body comment (§2.8 C6, §2.7)', () {
    _redGreen(
      26,
      '§2.8 C6, §2.7',
      says: contains('the value nothing'),
      red: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  void place() {
    // TODO: implement in Phase 6.
    throw UnsupportedError('Places the order.');
  }
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  void place() {
    throw UnsupportedError('Places the order.');
  }
}
''',
        },
      ),
    );

    test('§2.7\'s three-line banner is the one permitted //', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
// Generated by the CodeSpecs generator.
// codespecs_derivation_contract.md §2.7
// Do not edit; regenerate.

class Order {}
''',
        },
      );
      expect(_forCheck(26, input), isEmpty);
    });

    test('a fourth line above the imports is a comment beside the banner', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
// Generated by the CodeSpecs generator.
// codespecs_derivation_contract.md §2.7
// Do not edit; regenerate.
// Derived from CLA-4.2.

class Order {}
''',
        },
      );
      expect(_forCheck(26, input), hasLength(1));
    });

    test('a doc comment is not a comment this rule forbids', () {
      final input = _input(
        server: {'lib/a.dart': '/// The order.\nclass Order {}\n'},
      );
      expect(_forCheck(26, input), isEmpty);
    });
  });

  group('27 — doc comment shape (§2.8 C4)', () {
    _redGreen(
      27,
      '§2.8 C4',
      says: contains('unescaped'),
      red: _input(
        server: {
          'lib/a.dart': '''
/// Places an [Order] and returns its confirmation.
@CsTable('orders')
class Order {}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': r'''
/// Places an \[Order\] and returns its confirmation.
@CsTable('orders')
class Order {}
''',
        },
      ),
    );

    test('a trailing space is whitespace a second run may not reproduce', () {
      final input = _input(
        server: {'lib/a.dart': '/// The order. \nclass Order {}\n'},
      );
      expect(_forCheck(27, input), isNotEmpty);
      expect(_forCheck(27, input).first.message, contains('trailing'));
    });

    test('a blank line between the block and the first annotation', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
/// The order.

@CsTable('orders')
class Order {}
''',
        },
      );
      expect(_forCheck(27, input), isNotEmpty);
      expect(_forCheck(27, input).first.message, contains('blank line'));
    });

    test('the block sits above the *first* annotation, not the declaration',
        () {
      final input = _input(
        server: {
          'lib/a.dart': '''
/// The order.
@CodeSpec('ce-db.Order', source: ['SBP.3.1'])
@DocSpec([DocRef('SBP.3.1', 'the order table')])
@CsTable('orders')
class Order {}
''',
        },
      );
      expect(_forCheck(27, input), isEmpty);
    });

    test('an angle bracket is written &lt;, so dartdoc does not eat it', () {
      final input = _input(
        server: {'lib/a.dart': '/// Holds a <name>.\nclass Order {}\n'},
      );
      expect(_forCheck(27, input), isNotEmpty);
    });

    test('an enum constant\'s comment is a comment C4 constrains too', () {
      // §3.1.1 makes a domain enum's constant the one member whose comment is
      // its own trace, so the shape rules have to reach it like any other.
      final input = _input(
        shared: {
          'lib/a.dart': '''
@CsDomainEnum()
enum CustomerState {
  /// The state a <new> customer starts in.
  active,
}
''',
        },
      );
      expect(_forCheck(27, input), isNotEmpty);
    });

    test('a fenced code block is left exactly as the source wrote it', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
/// The order.
///
/// ```
/// order[0] = Order<int>();
/// ```
class Order {}
''',
        },
      );
      expect(_forCheck(27, input), isEmpty);
    });
  });

  group('28 — the form-3b statement kinds (§2.4)', () {
    _redGreen(
      28,
      '§2.4, §2.4 B3',
      says: contains('none of the five'),
      red: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(String orderId) async {
    orderId = orderId.trim();
    await collaborator.placeReservesTheStock(orderId);
  }
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(String orderId) async {
    await collaborator.placeReservesTheStock(orderId);
    return collaborator.placeConfirmsIt(orderId);
  }
}
''',
        },
      ),
    );

    test('a non-final local is a body that can reassign, so it computes', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Totals the order.
  int total(String orderId) {
    var lines = query.select(orderId);
    return lines;
  }
}
''',
        },
      );
      expect(_forCheck(28, input), isNotEmpty);
      expect(_forCheck(28, input).first.message, contains('final'));
    });

    test('a final local bound from something that is not a call', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Totals the order.
  int total(String orderId) {
    final limit = 100;
    return query.select(orderId);
  }
}
''',
        },
      );
      expect(_forCheck(28, input), isNotEmpty);
      expect(_forCheck(28, input).first.message, contains('not a call'));
    });

    test('binding a collaborator result is a B3 breach, not a kind-3 use', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(String orderId) async {
    final held = await collaborator.placeReservesTheStock(orderId);
    return collaborator.placeConfirmsIt(orderId);
  }
}
''',
        },
      );
      expect(_forCheck(28, input), isNotEmpty);
      expect(_forCheck(28, input).first.message, contains('B3'));
    });

    test('a throw inside a 3b body is a 3a body in the wrong place', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(String orderId) async {
    await collaborator.placeReservesTheStock(orderId);
    throw UnsupportedError('Confirms it.');
  }
}
''',
        },
      );
      expect(_forCheck(28, input), isNotEmpty);
    });

    test('a form-3a body is the throw, so this rule has nothing to judge', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  void place() {
    throw UnsupportedError('Places the order.');
  }
}
''',
        },
      );
      expect(_forCheck(28, input), isEmpty);
    });

    test('a statement nested in a branch is judged like any other', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(String orderId) async {
    if (await collaborator.placeStockIsShortApplies(orderId)) {
      orderId = orderId.trim();
    }
    return collaborator.placeConfirmsIt(orderId);
  }
}
''',
        },
      );
      expect(_forCheck(28, input), isNotEmpty);
    });
  });

  group('29 — branch conditions and B7 (§2.4 B4, §2.4 B7)', () {
    _redGreen(
      29,
      '§2.4 B4, §2.4 B7',
      says: contains('not a collaborator guard call'),
      red: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(String orderId, int total) async {
    if (total > 100) {
      await collaborator.placeEscalates(orderId, total);
    }
    return collaborator.placeConfirmsIt(orderId, total);
  }
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(String orderId, int total) async {
    if (await collaborator.placeOverLimitApplies(orderId, total)) {
      await collaborator.placeEscalates(orderId, total);
    }
    return collaborator.placeConfirmsIt(orderId, total);
  }
}
''',
        },
      ),
    );

    test('a guard on something other than the collaborator is still composed',
        () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(String orderId) async {
    if (policy.overLimitApplies(orderId)) {
      await collaborator.placeEscalates(orderId);
    }
    return collaborator.placeConfirmsIt(orderId);
  }
}
''',
        },
      );
      expect(_forCheck(29, input), isNotEmpty);
    });

    test('B7: this derivation produces no repetition', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(List<String> ids) async {
    for (final id in ids) {
      await collaborator.placeReservesTheStock(id);
    }
    return collaborator.placeConfirmsIt(ids);
  }
}
''',
        },
      );
      expect(_forCheck(29, input), isNotEmpty);
      expect(_forCheck(29, input).first.message, contains('repeats'));
    });

    test('B7: this derivation produces no multi-way choice', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  Future<void> place(String state) async {
    switch (state) {
      case 'held':
        await collaborator.placeReleasesTheHold(state);
    }
    return collaborator.placeConfirmsIt(state);
  }
}
''',
        },
      );
      expect(_forCheck(29, input), isNotEmpty);
      expect(_forCheck(29, input).first.message, contains('multi-way'));
    });

    test('a form-3a body has no branch, so this rule has nothing to judge', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
class OrderService {
  /// Places the order.
  void place() {
    throw UnsupportedError('Places the order.');
  }
}
''',
        },
      );
      expect(_forCheck(29, input), isEmpty);
    });
  });

  group('30 — the collaborator signature follows its caller (§3.0.1)', () {
    _redGreen(
      30,
      '§3.0.1, §2.4 B3, §2.4 B4',
      says: contains('name-for-name'),
      red: _input(
        server: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class OrderServiceCollaborator {
  /// Reserves the stock.
  Future<void> placeReservesTheStock(int orderId);
}

class OrderService {
  late final OrderServiceCollaborator collaborator;

  /// Places the order.
  Future<void> place(String orderId) async {
    return collaborator.placeReservesTheStock(orderId);
  }
}
''',
        },
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class OrderServiceCollaborator {
  /// Reserves the stock.
  Future<void> placeReservesTheStock(String orderId);
}

class OrderService {
  late final OrderServiceCollaborator collaborator;

  /// Places the order.
  Future<void> place(String orderId) async {
    return collaborator.placeReservesTheStock(orderId);
  }
}
''',
        },
      ),
    );

    test('an earlier contributing step produces no value', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class OrderServiceCollaborator {
  /// Reserves the stock.
  Future<String> placeReservesTheStock(String orderId);

  /// Confirms it.
  Future<void> placeConfirmsIt(String orderId);
}

class OrderService {
  late final OrderServiceCollaborator collaborator;

  /// Places the order.
  Future<void> place(String orderId) async {
    await collaborator.placeReservesTheStock(orderId);
    return collaborator.placeConfirmsIt(orderId);
  }
}
''',
        },
      );
      expect(_forCheck(30, input), hasLength(1));
      expect(_forCheck(30, input).single.message, contains('produces no value'));
    });

    test('a guard returns bool, because B4 made it a condition', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class OrderServiceCollaborator {
  /// Whether the order is over the limit.
  Future<String> placeOverLimitApplies(String orderId);

  /// Escalates it.
  Future<void> placeEscalates(String orderId);
}

class OrderService {
  late final OrderServiceCollaborator collaborator;

  /// Places the order.
  Future<void> place(String orderId) async {
    if (await collaborator.placeOverLimitApplies(orderId)) {
      await collaborator.placeEscalates(orderId);
    }
    return collaborator.placeEscalates(orderId);
  }
}
''',
        },
      );
      expect(_forCheck(30, input), isNotEmpty);
      expect(_forCheck(30, input).first.message, contains('guard'));
    });

    test('the last contributing step carries the calling body\'s return type',
        () {
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class OrderServiceCollaborator {
  /// Confirms it.
  Future<void> placeConfirmsIt(String orderId);
}

class OrderService {
  late final OrderServiceCollaborator collaborator;

  /// Places the order.
  Future<String> place(String orderId) async {
    return collaborator.placeConfirmsIt(orderId);
  }
}
''',
        },
      );
      expect(_forCheck(30, input), isNotEmpty);
      expect(_forCheck(30, input).first.message, contains('return'));
    });

    test('an unresolved call is check 23\'s, so this one stays silent', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
@CsCollaborator()
abstract class OrderServiceCollaborator {
  /// Confirms it.
  Future<void> placeConfirmsIt(String orderId);
}

class OrderService {
  late final OrderServiceCollaborator collaborator;

  /// Places the order.
  Future<void> place(String orderId) async {
    return collaborator.placeSomethingElse(orderId);
  }
}
''',
        },
      );
      expect(_forCheck(30, input), isEmpty);
      expect(_forCheck(23, input), isNotEmpty);
    });
  });

  group('31 — determinism (§2.8 C5, §2.1 N1)', () {
    _redGreen(
      31,
      '§2.8 C5, §2.1 N1',
      says: contains('differs between the two runs'),
      red: _input(
        server: {'lib/a.dart': "@CsTable('orders')\nclass Order {}\n"},
        againServer: {'lib/a.dart': "@CsTable('order')\nclass Order {}\n"},
      ),
      green: _input(
        server: {'lib/a.dart': "@CsTable('orders')\nclass Order {}\n"},
        againServer: {'lib/a.dart': "@CsTable('orders')\nclass Order {}\n"},
      ),
    );

    test('with one run there is nothing to compare, so it raises nothing', () {
      final input = _input(
        server: {'lib/a.dart': "@CsTable('orders')\nclass Order {}\n"},
      );
      expect(_forCheck(31, input), isEmpty);
    });

    test('a file name that changed is a naming derivation that is not one', () {
      final input = _input(
        server: {'lib/order.dart': 'class Order {}\n'},
        againServer: {'lib/order_1.dart': 'class Order {}\n'},
      );
      final raised = _forCheck(31, input);
      expect(raised, hasLength(2));
      expect(raised.first.message, contains('lib/order.dart'));
      expect(raised.last.message, contains('lib/order_1.dart'));
    });

    test('whitespace counts, because C5 promises bytes and not a model', () {
      final input = _input(
        server: {'lib/a.dart': 'class Order {}\n'},
        againServer: {'lib/a.dart': 'class  Order {}\n'},
      );
      expect(_forCheck(31, input), isNotEmpty);
    });

    test('the message names the line the two runs first disagreed on', () {
      final input = _input(
        server: {'lib/a.dart': 'class Order {}\nclass Line {}\n'},
        againServer: {'lib/a.dart': 'class Order {}\nclass Item {}\n'},
      );
      expect(_forCheck(31, input).single.message, contains('line 2'));
    });
  });

  group('32 — comment source (§2.8 C1)', () {
    _redGreen(
      32,
      '§2.8 C1',
      says: contains('no extract holds'),
      red: _input(
        server: {
          'lib/a.dart': '''
/// A person or organisation that places orders.
///
/// Customers place orders regularly and are our most valued relationship.
@CodeSpec('dataAccess.Customer', source: ['IMO-014'])
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
@CsTable('customer')
class Customer {}
''',
        },
        extracts: _extract(_customerEntries),
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
/// A person or organisation that places orders.
///
/// $_customerContent
@CodeSpec('dataAccess.Customer', source: ['IMO-014'])
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
@CsTable('customer')
class Customer {}
''',
        },
        extracts: _extract(_customerEntries),
      ),
    );

    test('with no extracts there is no second side, so it raises nothing', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
/// Prose that occurs in no specification anywhere.
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
class Customer {}
''',
        },
      );
      expect(_forCheck(32, input), isEmpty);
    });

    test('a section the extracts do not know is not a section it can judge',
        () {
      final input = _input(
        server: {
          'lib/a.dart': '''
/// Prose that occurs in no specification anywhere.
@DocSpec([DocRef('SBP.9.9', 'a section no area routed')])
class Order {}
''',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(32, input), isEmpty);
    });

    test('C4.4 escaping is check 27\'s, so an escaped line still matches', () {
      final input = _input(
        server: {
          'lib/a.dart': r'''
/// The \[primary\] key of the customer.
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
class Customer {}
''',
        },
        extracts: _extract([
          ('IMO-014', 'description', 'The [primary] key of the customer.'),
        ]),
      );
      expect(_forCheck(32, input), isEmpty);
    });

    test('a re-wrapped line is check 34\'s fault, and is not reported twice',
        () {
      final input = _input(
        server: {
          'lib/a.dart': '''
/// Customers are never deleted — a closed
/// account keeps its orders.
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
class Customer {}
''',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(32, input), isEmpty);
      expect(_forCheck(34, input), isNotEmpty);
    });

    test('an enum constant carries no `@DocSpec`, and is still author text',
        () {
      final input = _input(
        shared: {
          'lib/a.dart': '''
@DocSpec([DocRef('IMO-014', 'supplies the domain')])
@CsDomainEnum()
enum CustomerState {
  /// Invented prose for a constant that never had any.
  active,
}
''',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(32, input), isNotEmpty);
      expect(
        _forCheck(32, input).single.message,
        contains('C1 takes a comment from the specification'),
      );
    });
  });

  group('33 — grouped holder template (§2.8 C3)', () {
    _redGreen(
      33,
      '§2.8 C3',
      says: contains('is not C3\'s template'),
      red: _input(
        shared: {
          'lib/keys.dart': '''
/// Holds every resource key the application authorizes against.
class ResourceKeys {}
''',
        },
        extracts: _extract(_customerEntries),
      ),
      green: _input(
        shared: {
          'lib/keys.dart': '''
/// Resource keys for Ordering.
class ResourceKeys {}
''',
        },
        extracts: _extract(_customerEntries),
      ),
    );

    test('a second sentence is the one C3 says exists nowhere', () {
      final input = _input(
        shared: {
          'lib/keys.dart': '''
/// Resource keys for Ordering.
///
/// Grouped by the module that owns them.
class ResourceKeys {}
''',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(33, input), isNotEmpty);
      expect(_forCheck(33, input).single.message, contains('2 lines of prose'));
    });

    test('a declaration that traces to a section is not a grouped holder', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
/// A person or organisation that places orders.
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
class Customer {}
''',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(33, input), isEmpty);
    });

    test('a member is not a grouped holder — C3 grants the holder, not its '
        'contents', () {
      final input = _input(
        shared: {
          'lib/keys.dart': '''
/// Resource keys for Ordering.
class ResourceKeys {
  /// The name the customer trades under.
  static const customerPii = CsResourceKeyRef('customer.pii');
}
''',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(33, input), isEmpty);
    });
  });

  group('34 — comment fidelity (§2.8 C4.2)', () {
    _redGreen(
      34,
      '§2.8 C4.2',
      says: contains('part of the source line'),
      red: _input(
        server: {
          'lib/a.dart': '''
/// Customers are never deleted — a closed
/// account keeps its orders.
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
class Customer {}
''',
        },
        extracts: _extract(_customerEntries),
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
/// $_customerContent
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
class Customer {}
''',
        },
        extracts: _extract(_customerEntries),
      ),
    );

    test('a value the comment stopped rendering part-way', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
/// - the order is placed
/// - the customer is billed
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
class Customer {}
''',
        },
        extracts: _extract([
          (
            'IMO-014',
            'content',
            '- the order is placed\n'
                '- the customer is billed\n'
                '- the warehouse is notified',
          ),
        ]),
      );
      final raised = _forCheck(34, input);
      expect(raised, hasLength(1));
      expect(raised.single.message, contains('renders 2 of the 3 lines'));
    });

    test('a multi-line value rendered whole is not a truncation', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
/// - the order is placed
/// - the customer is billed
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
class Customer {}
''',
        },
        extracts: _extract([
          (
            'IMO-014',
            'content',
            '- the order is placed\n- the customer is billed',
          ),
        ]),
      );
      expect(_forCheck(34, input), isEmpty);
    });

    test('the untraced tier has no value boundaries, so it is left alone', () {
      final input = _input(
        shared: {
          'lib/a.dart': '''
@DocSpec([DocRef('IMO-014', 'supplies the domain')])
@CsDomainEnum()
enum CustomerState {
  /// Customers are never deleted — a closed
  active,
}
''',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(34, input), isEmpty);
    });
  });

  group('35 — extract coverage (§9.6 of codespecs_mapping.md)', () {
    _redGreen(
      35,
      '§9.6 of codespecs_mapping.md',
      says: contains('reached no code'),
      red: _input(
        server: {
          'lib/a.dart': '''
@CodeSpec('dataAccess.Customer', source: ['IMO-014'])
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
@CsTable('customer')
class Customer {
  @CsColumn(column: 'cust_name', length: 80)
  late final String name;
}
''',
        },
        extracts: _extract([
          ..._customerEntries,
          ('DATAA', 'maxLength', '80'),
        ]),
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
@CodeSpec('dataAccess.Customer', source: ['IMO-014'])
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
@CsTable('customer')
class Customer {
  @DocSpec([DocRef('DATAA', 'supplies the maximum length')])
  @CsColumn(column: 'cust_name', length: 80)
  late final String name;
}
''',
        },
        extracts: _extract([
          ..._customerEntries,
          ('DATAA', 'maxLength', '80'),
        ]),
      ),
    );

    test('with no extracts there is no left-hand set, so it raises nothing', () {
      final input = _input(
        server: {'lib/a.dart': "@CsTable('customer') class Customer {}"},
      );
      expect(_forCheck(35, input), isEmpty);
    });

    test('a section with nine values is one gap, not nine', () {
      final input = _input(
        server: {'lib/a.dart': 'class Customer {}'},
        extracts: _extract([
          for (var i = 0; i < 9; i++) ('IMO-014', 'field$i', 'value $i'),
        ]),
      );
      final raised = _forCheck(35, input);
      expect(raised, hasLength(1));
      expect(raised.single.message, contains('routes 9 value(s) of IMO-014'));
    });

    test('the gap names the fields, so it is actionable rather than a count',
        () {
      final input = _input(
        server: {'lib/a.dart': 'class Customer {}'},
        extracts: _extract(_customerEntries),
      );
      expect(
        _forCheck(35, input).single.message,
        allOf(
          contains('CE-DB'),
          contains('DataEntityEntry.description'),
          contains('DataEntityEntry.content'),
        ),
      );
    });

    test('@CodeSpec.source alone covers a section — check 7 owns the drift', () {
      final input = _input(
        server: {
          'lib/a.dart': "@CodeSpec('dataAccess.Customer', source: ['IMO-014']) "
              'class Customer {}',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(35, input), isEmpty);
      expect(_forCheck(7, input), isNotEmpty);
    });

    test('a truncated area fails the pass rather than warning', () {
      // The completeness half of §9.6 made operational: an area whose extract
      // holds three sections and whose generated code carries one is exactly
      // the failure a trio-only pass cannot see.
      final truncated = _input(
        server: {
          'lib/a.dart': '''
@CodeSpec('dataAccess.Customer', source: ['IMO-014'])
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
@CsTable('customer')
class Customer {}
''',
        },
        extracts: _extract([
          ..._customerEntries,
          ('IMO-014-a', 'attributeName', 'name'),
          ('IMO-014-b', 'attributeName', 'signedContract'),
        ]),
      );
      expect(
        () => assertCodeSpecsValid(truncated),
        throwsA(isA<CodeSpecsValidationException>()),
      );
      expect(
        _forCheck(35, truncated).map((v) => v.message).join('\n'),
        allOf(contains('IMO-014-a'), contains('IMO-014-b')),
      );
    });
  });

  group('36 — a back-link resolves (§9.6 of codespecs_mapping.md)', () {
    _redGreen(
      36,
      '§9.6 of codespecs_mapping.md',
      says: contains('which no extract holds'),
      red: _input(
        server: {
          'lib/a.dart': '''
@CodeSpec('dataAccess.Customer', source: ['IMO-014', 'IMO-991'])
@DocSpec([
  DocRef('IMO-014', 'supplies the entity'),
  DocRef('IMO-991', 'supplies a section no area routed'),
])
@CsTable('customer')
class Customer {}
''',
        },
        extracts: _extract(_customerEntries),
      ),
      green: _input(
        server: {
          'lib/a.dart': '''
@CodeSpec('dataAccess.Customer', source: ['IMO-014'])
@DocSpec([DocRef('IMO-014', 'supplies the entity')])
@CsTable('customer')
class Customer {}
''',
        },
        extracts: _extract(_customerEntries),
      ),
    );

    test('with no extracts there is nothing to resolve against', () {
      final input = _input(
        server: {
          'lib/a.dart': "@DocSpec([DocRef('SBP.9.9', 'nowhere')]) "
              'class Customer {}',
        },
      );
      expect(_forCheck(36, input), isEmpty);
    });

    test('one declaration naming an id in both back-links reports it once', () {
      final input = _input(
        server: {
          'lib/a.dart': '''
@CodeSpec('dataAccess.Customer', source: ['IMO-991'])
@DocSpec([DocRef('IMO-991', 'supplies a section no area routed')])
class Customer {}
''',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(36, input), hasLength(1));
    });

    test('it accounts for the section check 32 declines to judge', () {
      // Check 32 skips a section it has no text for, on the grounds that it
      // cannot hold a comment against text it does not hold. This is where
      // that skip is reported — once, and by the rule it actually breaks.
      final input = _input(
        server: {
          'lib/a.dart': '''
/// Prose that occurs in no specification anywhere.
@DocSpec([DocRef('SBP.9.9', 'a section no area routed')])
class Order {}
''',
        },
        extracts: _extract(_customerEntries),
      );
      expect(_forCheck(32, input), isEmpty);
      expect(_forCheck(36, input), hasLength(1));
    });
  });

  group('the §4 worked example', () {
    // The example is the contract's own demonstration that the rules compose,
    // so it is the fixture that has to pass every comment check: a rule the
    // worked example breaks is a rule stated against the contract's own output.
    CodeSpecsValidationInput workedExample() => _input(
          shared: {
            'lib/src/authorization/resource_keys.dart': '''
// GENERATED by TomSpecs Phase 4 (CodeSpecs) — do not edit.

import 'package:tom_code_specs/tom_code_specs.dart';

/// Resource keys for Ordering.
class ResourceKeys {
  static const customerPii = CsResourceKeyRef('customer.pii');
}
''',
          },
          server: {
            'lib/src/data_access/customer.dart': '''
// GENERATED by TomSpecs Phase 4 (CodeSpecs) — do not edit.
// Source document: information_model.md (D06)
// Spec model version: 1.4.0

import 'package:tom_code_specs/tom_code_specs.dart';
import 'package:tom_core_server/tom_core_server.dart';

import '../authorization/resource_keys.dart';

/// A person or organisation that places orders.
///
/// $_customerContent
@CodeSpec(
  'dataAccess.Customer',
  source: ['IMO-014', 'IMO-014-a', 'DATAA', 'IMO-014-b', 'DAATT-DTFR'],
)
@DocSpec([
  DocRef('IMO-014', 'supplies the entity, its table and its storage placement'),
  DocRef('IMO-014-a', 'supplies the stored attribute, its column and its storage type'),
  DocRef('DATAA', 'supplies the maximum length'),
  DocRef('IMO-014-b', 'supplies the stored attribute, its column and its storage type'),
  DocRef('DAATT-DTFR', 'supplies the file-reference facet settings'),
])
@CsTable('customer', datasource: 'core')
class Customer {
  /// The name the customer trades under.
  @DocSpec([
    DocRef('IMO-014-a', 'supplies the stored attribute, its column and its storage type'),
    DocRef('DATAA', 'supplies the maximum length'),
  ])
  @CsColumn(
    column: 'cust_name',
    columnType: 'VARCHAR',
    length: 80,
    accessKey: ResourceKeys.customerPii,
  )
  late final String name;

  @DocSpec([
    DocRef('IMO-014-b', 'supplies the stored attribute, its column and its storage type'),
    DocRef('DAATT-DTFR', 'supplies the file-reference facet settings'),
  ])
  @CsColumn(
    column: 'signed_contract',
    fileReference: CsFileReference(
      keyPrefix: 'contracts',
      acceptedMediaTypes: ['application/pdf'],
    ),
  )
  late final String signedContract;
}
''',
          },
          extracts: _extract([
            ..._customerEntries,
            ('IMO-014', 'entityName', 'Customer'),
            ('IMO-014', 'table', 'customer'),
            ('IMO-014', 'datasource', 'core'),
            ('IMO-014-a', 'attributeName', 'name'),
            ('IMO-014-a', 'column', 'cust_name'),
            ('IMO-014-a', 'columnType', 'VARCHAR'),
            ('IMO-014-a', 'accessKey', 'customer.pii'),
            ('IMO-014-a', 'description', 'The name the customer trades under.'),
            ('DATAA', 'maxLength', '80'),
            ('IMO-014-b', 'attributeName', 'signedContract'),
            ('IMO-014-b', 'column', 'signed_contract'),
            ('DAATT-DTFR', 'keyPrefix', 'contracts'),
            ('DAATT-DTFR', 'cascadeDelete', 'true'),
            ('DAATT-DTFR', 'acceptedMediaTypes', 'application/pdf'),
          ]),
        );

    // The example is where the two back-links have to be seen composing: the
    // class is the emission unit and the two members carry @DocSpec alone, so
    // all three arms of check 7 are exercised at once. It was asserted here
    // only after the example was found to break the rule it demonstrates.
    test('both back-links agree across the unit and its members (7)', () {
      expect(_forCheck(7, workedExample()), isEmpty);
    });

    test('every comment line comes from the extract (32)', () {
      expect(_forCheck(32, workedExample()), isEmpty);
    });

    test('the grouped holder carries C3\'s one sentence (33)', () {
      expect(_forCheck(33, workedExample()), isEmpty);
    });

    test('no line is a re-wrap and no value is cut short (34)', () {
      expect(_forCheck(34, workedExample()), isEmpty);
    });

    // The two transfer checks against the same fixture. They are the assertion
    // that the derivation rules the example demonstrates *elicit* every fact the
    // extract carries: a check that failed here would be a rule that never asked
    // for something the extract supplied, and the fix would be the rule.
    test('every extracted section reaches the code (35)', () {
      expect(_forCheck(35, workedExample()), isEmpty);
    });

    test('every back-link resolves against an extract (36)', () {
      expect(_forCheck(36, workedExample()), isEmpty);
    });
  });

  group('the pass as a whole', () {
    CodeSpecsValidationInput cleanTrio() => _input(
          shared: {
            'lib/contract.dart': '''
@CodeSpec('ce-sc.placeOrder', source: ['SBP.7.1'])
@DocSpec([DocRef('SBP.7.1', 'the place-order interaction')])
@CsEndpoint('order.place')
class placeOrder {}

@CodeSpec('ce-tx.orderFailed', source: ['SBP.7.4'])
@DocSpec([DocRef('SBP.7.4', 'the failure message')])
@CsText(
  baseCopy: 'The order could not be placed.',
  role: CsTextRole.error,
  category: CsTextCategory.errorCopy,
)
class orderFailed {}
''',
          },
          client: {
            'lib/form.dart': '''
import 'package:$_sharedPackage/contract.dart';

const submitOrder = CsActionRef('submitOrder');
const submitButton = CsElementRef('submitButton');

@CodeSpec('ce-fm.orderForm', source: ['SBP.4.1'])
@DocSpec([DocRef('SBP.4.1', 'the order form')])
@CsForm()
class orderForm {
  /// The heading of the order form.
  String get title => throw UnsupportedError('The heading of the order form.');
}

@CsTrigger(
  kind: CsTriggerKind.userGesture,
  action: CsActionRef('submitOrder'),
  element: CsElementRef('submitButton'),
  gesture: CsGesture.tap,
)
class submitOrderTrigger {}
''',
          },
          server: {
            'lib/service.dart': '''
import 'package:$_sharedPackage/contract.dart';

@CodeSpec('ce-sv.placeOrder', source: ['SBP.7.1'])
@DocSpec([DocRef('SBP.7.1', 'the place-order interaction')])
@CsEndpoint('order.place')
class PlaceOrderHandler {
  /// Places the order and returns its confirmation.
  void call() {
    throw UnsupportedError('Places the order and returns its confirmation.');
  }
}
''',
          },
          mirrors: const [
            CsEnumMirror(
              csEnumName: 'CsErrorSeverity',
              coreEnumName: 'TomErrorSeverity',
              csValues: ['info', 'warning', 'error', 'fatal'],
              coreValues: ['info', 'warning', 'error', 'fatal'],
            ),
          ],
        );

    test('a clean trio raises nothing at all', () {
      final report = runCodeSpecsChecks(cleanTrio());
      expect(report.violations, isEmpty, reason: report.lines.join('\n'));
      expect(report.passed, isTrue);
      expect(report.summary, 'codespecs: 36 checks passed');
    });

    test('assertCodeSpecsValid passes a clean trio', () {
      expect(() => assertCodeSpecsValid(cleanTrio()), returnsNormally);
    });

    test('a violation fails generation rather than warning', () {
      final broken = _input(
        server: {'lib/a.dart': "@CsTable('') class Order {}"},
      );
      expect(
        () => assertCodeSpecsValid(broken),
        throwsA(isA<CodeSpecsValidationException>()),
      );
    });

    test('the failure text names every rule broken', () {
      final broken = _input(
        server: {
          'lib/a.dart': '''
@CsTable('')
class Order {
  /// Sums the order lines.
  int total() {
    return 0;
  }
}
''',
        },
      );
      final report = runCodeSpecsChecks(broken);
      expect(report.violations.map((v) => v.check), containsAll([4, 6]));
      expect(report.summary, contains('across 2 of 36 checks'));
      expect(report.lines.join('\n'), contains('codespecs check 4 [§2.1 N5]'));
      expect(
        report.lines.join('\n'),
        contains('codespecs check 6 [§2.4 invariant 2]'),
      );
    });

    test('every check runs, so one breach does not mask another', () {
      final report = runCodeSpecsChecks(
        _input(
          client: {
            'lib/a.dart': "import 'package:$_serverPackage/a.dart';\n"
                "@CsUserSetting('', overridableBy: CsOverridableBy.client) "
                'class theme {}',
          },
        ),
      );
      expect(report.violations.map((v) => v.check).toSet(), {4, 11, 15});
    });
  });
}
