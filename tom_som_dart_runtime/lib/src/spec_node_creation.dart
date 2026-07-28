/// Meta-model-validated node creation for a live [SpecDocument]
/// (llm_and_d4rt_tools.md §5 "constrained node creation").
///
/// Every node a script or tool adds passes through this single gate, so the
/// document can only grow in ways the [SpecModel] permits for the parent. The
/// rules are the `tom_specs_model_rules.md` §10.2 *structural* rules — but read
/// from the model meta-data the runtime already carries ([SpecField.kind],
/// [SpecField.sectionIdPattern], [SpecField.min]), **not** from the
/// analyzer-backed authoring validator in `tom_specs_clitool`. The clitool
/// validates the *authored model graph*; this validates a *document mutation
/// against that model*. They are different layers and the runtime keeps its
/// lean, `yaml`-only dependency footprint.
///
/// [checkAddNode] is the single, value-aware rule-check entry point (exported
/// for reuse by editors and the engine); [SpecNodeCreator.add] applies it and
/// performs the mutation only when it returns `null`, so an illegal add never
/// touches the tree.
library;

import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_paths.dart';
import 'spec_reflection.dart';
import 'spec_section_id.dart';

/// Why an attempted node creation is illegal against the model.
enum SpecCreationCode {
  /// The parent path does not resolve to a node that can own named children
  /// (it is dangling, a leaf, or a list — lists grow through their own field,
  /// not by adding children to the list node).
  notAContainer,

  /// The requested child segment names no field on the parent's class.
  unknownChild,

  /// A caller-proposed list-item id does not keep the prefix mandated by the
  /// list's `@SectionIdPattern` (AA1 criterion 3/5: an override replaces the
  /// suffix, the pattern prefix stays).
  patternMismatch,

  /// A caller-proposed list-item id collides with another item's section id in
  /// the same list (AA1 criterion 5: section ids within a list must be unique).
  duplicateSectionId,

  /// A single-valued (non-list) child already holds a value — only one is
  /// allowed.
  cardinalityExceeded,
}

/// A rejected node-creation attempt. Thrown by [SpecNodeCreator.add] and
/// returned (rather than thrown) by [checkAddNode].
class SpecCreationError implements Exception {
  /// The parent path the add was attempted under.
  final String parentPath;

  /// The child section segment that was requested.
  final String childSegment;

  /// Why the add is illegal.
  final SpecCreationCode code;

  /// A human-readable explanation.
  final String message;

  const SpecCreationError({
    required this.parentPath,
    required this.childSegment,
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'SpecCreationError(${code.name}) '
      'under "$parentPath" → "$childSegment": $message';
}

/// Validates adding child [childSegment] under [parentPath] against [model],
/// consulting [document] for cardinality. Returns `null` when the add is legal,
/// otherwise the [SpecCreationError] describing the first rule it breaks.
///
/// This performs **no mutation**; it is the shared rule-check that
/// [SpecNodeCreator.add] (and any editor) calls before touching the tree.
SpecCreationError? checkAddNode(
  SpecModel model,
  SpecDocument document,
  String parentPath,
  String childSegment, {
  String? itemId,
}) {
  final refl = SpecReflection(model);

  SpecCreationError err(SpecCreationCode code, String message) =>
      SpecCreationError(
        parentPath: parentPath,
        childSegment: childSegment,
        code: code,
        message: message,
      );

  // 1. The parent must resolve to a class-bearing node (root / complex /
  //    section / complex list item). Leaves, lists and dangling paths cannot
  //    own named children.
  final parent = refl.resolve(parentPath);
  if (parent == null || parent.targetClass == null) {
    final what = parent == null ? 'does not resolve' : 'is a ${parent.kind.name}';
    return err(SpecCreationCode.notAContainer,
        'parent path $what and cannot own child nodes');
  }
  final parentClass = parent.targetClass!;

  // 2. The child segment must name a declared field of the parent's class.
  final field = _fieldForSegment(parentClass, childSegment);
  if (field == null) {
    return err(SpecCreationCode.unknownChild,
        '"$childSegment" is not a child of ${parentClass.name}');
  }

  final childPath = specPathJoin(parentPath, childSegment);

  if (field.kind == SpecFieldKind.list) {
    // 3. List item: validate a caller-proposed id. Lists have no upper bound,
    //    so there is no cardinality check. A missing id is generated later
    //    (criterion 3); an explicit override must keep the pattern prefix
    //    (criterion 3) and stay unique within the list (criterion 5).
    final pattern = field.sectionIdPattern;
    if (itemId != null && pattern != null) {
      final prefix = sectionIdPatternPrefix(pattern);
      if (!itemId.startsWith(prefix)) {
        return err(SpecCreationCode.patternMismatch,
            'item id "$itemId" does not keep the pattern prefix "$prefix"');
      }
      if (document.listItemSectionIds(childPath).contains(itemId)) {
        return err(SpecCreationCode.duplicateSectionId,
            'item id "$itemId" is already used in list "$childPath"');
      }
    }
    return null;
  }

  // 4. Single-valued child (complex / section / form / content / enum /
  //    scalar): cardinality is exactly one, so reject if a value already
  //    exists at or beneath the child path.
  if (document.hasValuesUnder(childPath)) {
    return err(SpecCreationCode.cardinalityExceeded,
        'a ${field.kind.name} child already exists at "$childPath"');
  }
  return null;
}

/// Applies [checkAddNode] and performs the constrained mutation.
///
/// Holds the [model]/[document] pair so callers add children by parent path and
/// child segment without re-supplying the context each time.
class SpecNodeCreator {
  final SpecModel model;
  final SpecDocument document;

  const SpecNodeCreator(this.model, this.document);

  /// Adds child [childSegment] under [parentPath] and returns the new node's
  /// path. For a list field this appends a fresh item (`…/<segment>-<seq>`),
  /// assigning its **section id** (AA1 criteria 3–5): [itemId] if given
  /// (override), otherwise one generated from the field's `@SectionIdPattern`
  /// using [date] (defaulting to now) for the two-letter-date component. Lists
  /// with no pattern (scalar lists) get no section id. For a single-valued
  /// field it returns the child path without mutating the sparse store (the
  /// caller then sets its value).
  ///
  /// Throws [SpecCreationError] — leaving the document untouched — when the add
  /// violates a structural rule (see [SpecCreationCode]).
  String add(String parentPath, String childSegment,
      {String? itemId, DateTime? date}) {
    final error = checkAddNode(model, document, parentPath, childSegment,
        itemId: itemId);
    if (error != null) throw error;

    final childPath = specPathJoin(parentPath, childSegment);
    final field = _fieldForSegment(
        SpecReflection(model).resolve(parentPath)!.targetClass!, childSegment)!;
    if (field.kind == SpecFieldKind.list) {
      final pattern = field.sectionIdPattern;
      if (pattern == null) return document.addListItem(childPath);
      final id = itemId ??
          generateListItemSectionId(pattern, date ?? DateTime.now(),
              document.listItemSectionIds(childPath));
      return document.addListItem(childPath, sectionId: id);
    }
    return childPath;
  }
}

/// The field of [cls] whose section segment (`@SectionId` ?? name) is
/// [segment], or `null` when the class declares no such child.
SpecField? _fieldForSegment(SpecClass cls, String segment) {
  for (final f in cls.fields) {
    if ((f.sectionId ?? f.name) == segment) return f;
  }
  return null;
}
