/// YAML serialization and the projection connect pass for the TomSpecs object
/// model (N11, N12).
///
/// ## What this provides
///
/// A spec is **one document** with fourteen entry points: the Solution
/// Blueprint master, twelve Phase 3 *projection* roots, and the D13 CodeSpecs
/// generation projection — all views that reference the same SBP sections
/// (`tom_specs_editor_specification.md` §14). Two serialization rules follow
/// from that:
///
///  - **Global save (`*.docspecs.yaml`) writes only the Solution Blueprint.**
///    Because every projection is a view over the same SBP sections,
///    serializing the SBP tree alone emits each section **exactly once** —
///    there are no duplicate subtrees (N9, `tom_specs_editor_specification.md`
///    §15.1). [SpecYaml.toYaml] of the SBP root is that global `document:`
///    pass.
///
///  - **An individual projection write runs a connect pass first.** A projection
///    root references SBP sections through its `@MapsTo` / `@DetailedIn` links;
///    those references are bound to the **live** SBP sections *immediately before*
///    writing the root's own file ([SpecYaml.toYamlForProjection]). Connecting
///    before write — rather than wiring at load and keeping copies in sync —
///    means an individual write always reflects current SBP content, and a
///    section that is **null in SBP is null in the projection too** (N12).
///
/// ## One file format, one encoder
///
/// The `*.docspecs.yaml` hierarchical-v2 format (SOM §12) has exactly one
/// encoder: [SpecDocumentYaml] in `tom_som_dart_runtime`, the shape all nine
/// SOM runtimes derive from. This library does **not** write YAML — it
/// *projects the live object tree onto a [SpecDocument]* and hands that to the
/// runtime encoder. A second emitter would be a second derivation of the same
/// format, and the two would drift: the preamble, the `document:` wrapper, the
/// indexed list-item keys, sparseness, headlines, sibling ordering and the
/// scalar-representability fallback are all decisions this library would have
/// to re-make and re-maintain. Projecting instead makes them true by
/// construction, so a document written here is loadable by every runtime.
///
/// The projection is the mirror image of [SpecDocumentYaml]'s encoder walk: for
/// each metadata node it locates the corresponding live object and writes that
/// object's values into the sparse stores under the node's path.
///
/// ## Keys and paths
///
/// A child is written under `<sectionId> <memberName>` (SOM §12.2) and keyed in
/// the document under the node's path segment (SOM §8). Both derivations of the
/// key rule are live here and are **cross-checked on every walk**:
/// [SpecSlot.key], filled by the spec-ops codegen from the model source, must
/// equal [SpecDocumentYaml.nodeKey] of the metadata node the slot binds to. The
/// static agreement `spec_ops_key_agreement_test.dart` asserts thereby becomes a
/// dynamic one — a key that drifts fails the very write that would have
/// produced an unreadable file.
///
/// ## Why the object walk looks like this
///
/// Like the snapshot engine, this walks the model through the reflection-free
/// contract resolver (`specSlotsOf` for children, `yamlScalarOf` for a node's
/// own content) so it adds no instance fields or getters to the model classes
/// and runs on Flutter without `dart:mirrors`. A node supplies the contract
/// either by mixing in `SpecNode` (the hand-written leaves) or by a registered
/// `SpecClassOps` emitted by the spec-ops codegen (the ~1250 model classes).
/// Headline, codeSpec and form values are read straight off [DocSpecsSection],
/// which every model class extends; an object that is not one simply carries
/// none of them.
///
/// The connect binding follows the same dual path: [SpecProjection.connect] for
/// the mixin leaves, or [SpecClassOps.connect] for registered projection roots.
library;

// Imported by `show` rather than wholesale: the runtime barrel also exports a
// `DocSpecsSection` of its own — the markdown DocSpecs parse tree (SOM §14),
// unrelated to the model base class of the same name in `tom_specs_core`.
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show
        SomMetaKind,
        SomMetaNode,
        SomMetaTree,
        SpecDocument,
        SpecDocumentYaml,
        SpecYamlFormatException,
        specPathJoin;
import 'package:tom_specs_core/tom_specs_core.dart';

import '../snapshot/spec_node.dart';

/// A projection root that can bind its references onto a live source tree
/// (the Solution Blueprint) immediately before its individual file is written.
///
/// Hand-written projections mix this in; generated projection roots supply the
/// same binding through [SpecClassOps.connect]. [connect] re-points the
/// projection's slots onto the matching sections of `source`; after it runs,
/// serializing the projection reflects current SBP content, and any section
/// absent from SBP is left null (N12 — one shared tree, no divergence).
mixin SpecProjection on SpecNode {
  /// Binds this projection's references onto the live sections of [source]
  /// (the Solution Blueprint root), in place. Called by
  /// [SpecYaml.toYamlForProjection] right before serialization.
  void connect(Object source);
}

