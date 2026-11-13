/// An entity's keys and indexes as the server mappers read them from the IR
/// (`irspecs_ir.md` §11–§14; `codespecs_derivation_contract.md` §3.3.11): the
/// `@CsTableKey` and `@CsTableIndex` markers of each `@CsTable` class, with
/// the columns they name resolved to the class's members, and the PostgreSQL
/// DDL the Go and Java mappers write from them.
///
/// The markers carry the specification's facts verbatim; nothing here invents
/// a key. A foreign key without `referencedColumns` references its target's
/// primary key, as SQL's `REFERENCES t` does (codespecs_derivation_contract.md §3.3.11).
library;

import '../../codespecs/cs_model.dart';
import '../emitters/emit_common.dart';
import '../ir_model.dart';
import 'dart_tom/dart_tom_mapper.dart' show IrMapException;
import 'mapper_common.dart';

/// One stored member of an entity: the field, its physical column, and its
/// type as the IR states it.
class IrColumn {
  /// The member declaration.
  final CsDeclaration member;

  /// The physical column name (`@CsColumn(column:)`, else the member name in
  /// snake case).
  final String name;

  /// The `@CsColumn(columnType:)`, verbatim, or `null` when it states none.
  final String? columnType;

  /// The member's Dart type without its `?`.
  final String dartType;

  /// Whether the member is nullable.
  final bool nullable;

  /// Creates a column.
  const IrColumn(
    this.member,
    this.name,
    this.columnType,
    this.dartType,
    this.nullable,
  );
}

/// One `@CsTableKey`.
class IrTableKey {
  /// The constraint name, verbatim.
  final String name;

  /// The `CsKeyKind` constant's name: `primary`, `foreign`, `alternate`,
  /// `composite`, `natural`, `surrogate`.
  final String kind;

  /// The key's columns, in key order.
  final List<String> columns;

  /// The `CsKeyGeneration` constant's name, or `null`.
  final String? generation;

  /// The sequence of a `sequence` generation, or `null`.
  final String? sequenceName;

  /// The class name of a foreign key's target, or `null`.
  final String? references;

  /// The target's columns as stated; empty means its primary key.
  final List<String> referencedColumns;

  /// The `CsReferentialAction` constant names, or `null`.
  final String? onDelete;

  /// The `CsReferentialAction` constant names, or `null`.
  final String? onUpdate;

  /// Whether the constraint is deferrable, or `null` when not stated.
  final bool? deferrable;

  /// Creates a key.
  const IrTableKey({
    required this.name,
    required this.kind,
    required this.columns,
    this.generation,
    this.sequenceName,
    this.references,
    this.referencedColumns = const [],
    this.onDelete,
    this.onUpdate,
    this.deferrable,
  });

  /// Whether the key identifies the row (`CsKeyKind.identifiesRow`): the
  /// table's primary key.
  bool get identifiesRow => kind != 'foreign' && kind != 'alternate';

  /// Whether this is a foreign key.
  bool get isForeign => kind == 'foreign';

  /// Whether this is an alternate (unique) key.
  bool get isAlternate => kind == 'alternate';
}

/// One `@CsTableIndex`.
class IrTableIndex {
  /// The index name, verbatim.
  final String name;

  /// The index columns as written, a direction included
  /// (`'created_at DESC'`).
  final List<String> entries;

  /// The `CsIndexType` constant's name, or `null`.
  final String? indexType;

  /// The covering columns.
  final List<String> includeColumns;

  /// Whether the index is unique, or `null` when not stated.
  final bool? isUnique;

  /// Whether the index is clustered, or `null` when not stated.
  final bool? isClustered;

  /// The partial-index condition, verbatim, or `null`.
  final String? filterCondition;

  /// Creates an index.
  const IrTableIndex({
    required this.name,
    required this.entries,
    this.indexType,
    this.includeColumns = const [],
    this.isUnique,
    this.isClustered,
    this.filterCondition,
  });

  /// The column names, without their directions.
  List<String> get columns => [for (final e in entries) irIndexEntryColumn(e)];

  /// Whether the entry at [i] is descending.
  bool isDescending(int i) => irIndexEntryDescending(entries[i]);
}

