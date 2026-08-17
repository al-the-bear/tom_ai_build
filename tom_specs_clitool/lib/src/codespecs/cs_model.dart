/// The source model the CodeSpecs validator checks run over.
///
/// This is a **reading** of emitted CodeSpecs Dart, not a re-derivation of it:
/// one [CsLocusProject] per generated project of the
/// `codespecs_mapping.md` §4.2 trio, each holding the declarations, their `Cs*`
/// markers with argument values, the back-link annotations, the method-body
/// shapes and the substrate constructions the
/// `codespecs_derivation_contract.md` §6 checks read.
///
/// Values are modelled rather than resolved. A generated file writes every
/// marker inline with literal, enum-access or `Cs*Ref` const arguments
/// (`codespecs_derivation_contract.md` §2.7), so the constant surface the checks
/// need is exactly what the syntax carries.
library;

import 'cs_extract.dart';

/// One of the three generated projects (`codespecs_mapping.md` §4.2).
enum CsLocus {
  /// The project both others depend on.
  shared,

  /// The client-only project.
  client,

  /// The server-only project.
  server;

  /// The name used in violation messages.
  String get label => name;
}

/// Where a violation is (file plus 1-based line).
class CsLocation {
  /// The file the element was read from, as given to the reader.
  final String file;

  /// The 1-based line of the element.
  final int line;

  /// Creates a location.
  const CsLocation(this.file, this.line);

  @override
  String toString() => '$file:$line';
}

// ---------------------------------------------------------------------------
// Constant values
// ---------------------------------------------------------------------------

/// A constant value read off a CodeSpecs annotation argument or a substrate
/// constructor argument.
sealed class CsValue {
  /// Creates a value.
  const CsValue();
}

/// A string literal.
class CsStringValue extends CsValue {
  /// The literal text.
  final String value;

  /// Creates a string value.
  const CsStringValue(this.value);

  @override
  String toString() => "'$value'";
}

/// A boolean literal.
class CsBoolValue extends CsValue {
  /// The literal value.
  final bool value;

  /// Creates a boolean value.
  const CsBoolValue(this.value);

  @override
  String toString() => '$value';
}

/// An integer literal.
class CsIntValue extends CsValue {
  /// The literal value.
  final int value;

  /// Creates an integer value.
  const CsIntValue(this.value);

  @override
  String toString() => '$value';
}

/// A `null` literal — written where a per-kind slot is deliberately absent.
class CsNullValue extends CsValue {
  /// Creates a null value.
  const CsNullValue();

  @override
  String toString() => 'null';
}

/// A qualified identifier: an enum access (`CsTextRole.error`) or a catalogue
/// const reference (`SharedOperations.login`). Which of the two it is depends on
/// the reading check, so the model keeps both parts and decides nothing.
class CsQualifiedValue extends CsValue {
  /// The part before the dot — an enum type or a catalogue holder.
  final String prefix;

  /// The part after the dot — an enum constant or a const member.
  final String name;

  /// Creates a qualified value.
  const CsQualifiedValue(this.prefix, this.name);

  /// The dotted source form.
  String get path => '$prefix.$name';

  @override
  String toString() => path;
}

/// A constructor call — a `Cs*Ref` const, a value class such as
/// `CsGradedAccess`, or a `tom_core` substrate construction.
class CsConstructionValue extends CsValue {
  /// The constructed type name.
  final String type;

  /// Positional arguments, in source order.
  final List<CsValue> positional;

  /// Named arguments.
  final Map<String, CsValue> named;

  /// Creates a construction value.
  const CsConstructionValue(this.type, this.positional, this.named);

  /// The first positional argument as a string, when it is one.
  ///
  /// Every `Cs*Ref` in `cross_part_refs.dart` wraps exactly one id string in its
  /// first positional slot, so this is the ref id.
  String? get idArgument {
    final first = positional.isEmpty ? null : positional.first;
    return first is CsStringValue ? first.value : null;
  }

  @override
  String toString() {
    final args = [
      ...positional.map((v) => '$v'),
      ...named.entries.map((e) => '${e.key}: ${e.value}'),
    ];
    return '$type(${args.join(', ')})';
  }
}

