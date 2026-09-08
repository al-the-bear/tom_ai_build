/// The slice of a [SpecModel] one SOM generation run actually emits — the
/// selected `@Document` roots and the model classes reachable from them.
///
/// **Why this exists.** The root filter and the reachability walk are one rule
/// each, and each was written out once per emitter: nine copies of the walk
/// (`_reachableClasses`) and eighteen of the filter (`_selectedRoots` in the
/// nine facade emitters, `_roots` in the nine metadata emitters), all
/// byte-identical. Twenty-seven copies of two rules is twenty-seven places a
/// fix would have to land, and it is why the generation *results* could report
/// the whole model while the emitters walked a subset — nothing owned the
/// question "what did this run cover?", so nobody could answer it.
///
/// The emitters keep their private accessors as one-line delegates, so a call
/// site still reads `_selectedRoots`; only the rule moved.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The `@Document` roots a run with [documentRoots] generates for.
///
/// An empty [documentRoots] means **every** root — that is the CLI's default
/// and the shape of every committed `tom_som_*_v0` package. A named root that
/// the model does not declare is silently absent rather than an error: the
/// filter selects, it does not assert.
List<SpecRoot> somSelectedRoots(SpecModel model, List<String> documentRoots) {
  if (documentRoots.isEmpty) return model.roots;
  final wanted = documentRoots.toSet();
  return model.roots.where((r) => wanted.contains(r.type)).toList();
}

/// The model classes reachable from [rootTypes] by following the field kinds
/// that name another class — `complex` and `section` through `SpecField.type`,
/// `list` through `elementType` when the element is complex.
///
/// `form`, `content`, `enumValue` and `scalar` fields terminate the walk: a
/// form projects to members of the *owning* emitted type rather than to a model
/// class of its own, and the other three are leaves.
///
/// A name with no class in [model] is skipped rather than throwing — a
/// dangling type reference is the meta validator's business, and failing here
/// would turn it into a crash halfway through emission.
Set<String> somReachableClasses(SpecModel model, Set<String> rootTypes) {
  final visited = <String>{};
  final queue = <String>[...rootTypes];
  while (queue.isNotEmpty) {
    final name = queue.removeLast();
    if (!visited.add(name)) continue;
    final cls = model.classNamed(name);
    if (cls == null) continue;
    for (final f in cls.fields) {
      switch (f.kind) {
        case SpecFieldKind.complex:
        case SpecFieldKind.section:
          if (f.type != null) queue.add(f.type!);
          break;
        case SpecFieldKind.list:
          if (f.elementIsComplex && f.elementType != null) {
            queue.add(f.elementType!);
          }
          break;
        case SpecFieldKind.form:
        case SpecFieldKind.content:
        case SpecFieldKind.enumValue:
        case SpecFieldKind.scalar:
          break;
      }
    }
  }
  return visited;
}

/// What one generation run covers: the roots it emitted a typed root type for,
/// and the model classes reachable from them.
///
/// This is the answer the nine `Som*GenerationResult` classes report. It is
/// deliberately a property of the *run*, not of the model — the model's own
/// size is stamped in `meta/spec_model.meta.json` (`classCount` / `rootCount`),
/// which every result names through its `metaJsonPath`.
class SomEmittedSurface {
  /// Both fields are required: a surface is only ever built from a completed
  /// selection-and-walk pair, so there is no partial form worth constructing.
  const SomEmittedSurface({required this.roots, required this.classNames});

  /// The selected roots, in model order.
  final List<SpecRoot> roots;

  /// The names of the model classes reachable from [roots].
  final Set<String> classNames;

  /// How many `@Document` roots this run generated a typed root type for.
  int get rootCount => roots.length;

  /// How many **model classes** the emitted facade covers.
  ///
  /// Not the number of generated *types*: a `@Form` field and an enum each add
  /// a type beyond their model class, so every language emits more types than
  /// this. Not the model's size either — see [SomEmittedSurface].
  int get classCount => classNames.length;
}

