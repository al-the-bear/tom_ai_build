/// A project's specification documents read side by side, one per root, and
/// the validation of the set (`tom_specs_model_rules.md` §9.7): the places a
/// Phase 3 document shares with the Solution Blueprint agree, element by
/// element and value by value, and the links that cross two documents hold.
///
/// The documents are never assembled into one: each keeps its own registry,
/// and every finding names the document a place is in. [syncReport] writes
/// nothing; [renameId] renames an id in every document at once.
library;

import 'dart:io';

import 'spec_document.dart';
import 'spec_links_validator.dart';
import 'spec_meta.dart';
import 'spec_meta_bridge.dart';
import 'spec_model.dart';
import 'spec_place.dart';
import 'spec_reflection.dart';
import 'spec_review_annotations.dart' show applyInlineMarksText;
import 'spec_section_id.dart';
import 'spec_validator.dart';

// ---------------------------------------------------------------------------
// The vocabulary of the set
// ---------------------------------------------------------------------------

/// What a finding of the set reports.
enum SpecSyncCode {
  /// Both documents hold the shared place, and the values differ.
  sharedValueDiffers,

  /// The Phase 3 document fills a shared place the Blueprint leaves empty.
  sharedValueMissing,

  /// The Blueprint fills a shared place the Phase 3 document leaves empty;
  /// the Phase 3 document emptied it, so `backfill` clears it.
  sharedValueOnlyInBlueprint,

  /// An element of an `equal` list (or an id of an `equal` reference field)
  /// is only in the Phase 3 document.
  sharedElementMissing,

  /// An element (or id) is only in the Blueprint, under `equal` or `subset`;
  /// `backfill` removes it.
  sharedElementOnlyInBlueprint,

  /// Under `subset`, an element (or id) only in the Phase 3 document: it may
  /// be added to the Blueprint, and is not carried in.
  sharedElementMayBeAdded,

  /// A `@SummaryOf(document:)` whose summary and detail sit in two documents
  /// does not hold (a row naming nothing, twice, a missing element under
  /// `equal`, a repeated value differing).
  crossSummaryMismatch,

  /// An `inverseOf` whose two ends sit in two documents is one-sided.
  crossInverseMissing,

  /// A value holding pending change marks, listed for the user.
  pendingReview,

  /// A change `deriveFields` would write in a document under review that
  /// cannot be marked exactly.
  unmarkable,
}

/// How a finding of the set is resolved.
enum SpecSyncResolution {
  /// `backfill` resolves it, writing the Blueprint.
  backfill,

  /// `deriveFields` resolves it.
  deriveFields,

  /// The agent decides (or asks the user).
  agent,

  /// Reported, not a finding: it does not hold up a gate.
  info,
}

/// Which document holds a shared place's value.
enum SpecSyncHolder {
  /// The Phase 3 document (the default).
  detail,

  /// The Blueprint (`@SyncedWith(heldHere:)`).
  blueprint,
}

/// Why a document set cannot be built.
enum SpecDocumentSetRefusal {
  /// Two documents populate one root.
  sameRoot,

  /// A document populates no root.
  noRoot,

  /// A document populates two roots.
  twoRoots,

  /// A document is the CodeSpecs projection, which is no specification.
  projection,

  /// Fragments of one root overlap.
  overlap,

  /// A synced class's positions in the Blueprint and its document cannot be
  /// paired (invariant `SHARED-ANCHOR`).
  unpairable,
}

/// A document set that cannot be built, with the documents it names.
class SpecDocumentSetError implements Exception {
  /// Why.
  final SpecDocumentSetRefusal refusal;

  /// The documents (or fragments) concerned, in the order given.
  final List<String> documents;

  /// For [SpecDocumentSetRefusal.unpairable], the class.
  final String? className;

  /// Prose for the reader.
  final String message;

  /// All parts are known where the error is raised.
  const SpecDocumentSetError(
    this.refusal,
    this.documents,
    this.message, {
    this.className,
  });

  /// The canonical JSON form the corpus compares (no message).
  Map<String, Object?> toJson() => {
    'refusal': refusal.name,
    'documents': documents,
    if (className != null) 'className': className,
  };

  @override
  String toString() => 'SpecDocumentSetError(${refusal.name}): $message';
}

/// A class kept in sync between the Blueprint and a Phase 3 document: its
/// position in each root.
class SpecSyncPair {
  /// The class carrying `@SyncedWith` / `@DetailedIn`.
  final String className;

  /// Its section id: the name of the pair in findings and filters.
  final String sectionId;

  /// The anchor in the Blueprint root (list items written `<list>-*`).
  final String blueprintAnchor;

  /// The anchor in the Phase 3 root.
  final String detailAnchor;

  /// The Phase 3 root's class name.
  final String detailRoot;

  /// The class's `@SyncedWith`, or null when only `@DetailedIn` is declared.
  final SpecSync? sync;

  /// The parts of a pair; the set computes them.
  const SpecSyncPair({
    required this.className,
    required this.sectionId,
    required this.blueprintAnchor,
    required this.detailAnchor,
    required this.detailRoot,
    this.sync,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'pair': sectionId,
    'className': className,
    'blueprint': blueprintAnchor,
    'detail': detailAnchor,
    'detailRoot': detailRoot,
  };
}

// ---------------------------------------------------------------------------
// The set
// ---------------------------------------------------------------------------

/// A project's specification documents, one per root, read side by side.
class SpecDocumentSet {
  /// [documents]: name (the file name the tools use) → document. Each
  /// document populates exactly one root; two documents of one root, a
  /// document with no populated root or with two, and the CodeSpecs
  /// projection are refused with a [SpecDocumentSetError] naming the
  /// documents, as is a model whose synced positions cannot be paired.
  SpecDocumentSet(this.model, Map<String, SpecDocument> documents)
    : refl = SpecReflection(model) {
    _pairs = _computePairs();
    documents.forEach(put);
  }

  /// Loads YAML or SOM Markdown files; files of one root are fragments and
  /// are assembled first (refusing overlaps). Each document is named by its
  /// first file's name.
  static SpecDocumentSet load(SpecModel model, Iterable<String> files) {
    final trees = <String, SomMetaTree>{};
    final fragments = <String, SpecDocument>{};
    for (final file in files) {
      final text = File(file).readAsStringSync();
      final SpecDocument doc;
      if (file.endsWith('.md')) {
        doc = SpecDocument.fromMarkdown(text, model).document;
      } else {
        // The root key `<SECTIONID> <Type>:` names the tree to decode with.
        final root = model.roots
            .where(
              (r) => RegExp(
                '^\\s*${RegExp.escape(r.sectionId ?? '')} '
                '${RegExp.escape(r.type)}:',
                multiLine: true,
              ).hasMatch(text),
            )
            .firstOrNull;
        if (root == null) {
          throw SpecDocumentSetError(SpecDocumentSetRefusal.noRoot, [
            file.split('/').last,
          ], '${file.split('/').last} names no root of the model');
        }
        doc = SpecDocument.fromYaml(
          text,
          trees.putIfAbsent(
            root.type,
            () => buildSomMetaTree(model, rootType: root.type),
          ),
        );
      }
      fragments[file.split('/').last] = doc;
    }
    return SpecDocumentSet.fromFragments(model, fragments);
  }