/// The column of an index entry: `'created_at DESC'` → `created_at`.
String irIndexEntryColumn(String entry) {
  final parts = entry.trim().split(RegExp(r'\s+'));
  if (parts.length == 2 &&
      (parts[1].toUpperCase() == 'ASC' || parts[1].toUpperCase() == 'DESC')) {
    return parts.first;
  }
  return entry.trim();
}

/// Whether an index entry is written descending.
bool irIndexEntryDescending(String entry) {
  final parts = entry.trim().split(RegExp(r'\s+'));
  return parts.length == 2 && parts[1].toUpperCase() == 'DESC';
}

/// One `@CsTable` class with its columns, keys and indexes.
class IrEntityTable {
  /// The entity class name.
  final String entity;

  /// The physical table name.
  final String table;

  /// The stored members, in source order.
  final List<IrColumn> columns;

  /// The keys, in source order.
  final List<IrTableKey> keys;

  /// The indexes, in source order.
  final List<IrTableIndex> indexes;

  /// Creates an entity table.
  const IrEntityTable(
    this.entity,
    this.table,
    this.columns,
    this.keys,
    this.indexes,
  );

  /// The key that identifies the row, or `null` when the entity states none
  /// (`validate_codespecs` check 44 reports that).
  IrTableKey? get primaryKey {
    for (final k in keys) {
      if (k.identifiesRow) return k;
    }
    return null;
  }

  /// The foreign keys.
  Iterable<IrTableKey> get foreignKeys => keys.where((k) => k.isForeign);

  /// The alternate keys.
  Iterable<IrTableKey> get alternateKeys => keys.where((k) => k.isAlternate);

  /// The column named [name], or `null`.
  IrColumn? column(String name) {
    for (final c in columns) {
      if (c.name == name) return c;
    }
    return null;
  }

  /// The columns of [key], resolved; throws [IrMapException] for a column no
  /// member declares (check 42).
  List<IrColumn> keyColumns(IrTableKey key) => [
    for (final name in key.columns)
      column(name) ??
          (throw IrMapException(
            "@CsTableKey('${key.name}') of $entity names column '$name', "
            'which no @CsColumn of $entity declares',
          )),
  ];

  /// The primary key's columns, or empty when there is none.
  List<IrColumn> get primaryKeyColumns {
    final pk = primaryKey;
    return pk == null ? const [] : keyColumns(pk);
  }
}

/// A `List<String>` marker argument.
List<String> _strings(CsValue? v) => v is CsListValue
    ? [
        for (final e in v.values)
          if (e is CsStringValue) e.value,
      ]
    : const [];

/// A `bool` marker argument.
bool? _bool(CsValue? v) => v is CsBoolValue ? v.value : null;

/// The constant name of a qualified marker argument of [prefix].
String? _constant(CsValue? v, String prefix) =>
    v is CsQualifiedValue && v.prefix == prefix ? v.name : null;

/// The `@CsTableKey` markers of [d].
List<IrTableKey> irTableKeys(CsDeclaration d) => [
  for (final m in d.markers)
    if (m.name == 'CsTableKey')
      IrTableKey(
        name: irString(m.positional.firstOrNull) ?? '',
        kind: _constant(m.named['kind'], 'CsKeyKind') ?? '',
        columns: _strings(m.named['columns']),
        generation: _constant(m.named['generation'], 'CsKeyGeneration'),
        sequenceName: irString(m.named['sequenceName']),
        references: switch (m.named['references']) {
          CsUnknownValue(:final source) => source.trim(),
          CsQualifiedValue(:final name) => name,
          CsStringValue(:final value) => value,
          _ => null,
        },
        referencedColumns: _strings(m.named['referencedColumns']),
        onDelete: _constant(m.named['onDelete'], 'CsReferentialAction'),
        onUpdate: _constant(m.named['onUpdate'], 'CsReferentialAction'),
        deferrable: _bool(m.named['deferrable']),
      ),
];

/// The `@CsTableIndex` markers of [d].
List<IrTableIndex> irTableIndexes(CsDeclaration d) => [
  for (final m in d.markers)
    if (m.name == 'CsTableIndex')
      IrTableIndex(
        name: irString(m.positional.firstOrNull) ?? '',
        entries: _strings(m.named['columns']),
        indexType: _constant(m.named['indexType'], 'CsIndexType'),
        includeColumns: _strings(m.named['includeColumns']),
        isUnique: _bool(m.named['isUnique']),
        isClustered: _bool(m.named['isClustered']),
        filterCondition: irString(m.named['filterCondition']),
      ),
];