/// Resolves the connect binding of [projection] (mixin override or registered
/// ops) and runs it against [source], or returns `false` when [projection] has
/// no connect binding.
bool connectProjection(Object projection, Object source) {
  if (projection is SpecProjection) {
    projection.connect(source);
    return true;
  }
  final connect = SpecRegistry.opsFor(projection.runtimeType)?.connect;
  if (connect == null) return false;
  connect(projection, source);
  return true;
}

/// Projects live node trees onto a [SpecDocument] for the shared
/// hierarchical-v2 encoder, and orchestrates the connect-before-write pass for
/// projection roots (N11, N12).
abstract final class SpecYaml {
  /// The global `document:` pass: the `*.docspecs.yaml` of
  /// [solutionBlueprintRoot] alone, described by [tree].
  ///
  /// Pass the Solution Blueprint root here for the native save. Because the
  /// projection roots are views over the same sections, the SBP tree contains
  /// every section exactly once, so the output never duplicates a subtree
  /// (`tom_specs_editor_specification.md` §15.1). [tree] must be the metadata
  /// tree of that root; [modelVersion] stamps the authoring object-model
  /// version into the preamble when the caller knows it.
  static String toYaml(
    Object solutionBlueprintRoot, {
    required SomMetaTree tree,
    String? modelVersion,
  }) =>
      SpecDocumentYaml.encode(
        document: toDocument(solutionBlueprintRoot, tree: tree),
        tree: tree,
        modelVersion: modelVersion,
      );

  /// Connects [projection] onto the live [solutionBlueprintRoot] (N11) and then
  /// serializes the projection — the per-root individual-file write
  /// (`tom_specs_editor_specification.md` §15.2). [tree] must be the metadata
  /// tree of the *projection* root, not of the Solution Blueprint.
  static String toYamlForProjection(
    Object projection,
    Object solutionBlueprintRoot, {
    required SomMetaTree tree,
    String? modelVersion,
  }) {
    connectProjection(projection, solutionBlueprintRoot);
    return toYaml(projection, tree: tree, modelVersion: modelVersion);
  }

  /// Projects the live object tree rooted at [root] onto a sparse
  /// [SpecDocument] keyed by [tree]'s paths — the value-level half of a save,
  /// separated out so callers (and tests) can inspect, diff or edit the
  /// document before it is encoded.
  ///
  /// Throws [SpecYamlFormatException] when the object tree holds a value the
  /// format has no home for: an object whose members the metadata tree does not
  /// describe (or vice versa), a key that disagrees with
  /// [SpecDocumentYaml.nodeKey], or form field values on a section the metadata
  /// tree does not declare as a `@Form`. Failing loudly here is the point: the
  /// alternative is a file that silently lost data.
  ///
  /// Free text on a `@Form` section is *not* such a value: it is the form's
  /// preamble (SOM §11.4 rule 7), and it binds to the node's `content` key like
  /// any other section's body (SOM §12.2).
  static SpecDocument toDocument(
    Object root, {
    required SomMetaTree tree,
  }) {
    final doc = SpecDocument();
    _Projector(doc).bind(tree.root, tree.root.segment, root);
    return doc;
  }
}

/// The object-tree → [SpecDocument] walk. One instance per projection so the
/// error messages can name the path they failed at without threading state.
class _Projector {
  _Projector(this.doc);

  final SpecDocument doc;

  /// Binds [object] and everything beneath it into [doc] under [path], guided
  /// by the metadata [node].
  void bind(SomMetaNode node, String path, Object object) {
    _bindSectionMeta(path, object);
    switch (node.kind) {
      case SomMetaKind.form:
        _bindForm(node, path, object);
      case SomMetaKind.content:
      case SomMetaKind.scalar:
      case SomMetaKind.enumValue:
        _bindLeaf(node, path, object);
      case SomMetaKind.section:
      case SomMetaKind.complex:
        // A section/complex node with no children is either a leaf whose target
        // class lies outside the model (`TextSection` and friends) or a
        // recursive re-entry, where the generated chains — and therefore the
        // file format — terminate. Both carry a value and nothing below it.
        if (node.children.isEmpty) {
          _bindLeaf(node, path, object);
        } else {
          _bindChildren(node, path, object);
        }
      case SomMetaKind.list:
        throw SpecYamlFormatException(
            'list node ${node.debugName} reached as a single value at "$path"; '
            'lists are bound from their owning section');
    }
  }

