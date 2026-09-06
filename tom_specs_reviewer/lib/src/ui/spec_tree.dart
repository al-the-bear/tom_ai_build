import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import '../model/review_store.dart';
import 'review_controls.dart';

/// The structural-path segments, the marker labels and the
/// `kRenderedAnnotations` coverage contract come from `tom_som_dart_runtime`
/// (`spec_annotation_display.dart`), shared with the spec editor so the two
/// surfaces cannot disagree about what the model's annotations mean. Only the
/// palette below — how each [SpecChipRole] is coloured on this light canvas —
/// is the reviewer's own.

/// The colour this surface gives each kind of statement a chip makes.
///
/// Kept here rather than in the shared layer because the two surfaces have
/// opposite backgrounds: these values are chosen for the reviewer's light
/// canvas and are illegible on the editor's dark shell.
Color _roleColor(SpecChipRole role) {
  switch (role) {
    case SpecChipRole.caseValue:
      return Colors.amber.shade800;
    case SpecChipRole.codeSpecMapped:
      return Colors.cyan.shade700;
    case SpecChipRole.codeSpecNone:
    case SpecChipRole.followUpNone:
      return Colors.orange;
    case SpecChipRole.codeSpecUnmapped:
      return Colors.grey;
    case SpecChipRole.followUpMapped:
      return Colors.deepPurple.shade400;
    case SpecChipRole.noArtifact:
      return Colors.blueGrey.shade400;
    case SpecChipRole.projection:
      return Colors.teal;
    case SpecChipRole.unused:
      return Colors.pink;
    case SpecChipRole.references:
      return Colors.blueGrey;
    case SpecChipRole.choiceComplete:
      return Colors.green.shade700;
    case SpecChipRole.choiceIncomplete:
    case SpecChipRole.choiceUncovered:
      return Colors.orange.shade800;
    case SpecChipRole.choiceBroken:
      return Colors.red;
    case SpecChipRole.handoff:
      return Colors.indigo;
    case SpecChipRole.structural:
      return Colors.grey;
  }
}

/// Paints the shared [SpecChip] descriptors in this surface's palette.
List<_Chip> _paint(List<SpecChip> chips) => [
      for (final c in chips) _Chip(c.label, _roleColor(c.role), tooltip: c.tooltip),
    ];

/// Shared tree-wide state read by every node via the element tree.
///
/// Carries the two hand-off **cut** flags (2b/2d) and the in-tree
/// **navigation** target (2c). Navigation is expressed as a chain of class
/// names ([navPathTypes]) from the document root down to [navTargetType];
/// nodes on that chain auto-expand and the endpoint is tagged with
/// [navTargetKey] so the tree can scroll it into view.
///
/// A class is a hand-off when it carries a `@DetailedIn` (detail lives in
/// another document) or a `@MapsTo` (the whole section maps onto another
/// document) marker pointing *away* from the current [rootType]. Cutting a
/// hand-off shows the section but suppresses its descending subsections.
class SpecTreeScope extends InheritedWidget {
  /// Cut at `@DetailedIn` hand-offs.
  final bool cutAtDetails;

  /// Cut at `@MapsTo` hand-offs.
  final bool cutAtMaps;

  /// Reveal the `@SerializationOrder` ordinal on every annotated row.
  ///
  /// Off by default: nearly five thousand members carry one, so showing them
  /// always would add a badge to almost every line for a question most reviews
  /// never ask. Lives on the scope — and therefore above the tree — so it keeps
  /// its value when the reviewer switches documents.
  final bool showSerializationOrder;

  /// The root document type currently rendered (used to decide whether a
  /// marker points *away* from this document).
  final String rootType;

  /// Whether [rootType] is a `@CodeSpecsProjection` (`codespecs_mapping.md`
  /// §8.4). Carried on the scope rather than threaded through every node
  /// because it is a property of the whole tree, and every node — down to the
  /// synthetic content rows — needs it to caveat its review controls.
  final bool isProjection;

  /// Class names on the navigation chain root→target (empty when not
  /// navigating).
  final Set<String> navPathTypes;

  /// The class the user navigated to, highlighted and scrolled into view.
  final String? navTargetType;

  /// Key attached to the single navigation-target row for `ensureVisible`.
  final GlobalKey? navTargetKey;

  /// Invoked when a hand-off marker is clicked: jump to the `targetRoot`
  /// document and reveal the `targetType` subsection within it.
  final void Function(String targetRoot, String targetType) onHandoffTap;

  /// Publishes the tree-wide view settings to every row below.
  ///
  /// Every argument is required: this scope is the single source of the
  /// settings each row reads, so a defaulted one would silently disagree with
  /// the toolbar that owns it.
  const SpecTreeScope({
    super.key,
    required this.cutAtDetails,
    required this.cutAtMaps,
    required this.showSerializationOrder,
    required this.rootType,
    required this.isProjection,
    required this.navPathTypes,
    required this.navTargetType,
    required this.navTargetKey,
    required this.onHandoffTap,
    required super.child,
  });

