/// Shared enumeration of **generated path constants** (plan item #11) for the
/// SOM typed facades.
///
/// Generic consumers of a [SpecDocument] address sections by raw string paths
/// (`'SBP/currentLandscape/CUOPME-OPER-LST'`) — undiscoverable and typo-prone.
/// Item 11 generates, per document root, a holder of named constants
/// (`SbpPaths.currentLandscapeOperationalMetrics`) whose values are those exact
/// paths, so generic code references a symbol instead of a literal.
///
/// The **name/value data is identical across all nine languages** — only the
/// surface syntax of the emitted holder differs. This module is therefore the
/// single source of truth: every language emitter formats the same
/// [SpecPathHolder] list, guaranteeing the constant names and path strings never
/// drift between facades.
///
/// ## What earns a constant
///
/// Every *fixed* navigable position reachable from a root earns one constant:
/// each `complex`, `section`, `list`, `form`, `content`, `scalar` and `enum`
/// field. List **items** (`…-<seq>`) are dynamic and never fixed, so they are
/// excluded — a list field yields the constant for the list *container* path
/// only. Form-field values are sub-keys of a form store, not path segments, so
/// they are likewise excluded.
///
/// The walk descends through `complex`/`section` fields (which collapse into
/// their target class) with **cycle detection**: a type already on the current
/// navigation stack is not re-entered, keeping recursive models finite.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// One generated path constant: a [name] symbol bound to an absolute generic
/// [path] string.
class SpecPathConstant {
  /// The constant's identifier (camelCase navigation chain of field names,
  /// disambiguated with a numeric suffix on the rare camelCase collision).
  final String name;

  /// The absolute generic path the constant addresses (root segment + each
  /// field segment, `@SectionId` ?? name).
  final String path;

  /// The kind of the field the constant terminates on — lets an emitter shape
  /// per-kind documentation.
  final SpecFieldKind kind;

  const SpecPathConstant({
    required this.name,
    required this.path,
    required this.kind,
  });
}

/// The path-constant holder for one document root.
class SpecPathHolder {
  /// The document root this holder covers.
  final SpecRoot root;

  /// The holder type name (`<Pascal(rootSegment)>Paths`, e.g. `SbpPaths`).
  final String holderName;

  /// The root's path segment (`@SectionId` ?? type, e.g. `SBP`) — the prefix of
  /// every constant's [SpecPathConstant.path].
  final String rootSegment;

  /// The constants, in deterministic DFS order.
  final List<SpecPathConstant> constants;

  const SpecPathHolder({
    required this.root,
    required this.holderName,
    required this.rootSegment,
    required this.constants,
  });
}

/// Enumerates the [SpecPathHolder]s for the selected [documentRoots] (empty ⇒
/// every root in [model]), in the model's root order.
///
/// Deterministic: the DFS follows `cls.fields` (serialization order) and the
/// per-holder collision suffixing is allocated in that same encounter order, so
/// repeated runs over an unchanged model produce byte-identical output. Throws
/// [StateError] if two constants in one holder still collide after suffixing
/// (a should-never-happen guard).
List<SpecPathHolder> enumerateSpecPathHolders(
  SpecModel model, {
  List<String> documentRoots = const [],
}) {
  final ref = SpecReflection(model);
  final wanted = documentRoots.toSet();
  final roots = documentRoots.isEmpty
      ? model.roots
      : model.roots.where((r) => wanted.contains(r.type)).toList();

  final holders = <SpecPathHolder>[];
  for (final root in roots) {
    final rootSegment = ref.rootSegment(root);
    final constants = <SpecPathConstant>[];
    final usedNames = <String>{};
    final stack = <String>{};

    void walk(String? className, String path, List<String> chain) {
      final cls = ref.classNamed(className);
      if (cls == null) return;
      if (!stack.add(className!)) return; // cycle guard
      for (final f in cls.fields) {
        final childPath = '$path$kSpecPathSeparator${ref.fieldSegment(f)}';
        final childChain = [...chain, f.name];
        final name = _allocName(_camelChain(childChain), usedNames);
        constants.add(SpecPathConstant(
          name: name,
          path: childPath,
          kind: f.kind,
        ));
        if (f.kind == SpecFieldKind.complex ||
            f.kind == SpecFieldKind.section) {
          walk(f.type, childPath, childChain);
        }
      }
      stack.remove(className);
    }

    walk(root.type, rootSegment, const []);

    // Guard: names must be unique within the holder.
    final seen = <String>{};
    for (final c in constants) {
      if (!seen.add(c.name)) {
        throw StateError('duplicate path-constant name "${c.name}" in holder '
            'for root ${root.type}');
      }
    }

    holders.add(SpecPathHolder(
      root: root,
      holderName: '${_titleToken(rootSegment)}Paths',
      rootSegment: rootSegment,
      constants: constants,
    ));
  }
  return holders;
}

/// camelCase of a navigation [chain] of field names — first token lower-initial,
/// the rest upper-initial, concatenated.
String _camelChain(List<String> chain) {
  final b = StringBuffer();
  for (var i = 0; i < chain.length; i++) {
    final part = chain[i];
    if (part.isEmpty) continue;
    b.write(i == 0
        ? part[0].toLowerCase() + part.substring(1)
        : part[0].toUpperCase() + part.substring(1));
  }
  return b.toString();
}

/// Title-cases a single segment token (`SBP` → `Sbp`, `foo` → `Foo`), used to
/// build the holder type name from the root segment.
String _titleToken(String s) {
  final parts = s.split(RegExp(r'[^A-Za-z0-9]+')).where((p) => p.isNotEmpty);
  return parts
      .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join();
}

/// Returns [base] if free, else the smallest `base<n>` (n ≥ 2) not yet taken,
/// recording the result in [used]. Suffixing only ASCII digits keeps the name
/// a valid identifier in every target language.
String _allocName(String base, Set<String> used) {
  if (used.add(base)) return base;
  var n = 2;
  while (!used.add('$base$n')) {
    n++;
  }
  return '$base$n';
}
