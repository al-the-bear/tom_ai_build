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