  /// The nearest enclosing scope, which every row depends on for its settings.
  ///
  /// Asserts rather than returning null: a row rendered outside the scope is a
  /// wiring mistake, and failing at the point of the mistake beats every row
  /// silently falling back to defaults.
  static SpecTreeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SpecTreeScope>();
    assert(scope != null, 'SpecTreeScope not found in context');
    return scope!;
  }

  /// Whether [cls] is a cut point under the current switch settings: it carries
  /// a marker pointing to a *different* document and that marker's switch is on.
  bool isCut(SpecClass cls) {
    final detailHandoff = cls.detailedIn != null && cls.detailedIn != rootType;
    final mapsHandoff = cls.mapsTo != null && cls.mapsTo != rootType;
    return (cutAtDetails && detailHandoff) || (cutAtMaps && mapsHandoff);
  }

  @override
  bool updateShouldNotify(SpecTreeScope old) =>
      cutAtDetails != old.cutAtDetails ||
      cutAtMaps != old.cutAtMaps ||
      showSerializationOrder != old.showSerializationOrder ||
      rootType != old.rootType ||
      isProjection != old.isProjection ||
      navTargetType != old.navTargetType ||
      !setEquals(navPathTypes, old.navPathTypes);
}

/// Computes the shortest chain of class names from [rootType] to [targetType]
/// by following `elementType` / `type` references (BFS over the class graph).
///
/// Returns the set of every class name on that path (inclusive). Empty when the
/// target is unreachable.
Set<String> pathToType(SpecModel model, String rootType, String targetType) {
  if (rootType == targetType) return {rootType};
  final parent = <String, String>{};
  final visited = <String>{rootType};
  final queue = <String>[rootType];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final cls = model.classNamed(current);
    if (cls == null) continue;
    for (final field in cls.fields) {
      for (final ref in [field.elementType, field.type]) {
        if (ref == null ||
            !model.classes.containsKey(ref) ||
            visited.contains(ref)) {
          continue;
        }
        visited.add(ref);
        parent[ref] = current;
        if (ref == targetType) {
          final path = <String>{targetType};
          var cur = targetType;
          while (parent.containsKey(cur)) {
            cur = parent[cur]!;
            path.add(cur);
          }
          return path;
        }
        queue.add(ref);
      }
    }
  }
  return const {};
}

/// Marks the root of a `@CodeSpecsProjection` document in the tree, echoing the
/// badge the root list shows, so the projection reads the same in both places.
List<_Chip> _projectionChips() => _paint(const [projectionChip]);

/// The chips stating where a node's subject matter is headed — see
/// `kindChips` in the shared display layer for why the three verdicts interact.
List<_Chip> _kindChips(
  KindLink? codeSpec,
  KindLink? followUp,
  NoArtifactLink? noArtifact,
) =>
    _paint(kindChips(codeSpec, followUp, noArtifact));

/// The chips a field row carries: which alternative of a closed choice it is,
/// then where its subtree is headed.
List<_Chip> _fieldChips(SpecField f) => _paint(fieldChips(f));

/// The `@Case` bindings alone, for the merged field+class row of a complex
/// alternative where the binding has nowhere else to be stated.
List<_Chip> _caseChips(SpecField f) => _paint(caseChips(f));

/// Renders the structure tree for a single document root.
class SpecTree extends StatefulWidget {
  /// The class graph the tree resolves member types against.
  final SpecModel model;

  /// The document root this tree is rooted at — one tree per root.
  final SpecRoot root;

  /// The observation store backing each row's markings.
  ///
  /// Keyed by structural path, so the same node reached through two documents
  /// carries two independent markings by design.
  final ReviewStore store;

  /// Suppress subsections at `@DetailedIn` hand-off points (2b).
  final bool cutAtDetails;

  /// Suppress subsections at `@MapsTo` hand-off points (2d).
  final bool cutAtMaps;

  /// Reveal `@SerializationOrder` ordinals on the rows that carry one.
  final bool showSerializationOrder;

  /// Class to reveal and scroll to within this document (2c).
  final String? navTargetType;

  /// Called when a hand-off marker is tapped, to switch documents.
  final void Function(String targetRoot, String targetType) onHandoffTap;

  /// Builds the tree for one document [root].
  ///
  /// Every argument is required, including the view switches: the tree is
  /// always rendered inside a toolbar that owns them, so a default here could
  /// only ever contradict it.
  const SpecTree({
    super.key,
    required this.model,
    required this.root,
    required this.store,
    required this.onHandoffTap,
    this.cutAtDetails = false,
    this.cutAtMaps = false,
    this.showSerializationOrder = false,
    this.navTargetType,
  });