/// A list literal.
class CsListValue extends CsValue {
  /// The elements, in source order.
  final List<CsValue> values;

  /// Creates a list value.
  const CsListValue(this.values);

  @override
  String toString() => '[${values.join(', ')}]';
}

/// An expression the reader did not model — kept with its source text so a
/// message can quote it rather than say "something".
class CsUnknownValue extends CsValue {
  /// The source text of the expression.
  final String source;

  /// Creates an unknown value.
  const CsUnknownValue(this.source);

  @override
  String toString() => source;
}

// ---------------------------------------------------------------------------
// Annotations
// ---------------------------------------------------------------------------

/// One `Cs*` part marker as written on a declaration.
class CsMarker {
  /// The marker name without the `@` (`CsTrigger`).
  final String name;

  /// Positional arguments, in source order.
  final List<CsValue> positional;

  /// Named arguments.
  final Map<String, CsValue> named;

  /// Where the marker is written.
  final CsLocation location;

  /// Creates a marker.
  const CsMarker(this.name, this.positional, this.named, this.location);

  /// The first positional argument, or `null` when the marker has none.
  ///
  /// `codespecs_derivation_contract.md` §2.3 puts the authored identifier in
  /// exactly this slot for every marker that has one.
  CsValue? get firstPositional =>
      positional.isEmpty ? null : positional.first;

  /// The first positional argument as a string, when it is one.
  String? get firstPositionalString {
    final first = firstPositional;
    return first is CsStringValue ? first.value : null;
  }

  /// Named arguments that are neither absent nor an explicit `null`.
  Map<String, CsValue> get presentNamed => {
        for (final e in named.entries)
          if (e.value is! CsNullValue) e.key: e.value,
      };
}

/// One `DocRef` tuple of a `@DocSpec` annotation.
class CsDocRef {
  /// The SOM section id, verbatim.
  final String sectionId;

  /// The one-sentence edge description.
  final String description;

  /// Creates a doc reference.
  const CsDocRef(this.sectionId, this.description);
}

/// A `@CodeSpec` back-link.
class CsCodeSpecLink {
  /// The stable CodeSpec id, `<canonical id>.<identifier>`.
  final String id;

  /// The flat set of SOM sections that fed the element.
  final List<String> source;

  /// Where the annotation is written.
  final CsLocation location;

  /// Creates a `@CodeSpec` link.
  const CsCodeSpecLink(this.id, this.source, this.location);

  /// The identifier half of [id] — what N1 derived, or empty when it derived
  /// nothing.
  String get identifier {
    final dot = id.indexOf('.');
    return dot < 0 ? id : id.substring(dot + 1);
  }

  /// The canonical part id half of [id].
  String get canonicalId {
    final dot = id.indexOf('.');
    return dot < 0 ? '' : id.substring(0, dot);
  }
}

// ---------------------------------------------------------------------------
// Declarations
// ---------------------------------------------------------------------------

/// What a method body does, as far as the "compiles but does not execute"
/// invariants of `codespecs_derivation_contract.md` §2.4 care.
enum CsBodyShape {
  /// No body at all — abstract, external, or a field/getter declaration.
  none,

  /// The entire body is a single `throw`.
  throwOnly,

  /// The body returns a value.
  returnsValue,

  /// A body that is neither of the above.
  other,
}

/// One call site inside a generated body.
///
/// Read as **source text**, not as a resolved element: the reader is a syntax
/// pass (`cs_reader`), so a call is a receiver spelling plus a method name.
/// That is exactly enough for the collaborator half of check 23 —
/// `collaborator.<m>(…)` — and deliberately not enough for the substrate half,
/// which the emitted trio's own compiler already catches
/// (`codespecs_derivation_contract.md` §6).
class CsCall {
  /// The receiver as written (`collaborator`), or `null` for an unqualified
  /// call.
  final String? receiver;

  /// The invoked method name.
  final String method;

  /// Where the call is written.
  final CsLocation location;

  /// Creates a call site.
  const CsCall({
    required this.method,
    required this.location,
    this.receiver,
  });
}

