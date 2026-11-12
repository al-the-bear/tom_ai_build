/// The IR's data form (`irspecs_ir.md`): every CsModel class to and from plain
/// maps, lists and scalars — what the YAML writer prints, what the JSON Schema
/// (`tool/irspecs_ir.schema.json`) constrains and what the reader parses back.
///
/// Conventions, all fixed so two writes of one trio are byte-identical:
/// keys are written in the order this codec lists them; a nullable field whose
/// value is `null` is left out; booleans and lists are always written; named
/// arguments are a list of `{name, value}` pairs, because their order is part
/// of the source. A location is written as `line` only: an element's file is
/// the file it is listed under.
library;

import '../codespecs/cs_model.dart';
import 'ir_model.dart';
import 'ir_steps.dart';

/// Every field of every CsModel class a trio's reading holds, by class: what
/// this codec writes and reads back.
///
/// The field-coverage test walks the CsModel classes and fails on a field
/// that is in neither this table nor [irOmittedCsModelFields], so a field
/// added to CsModel cannot be left out of the IR without a decision. A
/// [CsLocation] is carried as its `line`; its `file` is the path of the file
/// the element is listed under.
const Map<String, Set<String>> irCarriedCsModelFields = {
  'CsLocusProject': {'locus', 'packageName', 'files'},
  'CsFile': {
    'path',
    'imports',
    'exports',
    'comments',
    'declarations',
    'constructions',
  },
  'CsComment': {'text', 'isDocumentation', 'isBanner', 'location'},
  'CsLocation': {'file', 'line'},
  'CsDeclaration': {
    'locus',
    'name',
    'owner',
    'markers',
    'codeSpec',
    'docSpec',
    'docSpecLocation',
    'hasInitialiser',
    'isFinal',
    'isLate',
    'declaredType',
    'bodies',
    'kind',
    'isAbstract',
    'isStatic',
    'docComment',
    'annotations',
    'typeParameters',
    'superclass',
    'interfaces',
    'mixins',
    'isConst',
    'initialiser',
    'location',
  },
  'CsAnnotation': {'source', 'location'},
  'CsMarker': {'name', 'positional', 'named', 'location'},
  'CsCodeSpecLink': {'id', 'source', 'location'},
  'CsDocRef': {'sectionId', 'description', 'descriptionLiteral'},
  'CsDocComment': {'lines', 'location'},
  'CsMethodBody': {
    'name',
    'shape',
    'calls',
    'statements',
    'parameters',
    'returnType',
    'thrownMessage',
    'thrownType',
    'isAsync',
    'accessor',
    'isArrow',
    'thrownLiteral',
    'location',
  },
  'CsParameter': {'name', 'type', 'kind', 'defaultValue'},
  'CsCall': {'receiver', 'method', 'arguments', 'location'},
  'CsStatement': {
    'kind',
    'source',
    'call',
    'valueIdentifier',
    'valueSource',
    'boundName',
    'isFinal',
    'nested',
    'keyword',
    'hasElse',
    'location',
  },
  'CsConstruction': {'type', 'positional', 'named', 'holder', 'location'},
  'CsStringValue': {'value', 'literal'},
  'CsBoolValue': {'value'},
  'CsIntValue': {'value'},
  'CsNullValue': {},
  'CsQualifiedValue': {'prefix', 'name'},
  'CsConstructionValue': {'type', 'positional', 'named'},
  'CsListValue': {'values'},
  'CsUnknownValue': {'source'},
};

/// The CsModel fields the IR deliberately does not carry, with the reason
/// (`irspecs_ir.md`, § Every field, and the one left out).
const Map<String, Map<String, String>> irOmittedCsModelFields = {
  'CsFile': {
    'source':
        "The file's text is what a mapper writes from the IR; carrying it "
        'would make the byte-equal proof of the Dart + Tom mapper '
        '(irspecs4) compare the text with itself.',
  },
};

/// [document] as data.
Map<String, Object?> irDocumentToData(IrDocument document) => {
  'format': kIrSpecsFormat,
  'formatVersion': kIrSpecsFormatVersion,
  'area': document.area,
  'projects': [
    for (final project in document.projects)
      {'locus': project.locus.name, 'package': project.packageName},
  ],
  'files': [for (final entry in document.files) _file(entry)],
};