  @override
  State<SpecTree> createState() => _SpecTreeState();
}

class _SpecTreeState extends State<SpecTree> {
  final GlobalKey _targetKey = GlobalKey();
  Set<String> _navPathTypes = const {};

  @override
  void initState() {
    super.initState();
    _recomputeNav();
  }

  @override
  void didUpdateWidget(SpecTree old) {
    super.didUpdateWidget(old);
    if (old.navTargetType != widget.navTargetType ||
        old.root.type != widget.root.type) {
      _recomputeNav();
    }
  }

  void _recomputeNav() {
    final target = widget.navTargetType;
    _navPathTypes = target == null
        ? const {}
        : pathToType(widget.model, widget.root.type, target);
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _targetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.1,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.model.classNamed(widget.root.type);
    if (cls == null) {
      return Center(
          child: Text('Root type "${widget.root.type}" not found in model'));
    }
    final onNavPath = widget.navTargetType != null &&
        _navPathTypes.contains(widget.root.type);
    return SpecTreeScope(
      cutAtDetails: widget.cutAtDetails,
      cutAtMaps: widget.cutAtMaps,
      showSerializationOrder: widget.showSerializationOrder,
      rootType: widget.root.type,
      isProjection: cls.isCodeSpecsProjection,
      navPathTypes: _navPathTypes,
      navTargetType: widget.navTargetType,
      navTargetKey: _targetKey,
      onHandoffTap: widget.onHandoffTap,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _ClassNode(
            model: widget.model,
            store: widget.store,
            cls: cls,
            path: widget.root.type,
            ancestors: {widget.root.type},
            depth: 0,
            initiallyExpanded: true,
            titleOverride: widget.root.title,
            onNavPath: onNavPath,
          ),
        ],
      ),
    );
  }
}

/// A complex-class instance: a header row plus its fields when expanded.
class _ClassNode extends StatefulWidget {
  final SpecModel model;
  final ReviewStore store;
  final SpecClass cls;
  final String path;
  final Set<String> ancestors;
  final int depth;
  final bool initiallyExpanded;

  /// Variable (field) name shown as the node label when this class is reached
  /// through a field, collapsing the field row and the class row into one.
  final String? titleOverride;

  /// Section id to prefer over the class's own (the owning field's id).
  final String? sectionIdOverride;

  /// Doc text to prefer over the class's own (the owning field's doc).
  final String? docOverride;

  /// The owning field, when this class node is the collapsed field+class row.
  ///
  /// A field-level `@CodeSpecKind` overrides the class's for that one usage, so
  /// the merged row must state the field's mapping when it has one and fall
  /// back to the class's otherwise.
  final SpecField? owningField;

  /// Render a `recursive` marker (this class re-enters an ancestor type).
  final bool recursive;

  /// True when this node sits on the active navigation chain.
  final bool onNavPath;

  const _ClassNode({
    super.key,
    required this.model,
    required this.store,
    required this.cls,
    required this.path,
    required this.ancestors,
    required this.depth,
    this.initiallyExpanded = false,
    this.titleOverride,
    this.sectionIdOverride,
    this.docOverride,
    this.owningField,
    this.recursive = false,
    this.onNavPath = false,
  });

  @override
  State<_ClassNode> createState() => _ClassNodeState();
}

class _ClassNodeState extends State<_ClassNode> {
  bool? _expanded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _expanded ??= widget.initiallyExpanded;
    // Force-expand along the navigation chain so the target is revealed.
    if (widget.onNavPath) _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final scope = SpecTreeScope.of(context);
    final cls = widget.cls;

    // 2b/2d: at a hand-off point pointing to *another* document, keep the
    // section (its content/form/scalar/enum) but suppress the descending
    // subsections.
    final cut = scope.isCut(cls);
    final visibleFields = cut
        ? cls.fields
            .where((f) =>
                f.kind != SpecFieldKind.list && f.kind != SpecFieldKind.complex)
            .toList()
        : cls.fields;
    // A section with subsections always has its own intro content. When the
    // class does not model a `content` field explicitly, inject one (mirrors
    // the list-section content part).
    final hasContentField =
        cls.fields.any((f) => f.kind == SpecFieldKind.content);
    final hasSubsections = cls.fields.any((f) =>
        f.kind == SpecFieldKind.list ||
        f.kind == SpecFieldKind.complex ||
        f.kind == SpecFieldKind.section);
    final injectContent = !hasContentField && hasSubsections;

    final hasChildren = visibleFields.isNotEmpty || injectContent;
    final expanded = _expanded ?? widget.initiallyExpanded;