/// Computes the [SomEmittedSurface] a run over [model] with [documentRoots]
/// covers — the same two steps every emitter performs before emitting, so the
/// reported figure cannot disagree with what was written.
SomEmittedSurface somEmittedSurface(
  SpecModel model, {
  List<String> documentRoots = const [],
}) {
  final roots = somSelectedRoots(model, documentRoots);
  return SomEmittedSurface(
    roots: roots,
    classNames: somReachableClasses(model, roots.map((r) => r.type).toSet()),
  );
}

/// One enum type a generated facade must declare.
///
/// Language-neutral on purpose: every emitter maps this onto its own idiom —
/// a Python `Enum`, a Java `enum`, a frozen JavaScript object, Go and Rust
/// constants, C `#define` tokens — but they must all agree on *which* enums
/// exist and what tokens they carry, because the token is what lands in the
/// document and a document written by one port is read by all of them.
class SomEnumType {
  /// The model's enum type name, naming the generated type and its parse
  /// helper. Unique by construction: the collection dedupes by this name.
  final String name;

  /// The declared constants, in model declaration order. Each is emitted twice
  /// over — once as the constant and once as the **stored token** — and the
  /// two are deliberately the same string.
  ///
  /// Order is load-bearing in the ports that fall back to a positional
  /// identifier when a name sanitizes to nothing: reordering the model would
  /// rename constants rather than merely reorder them.
  final List<String> values;

  /// Each constant's model doc comment, keyed by constant name; a constant
  /// with no comment is absent.
  ///
  /// [values] alone says *which* tokens are legal, which for a closed
  /// vocabulary is the smaller half of the question — the author's choice is
  /// between adjacent constants, and what separates them lives only here.
  final Map<String, String> docs;

  /// Creates an enum type description.
  const SomEnumType(this.name, this.values, this.docs);
}

/// Every enum type reachable from [reachable], in name order.
///
/// **This is the rule that drifted, which is why it lives here.** Nine emitters
/// each carried a private copy; eight collected only `SpecFieldKind.enumValue`
/// fields, and the model declares **zero** of those — so eight facades emitted
/// no enum at all while their emission machinery sat unused. The Dart copy was
/// the odd one out: it also walked `@Form` fields, which is where all of the
/// model's reachable enums actually live. The result was a typed enum with
/// per-constant documentation in Dart and a bare string accessor in the other
/// eight, from one model.
///
/// Both sources are collected here, once:
///
/// - a `SpecFieldKind.enumValue` field, via its `enumType`; and
/// - an enum-valued member of a `@Form` field, via its declared type.
///
/// A nullable declared type (`Foo?`) names the same enum as `Foo`, so the `?`
/// is stripped before the name is used as a key — otherwise one model enum
/// would be emitted twice under two names.
List<SomEnumType> somReachableEnums(SpecModel model, Set<String> reachable) {
  final byName = <String, SomEnumType>{};
  for (final name in reachable) {
    final cls = model.classNamed(name);
    if (cls == null) continue;
    for (final f in cls.fields) {
      if (f.kind == SpecFieldKind.enumValue && f.enumType != null) {
        byName.putIfAbsent(
          f.enumType!,
          () => SomEnumType(f.enumType!, f.enumValues, f.enumValueDocs),
        );
      }
      if (f.kind == SpecFieldKind.form) {
        for (final ff in f.formFields) {
          if (ff.enumValues.isEmpty) continue;
          final type = somScalarBaseName(ff.type);
          byName.putIfAbsent(
            type,
            () => SomEnumType(type, ff.enumValues, ff.enumValueDocs),
          );
        }
      }
    }
  }
  return byName.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}

/// [typeName] without a trailing `?`.
///
/// Shared because an emitter that stripped it differently would file one model
/// enum under two names.
String somScalarBaseName(String typeName) => typeName.endsWith('?')
    ? typeName.substring(0, typeName.length - 1)
    : typeName;