/// What kind of statement one line of a generated body is.
///
/// The five `codespecs_derivation_contract.md` §2.4 admits, plus the two shapes
/// that are **not** among them and so have to be nameable in order to be
/// rejected: [thrown] (a 3a body is a throw, a 3b body may not contain one) and
/// [other] (everything the five do not cover — an assignment, a bare literal, a
/// `try`, an arithmetic expression).
enum CsStatementKind {
  /// §2.4 kind 1 or 2 — a call on the collaborator or on a named substrate.
  call,

  /// §2.4 kind 3 — a `final` local binding of a call's result.
  localBinding,

  /// §2.4 kind 4 — `if` / `for` / `switch` / `while`.
  controlFlow,

  /// §2.4 kind 5 — a `return`.
  returned,

  /// A `throw`. The whole of a form-3a body; never a statement of a 3b one.
  thrown,

  /// Anything else, which §2.4 admits nowhere.
  other,
}

/// One statement of a generated body.
///
/// Read as syntax, like everything else in this model: a statement is its kind,
/// its source text, and — where it has one — the call its value comes out of.
/// That last part is what lets the §2.4 invariant-2 check ask *could the
/// generator have made this value up?* rather than *does the body return?*.
class CsStatement {
  /// Which of the §2.4 statement kinds this is.
  final CsStatementKind kind;

  /// The statement as written, whitespace-collapsed, so a message can quote it.
  final String source;

  /// The call the statement's value comes out of — the returned expression, the
  /// binding's initialiser, the branch condition — unwrapped from any `await`.
  /// `null` when the value expression is not a call.
  final CsCall? call;

  /// The bare identifier the value expression is, when it is one. A `return` of
  /// a local bound earlier in the body reads as this.
  final String? valueIdentifier;

  /// The source text of the value expression, when the statement has one.
  final String? valueSource;

  /// The name a [CsStatementKind.localBinding] binds.
  final String? boundName;

  /// Whether a local binding is declared `final`.
  final bool isFinal;

  /// The statements inside a control-flow statement's blocks, in source order.
  final List<CsStatement> nested;

  /// Which control-flow construct a [CsStatementKind.controlFlow] statement is —
  /// `if`, `for`, `while`, `switch`, or `block` for a bare nested block.
  ///
  /// Read from the syntax rather than sniffed back out of [source], because
  /// §2.4 B7 distinguishes the constructs by name: `if` is derived, repetition
  /// and multi-way choice are not.
  final String? keyword;

  /// Where the statement is written.
  final CsLocation location;

  /// Creates a statement.
  const CsStatement({
    required this.kind,
    required this.source,
    required this.location,
    this.call,
    this.valueIdentifier,
    this.valueSource,
    this.boundName,
    this.isFinal = false,
    this.nested = const [],
    this.keyword,
  });

  /// This statement and every statement nested inside it, outermost first.
  Iterable<CsStatement> get selfAndNested sync* {
    yield this;
    for (final statement in nested) {
      yield* statement.selfAndNested;
    }
  }
}

/// One formal parameter of a generated method, as written.
///
/// Both halves are source text rather than resolved elements: §3.0.1 point 2
/// requires a collaborator method to repeat its caller's list "name-for-name and
/// type-for-type", and two spellings of the same type are a divergence that rule
/// exists to catch.
class CsParameter {
  /// The parameter name.
  final String name;

  /// The declared type as written, or `null` when the parameter declares none.
  final String? type;

  /// Creates a parameter.
  const CsParameter(this.name, [this.type]);

  @override
  String toString() => type == null ? name : '$type $name';
}

/// A method or accessor body of a generated declaration.
class CsMethodBody {
  /// The method name.
  final String name;

  /// What the body does.
  final CsBodyShape shape;

  /// The call sites the body contains, in source order.
  final List<CsCall> calls;

  /// The body's statements, in source order. Empty for a body-less method and
  /// for a body shape the reader does not decompose.
  final List<CsStatement> statements;

  /// The declared formal parameters, in source order.
  final List<CsParameter> parameters;

  /// The declared return type as written, or `null` when there is none.
  final String? returnType;

  /// The literal argument of the `throw`, when the body is a single throw of a
  /// constructor call with a string literal. `null` when unreadable.
  final String? thrownMessage;

  /// The thrown type, when the body is a single throw of a constructor call.
  final String? thrownType;