  /// Writes the two per-section markers every node may carry: the stored
  /// headline (YRD3) and the forward DocSpecs→CodeSpecs link
  /// (codespecs_mapping.md §9.2). Both are sparse — empty means "unset".
  ///
  /// [DocSpecsSection.id] is deliberately **not** written: outside a list it is
  /// a re-derivable echo of the section id the metadata tree already owns, and
  /// the format keys on the metadata. Inside a list it *is* the item's identity
  /// and is passed to [SpecDocument.addListItem] by [_bindList].
  void _bindSectionMeta(String path, Object object) {
    if (object is! DocSpecsSection) return;
    final headline = object.headline;
    if (headline != null && headline.isNotEmpty) {
      doc.setHeadline(path, headline);
    }
    if (object.codeSpec.isNotEmpty) {
      doc.setCodeSpec(path, object.codeSpec.join(','));
    }
  }

  /// Binds a value leaf: the object's own scalar payload, and nothing else.
  void _bindLeaf(SomMetaNode node, String path, Object object) {
    final scalar = _scalarOf(object);
    if (scalar != null && scalar.isNotEmpty) doc.setContent(path, scalar);
    _assertNoForm(node, path, object);
    final slots = specSlotsOf(object);
    for (final slot in slots) {
      final held = slot.isList ? slot.list.isNotEmpty : slot.node != null;
      if (held) {
        throw SpecYamlFormatException(
            'no home for ${slot.label ?? '<unlabelled>'} beneath "$path": '
            '${node.debugName} is a leaf in the metadata tree'
            '${node.recursive ? ' (recursive re-entry)' : ''}');
      }
    }
  }

  /// Binds a `@Form` section: its preamble content plus one document form entry
  /// keyed by form-field name.
  ///
  /// A form section's free text is `DocSpecsSection.content`, exactly as it is
  /// for a section with no form, and it binds to the same `content` key of the
  /// node's mapping (SOM §11.4 rule 7 and SOM §12.2). The form's parsed field
  /// values bind beside it under their field names.
  void _bindForm(SomMetaNode node, String path, Object object) {
    final preamble = _scalarOf(object);
    if (preamble != null && preamble.isNotEmpty) {
      doc.setContent(path, preamble);
    }
    final form = (object is DocSpecsSection) ? object.form : null;
    if (form == null) return;
    final meta = node.form;
    if (meta == null) {
      throw SpecYamlFormatException(
          'form values at "$path" but ${node.debugName} carries no form '
          'metadata');
    }
    form.values.forEach((name, value) {
      if (meta.fieldNamed(name) == null) {
        throw SpecYamlFormatException(
            'unknown form field "$name" at "$path" (${node.debugName})');
      }
      if (value == null) return;
      doc.setFormField(path, name, '$value');
    });
  }

  /// Binds a section/complex node by pairing its metadata children with the
  /// object's slots.
  ///
  /// The pairing is by **member name**, which is the one name both sides
  /// genuinely share: the metadata carries `memberName` and the codegen fills
  /// [SpecSlot.label] from the same model source. Every pair is then key-checked
  /// (see the library doc). Anything unpaired is an error, in both directions —
  /// a slot with no metadata child would be silently dropped, and a metadata
  /// child with no slot would leave a hole no runtime could distinguish from
  /// "unset".
  void _bindChildren(SomMetaNode node, String path, Object object) {
    final slots = <String, SpecSlot>{};
    for (final slot in specSlotsOf(object)) {
      final label = slot.label;
      if (label == null) {
        throw SpecYamlFormatException(
            'unlabelled slot beneath "$path" (${node.debugName}); a slot must '
            'name its member to be serialized');
      }
      slots[label] = slot;
    }

    final ownValue = <SomMetaNode>[];
    for (final child in node.children) {
      final member = child.memberName;
      if (member == null) {
        throw SpecYamlFormatException(
            'metadata child of ${node.debugName} at "$path" has no member name');
      }
      final slot = slots.remove(member);
      if (slot == null) {
        // No slot means the member is not a child object but the class's own
        // value member — the `String? content` every model class declares,
        // which `yamlScalarOf` returns and the codegen therefore does not emit
        // a slot for.
        ownValue.add(child);
        continue;
      }
      _checkKey(node, path, slot, child);
      final childPath = specPathJoin(path, child.segment);
      if (child.kind == SomMetaKind.list) {
        if (!slot.isList) {
          throw SpecYamlFormatException(
              'slot "$member" at "$childPath" holds a single node but '
              '${child.debugName} is a list');
        }
        _bindList(child, childPath, slot.list);
        continue;
      }
      if (slot.isList) {
        throw SpecYamlFormatException(
            'slot "$member" at "$childPath" holds a list but '
            '${child.debugName} is ${child.kind.name}');
      }
      final value = slot.node;
      if (value == null) continue; // sparse: an unset section writes nothing
      bind(child, childPath, value);
    }

    if (slots.isNotEmpty) {
      throw SpecYamlFormatException(
          'slots ${slots.keys.join(', ')} beneath "$path" have no metadata '
          'child of ${node.debugName}; the model and its exported metadata '
          'disagree');
    }
    _bindOwnValue(node, path, object, ownValue);
  }