/// The `@CsTable` class [e] of [index] as an [IrEntityTable], or `null` when
/// it is no `@CsTable` class.
IrEntityTable? irEntityTable(IrIndex index, IrEntry e) {
  final d = e.declaration;
  final cs = irMarker(d, 'CsTable');
  if (cs == null) return null;
  final columns = <IrColumn>[];
  for (final m in index.membersOf(e)) {
    if (m.kind != CsDeclarationKind.field || m.isStatic) continue;
    final col = irMarker(m, 'CsColumn');
    final dart = (m.declaredType ?? 'String').trim();
    final nullable = dart.endsWith('?');
    columns.add(
      IrColumn(
        m,
        irString(col?.named['column']) ?? irSnake(m.name),
        irString(col?.named['columnType']),
        nullable ? dart.substring(0, dart.length - 1) : dart,
        nullable,
      ),
    );
  }
  return IrEntityTable(
    d.name,
    irString(cs.positional.firstOrNull) ?? irSnake(d.name),
    columns,
    irTableKeys(d),
    irTableIndexes(d),
  );
}

/// Every `@CsTable` class of the server files [server], in file then source
/// order.
List<IrEntityTable> irEntityTables(List<({String area, IrFile file})> server) {
  final out = <IrEntityTable>[];
  for (final f in server) {
    final index = irFileIndex(f.area, f.file);
    for (final e in index.topLevel) {
      final t = irEntityTable(index, e);
      if (t != null) out.add(t);
    }
  }
  return out;
}

/// The table [key] references among [tables]; throws [IrMapException] when
/// its target is no `@CsTable` class (check 43).
IrEntityTable irReferencedTable(
  IrEntityTable owner,
  IrTableKey key,
  Iterable<IrEntityTable> tables,
) {
  for (final t in tables) {
    if (t.entity == key.references) return t;
  }
  throw IrMapException(
    "@CsTableKey('${key.name}') of ${owner.entity} references "
    '${key.references}, which is no @CsTable class of the server project',
  );
}

/// The target columns of the foreign key [key]: as stated, else the target's
/// primary key (codespecs_derivation_contract.md §3.3.11).
List<String> irReferencedColumns(
  IrEntityTable owner,
  IrTableKey key,
  Iterable<IrEntityTable> tables,
) {
  if (key.referencedColumns.isNotEmpty) return key.referencedColumns;
  final target = irReferencedTable(owner, key, tables);
  final pk = target.primaryKey;
  if (pk == null) {
    throw IrMapException(
      "@CsTableKey('${key.name}') of ${owner.entity} references "
      '${target.entity}, which has no primary key',
    );
  }
  return pk.columns;
}

// ---------------------------------------------------------------------------
// PostgreSQL DDL (the Go mapper's sqlc schema, the Java mapper's Flyway
// migration)
// ---------------------------------------------------------------------------

/// The SQL of a `CsReferentialAction` constant.
String irSqlReferentialAction(String action) => switch (action) {
  'cascade' => 'CASCADE',
  'setNull' => 'SET NULL',
  'restrict' => 'RESTRICT',
  'noAction' => 'NO ACTION',
  'setDefault' => 'SET DEFAULT',
  _ => throw IrMapException('the referential action `$action` has no SQL'),
};

/// The PostgreSQL access method of a `CsIndexType` constant. `fullText` is a
/// GIN index (the column is a `tsvector`), `spatial` a GiST index.
String irSqlIndexMethod(String type) => switch (type) {
  'bTree' => 'btree',
  'hash' => 'hash',
  'gist' || 'spatial' => 'gist',
  'gin' || 'fullText' => 'gin',
  _ => throw IrMapException('the index type `$type` has no PostgreSQL method'),
};

/// The column default a key generation asks the database for: an identity
/// for `auto`, the sequence for `sequence`, `gen_random_uuid()` for `uuid`.
/// `ulid`, `custom` and `natural` are the application's: `null`.
String? _generatedDefault(IrTableKey key) => switch (key.generation) {
  'auto' => 'GENERATED BY DEFAULT AS IDENTITY',
  'sequence' when key.sequenceName != null =>
    "DEFAULT nextval('${key.sequenceName}')",
  'uuid' => 'DEFAULT gen_random_uuid()',
  _ => null,
};