  /// Builds a set from documents and fragments: [fragments] maps a name to a
  /// document; those of one root are fragments of one document, assembled in
  /// the order given (overlaps refused), the document named by its first
  /// fragment's name.
  static SpecDocumentSet fromFragments(
    SpecModel model,
    Map<String, SpecDocument> fragments,
  ) {
    final refl = SpecReflection(model);
    final byRoot = <String, Map<String, SpecDocument>>{};
    for (final e in fragments.entries) {
      final roots = _populatedRoots(refl, e.value);
      if (roots.length != 1) {
        throw SpecDocumentSetError(
          roots.isEmpty
              ? SpecDocumentSetRefusal.noRoot
              : SpecDocumentSetRefusal.twoRoots,
          [e.key],
          '${e.key} populates ${roots.isEmpty ? 'no root' : roots.join(' and ')}',
        );
      }
      (byRoot[roots.single] ??= {})[e.key] = e.value;
    }
    final documents = <String, SpecDocument>{};
    for (final group in byRoot.values) {
      if (group.length == 1) {
        documents.addAll(group);
        continue;
      }
      final assembly = SpecDocument.assemble(group);
      if (!assembly.ok) {
        throw SpecDocumentSetError(
          SpecDocumentSetRefusal.overlap,
          group.keys.toList(),
          'the fragments ${group.keys.join(', ')} overlap',
        );
      }
      documents[group.keys.first] = assembly.document!;
    }
    return SpecDocumentSet(model, documents);
  }

  /// The model the set is read with.
  final SpecModel model;

  /// The model's reflection.
  final SpecReflection refl;

  final Map<String, SpecDocument> _documents = {};
  final Map<String, String> _rootOf = {};
  late final List<SpecSyncPair> _pairs;

  /// The Blueprint's root class name: the root the others are `basedOn`.
  late final String? blueprintRoot = _blueprintRoot();

  String? _blueprintRoot() {
    final targets = <String>{};
    for (final r in model.roots) {
      final based = refl
          .classNamed(r.type)
          ?.annotation('Document')
          ?.argument('basedOn');
      if (based is List) targets.addAll(based.map((e) => '$e'));
    }
    return targets.length == 1 ? targets.single : null;
  }

  /// The D00SolutionBlueprint document (the Blueprint), or null.
  SpecDocument? get blueprint =>
      blueprintRoot == null ? null : document(blueprintRoot!);

  /// The document of [rootType] (a type name or a section id), or null.
  SpecDocument? document(String rootType) {
    final name = nameOf(rootType);
    return name == null ? null : _documents[name];
  }

  /// The name of the document of [rootType], or null.
  String? nameOf(String rootType) {
    final type = _typeOf(rootType);
    for (final e in _rootOf.entries) {
      if (e.value == type) return e.key;
    }
    return null;
  }

  String? _typeOf(String rootType) {
    for (final r in model.roots) {
      if (r.type == rootType || r.sectionId == rootType) return r.type;
    }
    return null;
  }

  /// The populated roots, in model order.
  Iterable<String> get roots => [
    for (final r in model.roots)
      if (_rootOf.containsValue(r.type)) r.type,
  ];

  /// The document names, in model order of their roots.
  List<String> get names => [for (final r in roots) nameOf(r)!];

  /// Every Phase 3 root a pair names with no document yet: its pairs are
  /// "not started", reported as such and never as findings.
  List<String> get missingRoots => [
    for (final r in model.roots)
      if (_pairs.any((p) => p.detailRoot == r.type) &&
          !_rootOf.containsValue(r.type))
        r.type,
  ];

  /// The anchor pairs, in the Blueprint's walk order.
  List<SpecSyncPair> get pairs => List.unmodifiable(_pairs);

  /// Adds or replaces a document (what `prefill` creates).
  void put(String name, SpecDocument document) {
    final roots = _populatedRoots(refl, document);
    if (roots.isEmpty) {
      throw SpecDocumentSetError(SpecDocumentSetRefusal.noRoot, [
        name,
      ], '$name populates no root');
    }
    if (roots.length > 1) {
      throw SpecDocumentSetError(SpecDocumentSetRefusal.twoRoots, [
        name,
      ], '$name populates ${roots.join(' and ')}');
    }
    final root = roots.single;
    if (refl.classNamed(root)?.isCodeSpecsProjection ?? false) {
      throw SpecDocumentSetError(SpecDocumentSetRefusal.projection, [
        name,
      ], '$name is the CodeSpecs projection, which is no specification');
    }
    for (final e in _rootOf.entries) {
      if (e.value == root && e.key != name) {
        throw SpecDocumentSetError(SpecDocumentSetRefusal.sameRoot, [
          e.key,
          name,
        ], '${e.key} and $name both populate $root');
      }
    }
    _documents[name] = document;
    _rootOf[name] = root;
  }

  /// The document named [name].
  SpecDocument? operator [](String name) => _documents[name];

  /// The root class name of the document named [name].
  String? rootOf(String name) => _rootOf[name];

  static List<String> _populatedRoots(SpecReflection refl, SpecDocument doc) {
    bool under(Iterable<String> paths, String seg) =>
        paths.any((p) => p == seg || p.startsWith('$seg/'));
    return [
      for (final r in refl.model.roots)
        if ([
          doc.contentPaths,
          doc.formPaths,
          doc.listPaths,
          doc.headlinePaths,
        ].any((paths) => under(paths, refl.rootSegment(r))))
          r.type,
    ];
  }

  // -------------------------------------------------------------------------
  // The anchor pairs
  // -------------------------------------------------------------------------

  List<SpecSyncPair> _computePairs() {
    final bp = blueprintRoot;
    if (bp == null) return const [];
    final positions = <String, List<SpecSectionPosition>>{};
    List<SpecSectionPosition> at(String root) =>
        positions.putIfAbsent(root, () {
          final all = specSectionPositions(refl, root);
          // A `@SameAs` copy is kept equal to its holder, never paired.
          final copies = [
            for (final p in all)
              if (!p.isMember && p.member?.sameAs != null) p.path,
          ];
          return [
            for (final p in all)
              if (!p.isMember &&
                  !copies.any((c) => p.path == c || p.path.startsWith('$c/')))
                p,
          ];
        });

    final candidates = <String, String>{}; // class → target root
    for (final p in at(bp)) {
      final cls = refl.classNamed(p.className);
      final target = cls?.syncedWith?.document ?? cls?.detailedIn;
      if (target == null || target == bp) continue;
      if (refl.classNamed(target) == null) continue;
      candidates.putIfAbsent(p.className, () => target);
    }

    final out = <SpecSyncPair>[];
    for (final e in candidates.entries) {
      final className = e.key, target = e.value;
      final mine = [
        for (final p in at(bp))
          if (p.className == className) p,
      ];
      final theirs = [
        for (final p in at(target))
          if (p.className == className) p,
      ];
      if (theirs.isEmpty) continue;
      final matched = <(SpecSectionPosition, SpecSectionPosition)>[];
      if (mine.length == 1 && theirs.length == 1) {
        matched.add((mine.single, theirs.single));
      } else {
        // Paired by the path below the nearest enclosing anchor.
        String key(SpecSectionPosition p, String root) {
          SpecSectionPosition? outer;
          for (final q in at(root)) {
            if (q.path == p.path || !p.path.startsWith('${q.path}/')) continue;
            if (!candidates.containsKey(q.className)) continue;
            if (outer == null || q.path.length > outer.path.length) outer = q;
          }
          final ids = outer == null
              ? p.sectionIds
              : p.sectionIds.sublist(outer.sectionIds.length);
          return '${outer?.className ?? ''}/${ids.join('/')}';
        }

        final byKey = <String, SpecSectionPosition>{};
        for (final p in theirs) {
          final k = key(p, target);
          if (byKey.containsKey(k)) _unpairable(className);
          byKey[k] = p;
        }
        for (final p in mine) {
          final q = byKey.remove(key(p, bp));
          if (q == null) _unpairable(className);
          matched.add((p, q));
        }
        if (byKey.isNotEmpty) _unpairable(className);
      }
      final cls = refl.classNamed(className)!;
      for (final (b, d) in matched) {
        out.add(
          SpecSyncPair(
            className: className,
            sectionId: cls.sectionId ?? className,
            blueprintAnchor: b.path,
            detailAnchor: d.path,
            detailRoot: target,
            sync: cls.syncedWith,
          ),
        );
      }
    }
    return out;
  }