/// The document [data] describes. [source] names it in errors.
///
/// Throws [IrSpecsException] on a wrong format or version, and on data that
/// does not have the shape [irDocumentToData] writes.
IrDocument irDocumentFromData(Object? data, {String source = 'IR document'}) {
  try {
    final map = _map(data);
    if (map['format'] != kIrSpecsFormat) {
      throw IrSpecsException(
        '$source: format is "${map['format']}", expected "$kIrSpecsFormat"',
      );
    }
    if (map['formatVersion'] != kIrSpecsFormatVersion) {
      throw IrSpecsException(
        '$source: formatVersion ${map['formatVersion']} is not '
        '$kIrSpecsFormatVersion',
      );
    }
    return IrDocument(
      area: map['area'] as String,
      projects: [
        for (final project in _list(map['projects']))
          IrProject(
            _locus(_map(project)['locus']),
            _map(project)['package'] as String,
          ),
      ],
      files: [for (final f in _list(map['files'])) _readFile(f)],
    );
  } on IrSpecsException {
    rethrow;
  } on Object catch (e) {
    throw IrSpecsException('$source: not an $kIrSpecsFormat document ($e)');
  }
}

// ---------------------------------------------------------------------------
// Writing
// ---------------------------------------------------------------------------

/// One file entry of a document as data — the record `validate_codespecs`
/// compares between two IR runs (check 31) in place of the file's text.
Map<String, Object?> irFileToData(IrFile entry) => _file(entry);

Map<String, Object?> _file(IrFile entry) {
  final f = entry.file;
  final steps = {for (final r in entry.steps) '${r.owner}.${r.body}': r};
  return {
    'locus': entry.locus.name,
    'path': f.path,
    'imports': f.imports,
    'exports': f.exports,
    'comments': [
      for (final c in f.comments)
        {
          'text': c.text,
          'documentation': c.isDocumentation,
          'banner': c.isBanner,
          'line': c.location.line,
        },
    ],
    'declarations': [for (final d in f.declarations) _declaration(d, steps)],
    'constructions': [for (final c in f.constructions) _construction(c)],
  };
}

Map<String, Object?> _declaration(
  CsDeclaration d,
  Map<String, IrBodySteps> steps,
) => {
  'name': d.name,
  'owner': ?d.owner,
  'kind': d.kind.name,
  'line': d.location.line,
  'markers': [for (final m in d.markers) _marker(m)],
  if (d.codeSpec case final link?)
    'codeSpec': {
      'id': link.id,
      'source': link.source,
      'line': link.location.line,
    },
  if (d.docSpec case final refs?)
    'docSpec': [
      for (final r in refs)
        {
          'sectionId': r.sectionId,
          'description': r.description,
          'descriptionLiteral': ?r.descriptionLiteral,
        },
    ],
  'docSpecLine': ?d.docSpecLocation?.line,
  if (d.docComment case final doc?)
    'docComment': {'lines': doc.lines, 'line': doc.location.line},
  if (d.annotations.isNotEmpty)
    'annotations': [
      for (final a in d.annotations)
        {'source': a.source, 'line': a.location.line},
    ],
  'typeParameters': ?d.typeParameters,
  'superclass': ?d.superclass,
  if (d.interfaces.isNotEmpty) 'interfaces': d.interfaces,
  if (d.mixins.isNotEmpty) 'mixins': d.mixins,
  'isAbstract': d.isAbstract,
  'isStatic': d.isStatic,
  'isFinal': d.isFinal,
  'isLate': d.isLate,
  if (d.isConst) 'isConst': true,
  'hasInitialiser': d.hasInitialiser,
  'initialiser': ?d.initialiser,
  'declaredType': ?d.declaredType,
  'bodies': [
    for (final b in d.bodies)
      _body(b, d.isTopLevel ? steps['${d.name}.${b.name}'] : null),
  ],
};

Map<String, Object?> _marker(CsMarker m) => {
  'name': m.name,
  'positional': [for (final v in m.positional) _value(v)],
  'named': _named(m.named),
  'line': m.location.line,
};