/// `DEFERRABLE INITIALLY DEFERRED` when [key] is deferrable.
String _deferrable(IrTableKey key) =>
    key.deferrable == true ? ' DEFERRABLE INITIALLY DEFERRED' : '';

/// The PostgreSQL schema of [tables]: one `CREATE TABLE` each with its
/// primary and alternate keys, then every foreign key as an
/// `ALTER TABLE … ADD CONSTRAINT` (so a table may reference one written after
/// it), then every index. [sqlType] gives the type of a column whose
/// `@CsColumn` states none. [header] are the leading comment lines.
String irPostgresSchema(
  List<IrEntityTable> tables, {
  required String Function(IrColumn column) sqlType,
  required List<String> header,
}) {
  final out = [...header];
  final sequences = <String>{
    for (final t in tables)
      for (final k in t.keys)
        if (k.generation == 'sequence' && k.sequenceName != null)
          k.sequenceName!,
  };
  if (sequences.isNotEmpty) out.add('');
  for (final s in sequences) {
    out.add('CREATE SEQUENCE $s;');
  }
  for (final t in tables) {
    final pk = t.primaryKey;
    for (final k in t.keys) {
      t.keyColumns(k); // every key column is a member (check 42)
    }
    final generated = <String, String>{
      if (pk != null && pk.columns.length == 1 && _generatedDefault(pk) != null)
        pk.columns.single: _generatedDefault(pk)!,
    };
    final lines = [
      for (final c in t.columns)
        '  ${c.name} ${c.columnType ?? sqlType(c)}'
            '${c.nullable ? '' : ' NOT NULL'}'
            '${generated[c.name] == null ? '' : ' ${generated[c.name]}'}',
      if (pk != null)
        '  CONSTRAINT ${pk.name} PRIMARY KEY (${pk.columns.join(', ')})'
            '${_deferrable(pk)}',
      for (final k in t.alternateKeys)
        '  CONSTRAINT ${k.name} UNIQUE (${k.columns.join(', ')})'
            '${_deferrable(k)}',
    ];
    out
      ..add('')
      ..add('CREATE TABLE ${t.table} (')
      ..addAll([
        for (final (i, l) in lines.indexed)
          '$l${i < lines.length - 1 ? ',' : ''}',
      ])
      ..add(');');
  }
  for (final t in tables) {
    for (final k in t.foreignKeys) {
      t.keyColumns(k);
      final target = irReferencedTable(t, k, tables);
      final referenced = irReferencedColumns(t, k, tables);
      out
        ..add('')
        ..add('ALTER TABLE ${t.table}')
        ..add(
          '  ADD CONSTRAINT ${k.name} FOREIGN KEY (${k.columns.join(', ')})',
        )
        ..add(
          '  REFERENCES ${target.table} (${referenced.join(', ')})'
          '${k.onDelete == null ? '' : ' ON DELETE ${irSqlReferentialAction(k.onDelete!)}'}'
          '${k.onUpdate == null ? '' : ' ON UPDATE ${irSqlReferentialAction(k.onUpdate!)}'}'
          '${_deferrable(k)};',
        );
    }
  }
  for (final t in tables) {
    for (final x in t.indexes) {
      for (final c in [...x.columns, ...x.includeColumns]) {
        if (t.column(c) == null) {
          throw IrMapException(
            "@CsTableIndex('${x.name}') of ${t.entity} names column '$c', "
            'which no @CsColumn of ${t.entity} declares',
          );
        }
      }
      out
        ..add('')
        ..add(
          'CREATE ${x.isUnique == true ? 'UNIQUE ' : ''}INDEX ${x.name} '
          'ON ${t.table}'
          '${x.indexType == null ? '' : ' USING ${irSqlIndexMethod(x.indexType!)}'}'
          ' (${x.entries.map((e) => e.trim()).join(', ')})'
          '${x.includeColumns.isEmpty ? '' : ' INCLUDE (${x.includeColumns.join(', ')})'}'
          '${x.filterCondition == null ? '' : ' WHERE ${x.filterCondition}'};',
        );
      if (x.isClustered == true) {
        out.add('CLUSTER ${t.table} USING ${x.name};');
      }
    }
  }
  out.add('');
  return out.join('\n');
}