  Never _unpairable(String className) => throw SpecDocumentSetError(
    SpecDocumentSetRefusal.unpairable,
    const [],
    'the positions of $className in the Blueprint and its document cannot '
    'be paired (SHARED-ANCHOR)',
    className: className,
  );
}

// ---------------------------------------------------------------------------
// Findings and the report
// ---------------------------------------------------------------------------

/// One side of a finding: where the place is and what it holds.
class SpecSyncPlace {
  /// The document's name, or null when the set has none for this side.
  final String? document;

  /// The root's section id.
  final String root;

  /// The document path (for a place the document does not hold, the
  /// nearest path it does: the list an element would be added to).
  final String path;

  /// The form field, or null.
  final String? field;

  /// The value (read with pending marks rejected), or null when absent.
  final String? value;

  /// Whether the value holds pending change marks.
  final bool pendingMarks;

  /// The parts of a place.
  const SpecSyncPlace({
    required this.document,
    required this.root,
    required this.path,
    this.field,
    this.value,
    this.pendingMarks = false,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'document': document,
    'root': root,
    'path': path,
    if (field != null) 'field': field,
    if (value != null) 'value': value,
    'pendingMarks': pendingMarks,
  };
}

/// One finding of the set.
class SpecSyncFinding {
  /// What it reports.
  final SpecSyncCode code;

  /// The pair's section id (the summary's or link's class for a cross check,
  /// empty for a pending value outside every pair).
  final String pair;

  /// The Blueprint side (for a cross check, the side holding the link).
  final SpecSyncPlace blueprint;

  /// The Phase 3 side (for a cross check, the other end).
  final SpecSyncPlace detail;

  /// Which side holds the value.
  final SpecSyncHolder holder;

  /// How it is resolved.
  final SpecSyncResolution resolution;

  /// Prose for the agent; never compared.
  final String message;

  /// The parts of a finding.
  const SpecSyncFinding({
    required this.code,
    required this.pair,
    required this.blueprint,
    required this.detail,
    required this.holder,
    required this.resolution,
    required this.message,
  });

  /// Whether it is reported only, not a finding.
  bool get isInfo => resolution == SpecSyncResolution.info;

  /// The canonical JSON form (no message).
  Map<String, Object?> toJson() => {
    'code': code.name,
    'pair': pair,
    'blueprint': blueprint.toJson(),
    'detail': detail.toJson(),
    'holder': holder.name,
    'resolution': resolution.name,
    'info': isInfo,
  };
}

/// The validation of a document set.
class SpecSyncReport {
  /// The findings in pair and path order, `info` entries included.
  final List<SpecSyncFinding> findings;

  /// Each document's own findings (`validateDocument`, then `validateLinks`),
  /// by name, in the set's order.
  final Map<String, List<SpecValidationError>> documentFindings;

  /// The Phase 3 roots with no document yet.
  final List<String> notStarted;

  /// The parts of a report; [syncReport] builds it.
  const SpecSyncReport({
    required this.findings,
    required this.documentFindings,
    required this.notStarted,
  });

  /// Findings per code, `info` entries included, in code order.
  Map<String, int> countsByCode() => {
    for (final c in SpecSyncCode.values)
      if (findings.any((f) => f.code == c))
        c.name: findings.where((f) => f.code == c).length,
  };

  /// Findings per resolution, in resolution order.
  Map<String, int> countsByResolution() => {
    for (final r in SpecSyncResolution.values)
      if (findings.any((f) => f.resolution == r))
        r.name: findings.where((f) => f.resolution == r).length,
  };

  /// No finding other than `info`.
  bool get clean => findings.every((f) => f.isInfo);

  /// The canonical JSON form; every ordered value is a list.
  Map<String, Object?> toJson() => {
    'findings': [for (final f in findings) f.toJson()],
    'documentFindings': [
      for (final e in documentFindings.entries)
        [
          e.key,
          [
            for (final x in e.value) {'path': x.path, 'code': x.code.name},
          ],
        ],
    ],
    'notStarted': notStarted,
    'countsByCode': [
      for (final e in countsByCode().entries) [e.key, e.value],
    ],
    'countsByResolution': [
      for (final e in countsByResolution().entries) [e.key, e.value],
    ],
    'clean': clean,
  };
}

/// The validation of [set], with counts; [pairs] keeps the findings of
/// those pairs (by section id) only. Writes nothing.
SpecSyncReport syncReport(SpecDocumentSet set, {Set<String>? pairs}) {
  final c = _SetCheck(set);
  var index = 0;
  for (final p in set.pairs) {
    if (pairs == null || pairs.contains(p.sectionId)) c.comparePair(p, index);
    index++;
  }
  c.crossChecks(pairs, index);
  if (pairs == null) {
    c.pendingScan(index + 1);
    c.unmarkableScan(index + 2);
  }
  c.out.sort((a, b) {
    final i = a.order.compareTo(b.order);
    if (i != 0) return i;
    final k = a.key.compareTo(b.key);
    if (k != 0) return k;
    final x = a.finding.code.index.compareTo(b.finding.code.index);
    if (x != 0) return x;
    return (a.finding.blueprint.value ?? a.finding.detail.value ?? '')
        .compareTo(b.finding.blueprint.value ?? b.finding.detail.value ?? '');
  });
  return SpecSyncReport(
    findings: [for (final o in c.out) o.finding],
    documentFindings: {
      for (final name in set.names)
        name: [
          ...validateDocument(set.model, set[name]!),
          ...validateLinks(set.model, set[name]!),
        ],
    },
    notStarted: set.missingRoots,
  );
}

// ---------------------------------------------------------------------------
// The comparison
// ---------------------------------------------------------------------------

class _Ordered {
  _Ordered(this.order, this.key, this.finding);
  final int order;
  final String key;
  final SpecSyncFinding finding;
}

/// One value of a subtree, keyed for comparison.
class _Value {
  _Value(this.path, this.field, this.value, this.pending, this.spec);
  final String path;
  final String? field;
  final String value;
  final bool pending;
  final FormFieldSpec? spec;
}

/// A document side of a pair: its subtree's values and items, keyed by the
/// path below the anchor with list items written by their section id.
class _Side {
  _Side(this.name, this.root, this.anchor);
  final String? name;
  final String root;
  final String anchor;
  final Map<String, _Value> values = {};

  /// item key → item path, and the anchor's own key ''.
  final Map<String, String> items = {};
}

class _SetCheck {
  _SetCheck(this.set) : refl = set.refl;

  final SpecDocumentSet set;
  final SpecReflection refl;
  final List<_Ordered> out = [];

  void add(int order, String key, SpecSyncFinding f) =>
      out.add(_Ordered(order, key, f));

  String _rootSeg(String type) =>
      refl.rootSegment(refl.model.roots.firstWhere((r) => r.type == type));

