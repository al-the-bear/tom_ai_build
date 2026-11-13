/// An entity's keys and indexes in the server mappers (`irspecs_ir.md`
/// §11–§14, `codespecs_derivation_contract.md` §3.3.11): a server trio whose
/// three entities carry every kind of `@CsTableKey` and `@CsTableIndex` —
/// a sequence-generated surrogate key, an alternate key, a composite primary
/// key, a deferrable foreign key with both referential actions, a UUID key,
/// a covering, partial, descending index, a unique clustered index — mapped
/// by the Go, Java, C# and TypeScript server mappers.
///
/// The PostgreSQL DDL (the Go schema, the Java Flyway migration, the C#
/// migration) is run against a scratch PostgreSQL cluster when `initdb`,
/// `pg_ctl` and `psql` are found; the Go module through `sqlc generate` and
/// `go vet`, the Java project through `./gradlew compileJava`, the C#
/// solution through `dotnet build`, when their toolchains are found. Without
/// them those tests are skipped with the reason stated.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

import 'support/dotnet_toolchain.dart';
import 'support/go_toolchain.dart';
import 'support/java_toolchain.dart';

final _areas = p.absolute(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);
const _server = 'acc_codespec_server';

const _accountKind = '''
import 'package:tom_code_specs/tom_code_specs.dart';

/// What an account is for.
@CsEnum()
enum AccountKind {
  /// A customer's account.
  customer,

  /// An internal account.
  internal,
}
''';

const _account = '''
import 'package:acc_codespec_shared/acc_codespec_shared.dart';
import 'package:tom_code_specs/tom_code_specs.dart';

/// A ledger account.
@CsTable('acc_account')
@CsTableKey(
  'pk_account',
  kind: CsKeyKind.surrogate,
  columns: ['account_id'],
  generation: CsKeyGeneration.sequence,
  sequenceName: 'acc_account_seq',
)
@CsTableKey('ak_account_number', kind: CsKeyKind.alternate, columns: ['number'])
@CsTableIndex(
  'ix_account_opened',
  columns: ['opened_at DESC', 'number'],
  indexType: CsIndexType.bTree,
  includeColumns: ['holder'],
  filterCondition: 'closed = false',
)
class Account {
  /// The account id.
  @CsColumn(column: 'account_id', columnType: 'bigint')
  late int accountId;

  /// The account number.
  @CsColumn(columnType: 'varchar(34)')
  late String number;

  /// The holder.
  @CsColumn(columnType: 'varchar(200)')
  late String holder;

  /// When it was opened.
  @CsColumn(column: 'opened_at', columnType: 'timestamptz')
  late DateTime openedAt;

  /// Whether it is closed.
  @CsColumn(columnType: 'boolean')
  late bool closed;

  /// What the account is for.
  @CsColumn(columnType: 'varchar(16)')
  late AccountKind kind;
}
''';

const _posting = '''
import 'package:tom_code_specs/tom_code_specs.dart';

import 'account.dart';

/// A posting on an account.
@CsTable('acc_posting')
@CsTableKey(
  'pk_posting',
  kind: CsKeyKind.composite,
  columns: ['account_id', 'seq_no'],
)
@CsTableKey(
  'fk_posting_account',
  kind: CsKeyKind.foreign,
  columns: ['account_id'],
  references: Account,
  onDelete: CsReferentialAction.cascade,
  onUpdate: CsReferentialAction.restrict,
  deferrable: true,
)
@CsTableIndex(
  'ux_posting_reference',
  columns: ['reference'],
  isUnique: true,
  isClustered: true,
)
class Posting {
  /// The account.
  @CsColumn(column: 'account_id', columnType: 'bigint')
  late int accountId;

  /// The sequence number within the account.
  @CsColumn(column: 'seq_no', columnType: 'integer')
  late int seqNo;

  /// The booking reference.
  @CsColumn(columnType: 'varchar(40)')
  late String reference;

  /// The amount.
  @CsColumn(columnType: 'numeric(14,2)')
  late double amount;
}
''';