  /// Binds the class's own value member — the member `yamlScalarOf` returns and
  /// [DocSpecsSection.form] belongs to — under its own path segment.
  void _bindOwnValue(
    SomMetaNode node,
    String path,
    Object object,
    List<SomMetaNode> candidates,
  ) {
    SomMetaNode? own;
    if (candidates.length == 1) {
      own = candidates.single;
    } else if (candidates.length > 1) {
      final content =
          candidates.where((c) => c.memberName == 'content').toList();
      if (content.length != 1) {
        throw SpecYamlFormatException(
            '${node.debugName} at "$path" has ${candidates.length} value '
            'members (${candidates.map((c) => c.memberName).join(', ')}) and no '
            'single `content`; which one carries the section value is ambiguous');
      }
      own = content.single;
    }

    if (own == null) {
      final scalar = _scalarOf(object);
      if (scalar != null && scalar.isNotEmpty) {
        throw SpecYamlFormatException(
            '${node.debugName} at "$path" carries a scalar value but its '
            'metadata declares no value member to write it under');
      }
      _assertNoForm(node, path, object);
      return;
    }

    final ownPath = specPathJoin(path, own.segment);
    switch (own.kind) {
      case SomMetaKind.form:
        _bindForm(own, ownPath, object);
      case SomMetaKind.content:
      case SomMetaKind.scalar:
      case SomMetaKind.enumValue:
        final scalar = _scalarOf(object);
        if (scalar != null && scalar.isNotEmpty) {
          doc.setContent(ownPath, scalar);
        }
        _assertNoForm(node, path, object);
      case SomMetaKind.section:
      case SomMetaKind.complex:
      case SomMetaKind.list:
        throw SpecYamlFormatException(
            'value member ${own.debugName} of ${node.debugName} at "$path" is '
            '${own.kind.name}, but it has no slot to walk');
    }
  }

  /// Binds one list field: each element becomes a document list item, carrying
  /// its [DocSpecsSection.id] as the item's section id when it has one.
  void _bindList(SomMetaNode node, String listPath, List<Object> elements) {
    final element = node.elementNode;
    for (final e in elements) {
      final id = (e is DocSpecsSection) ? e.id : null;
      final itemPath = doc.addListItem(
        listPath,
        sectionId: (id == null || id.isEmpty) ? null : id,
      );
      if (element == null) {
        // A list with no element subtree holds value items, not sections.
        _bindSectionMeta(itemPath, e);
        _bindLeaf(node, itemPath, e);
      } else {
        bind(element, itemPath, e);
      }
    }
  }

  /// Cross-checks the two derivations of the SOM §12.2 mapping key: the one the
  /// spec-ops codegen baked into [SpecSlot.sectionId] from the model source, and
  /// the one [SpecDocumentYaml] resolves from the exported metadata. They are
  /// the same rule read from the same annotations, so a disagreement means one
  /// side has drifted — and a drifted key is exactly what makes a file
  /// unreadable by the other eight runtimes.
  void _checkKey(
    SomMetaNode parent,
    String path,
    SpecSlot slot,
    SomMetaNode child,
  ) {
    final expected = SpecDocumentYaml.nodeKey(child);
    if (slot.key != expected) {
      throw SpecYamlFormatException(
          'key disagreement beneath "$path" (${parent.debugName}): slot writes '
          '"${slot.key}", metadata writes "$expected"');
    }
  }

  void _assertNoForm(SomMetaNode node, String path, Object object) {
    if (object is! DocSpecsSection) return;
    final form = object.form;
    if (form == null) return;
    if (form.values.values.every((v) => v == null || '$v'.isEmpty)) return;
    throw SpecYamlFormatException(
        'form values at "$path" but ${node.debugName} is not a @Form section');
  }

  /// The object's own scalar payload: the reflection-free contract first (it
  /// knows which member the class designates), falling back to
  /// [DocSpecsSection.content] for an object with no registered ops.
  static String? _scalarOf(Object object) =>
      yamlScalarOf(object) ??
      ((object is DocSpecsSection) ? object.content : null);
}