    final isTarget = widget.onNavPath && scope.navTargetType == cls.name;
    final label = widget.titleOverride ?? cls.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeRow(
          rowKey: isTarget ? scope.navTargetKey : null,
          highlight: isTarget,
          depth: widget.depth,
          expandable: hasChildren,
          expanded: expanded,
          onToggle:
              hasChildren ? () => setState(() => _expanded = !expanded) : null,
          leadingIcon: Icons.account_tree,
          iconColor: Colors.indigo,
          label: label,
          typeLabel: cls.name,
          sectionId: widget.sectionIdOverride ?? cls.sectionId,
          chips: [
            if (cls.mapsTo != null)
              _Chip(
                'maps→ ${cls.mapsTo}',
                Colors.purple,
                onTap: () => scope.onHandoffTap(cls.mapsTo!, cls.name),
              ),
            if (cls.detailedIn != null)
              _Chip(
                'detail→ ${cls.detailedIn}',
                Colors.deepOrange,
                onTap: () => scope.onHandoffTap(cls.detailedIn!, cls.name),
              ),
            if (widget.recursive) _Chip('recursive', Colors.red),
            if (cut) _Chip('cut', Colors.red),
            if (cls.isCodeSpecsProjection) ..._projectionChips(),
            // A complex alternative collapses field and class into this one
            // row, so its `@Case` binding has nowhere else to be stated.
            if (widget.owningField != null) ..._caseChips(widget.owningField!),
            ..._kindChips(
              widget.owningField?.codeSpecKind ?? cls.codeSpecKind,
              widget.owningField?.followUpKind ?? cls.followUpKind,
              widget.owningField?.noArtifact ?? cls.noArtifact,
            ),
          ],
          doc: widget.docOverride ?? cls.doc ?? cls.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: cls.name,
          extras: SpecRowExtras.of(field: widget.owningField, cls: cls),
        ),
        if (expanded) ...[
          if (injectContent)
            _SectionContent(
              depth: widget.depth + 1,
              path: '${widget.path}/$kSectionContentSegment',
              nodeLabel: '$label content',
              store: widget.store,
            ),
          ..._buildFields(visibleFields),
        ],
      ],
    );
  }

  /// The class's fields in declaration order, with the `@OneOf` alternatives
  /// (if any) folded into a single choice-group node at the position of the
  /// first of them.
  ///
  /// Grouping can pull a later alternative forward past a common section — in
  /// the real model `selectOptions` moves ahead of `validation`. That is
  /// accepted: this tree is a structural-review view, not a serialization view,
  /// and showing which fields are mutually exclusive is worth more here than
  /// preserving declaration order among fields that are not.
  List<Widget> _buildFields(List<SpecField> visibleFields) {
    final group = widget.cls.oneOf;
    final caseNames = group == null
        ? const <String>{}
        : {for (final f in group.caseFields) f.name};
    // Only the alternatives that survived the hand-off cut may be shown.
    final groupedFields =
        visibleFields.where((f) => caseNames.contains(f.name)).toList();

    final widgets = <Widget>[];
    var groupEmitted = false;
    for (final field in visibleFields) {
      if (caseNames.contains(field.name)) {
        if (groupEmitted) continue;
        groupEmitted = true;
        widgets.add(_OneOfGroupNode(
          model: widget.model,
          store: widget.store,
          group: group!,
          caseFields: groupedFields,
          path: '${widget.path}/$kOneOfSegment',
          fieldPathBase: widget.path,
          ancestors: widget.ancestors,
          depth: widget.depth + 1,
          parentOnNavPath: widget.onNavPath,
        ));
        continue;
      }
      widgets.add(_FieldNode(
        model: widget.model,
        store: widget.store,
        field: field,
        path: '${widget.path}/${field.name}',
        ancestors: widget.ancestors,
        depth: widget.depth + 1,
        parentOnNavPath: widget.onNavPath,
      ));
    }
    return widgets;
  }
}

/// The `@OneOf` closed choice of a class, rendered as a group whose children
/// are the mutually exclusive alternatives (`codespecs_mapping.md` §8.2).
///
/// It is a node rather than a chip on each alternative because exclusivity is a
/// statement about the *set*: nesting the alternatives one level in is what
/// separates them from the common sections that apply to every case, and the
/// group header is the only place the discriminator and its coverage have to
/// live.
class _OneOfGroupNode extends StatefulWidget {
  final SpecModel model;
  final ReviewStore store;
  final OneOfGroup group;

  /// The alternatives actually rendered — [OneOfGroup.caseFields] minus any the
  /// hand-off cut removed.
  final List<SpecField> caseFields;

  /// Review path of the group itself.
  final String path;

  /// Owning class path the alternatives' own paths are built from, so grouping
  /// does not move an existing review entry.
  final String fieldPathBase;

  final Set<String> ancestors;
  final int depth;
  final bool parentOnNavPath;

  const _OneOfGroupNode({
    required this.model,
    required this.store,
    required this.group,
    required this.caseFields,
    required this.path,
    required this.fieldPathBase,
    required this.ancestors,
    required this.depth,
    required this.parentOnNavPath,
  });