  /// Whether the method is declared `async` / `async*`.
  final bool isAsync;

  /// Where the method is declared.
  final CsLocation location;

  /// Creates a method body.
  const CsMethodBody({
    required this.name,
    required this.shape,
    required this.location,
    this.calls = const [],
    this.statements = const [],
    this.parameters = const [],
    this.returnType,
    this.thrownMessage,
    this.thrownType,
    this.isAsync = false,
  });

  /// Every statement of the body, nested ones included.
  Iterable<CsStatement> get allStatements =>
      statements.expand((s) => s.selfAndNested);

  /// Whether this body is a pseudo-implementation — §2.4's form 3b, which is
  /// every body that is neither absent nor a lone `throw`.
  bool get isPseudoImplementation =>
      shape != CsBodyShape.none && shape != CsBodyShape.throwOnly;
}

/// What kind of Dart declaration a [CsDeclaration] stands for.
///
/// Carried because several §6 checks turn on the *shape* of a declaration
/// rather than on its markers — check 24 rejects a field, a constructor or a
/// static member on a `@CsCollaborator` class, and a field and a body-less
/// method are otherwise indistinguishable in this model.
enum CsDeclarationKind {
  /// A top-level `class`.
  classType,

  /// A top-level `enum`.
  enumType,

  /// A top-level `mixin`.
  mixinType,

  /// A top-level variable.
  topLevelVariable,

  /// A top-level function.
  topLevelFunction,

  /// An instance or static field of a class.
  field,

  /// A method, getter or setter of a class.
  method,

  /// A constructor of a class.
  constructor,
}

/// A `///` documentation block, as written.
///
/// Kept as raw lines rather than as rendered text because
/// `codespecs_derivation_contract.md` §2.8 C4 constrains the *emitted* lines —
/// no trailing whitespace, escaped `\[`, `\]` and `&lt;` — and a normalised
/// reading would erase exactly what that rule is about.
class CsDocComment {
  /// The comment lines as written, each including its leading `///`.
  final List<String> lines;

  /// Where the first line is.
  final CsLocation location;

  /// Creates a doc comment.
  const CsDocComment(this.lines, this.location);

  /// The 1-based line the block ends on.
  int get endLine => location.line + lines.length - 1;

  /// The comment text with each line's `///` marker removed.
  List<String> get text => [
        for (final line in lines)
          line.startsWith('///') ? line.substring(3).trimLeft() : line,
      ];

  /// The comment text with each line's `/// ` marker removed and **nothing
  /// else** — at most the one space C4.1 puts after the marker.
  ///
  /// [text] trims each line's leading whitespace, which is what a check about
  /// escapes wants and exactly what a check about fidelity must not have: a
  /// nested list item or an indented fenced line differs from its source only
  /// in that indentation, so trimming it would make a mangled comment compare
  /// equal to the specification it mangled.
  List<String> get verbatimText => [
        for (final line in lines) _unmark(line),
      ];

  static String _unmark(String line) {
    if (!line.startsWith('///')) return line;
    final rest = line.substring(3);
    return rest.startsWith(' ') ? rest.substring(1) : rest;
  }

  /// Whether the block says anything at all — a block of bare `///` markers
  /// documents nothing.
  bool get isEmpty => text.every((l) => l.trim().isEmpty);
}

/// One comment token of a generated file.
///
/// Read so §2.8 C6 — *the only `//` in a generated file is §2.7's banner* — is
/// checkable. A doc comment is one of these too; [isDocumentation] is what tells
/// the two apart.
class CsComment {
  /// The comment as written, including its marker.
  final String text;

  /// Whether it is a `///` doc comment.
  final bool isDocumentation;

  /// Whether it precedes the file's very first token — §2.7's banner position.
  final bool isBanner;

  /// Where the comment is.
  final CsLocation location;

  /// Creates a comment.
  const CsComment({
    required this.text,
    required this.isDocumentation,
    required this.isBanner,
    required this.location,
  });
}

/// A generated declaration — a top-level class/enum/variable, or a member of
/// one.
class CsDeclaration {
  /// The locus project the declaration belongs to.
  final CsLocus locus;

  /// The declaration name (`Customer`, `save`).
  final String name;

