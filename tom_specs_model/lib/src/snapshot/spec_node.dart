/// Copy-on-write snapshotting for the TomSpecs object model (N5, U1).
///
/// The editor keeps an undo stack of document snapshots
/// (`tom_specs_editor_specification.md` §10). A snapshot must be a *cheap full
/// picture*: each new snapshot shares every **unchanged** subtree with its
/// predecessor **by identity** (structural sharing), and only the path from an
/// edited leaf up to the root is cloned. Restoring a snapshot is then trivial —
/// it is just another (independent) tree.
///
/// ## Why this shape
///
/// The model is ~3000 flat data classes with no shared base and no hand-written
/// snapshot support, and the editor runs on **Flutter** (no `dart:mirrors`). A
/// generic deep operation on typed fields therefore needs either per-class
/// support or reflection — reflection is unavailable, so this engine drives the
/// model through a tiny per-class contract (slots / cloneShallow / yamlScalar).
///
/// Two ways to supply that contract, resolved per node by [specSlotsOf] /
/// [cloneShallowOf] / [yamlScalarOf]:
///
///  - **Mix in [SpecNode]** and override the methods directly. Used by the one
///    real hand-written leaf (`DocumentHeader`) and by tests.
///  - **Register a [SpecClassOps]** in [SpecRegistry] keyed by the concrete
///    type. This is how the ~3000 generated model classes adopt the contract
///    *without any edit to their source* (OE-2): Dart 3.11 has no augmentation
///    support, so the contract cannot be mixed into hand-written classes from
///    generated code. The spec-ops codegen instead emits one registry file that
///    closes over each class's public fields. The model classes stay pristine
///    and add **no instance fields and no getters**, so the analyzer-based
///    `ModelReader` that builds `spec_model.json` and feeds the
///    `tom_specs_model_rules.md` §10.2 validator sees them unchanged.
///
/// Dirty state is held in a private [Expando] keyed by node identity rather than
/// in an instance field, precisely so it cannot leak into the model's reflected
/// field set. It works for any [Object] node, registry-backed or not.
library;

/// Tracks, per node, whether it has changed since the last snapshot.
///
/// Kept off the node (in an [Expando]) so neither [SpecNode] nor the registry
/// path adds an instance field to model classes. A node with no recorded state
/// is treated as **dirty** — a freshly constructed node has never been
/// snapshotted, so the first snapshot must capture it.
final Expando<bool> _dirtySinceSnapshot = Expando<bool>('specNodeDirty');

/// A model node that participates in copy-on-write snapshotting by overriding
/// the contract directly (the hand-written path; the generated path uses
/// [SpecRegistry] instead).
///
/// Implementations must declare **every** child model object in [specSlots];
/// any mutable child object left out of the slots would be shared between the
/// live tree and a snapshot and could later be corrupted by an in-place edit.
mixin SpecNode {
  /// Whether this node has been mutated since the last snapshot. New nodes
  /// report `true` (never snapshotted yet).
  bool get isDirtySinceSnapshot => _dirtySinceSnapshot[this] ?? true;

  /// Marks this node changed since the last snapshot, so the next snapshot
  /// clones it instead of sharing its predecessor's copy. The shared document
  /// controller calls this (or the module-level [markDirtyNode]) after applying
  /// any field edit (`tom_specs_editor_specification.md` §8).
  void markDirty() => _dirtySinceSnapshot[this] = true;

  /// The child-node relationships of this node, in a **stable order**. Leaf
  /// nodes inherit the empty default.
  ///
  /// Declared as a method (not a getter) on purpose: a getter would surface as
  /// a synthetic field in the analyzer element model and pollute the reflected
  /// model.
  List<SpecSlot> specSlots() => const [];

  /// A shallow copy of this node: same scalar values and the **same** child
  /// references. The snapshotter rewrites the children (via [specSlots])
  /// afterwards, so `cloneShallow` must not deep-copy them itself.
  SpecNode cloneShallow();

  /// This node's own scalar payload for serialization — its packed `@Form` /
  /// intro `content` string — or `null` if the node owns no scalar of its own.
  ///
  /// Containers inherit the `null` default; content-bearing leaves override it
  /// (typically `=> content`). Used by `SpecYaml` to emit each node's value;
  /// children are walked separately through [specSlots], so this returns only
  /// *this* node's scalar, never its descendants'.
  ///
  /// Declared as a method (not a getter) for the same reason as [specSlots].
  String? yamlScalar() => null;
}