  @override
  State<_OneOfGroupNode> createState() => _OneOfGroupNodeState();
}

class _OneOfGroupNodeState extends State<_OneOfGroupNode> {
  // Expanded by default: a collapsed group would hide the alternatives behind
  // an extra click, making the choice *less* visible than the ungrouped list it
  // replaces.
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeRow(
          depth: widget.depth,
          expandable: true,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
          leadingIcon: Icons.alt_route,
          iconColor: Colors.amber.shade800,
          label: 'one of: ${g.discriminator}',
          typeLabel: 'closed choice · ${widget.caseFields.length} alternatives',
          sectionId: null,
          chips: _paint(oneOfChips(g)),
          doc: g.note,
          store: widget.store,
          path: widget.path,
          nodeLabel: 'one of ${g.discriminator}',
        ),
        if (_expanded)
          for (final field in widget.caseFields)
            _FieldNode(
              model: widget.model,
              store: widget.store,
              field: field,
              path: '${widget.fieldPathBase}/${field.name}',
              ancestors: widget.ancestors,
              depth: widget.depth + 1,
              parentOnNavPath: widget.parentOnNavPath,
            ),
      ],
    );
  }
}

/// A single field. Rendering depends on [SpecField.kind].
class _FieldNode extends StatefulWidget {
  final SpecModel model;
  final ReviewStore store;
  final SpecField field;
  final String path;
  final Set<String> ancestors;
  final int depth;

  /// True when the *owning class* is on the navigation chain — a child class
  /// reached through this field is on the chain iff its name is also in
  /// [SpecTreeScope.navPathTypes].
  final bool parentOnNavPath;

  const _FieldNode({
    required this.model,
    required this.store,
    required this.field,
    required this.path,
    required this.ancestors,
    required this.depth,
    this.parentOnNavPath = false,
  });

  @override
  State<_FieldNode> createState() => _FieldNodeState();
}

class _FieldNodeState extends State<_FieldNode> {
  bool _expanded = false;

  /// The complex class this field descends into, if any.
  String? _childClassName() {
    final f = widget.field;
    if (f.kind == SpecFieldKind.complex) return f.type;
    if (f.kind == SpecFieldKind.list && f.elementIsComplex) {
      return f.elementType;
    }
    return null;
  }

  bool _childOnNavPath(SpecTreeScope scope) {
    final child = _childClassName();
    return widget.parentOnNavPath &&
        child != null &&
        scope.navPathTypes.contains(child);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-expand the field when its child class is on the navigation chain.
    if (_childOnNavPath(SpecTreeScope.of(context))) _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    switch (f.kind) {
      case SpecFieldKind.list:
        return _buildList(f);
      case SpecFieldKind.complex:
        return _buildComplex(f);
      case SpecFieldKind.form:
        return _buildForm(f);
      case SpecFieldKind.content:
        return _buildContent(f);
      case SpecFieldKind.section:
        return _buildSection(f);
      case SpecFieldKind.enumValue:
        return _buildEnum(f);
      case SpecFieldKind.scalar:
        return _buildScalar(f);
    }
  }

  // --- list ---------------------------------------------------------------
  Widget _buildList(SpecField f) {
    final elementType = f.elementType;
    final cls =
        f.elementIsComplex ? widget.model.classNamed(elementType) : null;
    final childOnPath = _childOnNavPath(SpecTreeScope.of(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeRow(
          depth: widget.depth,
          expandable: true,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
          leadingIcon: Icons.format_list_bulleted,
          iconColor: Colors.teal,
          label: f.name,
          typeLabel: 'List<${elementType ?? '?'}>'
              '${f.min != null ? '  min ${f.min}' : ''}',
          sectionId: f.sectionId,
          chips: _fieldChips(f),
          doc: f.doc ?? f.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: '${f.name} (list)',
          extras: SpecRowExtras.of(field: f),
        ),
        if (_expanded) ...[
          // A list is itself a document section: show its intro content first.
          _SectionContent(
            depth: widget.depth + 1,
            path: '${widget.path}/$kSectionContentSegment',
            nodeLabel: '${f.name} content',
            store: widget.store,
          ),
          for (var i = 0; i < 3; i++)
            _buildListItem(f, cls, elementType, i, childOnPath),
        ],
      ],
    );
  }