  // --- values ---------------------------------------------------------------

  static String _reviewed(String raw) =>
      applyInlineMarksText(raw, accept: false).trim();

  static bool _isPending(String raw) =>
      applyInlineMarksText(raw, accept: true) !=
      applyInlineMarksText(raw, accept: false);

  final Map<SpecDocument, Map<String, String>> _itemIds = {};
  final Map<String, bool> _items = {};
  final Map<SpecDocument, Map<String, List<String>>> _forms = {};
  final Map<String, String?> _registryDocs = {};
  final Map<String, Set<String>> _reach = {};
  final Map<SpecDocument, Map<String, Map<String, String>>> _entries = {};
  final Map<String, List<SpecSameAsBinding>> _sameAs = {};

  String _itemId(SpecDocument doc, String itemPath) => (_itemIds[doc] ??= {})
      .putIfAbsent(itemPath, () => _computeItemId(doc, itemPath));

  String _computeItemId(SpecDocument doc, String itemPath) {
    final stored = doc.itemSectionId(itemPath);
    if (stored != null) return stored;
    final list = itemPath.substring(0, itemPath.lastIndexOf('-'));
    final field = refl.resolve(list)?.field;
    return effectiveListItemSectionId(
      storedId: null,
      pattern: field?.sectionIdPattern,
      position: doc.listItems(list).indexOf(itemPath) + 1,
      fallbackStem: field?.name ?? list.split('/').last,
    );
  }

  bool _isItem(String path) => _items.putIfAbsent(
    path,
    () => refl.resolve(path)?.kind == SpecNodeKind.listItemComplex,
  );

  List<String> _expand(SpecDocument doc, String pattern) {
    var paths = <String>[''];
    for (final seg in pattern.split('/')) {
      final next = <String>[];
      for (final p in paths) {
        final base = p.isEmpty ? seg : '$p/$seg';
        if (seg.endsWith('-*')) {
          next.addAll(doc.listItems(base.substring(0, base.length - 2)));
        } else {
          next.add(base);
        }
      }
      paths = next;
    }
    return paths;
  }

  /// The key of [path] below [anchor]: item segments as `[id]`.
  String _key(SpecDocument doc, String anchor, String path) {
    if (path == anchor) return '';
    final out = <String>[];
    var at = anchor;
    for (final seg in path.substring(anchor.length + 1).split('/')) {
      at = '$at/$seg';
      out.add(
        _isItem(at)
            ? '${seg.substring(0, seg.lastIndexOf('-'))}[${_itemId(doc, at)}]'
            : seg,
      );
    }
    return out.join('/');
  }

  /// The key of an anchor itself among its siblings: the ids of the list
  /// items on its path.
  String _anchorKey(SpecDocument doc, String path) {
    final out = <String>[];
    var at = '';
    for (final seg in path.split('/')) {
      at = at.isEmpty ? seg : '$at/$seg';
      if (_isItem(at)) out.add(_itemId(doc, at));
    }
    return out.join('/');
  }

  /// The paths a place resolved under [anchor] stands for in [doc]: whole
  /// sections (prefixes) and single form fields.
  ({List<String> prefixes, Set<String> fields, Set<String> headlines}) _places(
    SpecDocument doc,
    Iterable<String> places,
    String anchor,
  ) {
    final prefixes = <String>[];
    final fields = <String>{};
    final headlines = <String>{};
    for (final text in places) {
      final SpecPlaceResolution r;
      try {
        r = SpecPlace.parse(text).resolve(refl, anchor);
      } on SpecPlaceException {
        continue;
      }
      for (final p in _expand(doc, r.path)) {
        switch (r.kind) {
          case SpecPlaceKind.formField:
            fields.add('$p#${r.field}');
          case SpecPlaceKind.headline:
            headlines.add(p);
          case SpecPlaceKind.sectionId:
            break;
          case SpecPlaceKind.section ||
              SpecPlaceKind.list ||
              SpecPlaceKind.form ||
              SpecPlaceKind.content:
            prefixes.add(p);
        }
      }
    }
    return (prefixes: prefixes, fields: fields, headlines: headlines);
  }

  static bool _underAny(String path, Iterable<String> prefixes) =>
      prefixes.any((p) => path == p || path.startsWith('$p/'));

  /// The values beneath [anchor] in [doc], with what the pair does not
  /// compare left out: `detailOnly` places, nested pairs, `@SameAs` copies
  /// and derived places.
  _Side _collect(
    String? name,
    SpecDocument doc,
    String root,
    String anchor,
    SpecSyncPair pair,
    List<String> nested,
  ) {
    final side = _Side(name, root, anchor);
    final skip = _places(doc, pair.sync?.detailOnly ?? const [], anchor);
    final excluded = [
      ...skip.prefixes,
      ...nested,
      for (final b in _sameAs.putIfAbsent(
        root,
        () => specSameAsBindings(refl, root),
      ))
        ..._expand(doc, b.copyPath),
    ];
    bool under(String p) => p == anchor || p.startsWith('$anchor/');
    bool out_(String p) => p != anchor && _underAny(p, excluded);

    side.items[''] = anchor;
    for (final list in doc.listPaths) {
      if (!under(list) || out_(list)) continue;
      if (refl.resolve(list)?.field?.derivedFrom != null) {
        excluded.add(list);
        continue;
      }
      for (final item in doc.listItems(list)) {
        side.items[_key(doc, anchor, item)] = item;
      }
    }
    for (final p in doc.contentPaths) {
      if (!under(p) || out_(p)) continue;
      if (refl.resolve(p)?.field?.derivedFrom != null) continue;
      final raw = doc.content(p) ?? '';
      side.values['c:${_key(doc, anchor, p)}'] = _Value(
        p,
        null,
        _reviewed(raw),
        _isPending(raw),
        null,
      );
    }
    for (final p in doc.formPaths) {
      if (!under(p) || out_(p)) continue;
      final specs = refl.resolve(p)?.field?.formFields ?? const [];
      for (final field in doc.formFieldNames(p)) {
        if (skip.fields.contains('$p#$field')) continue;
        final spec = specs.where((f) => f.name == field).firstOrNull;
        if (spec != null &&
            (spec.derivedFrom != null ||
                spec.countOf.isNotEmpty ||
                spec.productOf.isNotEmpty ||
                spec.rankOf != null)) {
          continue;
        }
        final raw = doc.formField(p, field) ?? '';
        side.values['f:${_key(doc, anchor, p)}#$field'] = _Value(
          p,
          field,
          _reviewed(raw),
          _isPending(raw),
          spec,
        );
      }
    }
    for (final p in doc.headlinePaths) {
      if (!under(p) || out_(p) || skip.headlines.contains(p)) continue;
      final raw = doc.headline(p) ?? '';
      side.values['h:${_key(doc, anchor, p)}'] = _Value(
        p,
        null,
        _reviewed(raw),
        _isPending(raw),
        null,
      );
    }
    return side;
  }

  /// The path [key] stands for on [side]: the item paths it names as far as
  /// the side holds them; where it stops, the list an element would go in.
  String _pathOn(_Side side, String key) {
    if (key.isEmpty) return side.anchor;
    final segs = key.split('/');
    var path = side.anchor;
    var prefix = '';
    for (final s in segs) {
      prefix = prefix.isEmpty ? s : '$prefix/$s';
      final bracket = s.indexOf('[');
      if (bracket > 0) {
        final item = side.items[prefix];
        if (item == null) return '$path/${s.substring(0, bracket)}';
        path = item;
      } else {
        path = '$path/$s';
      }
    }
    return path;
  }