List<Object?> _named(Map<String, CsValue> named) => [
  for (final e in named.entries) {'name': e.key, 'value': _value(e.value)},
];

Map<String, Object?> _value(CsValue v) => switch (v) {
  CsStringValue(:final value, :final literal) => {
    'kind': 'string',
    'value': value,
    'literal': ?literal,
  },
  CsBoolValue(:final value) => {'kind': 'bool', 'value': value},
  CsIntValue(:final value) => {'kind': 'int', 'value': value},
  CsNullValue() => {'kind': 'null'},
  CsQualifiedValue(:final prefix, :final name) => {
    'kind': 'qualified',
    'prefix': prefix,
    'name': name,
  },
  CsConstructionValue(:final type, :final positional, :final named) => {
    'kind': 'construction',
    'type': type,
    'positional': [for (final p in positional) _value(p)],
    'named': _named(named),
  },
  CsListValue(:final values) => {
    'kind': 'list',
    'values': [for (final e in values) _value(e)],
  },
  CsUnknownValue(:final source) => {'kind': 'unknown', 'source': source},
};

Map<String, Object?> _body(CsMethodBody b, IrBodySteps? record) => {
  'name': b.name,
  'shape': b.shape.name,
  'line': b.location.line,
  'isAsync': b.isAsync,
  'accessor': ?b.accessor,
  if (b.isArrow) 'isArrow': true,
  'parameters': [
    for (final p in b.parameters)
      {
        'name': p.name,
        'type': ?p.type,
        if (p.kind != CsParameterKind.requiredPositional) 'kind': p.kind.name,
        'default': ?p.defaultValue,
      },
  ],
  'returnType': ?b.returnType,
  'thrownType': ?b.thrownType,
  'thrownMessage': ?b.thrownMessage,
  'thrownLiteral': ?b.thrownLiteral,
  'calls': [for (final c in b.calls) _call(c)],
  'statements': [for (final s in b.statements) _statement(s)],
  if (record?.steps case final steps?)
    'steps': [for (final step in steps) _step(step)],
  if (record?.issue case final issue?)
    'stepsRefused': {
      'rule': issue.rule,
      'message': issue.message,
      'line': issue.line,
    },
};

Map<String, Object?> _step(IrStep step) => switch (step) {
  IrCallStep(:final method, :final arguments) => {
    'step': 'call',
    'method': method,
    'arguments': arguments,
    'line': step.line,
  },
  IrReturnStep(:final method, :final arguments) => {
    'step': 'return',
    'method': ?method,
    'arguments': arguments,
    'line': step.line,
  },
  IrGuardedStep(:final guard, :final arguments, :final steps) => {
    'step': 'guarded',
    'guard': guard,
    'arguments': arguments,
    'line': step.line,
    'steps': [for (final s in steps) _step(s)],
  },
};

Map<String, Object?> _call(CsCall c) => {
  'receiver': ?c.receiver,
  'method': c.method,
  'arguments': c.arguments,
  'line': c.location.line,
};

Map<String, Object?> _statement(CsStatement s) => {
  'kind': s.kind.name,
  'source': s.source,
  'line': s.location.line,
  'keyword': ?s.keyword,
  'hasElse': s.hasElse,
  if (s.call case final call?) 'call': _call(call),
  'valueIdentifier': ?s.valueIdentifier,
  'valueSource': ?s.valueSource,
  'boundName': ?s.boundName,
  'isFinal': s.isFinal,
  'nested': [for (final n in s.nested) _statement(n)],
};

Map<String, Object?> _construction(CsConstruction c) => {
  'type': c.type,
  'holder': ?c.holder,
  'line': c.location.line,
  'positional': [for (final v in c.positional) _value(v)],
  'named': _named(c.named),
};

// ---------------------------------------------------------------------------
// Reading
// ---------------------------------------------------------------------------

