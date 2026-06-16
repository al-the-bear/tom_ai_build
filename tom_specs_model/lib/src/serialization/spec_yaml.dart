/// YAML serialization and the projection connect pass for the TomSpecs object
/// model (N11, N12).
///
/// ## What this provides
///
/// A spec is **one document** with thirteen entry points: the Project
/// Definition master plus twelve Phase 3 *projection* roots that reference the
/// same PD00 sections (§14). Two serialization rules follow from that:
///
///  - **Global save (`*.docspecs.yaml`) writes only the Project Definition.**
///    Because every projection is a view over the same PD sections, serializing
///    the PD tree alone emits each section **exactly once** — there are no
///    duplicate subtrees (N9, §15.1). [SpecYaml.toYaml] of the PD root is that
///    global `document:` pass.
///
///  - **An individual projection write runs a connect pass first.** A projection
///    root references PD sections through its `@MapsTo` / `@DetailedIn` links;
///    those references are bound to the **live** PD sections *immediately before*
///    writing the root's own file ([SpecYaml.toYamlForProjection]). Connecting
///    before write — rather than wiring at load and keeping copies in sync —
///    means an individual write always reflects current PD content, and a
///    section that is **null in PD is null in the projection too** (N12). The
///    pure-projection invariant (§14, validated in step 7) guarantees the
///    connect pass only re-points references and never invents or drops content.
///
/// ## Why this shape
///
/// Like the snapshot engine, this walks the model through the reflection-free
/// [SpecNode] contract (`specSlots` for children, `yamlScalar` for a node's own
/// content) so it adds no instance fields or getters to the model classes and
/// runs on Flutter without `dart:mirrors`. The per-section YAML *keys* and the
/// twelve per-root [SpecProjection.connect] bindings are emitted by the model
/// codegen that adopts [SpecNode] across all roots; this file owns the engine
/// and the contract they plug into.
library;

import '../snapshot/spec_node.dart';

/// A projection root that can bind its references onto a live source tree
/// (the Project Definition) immediately before its individual file is written.
///
/// The twelve Phase 3 roots mix this in. [connect] re-points the projection's
/// slots onto the matching sections of [source]; after it runs, serializing the
/// projection reflects current PD content, and any section absent from PD is
/// left null (N12 — one shared tree, no divergence).
mixin SpecProjection on SpecNode {
  /// Binds this projection's references onto the live sections of [source]
  /// (the Project Definition root), in place. Called by
  /// [SpecYaml.toYamlForProjection] right before serialization.
  void connect(SpecNode source);
}

/// Serializes [SpecNode] trees to YAML and orchestrates the connect-before-write
/// pass for projection roots (N11, N12).
abstract final class SpecYaml {
  /// The global `document:` pass: the YAML of [projectDefinitionRoot] alone.
  ///
  /// Pass the Project Definition root here for the native `*.docspecs.yaml`
  /// save. Because the projection roots are views over the same sections, the
  /// PD tree contains every section exactly once, so the output never duplicates
  /// a subtree (§15.1).
  static String toYaml(SpecNode projectDefinitionRoot) {
    final buffer = StringBuffer();
    _emit(projectDefinitionRoot, 0, buffer);
    return buffer.toString();
  }

  /// Connects [projection] onto the live [projectDefinitionRoot] (N11) and then
  /// serializes the projection — the per-root individual-file write (§15.2).
  static String toYamlForProjection(
    SpecProjection projection,
    SpecNode projectDefinitionRoot,
  ) {
    projection.connect(projectDefinitionRoot);
    return toYaml(projection);
  }

  /// A structured view of [node]'s serialization: the node's own scalar under
  /// `content` (when present) plus one entry per child slot (single child →
  /// nested map or `null`; list → list of maps), keyed by the slot label.
  ///
  /// Useful for tests and for callers that want the tree as data rather than
  /// formatted YAML.
  static Map<String, Object?> toMap(SpecNode node) {
    final map = <String, Object?>{};
    final scalar = node.yamlScalar();
    if (scalar != null) map['content'] = scalar;

    final slots = node.specSlots();
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final key = slot.label ?? (slot.isList ? 'list$i' : 'node$i');
      if (slot.isList) {
        map[key] = [for (final child in slot.list) toMap(child)];
      } else {
        final child = slot.node;
        map[key] = child == null ? null : toMap(child);
      }
    }
    return map;
  }

  // --- YAML emitter -------------------------------------------------------

  static void _emit(SpecNode node, int indent, StringBuffer out) {
    final pad = '  ' * indent;
    final scalar = node.yamlScalar();
    if (scalar != null) {
      _emitScalar(pad, 'content', scalar, indent, out);
    }
    final slots = node.specSlots();
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final key = slot.label ?? (slot.isList ? 'list$i' : 'node$i');
      if (slot.isList) {
        final list = slot.list;
        if (list.isEmpty) {
          out.writeln('$pad$key: []');
        } else {
          out.writeln('$pad$key:');
          for (final child in list) {
            out.writeln('$pad  -');
            _emit(child, indent + 2, out);
          }
        }
      } else {
        final child = slot.node;
        if (child == null) {
          out.writeln('$pad$key: null');
        } else {
          out.writeln('$pad$key:');
          _emit(child, indent + 1, out);
        }
      }
    }
  }

  /// Emits `key:` as a literal block scalar (`|`) so multi-line section content
  /// stays human-readable and round-trips losslessly (§15.1).
  static void _emitScalar(
    String pad,
    String key,
    String value,
    int indent,
    StringBuffer out,
  ) {
    out.writeln('$pad$key: |');
    final childPad = '  ' * (indent + 1);
    for (final line in value.split('\n')) {
      out.writeln('$childPad$line');
    }
  }
}