/// The per-class snapshot/serialization contract for a model class that does
/// **not** mix in [SpecNode] — supplied by the spec-ops codegen and registered
/// in [SpecRegistry] (OE-2).
///
/// Each callback receives the live node as an [Object]; the generated body
/// casts it to the concrete type and closes over its public fields. Mirrors the
/// [SpecNode] methods one-to-one: [slots] ↔ `specSlots`, [cloneShallow] ↔
/// `cloneShallow`, [yamlScalar] ↔ `yamlScalar`, plus the optional [connect]
/// binding for projection roots (the registry equivalent of `SpecProjection`).
class SpecClassOps {
  /// Enumerates the node's child relationships, in model declaration order.
  ///
  /// Order is the contract: it fixes the serialized member order and the order
  /// the snapshotter walks children in, so a generated body must not sort.
  final List<SpecSlot> Function(Object node) slots;

  /// Copies the node one level deep — a new instance whose slots still point
  /// at the *same* child objects.
  ///
  /// Shallow is the whole point: structural sharing means only the path from
  /// an edited leaf to the root is cloned, so a deep copy here would make
  /// every snapshot O(document) instead of O(depth).
  final Object Function(Object node) cloneShallow;

  /// The node's own scalar value for serialization, or null when it has none.
  ///
  /// Null-valued (rather than absent) for a node that *has* the concept but
  /// currently holds nothing, which is why the callback returns `String?`
  /// rather than the whole callback being omitted.
  final String? Function(Object node)? yamlScalar;

  /// Re-points a projection root's members onto the live sections of the
  /// source node passed to the callback.
  ///
  /// Only projection roots carry one; null for an ordinary class. Without it a
  /// projection serializes its own default-constructed sections rather than
  /// the document's — the registry equivalent of `SpecProjection`.
  final void Function(Object node, Object source)? connect;

  /// Declares one class's contract.
  ///
  /// [slots] and [cloneShallow] are required because the snapshotter cannot
  /// walk or copy without them; [yamlScalar] and [connect] are omitted by the
  /// classes that have no scalar and are not projection roots, which is most
  /// of them.
  const SpecClassOps({
    required this.slots,
    required this.cloneShallow,
    this.yamlScalar,
    this.connect,
  });
}

/// Holds the generated [SpecClassOps] for every model class that adopts the
/// snapshot/serialization contract via codegen rather than the [SpecNode]
/// mixin. Populated once by the generated `registerSpecOps()` (OE-2).
abstract final class SpecRegistry {
  static final Map<Type, SpecClassOps> _ops = {};

  /// Registers [ops] for the concrete [type]. Called from generated code.
  static void register(Type type, SpecClassOps ops) => _ops[type] = ops;

  /// The ops registered for [type], or `null` when [type] adopts the contract
  /// via the [SpecNode] mixin (or is not a model node at all).
  static SpecClassOps? opsFor(Type type) => _ops[type];

  /// Whether any ops have been registered (the generated `registerSpecOps()`
  /// has not run yet when this is `true`).
  static bool get isEmpty => _ops.isEmpty;

  /// Number of registered classes (diagnostics/tests).
  static int get length => _ops.length;
}

// --- Reflection-free contract resolver ------------------------------------
//
// Every engine walk goes through these four functions instead of calling the
// node directly, so [SpecNode] nodes and [SpecRegistry]-backed nodes are
// handled uniformly. The `is SpecNode` fast-path keeps the hand-written leaves
// and the existing tests working with zero registry lookups.

/// The child slots of [node] (mixin override or registered ops; empty default).
List<SpecSlot> specSlotsOf(Object node) {
  if (node is SpecNode) return node.specSlots();
  return SpecRegistry.opsFor(node.runtimeType)?.slots(node) ?? const [];
}

