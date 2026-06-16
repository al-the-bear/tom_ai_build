/// Copy-on-write snapshotting for the TomSpecs object model (N5, U1).
///
/// The editor keeps an undo stack of document snapshots (§10). A snapshot must
/// be a *cheap full picture*: each new snapshot shares every **unchanged**
/// subtree with its predecessor **by identity** (structural sharing), and only
/// the path from an edited leaf up to the root is cloned. Restoring a snapshot
/// is then trivial — it is just another (independent) tree.
///
/// ## Why this shape
///
/// The model is ~3000 flat data classes with no shared base and no code
/// generation, and the editor runs on **Flutter** (no `dart:mirrors`). A
/// generic deep operation on typed fields therefore needs either per-class
/// support or reflection — reflection is unavailable, so this engine uses a
/// tiny per-class contract that adds **no instance fields and no getters** to
/// the model classes (so the analyzer-based `ModelReader` that builds
/// `spec_model.json` and feeds the §8.6 validator sees the classes unchanged):
///
///  - mix in [SpecNode];
///  - implement [SpecNode.cloneShallow] (copy scalars, share child references);
///  - override [SpecNode.specSlots] to expose child-node relationships (leaf
///    nodes inherit the empty default);
///  - call [SpecNode.markDirty] after mutating a field. The editor routes every
///    edit through the shared document controller (§8), which is the single
///    place that marks nodes dirty.
///
/// Dirty state is held in a private [Expando] keyed by node identity rather than
/// in an instance field, precisely so it cannot leak into the model's reflected
/// field set.
library;

/// Tracks, per node, whether it has changed since the last snapshot.
///
/// Kept off the node (in an [Expando]) so [SpecNode] adds no instance field to
/// adopting classes. A node with no recorded state is treated as **dirty** — a
/// freshly constructed node has never been snapshotted, so the first snapshot
/// must capture it.
final Expando<bool> _dirtySinceSnapshot = Expando<bool>('specNodeDirty');

/// A model node that participates in copy-on-write snapshotting.
///
/// See the library doc for the adoption contract. Implementations must declare
/// **every** child model object in [specSlots]; any mutable child object left
/// out of the slots would be shared between the live tree and a snapshot and
/// could later be corrupted by an in-place edit.
mixin SpecNode {
  /// Whether this node has been mutated since the last snapshot. New nodes
  /// report `true` (never snapshotted yet).
  bool get isDirtySinceSnapshot => _dirtySinceSnapshot[this] ?? true;

  /// Marks this node changed since the last snapshot, so the next snapshot
  /// clones it instead of sharing its predecessor's copy. The shared document
  /// controller calls this after applying any field edit (§8).
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
  /// (typically `=> content`). Used by [SpecYaml] to emit each node's value;
  /// children are walked separately through [specSlots], so this returns only
  /// *this* node's scalar, never its descendants'.
  ///
  /// Declared as a method (not a getter) for the same reason as [specSlots]: a
  /// getter would surface as a synthetic field in the analyzer element model
  /// and pollute the reflected model.
  String? yamlScalar() => null;
}

/// One child-node relationship of a [SpecNode] — either a single child or a
/// list of children — exposed as uniform get/set hooks so the snapshotter can
/// walk and rewrite children without knowing field names or concrete types.
class SpecSlot {
  final bool isList;

  /// Stable serialization key for this slot (the model field name), or `null`
  /// when the slot is only walked structurally (snapshotting ignores labels).
  final String? label;

  final SpecNode? Function() _getNode;
  final void Function(SpecNode?) _setNode;
  final List<SpecNode> Function() _getList;
  final void Function(List<SpecNode>) _setList;

  /// A slot for a single (possibly null) child node.
  SpecSlot.node(SpecNode? Function() get, void Function(SpecNode?) set,
      {this.label})
      : isList = false,
        _getNode = get,
        _setNode = set,
        _getList = _emptyList,
        _setList = _ignoreList;

  /// A slot for a list of child nodes. The [set] closure receives a
  /// `List<SpecNode>` and is responsible for narrowing it back to the field's
  /// concrete element type (e.g. `(v) => _goals = v.cast<BusinessGoalEntry>()`).
  SpecSlot.list(List<SpecNode> Function() get, void Function(List<SpecNode>) set,
      {this.label})
      : isList = true,
        _getList = get,
        _setList = set,
        _getNode = _nullNode,
        _setNode = _ignoreNode;

  SpecNode? get node => _getNode();
  set node(SpecNode? value) => _setNode(value);

  List<SpecNode> get list => _getList();
  set list(List<SpecNode> value) => _setList(value);

  static List<SpecNode> _emptyList() => const [];
  static void _ignoreList(List<SpecNode> _) {}
  static SpecNode? _nullNode() => null;
  static void _ignoreNode(SpecNode? _) {}
}

/// Produces structurally-shared snapshots of a [SpecNode] tree.
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
  static SpecNode snapshot(SpecNode live, {SpecNode? previous}) =>
      _snap(live, previous);

  /// An independent deep copy of [node] (used to restore a snapshot into a
  /// fresh, editable live tree). Shares nothing with [node].
  static SpecNode restore(SpecNode node) => _deepCopy(node);

  static SpecNode _snap(SpecNode live, SpecNode? prev) {
    final slots = live.specSlots();
    final prevSlots =
        (prev != null && prev.runtimeType == live.runtimeType)
            ? prev.specSlots()
            : null;

    var changed = (_dirtySinceSnapshot[live] ?? true) || prevSlots == null;
    final snappedChildren = <Object?>[]; // SpecNode? | List<SpecNode>

    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      if (slot.isList) {
        final liveList = slot.list;
        final prevList = prevSlots?[i].list;
        if (prevList == null || prevList.length != liveList.length) {
          changed = true;
        }
        final out = <SpecNode>[];
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

    final copy = live.cloneShallow();
    _dirtySinceSnapshot[copy] = false;
    final copySlots = copy.specSlots();
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].isList) {
        copySlots[i].list = snappedChildren[i] as List<SpecNode>;
      } else {
        copySlots[i].node = snappedChildren[i] as SpecNode?;
      }
    }
    return copy;
  }

  static SpecNode _deepCopy(SpecNode node) {
    final slots = node.specSlots();
    final copy = node.cloneShallow();
    _dirtySinceSnapshot[copy] = false;
    final copySlots = copy.specSlots();
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