  /// The owning declaration name for a member; `null` for a top-level one.
  final String? owner;

  /// The `Cs*` part markers written on the declaration.
  final List<CsMarker> markers;

  /// The `@CodeSpec` back-link, when present.
  final CsCodeSpecLink? codeSpec;

  /// The `@DocSpec` tuples, or `null` when the annotation is absent.
  final List<CsDocRef>? docSpec;

  /// Whether a variable declaration carries an initialiser.
  final bool hasInitialiser;

  /// The declared type of a variable, as written; `null` when there is none —
  /// either because it is inferred (`final x = …`) or because the declaration
  /// is not a variable at all.
  ///
  /// Source text rather than a resolved type, because the reader is a syntax
  /// pass over a tree whose packages need not be resolvable.
  final String? declaredType;

  /// The method bodies this declaration declares.
  final List<CsMethodBody> bodies;

  /// Which Dart declaration shape this is.
  final CsDeclarationKind kind;

  /// Whether a class carries the `abstract` keyword.
  final bool isAbstract;

  /// Whether a member is declared `static`.
  final bool isStatic;

  /// The `///` block above the declaration, or `null` when there is none
  /// (`codespecs_derivation_contract.md` §2.8 C2).
  final CsDocComment? docComment;

  /// Where the declaration is written.
  final CsLocation location;

  /// Creates a declaration.
  const CsDeclaration({
    required this.locus,
    required this.name,
    required this.markers,
    required this.location,
    required this.kind,
    this.owner,
    this.codeSpec,
    this.docSpec,
    this.hasInitialiser = false,
    this.declaredType,
    this.bodies = const [],
    this.isAbstract = false,
    this.isStatic = false,
    this.docComment,
  });

  /// The line of the first annotation written on the declaration, or the
  /// declaration's own line when it carries none — what §2.8 C4 rule 3 requires
  /// a doc block to sit immediately above.
  int get firstAnnotationLine {
    var line = location.line;
    for (final marker in markers) {
      if (marker.location.line < line) line = marker.location.line;
    }
    final link = codeSpec;
    if (link != null && link.location.line < line) line = link.location.line;
    return line;
  }

  /// Whether this is a top-level declaration.
  bool get isTopLevel => owner == null;

  /// The `<owner>.<member>` path for a member, the bare name for a top-level
  /// declaration — the N9 form of a reference target.
  String get path => owner == null ? name : '$owner.$name';

  /// The first marker with [markerName], or `null`.
  CsMarker? marker(String markerName) {
    for (final m in markers) {
      if (m.name == markerName) return m;
    }
    return null;
  }

  /// Whether the declaration carries [markerName].
  bool has(String markerName) => marker(markerName) != null;
}

/// A `tom_core`-family construction in generated code — read for the checks
/// whose subject is a substrate constructor argument rather than a marker one.
class CsConstruction {
  /// The constructed type name.
  final String type;

  /// Positional arguments, in source order.
  final List<CsValue> positional;

  /// Named arguments.
  final Map<String, CsValue> named;

  /// The declaration the construction is the value of, when it has one.
  final String? holder;

  /// Where the construction is written.
  final CsLocation location;

  /// Creates a construction.
  const CsConstruction({
    required this.type,
    required this.positional,
    required this.named,
    required this.location,
    this.holder,
  });

  /// The named argument [argument] as a string, when it is a string literal.
  String? stringArgument(String argument) {
    final value = named[argument];
    return value is CsStringValue ? value.value : null;
  }
}

/// One generated Dart file.
class CsFile {
  /// The file path as given to the reader.
  final String path;

  /// The file's source text, verbatim.
  ///
  /// Kept because §2.8 C5's determinism promise is *byte-for-byte*: the check
  /// that verifies it diffs two runs' text, and a diff of the resolved model
  /// would miss exactly the reorderings and whitespace a non-deterministic
  /// generator produces.
  final String source;

  /// The `import` URIs the file declares.
  final List<String> imports;

  /// The declarations the file contributes.
  final List<CsDeclaration> declarations;

  /// The substrate constructions the file contains.
  final List<CsConstruction> constructions;

  /// Every comment token in the file, in source order.
  final List<CsComment> comments;