  static bool _sameTyped(String a, String b, FormFieldSpec? spec) {
    final t = spec?.type;
    if (t == 'int' || t == 'double' || t == 'num') {
      final x = num.tryParse(a), y = num.tryParse(b);
      if (x != null && y != null) return x == y;
    }
    if (t == 'bool') return a.toLowerCase() == b.toLowerCase();
    return a == b;
  }

  static List<String> _ids(String value) => [
    for (final s in value.split(','))
      if (s.trim().isNotEmpty) s.trim(),
  ];

  // --- one pair -------------------------------------------------------------

  void comparePair(SpecSyncPair pair, int order) {
    final bpName = set.nameOf(set.blueprintRoot!);
    final dtName = set.nameOf(pair.detailRoot);
    if (bpName == null || dtName == null) return; // not started
    final bp = set[bpName]!, dt = set[dtName]!;
    final bpRoot = set.blueprintRoot!;

    // Nested pairs are compared on their own.
    List<String> nested(SpecDocument doc, String root, bool blueprintSide) => [
      for (final other in set.pairs)
        if (other != pair &&
            (blueprintSide || other.detailRoot == pair.detailRoot))
          ..._expand(
            doc,
            blueprintSide ? other.blueprintAnchor : other.detailAnchor,
          ),
    ];

    final bpAnchors = {
      for (final a in _expand(bp, pair.blueprintAnchor)) _anchorKey(bp, a): a,
    };
    final dtAnchors = {
      for (final a in _expand(dt, pair.detailAnchor)) _anchorKey(dt, a): a,
    };
    for (final k in {...bpAnchors.keys, ...dtAnchors.keys}) {
      final ba = bpAnchors[k], da = dtAnchors[k];
      if (ba == null || da == null) continue; // the outer list reports it
      final b = _collect(
        bpName,
        bp,
        bpRoot,
        ba,
        pair,
        nested(bp, bpRoot, true).where((p) => p.startsWith('$ba/')).toList(),
      );
      final d = _collect(
        dtName,
        dt,
        pair.detailRoot,
        da,
        pair,
        nested(
          dt,
          pair.detailRoot,
          false,
        ).where((p) => p.startsWith('$da/')).toList(),
      );
      _compare(pair, order, b, d, bp, dt);
    }
  }

  void _compare(
    SpecSyncPair pair,
    int order,
    _Side b,
    _Side d,
    SpecDocument bp,
    SpecDocument dt,
  ) {
    final sync = pair.sync;
    // Relations: list key → (relation, where); field key → relation.
    final listRel = <String, ({String relation, String? where})>{};
    final fieldRel = <String, String>{};
    for (final r in sync?.relations ?? const <SpecListRelation>[]) {
      final SpecPlaceResolution res;
      try {
        res = SpecPlace.parse(r.place).resolve(refl, b.anchor);
      } on SpecPlaceException {
        continue;
      }
      for (final p in _expand(bp, res.path)) {
        final key = _key(bp, b.anchor, p);
        if (res.kind == SpecPlaceKind.list) {
          listRel[key] = (relation: r.relation, where: r.where);
        } else if (res.kind == SpecPlaceKind.formField) {
          fieldRel['$key#${res.field}'] = r.relation;
        }
      }
    }
    // A relation stated for a form field is the same for every element:
    // match it by its key with item ids dropped.
    String shape(String key) => key.replaceAll(RegExp(r'\[[^\]]*\]'), '[]');
    final fieldRelByShape = {
      for (final e in fieldRel.entries) shape(e.key): e.value,
    };
    final held = _places(bp, sync?.heldHere ?? const [], b.anchor);
    bool isHeld(String bpPath, [String? field]) =>
        _underAny(bpPath, held.prefixes) ||
        (field != null && held.fields.contains('$bpPath#$field'));

    SpecSyncPlace place(_Side s, String key, [String? field, String? value]) {
      final v = s.values[key];
      return SpecSyncPlace(
        document: s.name,
        root: refl.rootSegment(
          refl.model.roots.firstWhere((r) => r.type == s.root),
        ),
        path:
            v?.path ??
            _pathOn(
              s,
              key.startsWith('i:') ? key.substring(2) : _stripKind(key),
            ),
        field: field ?? v?.field,
        value: value ?? v?.value,
        pendingMarks: v?.pending ?? false,
      );
    }

    void emit(
      SpecSyncCode code,
      String key,
      String message, {
      required bool heldHere,
      String? field,
      String? bValue,
      String? dValue,
      SpecSyncResolution? resolution,
    }) {
      add(
        order,
        key,
        SpecSyncFinding(
          code: code,
          pair: pair.sectionId,
          blueprint: place(b, key, field, bValue),
          detail: place(d, key, field, dValue),
          holder: heldHere ? SpecSyncHolder.blueprint : SpecSyncHolder.detail,
          resolution:
              resolution ??
              (heldHere
                  ? SpecSyncResolution.agent
                  : SpecSyncResolution.backfill),
          message: message,
        ),
      );
    }

    // Elements.
    final oneSided = <String>[];
    final itemKeys = {...b.items.keys, ...d.items.keys}.toList()..sort();
    for (final k in itemKeys) {
      if (k.isEmpty) continue;
      final inB = b.items.containsKey(k), inD = d.items.containsKey(k);
      if (inB == inD) continue;
      if (oneSided.any((o) => k.startsWith('$o/'))) continue;
      oneSided.add(k);
      final parentList = k.substring(0, k.lastIndexOf('['));
      final rel = listRel[parentList];
      var relation = rel?.relation ?? 'equal';
      final itemPath = inB ? b.items[k]! : d.items[k]!;
      final doc = inB ? bp : dt;
      if (rel?.where != null) {
        final filter = SpecPlaceFilter.tryParse(rel!.where!);
        if (filter?.field != null &&
            !filter!.matches(_ownValues(doc, itemPath, filter.field!))) {
          relation = 'equal';
        }
      }
      final id = k.substring(k.lastIndexOf('[') + 1, k.length - 1);
      final heldHere = isHeld(inB ? itemPath : _pathOn(b, k));
      final key = 'i:$k';
      if (inD) {
        if (relation == 'subset') {
          emit(
            SpecSyncCode.sharedElementMayBeAdded,
            key,
            '$id is only in ${d.name}; under subset it may be added to '
            '${b.name}',
            heldHere: heldHere,
            dValue: id,
            resolution: SpecSyncResolution.info,
          );
        } else {
          emit(
            SpecSyncCode.sharedElementMissing,
            key,
            '$id is in ${d.name} and missing in ${b.name}',
            heldHere: heldHere,
            dValue: id,
          );
        }
      } else if (relation != 'superset') {
        emit(
          SpecSyncCode.sharedElementOnlyInBlueprint,
          key,
          '$id is only in ${b.name}; ${d.name} removed it',
          heldHere: heldHere,
          bValue: id,
        );
      }
    }
    bool beneathOneSided(String key) {
      final rel = _stripKind(key);
      return oneSided.any((o) => rel == o || rel.startsWith('$o/'));
    }

    // Values.
    final keys = {...b.values.keys, ...d.values.keys}.toList()..sort();
    for (final k in keys) {
      if (beneathOneSided(k)) continue;
      final vb = b.values[k], vd = d.values[k];
      final spec = vb?.spec ?? vd?.spec;
      final field = vb?.field ?? vd?.field;
      final bValue = vb?.value ?? '', dValue = vd?.value ?? '';
      final heldHere = isHeld(vb?.path ?? _pathOn(b, _stripKind(k)), field);
      if (spec != null && spec.multiple && spec.refersTo.isNotEmpty) {
        final relation = fieldRelByShape[shape(k.substring(2))] ?? 'equal';
        final ib = _ids(bValue).toSet(), id_ = _ids(dValue).toSet();
        for (final x in id_.difference(ib).toList()..sort()) {
          final may = relation == 'subset';
          emit(
            may
                ? SpecSyncCode.sharedElementMayBeAdded
                : SpecSyncCode.sharedElementMissing,
            k,
            '$x is named in ${d.name} and not in ${b.name}',
            field: field,
            heldHere: heldHere,
            dValue: x,
            bValue: bValue.isEmpty ? null : bValue,
            resolution: may ? SpecSyncResolution.info : null,
          );
        }
        if (relation != 'superset') {
          for (final x in ib.difference(id_).toList()..sort()) {
            emit(
              SpecSyncCode.sharedElementOnlyInBlueprint,
              k,
              '$x is named only in ${b.name}',
              field: field,
              heldHere: heldHere,
              bValue: x,
              dValue: dValue.isEmpty ? null : dValue,
            );
          }
        }
        continue;
      }
      if (bValue.isEmpty && dValue.isEmpty) continue;
      if (_sameTyped(bValue, dValue, spec)) continue;
      final what = field == null ? 'the value' : 'form field "$field"';
      if (bValue.isEmpty) {
        emit(
          SpecSyncCode.sharedValueMissing,
          k,
          field: field,
          '$what is filled in ${d.name} and empty in ${b.name}',
          heldHere: heldHere,
        );
      } else if (dValue.isEmpty) {
        emit(
          SpecSyncCode.sharedValueOnlyInBlueprint,
          k,
          field: field,
          '$what is filled only in ${b.name}; ${d.name} emptied it',
          heldHere: heldHere,
        );
      } else {
        emit(
          SpecSyncCode.sharedValueDiffers,
          k,
          field: field,
          '$what differs: "$bValue" in ${b.name}, "$dValue" in ${d.name}'
          '${heldHere ? ' (held in ${b.name})' : ''}',
          heldHere: heldHere,
        );
      }
    }
  }