const _tag = '''
import 'package:tom_code_specs/tom_code_specs.dart';

/// A free tag.
@CsTable('acc_tag')
@CsTableKey(
  'pk_tag',
  kind: CsKeyKind.primary,
  columns: ['tag_id'],
  generation: CsKeyGeneration.uuid,
)
class Tag {
  /// The tag id.
  @CsColumn(column: 'tag_id', columnType: 'uuid')
  late String tagId;

  /// The label.
  @CsColumn(columnType: 'text')
  String? label;
}
''';

List<IrDocument> _ir() {
  CsLocusProject project(CsLocus locus, Map<String, String> sources) =>
      readCsLocusProject(
        locus: locus,
        packageName: 'acc_codespec_${locus.name}',
        sources: sources,
      );
  final documents = irFromCsModel(
    shared: project(CsLocus.shared, {
      'lib/src/domain_enum/account_kind.dart': _accountKind,
    }),
    client: project(CsLocus.client, const {}),
    server: project(CsLocus.server, {
      'lib/src/data_access/account.dart': _account,
      'lib/src/data_access/posting.dart': _posting,
      'lib/src/data_access/tag.dart': _tag,
    }),
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

ProcessResult _run(
  String executable,
  List<String> args,
  String cwd, {
  Map<String, String>? environment,
}) => Process.runSync(
  executable,
  args,
  workingDirectory: cwd,
  environment: environment,
);

void _expectOk(ProcessResult r, String what) {
  expect(r.exitCode, 0, reason: '$what:\n${r.stdout}\n${r.stderr}');
}

/// The first of [names] found on the PATH or under [dirs].
String? _tool(List<String> names, List<String> dirs) {
  for (final dir in [
    ...(Platform.environment['PATH'] ?? '').split(':'),
    ...dirs,
  ]) {
    if (dir.isEmpty) continue;
    for (final n in names) {
      final f = File(p.join(dir, n));
      if (f.existsSync()) return f.path;
    }
  }
  return null;
}

String? _postgresBin() {
  for (final dir in [
    '/opt/homebrew/opt/postgresql@17/bin',
    '/opt/homebrew/opt/postgresql@16/bin',
    '/usr/lib/postgresql/17/bin',
    '/usr/lib/postgresql/16/bin',
    ...(Platform.environment['PATH'] ?? '').split(':'),
  ]) {
    if (dir.isNotEmpty && File(p.join(dir, 'initdb')).existsSync()) return dir;
  }
  return null;
}

/// The C locale: `initdb` refuses a session locale it does not know.
const _cLocale = {'LC_ALL': 'C', 'LANG': 'C'};

/// Runs [sql] against a scratch PostgreSQL cluster in a temporary folder.
void _expectPostgresAccepts(String bin, String sql, String what) {
  final dir = Directory.systemTemp.createTempSync('irspecs_keys_pg');
  final data = p.join(dir.path, 'data');
  try {
    _expectOk(
      _run(
        p.join(bin, 'initdb'),
        [
          '-D',
          data,
          '-U',
          'postgres',
          '--auth=trust',
          '--locale=C',
          '--encoding=UTF8',
          '--no-instructions',
        ],
        dir.path,
        environment: _cLocale,
      ),
      'initdb',
    );
    _expectOk(
      _run(
        p.join(bin, 'pg_ctl'),
        [
          '-D',
          data,
          '-o',
          "-k ${dir.path} -c listen_addresses='' -p 54329",
          '-l',
          p.join(dir.path, 'log'),
          '-w',
          'start',
        ],
        dir.path,
        environment: _cLocale,
      ),
      'pg_ctl start',
    );
    try {
      final file = File(p.join(dir.path, 'schema.sql'))..writeAsStringSync(sql);
      _expectOk(
        _run(p.join(bin, 'psql'), [
          '-h',
          dir.path,
          '-p',
          '54329',
          '-U',
          'postgres',
          '-v',
          'ON_ERROR_STOP=1',
          '-q',
          '-f',
          file.path,
        ], dir.path),
        '$what in PostgreSQL',
      );
    } finally {
      _run(p.join(bin, 'pg_ctl'), ['-D', data, '-m', 'fast', 'stop'], dir.path);
    }
  } finally {
    dir.deleteSync(recursive: true);
  }
}

/// The SQL a C# migration's `Up` runs: the raw string between `"""` lines.
String _migrationSql(String cs) {
  final start = cs.indexOf('migrationBuilder.Sql("""');
  final body = cs.substring(cs.indexOf('\n', start) + 1);
  return body.substring(0, body.indexOf('"""'));
}

void main() {
  late List<IrDocument> documents;
  setUpAll(() => documents = _ir());

  final pg = _postgresBin();
  final pgSkip = pg == null ? 'no PostgreSQL (initdb) on this host' : false;

  group('IRKEY1: the Go server mapper', () {
    late Map<String, String> files;
    setUpAll(() => files = mapGoServer(documents));

    test(
      'writes the keys, the foreign key and the indexes into the schema',
      () {
        final schema = files['$_server/db/schema.sql']!;
        expect(schema, contains('CREATE SEQUENCE acc_account_seq;'));
        expect(
          schema,
          contains(
            "  account_id bigint NOT NULL DEFAULT nextval('acc_account_seq'),",
          ),
        );
        expect(
          schema,
          contains(
            '  CONSTRAINT pk_account PRIMARY KEY (account_id),\n'
            '  CONSTRAINT ak_account_number UNIQUE (number)\n);',
          ),
        );
        expect(
          schema,
          contains(
            '  CONSTRAINT pk_posting PRIMARY KEY (account_id, seq_no)\n',
          ),
        );
        expect(
          schema,
          contains('  tag_id uuid NOT NULL DEFAULT gen_random_uuid(),'),
        );
        expect(
          schema,
          contains(
            'ALTER TABLE acc_posting\n'
            '  ADD CONSTRAINT fk_posting_account FOREIGN KEY (account_id)\n'
            '  REFERENCES acc_account (account_id) ON DELETE CASCADE '
            'ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;',
          ),
        );
        expect(
          schema,
          contains(
            'CREATE INDEX ix_account_opened ON acc_account USING btree '
            '(opened_at DESC, number) INCLUDE (holder) WHERE closed = false;',
          ),
        );
        expect(
          schema,
          contains(
            'CREATE UNIQUE INDEX ux_posting_reference ON acc_posting '
            '(reference);\nCLUSTER acc_posting USING ux_posting_reference;',
          ),
        );
      },
    );

    test('writes the queries by key, a composite key by all its columns', () {
      final posting = files['$_server/db/query/acc_posting.sql']!;
      expect(
        posting,
        contains(
          '-- name: FindPostingById :one\n'
          'SELECT * FROM acc_posting\n'
          r'WHERE account_id = $1 AND seq_no = $2;',
        ),
      );
      expect(
        posting,
        contains(
          '-- name: DeletePostingById :execrows\n'
          'DELETE FROM acc_posting\n'
          r'WHERE account_id = $1 AND seq_no = $2;',
        ),
      );
    });

    test('the schema runs in PostgreSQL', () {
      _expectPostgresAccepts(pg!, files['$_server/db/schema.sql']!, 'schema');
    }, skip: pgSkip);

    final go = findGoToolchain();
    final sqlc = _tool(['sqlc'], ['/opt/homebrew/bin']);
    test(
      'sqlc generates the queries, and the module vets',
      () {
        final dir = Directory.systemTemp.createTempSync('irspecs_keys_go');
        try {
          _write(dir, files);
          final module = p.join(dir.path, _server);
          _expectOk(_run(sqlc!, ['generate'], module), 'sqlc generate');
          final generated = File(
            p.join(module, 'db', 'acc_posting.sql.go'),
          ).readAsStringSync();
          expect(generated, contains('func (q *Queries) FindPostingById('));
          expect(generated, contains('func (q *Queries) DeletePostingById('));
          _expectOk(_run(go!, ['mod', 'tidy'], module), 'go mod tidy');
          _expectOk(_run(go, ['vet', './...'], module), 'go vet');
        } finally {
          dir.deleteSync(recursive: true);
        }
      },
      skip: go == null
          ? 'no `go` toolchain on this host'
          : sqlc == null
          ? 'no sqlc on this host'
          : false,
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  group('IRKEY2: the Java + Spring Boot server mapper', () {
    late Map<String, String> files;
    setUpAll(() => files = mapJavaSpring(documents));
    String java(String name) =>
        files['$_server/src/main/java/acc_codespec_server/server/$name.java']!;

    test('writes @Id, @IdClass, @GeneratedValue, the association and the '
        'table constraints', () {
      final account = java('Account');
      expect(
        account,
        contains(
          '@Table(\n'
          '    name = "acc_account",\n'
          '    uniqueConstraints = {\n'
          '        @UniqueConstraint(name = "ak_account_number", '
          'columnNames = {"number"})\n'
          '    },\n'
          '    indexes = {\n'
          '        @Index(name = "ix_account_opened", '
          'columnList = "opened_at DESC, number")\n'
          '    }\n'
          ')',
        ),
      );
      expect(
        account,
        contains(
          '    @Id\n'
          '    @GeneratedValue(strategy = GenerationType.SEQUENCE, '
          'generator = "acc_account_seq")\n'
          '    @SequenceGenerator(name = "acc_account_seq", '
          'sequenceName = "acc_account_seq", allocationSize = 1)\n',
        ),
      );
      final posting = java('Posting');
      expect(
        posting,
        contains('@IdClass(PostingId.class)\npublic class Posting {'),
      );
      expect(
        RegExp(r'    @Id\n').allMatches(posting).length,
        2,
        reason: 'one @Id per key column',
      );
      expect(
        posting,
        contains(
          '    @ManyToOne(fetch = FetchType.LAZY)\n'
          '    @JoinColumn(name = "account_id", referencedColumnName = '
          '"account_id", insertable = false, updatable = false, foreignKey = '
          '@ForeignKey(name = "fk_posting_account"))\n'
          '    private Account account;',
        ),
      );
      expect(posting, contains('    public Account getAccount() {'));
      final id = java('PostingId');
      expect(id, contains('public class PostingId implements Serializable {'));
      expect(id, contains('    private Integer accountId;'));
      expect(id, contains('Objects.hash(accountId, seqNo)'));
      expect(
        java('Tag'),
        contains(
          '    @Id\n'
          '    @GeneratedValue(strategy = GenerationType.UUID)\n',
        ),
      );
    });

    test('the Flyway migration runs in PostgreSQL', () {
      _expectPostgresAccepts(
        pg!,
        files['$_server/src/main/resources/db/migration/V1__ce_db_tables.sql']!,
        'the Flyway migration',
      );
    }, skip: pgSkip);

    final jdk = findJdk21();
    final gradle = findGradle(version: kJavaSpringVersions['gradle']!);
    test(
      'compiles',
      () {
        final dir = Directory.systemTemp.createTempSync('irspecs_keys_java');
        try {
          _write(dir, files);
          final project = p.join(dir.path, _server);
          _expectOk(
            _run(
              gradle!,
              ['--offline', '--quiet', 'compileJava'],
              project,
              environment: {'JAVA_HOME': jdk!},
            ),
            'gradle compileJava',
          );
        } finally {
          dir.deleteSync(recursive: true);
        }
      },
      skip: jdk == null
          ? 'no JDK 21 on this host'
          : gradle == null
          ? 'no Gradle ${kJavaSpringVersions['gradle']} on this host'
          : false,
      timeout: const Timeout(Duration(minutes: 10)),
    );
  });

  group('IRKEY3: the C# + ASP.NET Core server mapper', () {
    late Map<String, String> files;
    setUpAll(() => files = mapCsharpAspnet(documents));
    String server(String path) =>
        files.entries.firstWhere((e) => e.key.endsWith(path)).value;

    test('configures the keys, the foreign key and the indexes', () {
      final context = server('DbContext.cs');
      for (final line in [
        'modelBuilder.Entity<Account>().HasKey(e => e.AccountId)'
            '.HasName("pk_account");',
        'modelBuilder.Entity<Account>().Property(e => e.AccountId)'
            '.ValueGeneratedOnAdd()'
            '.HasDefaultValueSql("nextval(\'acc_account_seq\')");',
        'modelBuilder.Entity<Account>().HasAlternateKey(e => e.Number)'
            '.HasName("ak_account_number");',
        'modelBuilder.Entity<Account>().HasIndex(e => new { e.OpenedAt, '
            'e.Number }, "ix_account_opened").IsDescending(true, false)'
            '.HasMethod("btree").IncludeProperties(e => e.Holder)'
            '.HasFilter("closed = false");',
        'modelBuilder.Entity<Posting>().HasKey(e => new { e.AccountId, '
            'e.SeqNo }).HasName("pk_posting");',
        'modelBuilder.Entity<Posting>().HasOne<Account>().WithMany()'
            '.HasForeignKey(e => e.AccountId)'
            '.HasConstraintName("fk_posting_account")'
            '.OnDelete(DeleteBehavior.Cascade);',
        'modelBuilder.Entity<Posting>().HasIndex(e => e.Reference, '
            '"ux_posting_reference").IsUnique();',
        'modelBuilder.Entity<Tag>().Property(e => e.TagId)'
            '.ValueGeneratedOnAdd().HasDefaultValueSql("gen_random_uuid()");',
      ]) {
        expect(context, contains(line));
      }
    });

    test('the migration runs in PostgreSQL', () {
      _expectPostgresAccepts(
        pg!,
        _migrationSql(server('00000000000000_CeDbTables.cs')),
        'the migration',
      );
    }, skip: pgSkip);

    final dotnet = findDotnet8();
    test(
      'builds',
      () {
        final dir = Directory.systemTemp.createTempSync('irspecs_keys_cs');
        try {
          _write(dir, files);
          final r = _run(
            dotnet!,
            ['build', '-nologo'],
            p.join(dir.path, _server),
            environment: dotnetEnvironment(dotnet),
          );
          final out = '${r.stdout}${r.stderr}';
          expect(r.exitCode, 0, reason: out);
          expect(out, contains('0 Warning(s)'), reason: out);
        } finally {
          dir.deleteSync(recursive: true);
        }
      },
      skip: dotnet == null ? 'no .NET 8 SDK on this host' : false,
      timeout: const Timeout(Duration(minutes: 10)),
    );
  });

  group('IRKEY4: the TypeScript Hono server mapper', () {
    test('writes the named keys, the foreign key and the indexes', () {
      final files = mapTypeScript(documents, 'ts-hono-server');
      String table(String name) =>
          files.entries.firstWhere((e) => e.key.endsWith('/$name.ts')).value;
      final account = table('account');
      expect(
        account,
        contains(
          "accountId: bigint(\"account_id\", { mode: 'number' }).notNull()"
          ".default(sql`nextval('acc_account_seq')`),",
        ),
      );
      expect(
        account,
        contains('primaryKey({ name: "pk_account", columns: [t.accountId] }),'),
      );
      expect(account, contains('unique("ak_account_number").on(t.number),'));
      expect(
        account,
        contains(
          'index("ix_account_opened").using(\'btree\', t.openedAt.desc(), '
          't.number).where(sql`closed = false`),',
        ),
      );
      final posting = table('posting');
      expect(
        posting,
        contains(
          'primaryKey({ name: "pk_posting", columns: [t.accountId, t.seqNo] }),',
        ),
      );
      expect(
        posting,
        contains(
          'foreignKey({ name: "fk_posting_account", columns: [t.accountId], '
          "foreignColumns: [accountTable.accountId] }).onDelete('cascade')"
          ".onUpdate('restrict'),",
        ),
      );
      expect(
        posting,
        contains('uniqueIndex("ux_posting_reference").on(t.reference),'),
      );
      expect(
        table('tag'),
        contains('tagId: uuid("tag_id").notNull().defaultRandom(),'),
      );
    });

    final npm = _tool(['npm'], const []);
    test(
      'the workspace installs and type-checks',
      () {
        final dir = Directory.systemTemp.createTempSync('irspecs_keys_ts');
        try {
          _write(dir, {
            ...mapTypeScript(documents, kTsSharedMapper),
            ...mapTypeScript(documents, kTsHonoServerMapper),
          });
          final install = Process.runSync(
            'npm',
            ['install', '--no-audit', '--no-fund', '--loglevel=error'],
            workingDirectory: dir.path,
            runInShell: true,
          );
          expect(
            install.exitCode,
            0,
            reason: '${install.stdout}${install.stderr}',
          );
          final tsc = Process.runSync(
            'npx',
            ['tsc', '--noEmit', '-p', '.'],
            workingDirectory: dir.path,
            runInShell: true,
          );
          expect(tsc.exitCode, 0, reason: '${tsc.stdout}${tsc.stderr}');
        } finally {
          dir.deleteSync(recursive: true);
        }
      },
      skip: npm == null ? 'no npm on the PATH (source ~/.nvm/nvm.sh)' : false,
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