  /// Creates a file.
  const CsFile({
    required this.path,
    required this.source,
    required this.imports,
    required this.declarations,
    required this.constructions,
    this.comments = const [],
  });
}

/// One generated project of the §4.2 trio.
class CsLocusProject {
  /// Which project this is.
  final CsLocus locus;

  /// The package name, used by the locus-arrow check to recognise an import of
  /// a sibling project.
  final String packageName;

  /// The files the project contributes.
  final List<CsFile> files;

  /// Creates a locus project.
  const CsLocusProject({
    required this.locus,
    required this.packageName,
    required this.files,
  });

  /// Every declaration in the project.
  Iterable<CsDeclaration> get declarations =>
      files.expand((f) => f.declarations);

  /// Every construction in the project.
  Iterable<CsConstruction> get constructions =>
      files.expand((f) => f.constructions);
}

/// A closed catalogue and the `tom_core` catalogue it mirrors
/// (`codespecs_derivation_contract.md` §5.3).
class CsEnumMirror {
  /// The `tom_code_specs` enum name.
  final String csEnumName;

  /// The `tom_core` enum name it mirrors.
  final String coreEnumName;

  /// The mirror's values, in declaration order.
  final List<String> csValues;

  /// The counterpart's values, in declaration order.
  final List<String> coreValues;

  /// Creates a mirror pair.
  const CsEnumMirror({
    required this.csEnumName,
    required this.coreEnumName,
    required this.csValues,
    required this.coreValues,
  });
}

/// A second generation run over the same spec model, for the determinism check.
///
/// The only §6 check whose subject is two trios rather than one: §2.8 C5 and
/// §2.1 N1 promise that regenerating over an unchanged document reproduces the
/// output byte-for-byte, and nothing in a *single* trio can witness that. The
/// caller regenerates into a second tree and hands it over here; a caller that
/// does not is the one caller who has not run check 31, which the CLI says out
/// loud rather than passing silently.
class CodeSpecsRegeneration {
  /// The second run's shared project.
  final CsLocusProject shared;

  /// The second run's client project.
  final CsLocusProject client;

  /// The second run's server project.
  final CsLocusProject server;

  /// Creates a regeneration.
  const CodeSpecsRegeneration({
    required this.shared,
    required this.client,
    required this.server,
  });

  /// The project for [locus].
  CsLocusProject project(CsLocus locus) => switch (locus) {
        CsLocus.shared => shared,
        CsLocus.client => client,
        CsLocus.server => server,
      };
}

/// Everything the thirty-four checks read.
class CodeSpecsValidationInput {
  /// The shared project.
  final CsLocusProject shared;

  /// The client project.
  final CsLocusProject client;

  /// The server project.
  final CsLocusProject server;

  /// The CE-MG migration artifacts, relative path → SQL text, for the
  /// cumulative-DDL convergence check.
  final Map<String, String> migrations;

  /// The mirrored-catalogue pairs, for the mirror-completeness check.
  final List<CsEnumMirror> enumMirrors;

  /// A second generation run over the same model, for the determinism check.
  /// `null` when the caller performed none.
  final CodeSpecsRegeneration? regeneration;

  /// The per-area extracts the trio was authored from, for the comment checks.
  ///
  /// The second side of §2.8: a comment claims to carry specification text, and
  /// only the extract holds that text. Empty when the caller supplied none, in
  /// which case the three comment-source checks report nothing rather than
  /// guessing.
  final CsExtractSet extracts;

  /// Creates a validation input.
  CodeSpecsValidationInput({
    required this.shared,
    required this.client,
    required this.server,
    this.migrations = const {},
    this.enumMirrors = const [],
    this.regeneration,
    CsExtractSet? extracts,
  }) : extracts = extracts ?? CsExtractSet.empty;

  /// The three projects, in emission order.
  List<CsLocusProject> get projects => [shared, client, server];

  /// The project for [locus].
  CsLocusProject project(CsLocus locus) => switch (locus) {
        CsLocus.shared => shared,
        CsLocus.client => client,
        CsLocus.server => server,
      };

  /// Every declaration across the trio.
  Iterable<CsDeclaration> get declarations =>
      projects.expand((p) => p.declarations);
}