  static String _stripKind(String key) {
    final k = key.length > 2 && key[1] == ':' ? key.substring(2) : key;
    final hash = k.indexOf('#');
    return hash < 0 ? k : k.substring(0, hash);
  }

  /// The values a row's own forms (`<row>/<member>`) hold in [field].
  List<String> _ownValues(SpecDocument doc, String row, String field) {
    final index = _forms.putIfAbsent(doc, () {
      final out = <String, List<String>>{};
      for (final p in doc.formPaths) {
        final slash = p.lastIndexOf('/');
        if (slash > 0) (out[p.substring(0, slash)] ??= []).add(p);
      }
      return out;
    });
    return [
      for (final p in index[row] ?? const <String>[])
        if (doc.formField(p, field) != null)
          _reviewed(doc.formField(p, field)!),
    ];
  }

  // --- unmarkable derived changes -------------------------------------------

  /// Every change `deriveFields` would write in a document under review that
  /// cannot be marked exactly: left for the agent.
  void unmarkableScan(int order) {
    for (final name in set.names) {
      final doc = set[name]!;
      final root = refl.rootSegment(
        refl.model.roots.firstWhere((r) => r.type == set.rootOf(name)),
      );
      final derived = deriveFields(set.model, doc, dryRun: true);
      for (final u in derived.unresolved) {
        if (u.code != SpecValidationCode.unmarkable) continue;
        final p = SpecSyncPlace(document: name, root: root, path: u.path);
        add(
          order,
          '$name ${u.path}',
          SpecSyncFinding(
            code: SpecSyncCode.unmarkable,
            pair: '',
            blueprint: p,
            detail: p,
            holder: SpecSyncHolder.detail,
            resolution: SpecSyncResolution.agent,
            message: '${u.message} (in $name)',
          ),
        );
      }
    }
  }

  // --- pending marks --------------------------------------------------------

  /// Every value of every document that holds pending change marks.
  void pendingScan(int order) {
    for (final name in set.names) {
      final doc = set[name]!;
      final root = refl.rootSegment(
        refl.model.roots.firstWhere((r) => r.type == set.rootOf(name)),
      );
      void flag(String path, String? field, String raw) {
        if (!_isPending(raw)) return;
        final p = SpecSyncPlace(
          document: name,
          root: root,
          path: path,
          field: field,
          value: _reviewed(raw),
          pendingMarks: true,
        );
        add(
          order,
          '$name $path ${field ?? ''}',
          SpecSyncFinding(
            code: SpecSyncCode.pendingReview,
            pair: '',
            blueprint: p,
            detail: p,
            holder: SpecSyncHolder.detail,
            resolution: SpecSyncResolution.info,
            message:
                '${field == null ? 'the value' : 'form field "$field"'} at '
                '$path in $name holds pending change marks',
          ),
        );
      }

      for (final p in doc.contentPaths) {
        flag(p, null, doc.content(p) ?? '');
      }
      for (final p in doc.formPaths) {
        for (final f in doc.formFieldNames(p)) {
          flag(p, f, doc.formField(p, f) ?? '');
        }
      }
      for (final p in doc.headlinePaths) {
        flag(p, null, doc.headline(p) ?? '');
      }
    }
  }

  // --- links across two documents --------------------------------------------

  /// Every class instance of the document [name]: path, class, root segment.
  List<({String path, SpecClass cls})> _instances(
    SpecDocument doc,
    String type,
  ) {
    final out = <({String path, SpecClass cls})>[];
    void walk(SpecClass cls, String path, Set<String> onPath) {
      out.add((path: path, cls: cls));
      for (final f in cls.fields) {
        if (f.hasAnnotation('Reference')) continue;
        final member = '$path/${refl.fieldSegment(f)}';
        if (f.kind == SpecFieldKind.list && f.elementIsComplex) {
          final el = refl.classNamed(f.elementType);
          if (el == null) continue;
          for (final item in doc.listItems(member)) {
            walk(el, item, {});
          }
        } else if (f.kind == SpecFieldKind.complex ||
            f.kind == SpecFieldKind.section) {
          final child = refl.classNamed(f.type?.replaceAll('?', ''));
          if (child == null || onPath.contains(child.name)) continue;
          walk(child, member, {...onPath, cls.name});
        }
      }
    }

    final cls = refl.classNamed(type);
    if (cls != null) walk(cls, _rootSeg(type), {});
    return out;
  }

  /// The document a registry class is read in: the one whose root details it
  /// (a populated root other than the Blueprint's that reaches it), else the
  /// Blueprint.
  String? _registryDocument(String sectionId) => _registryDocs.putIfAbsent(
    sectionId,
    () => _computeRegistryDocument(sectionId),
  );

  String? _computeRegistryDocument(String sectionId) {
    final classes = {
      for (final c in refl.model.classes.values)
        if (c.sectionId == sectionId) c.name,
    };
    String? blueprint;
    for (final name in set.names) {
      final root = set.rootOf(name)!;
      final reach = _reach.putIfAbsent(
        root,
        () => refl.reachableClassNames(root),
      );
      if (!reach.any(classes.contains)) continue;
      if (root == set.blueprintRoot) {
        blueprint = name;
      } else {
        return name;
      }
    }
    return blueprint;
  }

