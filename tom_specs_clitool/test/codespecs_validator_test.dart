/// Fixtures for the twenty-four `codespecs_derivation_contract.md` §6 checks.
///
/// Every check gets **two** fixtures: one that violates the rule and one that
/// satisfies it. A check exercised only against clean input is
/// indistinguishable from a check that is not wired at all, so the red fixture
/// is the one that proves the check fires — and the green one proves it fires
/// for the rule rather than for the shape of the fixture.
///
/// The fixtures are in-memory Dart sources: the validator reads syntax, so a
/// fixture needs no package resolution and no filesystem.
library;

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
    );

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
    test('names the twenty-four checks in table order', () {
      expect(
        codeSpecsChecks.map((c) => c.number),
        [for (var i = 1; i <= 24; i++) i],
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

  group('6 — fabricated values (§2.4)', () {
    _redGreen(
      6,
      '§2.4',
      says: contains('returns a value'),
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
  });

  group('7 — back-link set equality (§2.5 rule 4)', () {
    _redGreen(
      7,
      '§2.5 rule 4',
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

    test('rule 5: a member adding no section carries neither back-link', () {
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
      expect(report.summary, 'codespecs: 24 checks passed');
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
  int total() {
    return 0;
  }
}
''',
        },
      );
      final report = runCodeSpecsChecks(broken);
      expect(report.violations.map((v) => v.check), containsAll([4, 6]));
      expect(report.summary, contains('across 2 of 24 checks'));
      expect(report.lines.join('\n'), contains('codespecs check 4 [§2.1 N5]'));
      expect(report.lines.join('\n'), contains('codespecs check 6 [§2.4]'));
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