  Widget _buildListItem(SpecField f, SpecClass? cls, String? elementType,
      int index, bool childOnPath) {
    final itemPath = '${widget.path}/$kListItemSegment';
    if (cls != null) {
      // Complex element: identical substructure, one shared review path.
      final recursive = widget.ancestors.contains(cls.name);
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ItemBanner(depth: widget.depth + 1, index: index),
            _ClassNode(
              key: ValueKey('${widget.path}#$index'),
              model: widget.model,
              store: widget.store,
              cls: cls,
              path: itemPath,
              ancestors: recursive
                  ? widget.ancestors
                  : {...widget.ancestors, cls.name},
              depth: widget.depth + 1,
              // Only the first instance carries the nav target (single key).
              onNavPath: childOnPath && index == 0,
            ),
          ],
        ),
      );
    }
    // Scalar element.
    return _NodeRow(
      depth: widget.depth + 1,
      expandable: false,
      expanded: false,
      onToggle: null,
      leadingIcon: Icons.label_outline,
      iconColor: Colors.blueGrey,
      label: 'Item ${index + 1}',
      typeLabel: elementType ?? 'value',
      sectionId: null,
      chips: const [],
      doc: null,
      store: widget.store,
      path: itemPath,
      nodeLabel: '${f.name} item',
    );
  }

  // --- complex ------------------------------------------------------------
  Widget _buildComplex(SpecField f) {
    final cls = widget.model.classNamed(f.type);
    if (cls == null) {
      return _NodeRow(
        depth: widget.depth,
        expandable: false,
        expanded: false,
        onToggle: null,
        leadingIcon: Icons.help_outline,
        iconColor: Colors.grey,
        label: f.name,
        typeLabel: '${f.type ?? '?'} (unresolved)',
        sectionId: f.sectionId,
        chips: _fieldChips(f),
        doc: f.doc ?? f.help,
        store: widget.store,
        path: widget.path,
        nodeLabel: f.name,
        extras: SpecRowExtras.of(field: f),
      );
    }
    // The field (variable) and the target class are the same element, so they
    // collapse to a single node: the class node carries the field name as its
    // label and the field's id/doc, and exposes the class's fields directly.
    final recursive = widget.ancestors.contains(cls.name);
    final childOnPath = _childOnNavPath(SpecTreeScope.of(context));
    return _ClassNode(
      model: widget.model,
      store: widget.store,
      cls: cls,
      path: widget.path,
      ancestors:
          recursive ? widget.ancestors : {...widget.ancestors, cls.name},
      depth: widget.depth,
      titleOverride: f.name,
      sectionIdOverride: f.sectionId,
      docOverride: f.doc ?? f.help,
      owningField: f,
      recursive: recursive,
      onNavPath: childOnPath,
    );
  }

  // --- form ---------------------------------------------------------------
  Widget _buildForm(SpecField f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeRow(
          depth: widget.depth,
          expandable: false,
          expanded: false,
          onToggle: null,
          leadingIcon: Icons.dynamic_form,
          iconColor: Colors.deepPurple,
          label: f.name,
          typeLabel: 'form · ${f.formFields.length} fields',
          sectionId: f.sectionId,
          chips: _fieldChips(f),
          doc: f.doc ?? f.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: '${f.name} (form)',
          extras: SpecRowExtras.of(field: f),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: 16.0 * (widget.depth + 1) + 24, top: 2, bottom: 4),
          child: _FormPanel(
            fields: f.formFields,
            store: widget.store,
            basePath: widget.path,
          ),
        ),
      ],
    );
  }

  // --- content (String) ---------------------------------------------------
  Widget _buildContent(SpecField f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeRow(
          depth: widget.depth,
          expandable: false,
          expanded: false,
          onToggle: null,
          leadingIcon: Icons.notes,
          iconColor: Colors.blue,
          label: f.name,
          typeLabel: 'content · ${f.contentType ?? 'text'}',
          sectionId: f.sectionId,
          chips: _fieldChips(f),
          doc: f.doc ?? f.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: '${f.name} (content)',
          extras: SpecRowExtras.of(field: f),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: 16.0 * (widget.depth + 1) + 24, top: 2, bottom: 4, right: 8),
          child: TextField(
            enabled: false,
            minLines: 3,
            maxLines: 3,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              hintText: f.help ?? f.doc ?? 'Content (${f.contentType ?? 'text'})',
            ),
          ),
        ),
      ],
    );
  }

  // --- section ------------------------------------------------------------
  Widget _buildSection(SpecField f) {
    return _NodeRow(
      depth: widget.depth,
      expandable: false,
      expanded: false,
      onToggle: null,
      leadingIcon: Icons.article_outlined,
      iconColor: Colors.brown,
      label: f.name,
      typeLabel: 'section · ${f.contentType ?? 'text'}',
      sectionId: f.sectionId,
      chips: _fieldChips(f),
      doc: f.doc ?? f.help,
      store: widget.store,
      path: widget.path,
      nodeLabel: '${f.name} (section)',
      extras: SpecRowExtras.of(field: f),
    );
  }

  // --- enum ---------------------------------------------------------------
  Widget _buildEnum(SpecField f) {
    return _NodeRow(
      depth: widget.depth,
      expandable: false,
      expanded: false,
      onToggle: null,
      leadingIcon: Icons.toggle_on,
      iconColor: Colors.green,
      label: f.name,
      typeLabel: 'enum · ${f.enumValues.join(', ')}',
      sectionId: f.sectionId,
      chips: _fieldChips(f),
      doc: f.doc ?? f.help,
      store: widget.store,
      path: widget.path,
      nodeLabel: '${f.name} (enum)',
      extras: SpecRowExtras.of(field: f),
    );
  }

  // --- scalar -------------------------------------------------------------
  Widget _buildScalar(SpecField f) {
    return _NodeRow(
      depth: widget.depth,
      expandable: false,
      expanded: false,
      onToggle: null,
      leadingIcon: Icons.short_text,
      iconColor: Colors.blueGrey,
      label: f.name,
      typeLabel: f.type ?? 'value',
      sectionId: f.sectionId,
      chips: _fieldChips(f),
      doc: f.doc ?? f.help,
      store: widget.store,
      path: widget.path,
      nodeLabel: f.name,
      extras: SpecRowExtras.of(field: f),
    );
  }
}