  String? _identity(SpecDocument doc, String item, String target) {
    final field = target.substring(target.indexOf('.') + 1);
    if (field == kSectionIdSlot) return _itemId(doc, item);
    final values = _ownValues(doc, item, field);
    return values.isEmpty ? null : values.first;
  }

  /// The entry of [doc] that [refersTo] names [id] by, or null.
  String? _entry(SpecDocument doc, List<String> refersTo, String id) {
    final byTarget = _entries.putIfAbsent(doc, () => {});
    for (final t in refersTo) {
      final index = byTarget.putIfAbsent(t, () {
        final out = <String, String>{};
        final sid = t.split('.').first;
        for (final list in doc.listPaths.toList()..sort()) {
          for (final item in doc.listItems(list)) {
            if (refl.resolve(item)?.targetClass?.sectionId != sid) continue;
            final name = _identity(doc, item, t);
            if (name != null) out.putIfAbsent(name, () => item);
          }
        }
        return out;
      });
      final hit = index[id];
      if (hit != null) return hit;
    }
    return null;
  }

  String? _nearestItem(String path) {
    var p = path;
    while (true) {
      if (_isItem(p)) return p;
      final slash = p.lastIndexOf('/');
      if (slash < 0) return null;
      p = p.substring(0, slash);
    }
  }

  void crossChecks(Set<String>? pairs, int order) {
    for (final name in set.names) {
      final doc = set[name]!;
      final root = set.rootOf(name)!;
      for (final i in _instances(doc, root)) {
        final pairId = i.cls.sectionId ?? i.cls.name;
        if (pairs != null && !pairs.contains(pairId)) continue;
        for (final f in i.cls.fields) {
          final member = '${i.path}/${refl.fieldSegment(f)}';
          final s = f.summaryOf;
          if (s?.document != null && f.kind == SpecFieldKind.list) {
            _crossSummaryRows(order, pairId, name, doc, member, s!);
          }
          for (final ff in f.formFields) {
            if (ff.summaryOf?.document != null) {
              _crossSummaryField(order, pairId, name, doc, member, ff);
            }
            if (ff.inverseOf != null && !ff.inverseOf!.symmetric) {
              _crossInverse(order, pairId, name, doc, member, ff);
            }
          }
        }
      }
    }
  }

  /// The detail elements of a cross summary: (document name, item → id).
  (String, SpecDocument, Map<String, String>)? _crossDetail(SpecSummaryOf s) {
    final name = set.nameOf(s.document!);
    if (name == null) return null; // not started
    final doc = set[name]!;
    final seg = _rootSeg(set.rootOf(name)!);
    SpecPlaceResolution? r;
    try {
      final slash = s.detail.indexOf('/');
      if (slash < 0) {
        r = SpecPlace.parse(s.detail).resolve(refl, seg);
      } else {
        final head = SpecPlace.parse(
          s.detail.substring(0, slash),
        ).resolve(refl, seg);
        final scope = head.kind == SpecPlaceKind.list
            ? '${head.path}-*'
            : head.path;
        final concrete = _expand(doc, scope);
        if (concrete.isNotEmpty) {
          final rest = SpecPlace.parse(
            s.detail.substring(slash + 1),
          ).resolve(refl, concrete.first);
          r = rest;
        }
      }
    } on SpecPlaceException {
      return null;
    }
    if (r == null || r.kind != SpecPlaceKind.list) return null;
    return (
      name,
      doc,
      {
        for (final list in _expand(doc, r.path))
          for (final item in doc.listItems(list)) item: _itemId(doc, item),
      },
    );
  }

  SpecSyncPlace _place(
    String? name,
    String path, {
    String? field,
    String? value,
  }) => SpecSyncPlace(
    document: name,
    root: name == null
        ? ''
        : refl.rootSegment(
            refl.model.roots.firstWhere((r) => r.type == set.rootOf(name)),
          ),
    path: path,
    field: field,
    value: value,
  );

  void _cross(
    int order,
    SpecSyncCode code,
    String pair,
    SpecSyncPlace here,
    SpecSyncPlace there,
    String message,
  ) => add(
    order,
    '${here.document} ${here.path} ${here.field ?? ''} ${there.value ?? ''}',
    SpecSyncFinding(
      code: code,
      pair: pair,
      blueprint: here,
      detail: there,
      holder: SpecSyncHolder.detail,
      resolution: SpecSyncResolution.agent,
      message: message,
    ),
  );

  void _crossSummaryRows(
    int order,
    String pair,
    String name,
    SpecDocument doc,
    String list,
    SpecSummaryOf s,
  ) {
    final detail = _crossDetail(s);
    if (detail == null) return;
    final (dName, dDoc, elements) = detail;
    final byId = {for (final e in elements.entries) e.value: e.key};
    final named = <String, String>{};
    for (final row in doc.listItems(list)) {
      final ids = s.match == null
          ? [_itemId(doc, row)]
          : _matchIds(doc, s.match!, row);
      for (final id in ids) {
        final target = byId[id];
        if (target == null) {
          _cross(
            order,
            SpecSyncCode.crossSummaryMismatch,
            pair,
            _place(name, row, value: id),
            _place(dName, list.isEmpty ? '' : _listOf(elements), value: id),
            'the summary row names $id, which is no element of ${s.detail} in '
            '$dName',
          );
          continue;
        }
        if (named.containsKey(id)) {
          _cross(
            order,
            SpecSyncCode.crossSummaryMismatch,
            pair,
            _place(name, row, value: id),
            _place(dName, target, value: id),
            'the summary row names $id, which ${named[id]} names already',
          );
          continue;
        }
        named[id] = row;
        for (final e in s.repeats.entries) {
          final mine = _valueAt(doc, e.key, row);
          final theirs = _valueAt(dDoc, e.value, target);
          if (mine == null || theirs == null || mine.$2.isEmpty) continue;
          if (mine.$2 != theirs.$2) {
            _cross(
              order,
              SpecSyncCode.crossSummaryMismatch,
              pair,
              _place(name, mine.$1, field: mine.$3, value: mine.$2),
              _place(dName, theirs.$1, field: theirs.$3, value: theirs.$2),
              '${e.key} repeats ${e.value} of $id as "${mine.$2}", but $dName '
              'holds "${theirs.$2}"',
            );
          }
        }
      }
    }
    if (s.relation == 'equal') {
      for (final e in elements.entries) {
        if (named.containsKey(e.value)) continue;
        _cross(
          order,
          SpecSyncCode.crossSummaryMismatch,
          pair,
          _place(name, list),
          _place(dName, e.key, value: e.value),
          'the detail element ${e.value} of $dName is named by no row of '
          '$list (relation: equal)',
        );
      }
    }
  }

  String _listOf(Map<String, String> elements) => elements.isEmpty
      ? ''
      : elements.keys.first.substring(0, elements.keys.first.lastIndexOf('-'));

  List<String> _matchIds(SpecDocument doc, String place, String row) {
    final v = _valueAt(doc, place, row);
    return v == null ? const [] : _ids(v.$2);
  }

  /// The value of [place] under the concrete [anchor]: (path, value, field).
  (String, String, String?)? _valueAt(
    SpecDocument doc,
    String place,
    String anchor,
  ) {
    final SpecPlaceResolution r;
    try {
      r = SpecPlace.parse(place).resolve(refl, anchor);
    } on SpecPlaceException {
      return null;
    }
    final paths = _expand(doc, r.path);
    if (paths.length != 1) return null;
    final p = paths.single;
    final raw = switch (r.kind) {
      SpecPlaceKind.formField => doc.formField(p, r.field!),
      SpecPlaceKind.content => doc.content(p),
      SpecPlaceKind.headline => doc.headline(p),
      SpecPlaceKind.sectionId => _isItem(p) ? _itemId(doc, p) : null,
      _ => null,
    };
    return (p, _reviewed(raw ?? ''), r.field);
  }