/// A shallow copy of [node] (mixin override or registered ops).
Object cloneShallowOf(Object node) {
  if (node is SpecNode) return node.cloneShallow();
  final ops = SpecRegistry.opsFor(node.runtimeType);
  if (ops == null) {
    throw StateError(
      'No SpecNode mixin or registered SpecClassOps for ${node.runtimeType}. '
      'Call registerSpecOps() before snapshotting/serializing the model.',
    );
  }
  return ops.cloneShallow(node);
}

/// [node]'s own scalar payload (mixin override or registered ops; `null`
/// default for containers).
String? yamlScalarOf(Object node) {
  if (node is SpecNode) return node.yamlScalar();
  return SpecRegistry.opsFor(node.runtimeType)?.yamlScalar?.call(node);
}

/// Whether [node] changed since the last snapshot. New/unrecorded nodes are
/// dirty.
bool isDirtySinceSnapshotOf(Object node) => _dirtySinceSnapshot[node] ?? true;

/// Marks [node] changed since the last snapshot (works for any node, mixin or
/// registry-backed). The shared document controller calls this on every edit.
void markDirtyNode(Object node) => _dirtySinceSnapshot[node] = true;

/// Clears [node]'s dirty flag (used by the snapshotter after folding it in).
void markCleanNode(Object node) => _dirtySinceSnapshot[node] = false;

/// One child-node relationship of a node — either a single child or a list of
/// children — exposed as uniform get/set hooks so the snapshotter can walk and
/// rewrite children without knowing field names or concrete types.
///
/// Children are typed as [Object] so list-element classes that adopt the
/// contract via the registry (not the [SpecNode] mixin) fit without change; the
/// engine never needs them to share a base type.
class SpecSlot {
  /// Whether this slot holds a list of children rather than a single child.
  ///
  /// Selects which pair of hooks is live: a list slot's [node]/`node=` are
  /// inert and a single slot's [list]/`list=` are, so a caller must branch on
  /// this rather than probing for null.
  final bool isList;

  /// The model member name this slot reads and writes, or `null` when the slot
  /// is only walked structurally (snapshotting ignores labels).
  ///
  /// This is the *Dart identifier*, not the serialization key — see [key].
  final String? label;

  /// The child's effective section id, or `null` when neither the member nor
  /// its target class carries one.
  ///
  /// Populated by the spec-ops codegen from `@SectionId`: the member-level id
  /// when present, otherwise — for a single section/complex child only — the
  /// target class's own id. List slots and value slots keep the member-level id
  /// with no class fallback (SOM §12.2).
  final String? sectionId;

  // The four hooks. Exactly one pair is live per slot; the other pair is bound
  // to the inert statics below, so reading it is safe and writing it is a
  // no-op rather than an error — the snapshotter walks uniformly and branches
  // on `isList` only where the distinction matters.
  final Object? Function() _getNode;
  final void Function(Object?) _setNode;
  final List<Object> Function() _getList;
  final void Function(List<Object>) _setList;

  /// A slot for a single (possibly null) child node.
  SpecSlot.node(Object? Function() get, void Function(Object?) set,
      {this.label, this.sectionId})
      : isList = false,
        _getNode = get,
        _setNode = set,
        _getList = _emptyList,
        _setList = _ignoreList;

  /// A slot for a list of child nodes. The [set] closure receives a
  /// `List<Object>` and is responsible for narrowing it back to the field's
  /// concrete element type (e.g. `(v) => goals = v.cast<BusinessGoalEntry>()`).
  SpecSlot.list(List<Object> Function() get, void Function(List<Object>) set,
      {this.label, this.sectionId})
      : isList = true,
        _getList = get,
        _setList = set,
        _getNode = _nullNode,
        _setNode = _ignoreNode;

  /// The mapping key this slot's child is written under (SOM §12.2): its
  /// [sectionId], one space, then the member name — or the bare member name
  /// when the slot carries no id.
  ///
  /// `null` when the slot has no [label] at all, which means it is walked
  /// structurally and never serialized. An id-less slot keys on its member name
  /// rather than on a synthesized id: a value holder beneath a section is not a
  /// section, so it has nothing language-neutral to be named by, and inventing
  /// one would put a name in the file that no schema and no other runtime
  /// knows.
  String? get key {
    final name = label;
    if (name == null) return null;
    final id = sectionId;
    return id == null ? name : '$id $name';
  }