/// A small coloured chip used for annotations (mapsTo, recursive, …).
///
/// When [onTap] is set the chip becomes clickable (used for hand-off markers).
/// [tooltip] carries detail too long for the chip itself — the `@CodeSpecKind`
/// mapping note, for instance, which explains *why* a section maps where it
/// does and would otherwise have nowhere to go.
class _Chip {
  final String text;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;
  const _Chip(this.text, this.color, {this.onTap, this.tooltip});
}

/// The common single-line header used by every node kind.
class _NodeRow extends StatefulWidget {
  final Key? rowKey;
  final bool highlight;
  final int depth;
  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggle;
  final IconData leadingIcon;
  final Color iconColor;
  final String label;
  final String typeLabel;
  final String? sectionId;
  final List<_Chip> chips;
  final String? doc;
  final ReviewStore store;
  final String path;
  final String nodeLabel;

  /// The annotations rendered beside the structural label. Defaults to
  /// [SpecRowExtras.none] for the synthetic rows that have no model node.
  final SpecRowExtras extras;

  const _NodeRow({
    this.rowKey,
    this.highlight = false,
    required this.depth,
    required this.expandable,
    required this.expanded,
    required this.onToggle,
    required this.leadingIcon,
    required this.iconColor,
    required this.label,
    required this.typeLabel,
    required this.sectionId,
    required this.chips,
    required this.doc,
    required this.store,
    required this.path,
    required this.nodeLabel,
    this.extras = SpecRowExtras.none,
  });

  @override
  State<_NodeRow> createState() => _NodeRowState();
}

class _NodeRowState extends State<_NodeRow> {
  /// Whether the provenance panel is open. Per row and off by default — the
  /// standards are long prose, and 2285 fields carry them.
  bool _refsOpen = false;