  void _crossSummaryField(
    int order,
    String pair,
    String name,
    SpecDocument doc,
    String form,
    FormFieldSpec ff,
  ) {
    final raw = doc.formField(form, ff.name);
    if (raw == null) return;
    final s = ff.summaryOf!;
    final detail = _crossDetail(s);
    if (detail == null) return;
    final (dName, _, elements) = detail;
    final known = elements.values.toSet();
    final seen = <String>{};
    for (final id in _ids(_reviewed(raw))) {
      if (!known.contains(id) || !seen.add(id)) {
        _cross(
          order,
          SpecSyncCode.crossSummaryMismatch,
          pair,
          _place(name, form, field: ff.name, value: id),
          _place(dName, _listOf(elements), value: id),
          known.contains(id)
              ? 'form field "${ff.name}" names $id twice'
              : 'form field "${ff.name}" names $id, which is no element of '
                    '${s.detail} in $dName',
        );
      }
    }
    if (s.relation == 'equal') {
      for (final e in elements.entries) {
        if (seen.contains(e.value)) continue;
        _cross(
          order,
          SpecSyncCode.crossSummaryMismatch,
          pair,
          _place(name, form, field: ff.name),
          _place(dName, e.key, value: e.value),
          'the detail element ${e.value} of $dName is not named in '
          '"${ff.name}" (relation: equal)',
        );
      }
    }
  }

  void _crossInverse(
    int order,
    String pair,
    String name,
    SpecDocument doc,
    String form,
    FormFieldSpec ff,
  ) {
    final raw = doc.formField(form, ff.name);
    if (raw == null) return;
    final value = _reviewed(raw);
    if (value.isEmpty) return;
    final inv = ff.inverseOf!;
    for (final b in _ids(value)) {
      // The document the named entry is read in.
      final registries = {for (final t in ff.refersTo) t.split('.').first};
      for (final registry in registries) {
        final other = _registryDocument(registry);
        if (other == null || other == name) continue;
        final oDoc = set[other]!;
        final targets = [
          for (final t in ff.refersTo)
            if (t.split('.').first == registry) t,
        ];
        final bPath = _entry(oDoc, targets, b);
        if (bPath == null) continue;
        for (final end in inv.fields) {
          final SpecPlaceResolution r;
          try {
            r = SpecPlace.parse(end).resolve(refl, bPath);
          } on SpecPlaceException {
            continue;
          }
          if (r.formField == null) continue;
          // This field's entry, named as the other end names it, and read in
          // its own registry document only.
          final aClasses = {
            for (final t in r.formField!.refersTo) t.split('.').first,
          };
          var a = _nearestItem(form);
          while (a != null &&
              !aClasses.contains(refl.resolve(a)?.targetClass?.sectionId)) {
            final slash = a.lastIndexOf('/');
            a = slash < 0 ? null : _nearestItem(a.substring(0, slash));
          }
          if (a == null) continue;
          final aSid = refl.resolve(a)!.targetClass!.sectionId!;
          if (_registryDocument(aSid) != name) continue;
          final aId = r.formField!.refersTo
              .map((t) => _identity(doc, a!, t))
              .whereType<String>()
              .firstOrNull;
          if (aId == null) continue;
          final ends = _expand(oDoc, r.path);
          final namesBack = ends.any(
            (p) => _ids(
              _reviewed(oDoc.formField(p, r.field!) ?? ''),
            ).contains(aId),
          );
          if (!namesBack) {
            _cross(
              order,
              SpecSyncCode.crossInverseMissing,
              pair,
              _place(name, form, field: ff.name, value: b),
              _place(
                other,
                ends.isEmpty ? bPath : ends.first,
                field: r.field,
                value: aId,
              ),
              'form field "${ff.name}" in $name names $b, but $b in $other '
              'does not name $aId back (${inv.fields.join(', ')})',
            );
          }
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// The global rename
// ---------------------------------------------------------------------------

/// Why [renameId] refuses.
class SpecRenameError implements Exception {
  /// The documents already holding the new id.
  final List<String> documents;

  /// Prose for the reader.
  final String message;

  /// Both known where it is raised.
  const SpecRenameError(this.documents, this.message);

  @override
  String toString() => 'SpecRenameError: $message';
}

/// One value [renameId] changed.
class SpecRenameChange {
  /// The document's name.
  final String document;

  /// The path: a list item (its section id) or the value's path.
  final String path;

  /// The form field, or null.
  final String? field;

  /// `sectionId`, `value` (a form field or content).
  final String kind;

  /// The value before and after.
  final String oldValue, newValue;

  /// The parts of a change.
  const SpecRenameChange({
    required this.document,
    required this.path,
    required this.kind,
    required this.oldValue,
    required this.newValue,
    this.field,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'document': document,
    'path': path,
    if (field != null) 'field': field,
    'kind': kind,
    'old': oldValue,
    'new': newValue,
  };
}

/// Renames the section id [from] to [to] in every document of [set] at once
/// (DP-part-cleanup-2): the list element carrying it, and every value naming
/// it as a whole token (references, comma-separated lists, the texts link
/// rows are extracted from). Refused, nothing changed, when an element of
/// any document already carries [to]. Returns the changes, in document and
/// path order.
List<SpecRenameChange> renameId(SpecDocumentSet set, String from, String to) {
  final c = _SetCheck(set);
  final holders = [
    for (final name in set.names)
      if (_items(set[name]!).any((i) => c._itemId(set[name]!, i) == to)) name,
  ];
  if (holders.isNotEmpty) {
    throw SpecRenameError(
      holders,
      '$to is already an id in ${holders.join(', ')}',
    );
  }
  final token = RegExp(
    '(?<![A-Za-z0-9-])${RegExp.escape(from)}(?![A-Za-z0-9-])',
  );
  final changes = <SpecRenameChange>[];
  for (final name in set.names) {
    final doc = set[name]!;
    for (final item in _items(doc)) {
      if (c._itemId(doc, item) != from) continue;
      doc.setItemSectionId(item, to);
      changes.add(
        SpecRenameChange(
          document: name,
          path: item,
          kind: 'sectionId',
          oldValue: from,
          newValue: to,
        ),
      );
    }
    for (final p in doc.contentPaths.toList()..sort()) {
      final v = doc.content(p) ?? '';
      if (!token.hasMatch(v)) continue;
      final n = v.replaceAll(token, to);
      doc.setContent(p, n);
      changes.add(
        SpecRenameChange(
          document: name,
          path: p,
          kind: 'value',
          oldValue: v,
          newValue: n,
        ),
      );
    }
    for (final p in doc.formPaths.toList()..sort()) {
      for (final f in doc.formFieldNames(p).toList()..sort()) {
        final v = doc.formField(p, f) ?? '';
        if (!token.hasMatch(v)) continue;
        final n = v.replaceAll(token, to);
        doc.setFormField(p, f, n);
        changes.add(
          SpecRenameChange(
            document: name,
            path: p,
            field: f,
            kind: 'value',
            oldValue: v,
            newValue: n,
          ),
        );
      }
    }
  }
  return changes;
}

List<String> _items(SpecDocument doc) => [
  for (final list in doc.listPaths.toList()..sort()) ...doc.listItems(list),
];