  /// The single child this slot holds, or null when the member is unset.
  ///
  /// Always null on a list slot ([isList] true) — that is the inert pair, not
  /// an empty child.
  Object? get node => _getNode();

  /// Replaces the single child. A no-op on a list slot.
  set node(Object? value) => _setNode(value);

  /// The children this slot holds, in document order.
  ///
  /// Always empty on a single-child slot ([isList] false) — that is the inert
  /// pair, not a childless list.
  List<Object> get list => _getList();

  /// Replaces the whole child list. A no-op on a single-child slot.
  ///
  /// Whole-list replacement rather than mutation in place, because the
  /// snapshotter's structural sharing depends on the previous list object
  /// staying untouched for the previous snapshot to keep pointing at.
  set list(List<Object> value) => _setList(value);

  static List<Object> _emptyList() => const [];
  static void _ignoreList(List<Object> _) {}
  static Object? _nullNode() => null;
  static void _ignoreNode(Object? _) {}
}

/// Produces structurally-shared snapshots of a node tree.
abstract final class SpecSnapshotter {
  /// Captures the current state of [live] as an immutable snapshot.
  ///
  /// Every subtree that is unchanged since [previous] is shared with
  /// [previous] **by identity**; only nodes that changed (or whose descendants
  /// changed) are cloned. After the walk, [live]'s dirty flags are cleared so
  /// the next call is incremental.
  ///
  /// Pass `previous: null` for the very first snapshot (a full independent
  /// copy). Snapshots never alias nodes from the live tree, so the live tree
  /// may continue to be edited in place without corrupting any snapshot.
  static Object snapshot(Object live, {Object? previous}) =>
      _snap(live, previous);

  /// An independent deep copy of [node] (used to restore a snapshot into a
  /// fresh, editable live tree). Shares nothing with [node].
  static Object restore(Object node) => _deepCopy(node);

  static Object _snap(Object live, Object? prev) {
    final slots = specSlotsOf(live);
    final prevSlots =
        (prev != null && prev.runtimeType == live.runtimeType)
            ? specSlotsOf(prev)
            : null;

    var changed = (_dirtySinceSnapshot[live] ?? true) || prevSlots == null;
    final snappedChildren = <Object?>[]; // Object? | List<Object>

    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      if (slot.isList) {
        final liveList = slot.list;
        final prevList = prevSlots?[i].list;
        if (prevList == null || prevList.length != liveList.length) {
          changed = true;
        }
        final out = <Object>[];
        for (var j = 0; j < liveList.length; j++) {
          final prevChild =
              (prevList != null && j < prevList.length) ? prevList[j] : null;
          final snapChild = _snap(liveList[j], prevChild);
          if (!identical(snapChild, prevChild)) changed = true;
          out.add(snapChild);
        }
        snappedChildren.add(out);
      } else {
        final liveChild = slot.node;
        final prevChild = prevSlots?[i].node;
        final snapChild =
            liveChild == null ? null : _snap(liveChild, prevChild);
        if (!identical(snapChild, prevChild)) changed = true;
        snappedChildren.add(snapChild);
      }
    }

    // The live node has now been folded into a snapshot; reset it so the next
    // snapshot only re-clones what changes from here on.
    _dirtySinceSnapshot[live] = false;

    if (!changed && prev != null) {
      return prev; // wholly unchanged subtree → share predecessor by identity
    }

    final copy = cloneShallowOf(live);
    _dirtySinceSnapshot[copy] = false;
    final copySlots = specSlotsOf(copy);
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].isList) {
        copySlots[i].list = snappedChildren[i] as List<Object>;
      } else {
        copySlots[i].node = snappedChildren[i];
      }
    }
    return copy;
  }

  static Object _deepCopy(Object node) {
    final slots = specSlotsOf(node);
    final copy = cloneShallowOf(node);
    _dirtySinceSnapshot[copy] = false;
    final copySlots = specSlotsOf(copy);
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].isList) {
        copySlots[i].list = [for (final c in slots[i].list) _deepCopy(c)];
      } else {
        final child = slots[i].node;
        copySlots[i].node = child == null ? null : _deepCopy(child);
      }
    }
    return copy;
  }
}