IrFile _readFile(Object? data) {
  final map = _map(data);
  final path = map['path'] as String;
  CsLocation at(Object? line) => CsLocation(path, line as int);
  final locus = _locus(map['locus']);
  final steps = <IrBodySteps>[];
  final declarations = [
    for (final d in _list(map['declarations']))
      _readDeclaration(_map(d), locus, at, steps),
  ];
  return IrFile(
    locus,
    CsFile(
      path: path,
      source: '',
      imports: _strings(map['imports']),
      exports: _strings(map['exports']),
      comments: [
        for (final c in _list(map['comments']))
          CsComment(
            text: _map(c)['text'] as String,
            isDocumentation: _map(c)['documentation'] as bool,
            isBanner: _map(c)['banner'] as bool,
            location: at(_map(c)['line']),
          ),
      ],
      declarations: declarations,
      constructions: [
        for (final c in _list(map['constructions']))
          CsConstruction(
            type: _map(c)['type'] as String,
            holder: _map(c)['holder'] as String?,
            location: at(_map(c)['line']),
            positional: _values(_map(c)['positional']),
            named: _readNamed(_map(c)['named']),
          ),
      ],
    ),
    steps,
  );
}

CsDeclaration _readDeclaration(
  Map<String, Object?> d,
  CsLocus locus,
  CsLocation Function(Object?) at,
  List<IrBodySteps> steps,
) {
  final name = d['name'] as String;
  if (d['owner'] == null) {
    for (final b in _list(d['bodies'])) {
      final body = _map(b);
      final record = _readBodySteps(name, body);
      if (record != null) steps.add(record);
    }
  }
  final link = d['codeSpec'] == null ? null : _map(d['codeSpec']);
  final doc = d['docComment'] == null ? null : _map(d['docComment']);
  return CsDeclaration(
    locus: locus,
    name: d['name'] as String,
    owner: d['owner'] as String?,
    kind: CsDeclarationKind.values.byName(d['kind'] as String),
    location: at(d['line']),
    markers: [
      for (final m in _list(d['markers']))
        CsMarker(
          _map(m)['name'] as String,
          _values(_map(m)['positional']),
          _readNamed(_map(m)['named']),
          at(_map(m)['line']),
        ),
    ],
    codeSpec: link == null
        ? null
        : CsCodeSpecLink(
            link['id'] as String,
            _strings(link['source']),
            at(link['line']),
          ),
    docSpec: d['docSpec'] == null
        ? null
        : [
            for (final r in _list(d['docSpec']))
              CsDocRef(
                _map(r)['sectionId'] as String,
                _map(r)['description'] as String,
                _map(r)['descriptionLiteral'] as String?,
              ),
          ],
    docSpecLocation: d['docSpecLine'] == null ? null : at(d['docSpecLine']),
    docComment: doc == null
        ? null
        : CsDocComment(_strings(doc['lines']), at(doc['line'])),
    annotations: [
      for (final a in _list(d['annotations'] ?? const []))
        CsAnnotation(_map(a)['source'] as String, at(_map(a)['line'])),
    ],
    typeParameters: d['typeParameters'] as String?,
    superclass: d['superclass'] as String?,
    interfaces: _strings(d['interfaces'] ?? const []),
    mixins: _strings(d['mixins'] ?? const []),
    isConst: d['isConst'] as bool? ?? false,
    initialiser: d['initialiser'] as String?,
    isAbstract: d['isAbstract'] as bool,
    isStatic: d['isStatic'] as bool,
    isFinal: d['isFinal'] as bool,
    isLate: d['isLate'] as bool,
    hasInitialiser: d['hasInitialiser'] as bool,
    declaredType: d['declaredType'] as String?,
    bodies: [for (final b in _list(d['bodies'])) _readBody(_map(b), at)],
  );
}

IrBodySteps? _readBodySteps(String owner, Map<String, Object?> body) {
  final name = body['name'] as String;
  if (body['steps'] case final List<Object?> steps) {
    return IrBodySteps.read(owner, name, [for (final s in steps) _readStep(s)]);
  }
  if (body['stepsRefused'] case final Object refused) {
    final issue = _map(refused);
    return IrBodySteps.refused(
      owner,
      name,
      IrStepIssue(
        issue['rule'] as String,
        issue['message'] as String,
        issue['line'] as int,
      ),
    );
  }
  return null;
}