  @override
  Widget build(BuildContext context) {
    final extras = widget.extras;
    return Container(
      key: widget.rowKey,
      color: widget.highlight ? Colors.amber.withValues(alpha: 0.25) : null,
      child: InkWell(
        onTap: widget.onToggle,
        child: Padding(
          padding:
              EdgeInsets.only(left: 16.0 * widget.depth, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: widget.expandable
                    ? Icon(
                        widget.expanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 20,
                      )
                    : const SizedBox.shrink(),
              ),
              Icon(widget.leadingIcon, size: 16, color: widget.iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (SpecTreeScope.of(context).showSerializationOrder &&
                            extras.serializationOrder != null)
                          _Badge('#${extras.serializationOrder}',
                              tooltip: 'Serialization order'),
                        Text(widget.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              // An unused section is a keep-or-drop candidate;
                              // striking it makes that legible while scrolling,
                              // which a chip among seven others does not.
                              decoration: extras.unused
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                        if (extras.headline != null)
                          Text('“${extras.headline}”',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.indigo.shade400)),
                        ReviewControls(
                          store: widget.store,
                          path: widget.path,
                          nodeLabel: widget.nodeLabel,
                          isProjection: SpecTreeScope.of(context).isProjection,
                        ),
                        Text(widget.typeLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace')),
                        if (widget.sectionId != null)
                          _Badge(widget.sectionId!),
                        if (extras.sectionIdPattern != null)
                          _Badge(extras.sectionIdPattern!,
                              color: Colors.blueGrey.shade50,
                              tooltip: 'Section-id pattern for each item'),
                        if (extras.unused)
                          _ChipWidget(_Chip(unusedChip.label,
                              _roleColor(unusedChip.role),
                              tooltip: unusedChip.tooltip)),
                        for (final chip in widget.chips) _ChipWidget(chip),
                        if (extras.hasReferences)
                          _ChipWidget(_Chip(referencesChip.label,
                              _roleColor(referencesChip.role),
                              tooltip: referencesChip.tooltip,
                              onTap: () =>
                                  setState(() => _refsOpen = !_refsOpen))),
                        if (extras.comment != null)
                          Text('← ${extras.comment}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade900,
                                  fontStyle: FontStyle.italic)),
                      ],
                    ),
                    if (widget.doc != null && widget.doc!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          widget.doc!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    if (_refsOpen && extras.hasReferences)
                      _ReferencesPanel(extras: extras),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small grey monospace badge — the section id, its pattern, or the
/// serialization ordinal.
class _Badge extends StatelessWidget {
  final String text;
  final Color? color;
  final String? tooltip;

  const _Badge(this.text, {this.color, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
    );
    return tooltip == null ? body : Tooltip(message: tooltip!, child: body);
  }
}

/// The provenance a node records: what the section means, which public
/// standards it derives from, and what it cross-references in the model.
///
/// Shown only on demand — the standards are full sentences, and inlining them
/// on the 2285 fields that carry them would drown the structure the tree exists
/// to show.
class _ReferencesPanel extends StatelessWidget {
  final SpecRowExtras extras;

  const _ReferencesPanel({required this.extras});

  @override
  Widget build(BuildContext context) {
    final refs = extras.standardReferences;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blueGrey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (refs?.connotation != null)
              Text(refs!.connotation!,
                  style: const TextStyle(fontSize: 11)),
            for (final standard in refs?.standards ?? const <String>[])
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $standard',
                    style:
                        TextStyle(fontSize: 11, color: Colors.blueGrey.shade700)),
              ),
            if (extras.reference != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('→ references ${extras.reference}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade700,
                        fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Renders a single [_Chip], clickable when it carries an `onTap`.
class _ChipWidget extends StatelessWidget {
  final _Chip chip;
  const _ChipWidget(this.chip);

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: chip.color.withValues(alpha: chip.onTap != null ? 0.22 : 0.15),
        borderRadius: BorderRadius.circular(3),
        border: chip.onTap != null
            ? Border.all(color: chip.color.withValues(alpha: 0.6))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chip.onTap != null) ...[
            Icon(Icons.open_in_new, size: 10, color: chip.color),
            const SizedBox(width: 2),
          ],
          Text(chip.text,
              style: TextStyle(
                  fontSize: 10,
                  color: chip.color,
                  fontWeight:
                      chip.onTap != null ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
    final interactive = chip.onTap == null
        ? body
        : InkWell(
            borderRadius: BorderRadius.circular(3),
            onTap: chip.onTap,
            child: body,
          );
    final tooltip = chip.tooltip;
    if (tooltip == null || tooltip.trim().isEmpty) return interactive;
    return Tooltip(message: tooltip, child: interactive);
  }
}

/// A faint banner separating the three rendered instances of a list element.
class _ItemBanner extends StatelessWidget {
  final int depth;
  final int index;
  const _ItemBanner({required this.depth, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * depth + 24, top: 4, bottom: 2),
      child: Text('Item ${index + 1}',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade300,
              letterSpacing: 0.5)),
    );
  }
}

/// The intro content paragraph that every list/subsection-bearing section
/// carries. It renders a `content`-styled header row plus a disabled three-line
/// text area, and is independently reviewable through its own `§content` path.
class _SectionContent extends StatelessWidget {
  final int depth;
  final String path;
  final String nodeLabel;
  final ReviewStore store;

  const _SectionContent({
    required this.depth,
    required this.path,
    required this.nodeLabel,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeRow(
          depth: depth,
          expandable: false,
          expanded: false,
          onToggle: null,
          leadingIcon: Icons.notes,
          iconColor: Colors.blue,
          label: 'content',
          typeLabel: 'content · text',
          sectionId: null,
          chips: const [],
          doc: null,
          store: store,
          path: path,
          nodeLabel: nodeLabel,
        ),
        Padding(
          padding: EdgeInsets.only(
              left: 16.0 * (depth + 1) + 24, top: 2, bottom: 4, right: 8),
          child: const TextField(
            enabled: false,
            minLines: 3,
            maxLines: 3,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Content (text)',
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders all fields of a `@Form` content section so they are visible at once.
///
/// Each form field is independently reviewable: its [ReviewControls] use the
/// structural path `<formPath>/<fieldName>`, so the reviewer can comment on and
/// flag individual fields (e.g. "convert to content subsection").
class _FormPanel extends StatelessWidget {
  final List<FormFieldSpec> fields;
  final ReviewStore store;
  final String basePath;

  const _FormPanel({
    required this.fields,
    required this.store,
    required this.basePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.04),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final field in fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(field.label,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      ReviewControls(
                        store: store,
                        isProjection: SpecTreeScope.of(context).isProjection,
                        path: '$basePath/${field.name}',
                        nodeLabel: 'form field: ${field.label}',
                      ),
                      Text(field.type,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace')),
                      if (field.required)
                        const Text('*',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: field.hint ?? field.label,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