IrStep _readStep(Object? data) {
  final s = _map(data);
  final line = s['line'] as int;
  final arguments = _strings(s['arguments']);
  return switch (s['step']) {
    'call' => IrCallStep(s['method'] as String, arguments, line),
    'return' => IrReturnStep(s['method'] as String?, arguments, line),
    'guarded' => IrGuardedStep(s['guard'] as String, arguments, [
      for (final n in _list(s['steps'])) _readStep(n),
    ], line),
    final kind => throw IrSpecsException('unknown step "$kind"'),
  };
}

CsMethodBody _readBody(
  Map<String, Object?> b,
  CsLocation Function(Object?) at,
) => CsMethodBody(
  name: b['name'] as String,
  shape: CsBodyShape.values.byName(b['shape'] as String),
  location: at(b['line']),
  isAsync: b['isAsync'] as bool,
  accessor: b['accessor'] as String?,
  isArrow: b['isArrow'] as bool? ?? false,
  thrownLiteral: b['thrownLiteral'] as String?,
  parameters: [
    for (final p in _list(b['parameters']))
      CsParameter(
        _map(p)['name'] as String,
        _map(p)['type'] as String?,
        _map(p)['kind'] == null
            ? CsParameterKind.requiredPositional
            : CsParameterKind.values.byName(_map(p)['kind'] as String),
        _map(p)['default'] as String?,
      ),
  ],
  returnType: b['returnType'] as String?,
  thrownType: b['thrownType'] as String?,
  thrownMessage: b['thrownMessage'] as String?,
  calls: [for (final c in _list(b['calls'])) _readCall(_map(c), at)],
  statements: [
    for (final s in _list(b['statements'])) _readStatement(_map(s), at),
  ],
);

CsCall _readCall(Map<String, Object?> c, CsLocation Function(Object?) at) =>
    CsCall(
      receiver: c['receiver'] as String?,
      method: c['method'] as String,
      arguments: c['arguments'] == null ? const [] : _strings(c['arguments']),
      location: at(c['line']),
    );

CsStatement _readStatement(
  Map<String, Object?> s,
  CsLocation Function(Object?) at,
) => CsStatement(
  kind: CsStatementKind.values.byName(s['kind'] as String),
  source: s['source'] as String,
  location: at(s['line']),
  keyword: s['keyword'] as String?,
  hasElse: s['hasElse'] as bool? ?? false,
  call: s['call'] == null ? null : _readCall(_map(s['call']), at),
  valueIdentifier: s['valueIdentifier'] as String?,
  valueSource: s['valueSource'] as String?,
  boundName: s['boundName'] as String?,
  isFinal: s['isFinal'] as bool,
  nested: [for (final n in _list(s['nested'])) _readStatement(_map(n), at)],
);

CsValue _readValue(Object? data) {
  final v = _map(data);
  return switch (v['kind']) {
    'string' => CsStringValue(v['value'] as String, v['literal'] as String?),
    'bool' => CsBoolValue(v['value'] as bool),
    'int' => CsIntValue(v['value'] as int),
    'null' => const CsNullValue(),
    'qualified' => CsQualifiedValue(v['prefix'] as String, v['name'] as String),
    'construction' => CsConstructionValue(
      v['type'] as String,
      _values(v['positional']),
      _readNamed(v['named']),
    ),
    'list' => CsListValue(_values(v['values'])),
    'unknown' => CsUnknownValue(v['source'] as String),
    final kind => throw IrSpecsException('unknown value kind "$kind"'),
  };
}

List<CsValue> _values(Object? data) => [
  for (final v in _list(data)) _readValue(v),
];

Map<String, CsValue> _readNamed(Object? data) => {
  for (final e in _list(data))
    _map(e)['name'] as String: _readValue(_map(e)['value']),
};

CsLocus _locus(Object? name) => CsLocus.values.byName(name as String);

Map<String, Object?> _map(Object? data) =>
    (data as Map).cast<String, Object?>();

List<Object?> _list(Object? data) => (data as List).cast<Object?>();

List<String> _strings(Object? data) => _list(data).cast<String>().toList();
