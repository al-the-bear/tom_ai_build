import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import '../model/review_store.dart';
import 'review_controls.dart';

/// Structural-path segment standing in for "any element of this list".
///
/// All visual instances of a list element share this one segment so a review
/// decision targets the *structure*, not a particular rendered instance.
const String kListItemSegment = '§item';

/// Structural-path segment for a list section's own intro content.
///
/// In TomSpecs every list *is* a document section, so besides its repeated
/// items it always carries an introductory content paragraph. This segment
/// keys that paragraph for review, distinct from the list and its items.
const String kSectionContentSegment = '§content';

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

  /// The root document type currently rendered (used to decide whether a
  /// marker points *away* from this document).
  final String rootType;

  /// Class names on the navigation chain root→target (empty when not
  /// navigating).
  final Set<String> navPathTypes;

  /// The class the user navigated to, highlighted and scrolled into view.
  final String? navTargetType;

  /// Key attached to the single navigation-target row for `ensureVisible`.
  final GlobalKey? navTargetKey;

  /// Invoked when a hand-off marker is clicked: jump to [targetRoot] document
  /// and reveal the [targetType] subsection within it.
  final void Function(String targetRoot, String targetType) onHandoffTap;

  const SpecTreeScope({
    super.key,
    required this.cutAtDetails,
    required this.cutAtMaps,
    required this.rootType,
    required this.navPathTypes,
    required this.navTargetType,
    required this.navTargetKey,
    required this.onHandoffTap,
    required super.child,
  });

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
      rootType != old.rootType ||
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

/// Renders the structure tree for a single document root.
class SpecTree extends StatefulWidget {
  final SpecModel model;
  final SpecRoot root;
  final ReviewStore store;

  /// Suppress subsections at `@DetailedIn` hand-off points (2b).
  final bool cutAtDetails;

  /// Suppress subsections at `@MapsTo` hand-off points (2d).
  final bool cutAtMaps;

  /// Class to reveal and scroll to within this document (2c).
  final String? navTargetType;

  /// Called when a hand-off marker is tapped, to switch documents.
  final void Function(String targetRoot, String targetType) onHandoffTap;

  const SpecTree({
    super.key,
    required this.model,
    required this.root,
    required this.store,
    required this.onHandoffTap,
    this.cutAtDetails = false,
    this.cutAtMaps = false,
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
      rootType: widget.root.type,
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
          ],
          doc: widget.docOverride ?? cls.doc ?? cls.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: cls.name,
        ),
        if (expanded) ...[
          if (injectContent)
            _SectionContent(
              depth: widget.depth + 1,
              path: '${widget.path}/$kSectionContentSegment',
              nodeLabel: '$label content',
              store: widget.store,
            ),
          for (final field in visibleFields)
            _FieldNode(
              model: widget.model,
              store: widget.store,
              field: field,
              path: '${widget.path}/${field.name}',
              ancestors: widget.ancestors,
              depth: widget.depth + 1,
              parentOnNavPath: widget.onNavPath,
            ),
        ],
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
          sectionId: f.sectionId ?? f.sectionIdPattern,
          chips: const [],
          doc: f.doc ?? f.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: '${f.name} (list)',
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
        chips: const [],
        doc: f.doc ?? f.help,
        store: widget.store,
        path: widget.path,
        nodeLabel: f.name,
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
          chips: const [],
          doc: f.doc ?? f.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: '${f.name} (form)',
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
          chips: const [],
          doc: f.doc ?? f.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: '${f.name} (content)',
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
      chips: const [],
      doc: f.doc ?? f.help,
      store: widget.store,
      path: widget.path,
      nodeLabel: '${f.name} (section)',
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
      chips: const [],
      doc: f.doc ?? f.help,
      store: widget.store,
      path: widget.path,
      nodeLabel: '${f.name} (enum)',
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
      chips: const [],
      doc: f.doc ?? f.help,
      store: widget.store,
      path: widget.path,
      nodeLabel: f.name,
    );
  }
}

/// A small coloured chip used for annotations (mapsTo, recursive, …).
///
/// When [onTap] is set the chip becomes clickable (used for hand-off markers).
class _Chip {
  final String text;
  final Color color;
  final VoidCallback? onTap;
  const _Chip(this.text, this.color, {this.onTap});
}

/// The common single-line header used by every node kind.
class _NodeRow extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: rowKey,
      color: highlight ? Colors.amber.withValues(alpha: 0.25) : null,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: EdgeInsets.only(left: 16.0 * depth, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: expandable
                    ? Icon(
                        expanded ? Icons.expand_more : Icons.chevron_right,
                        size: 20,
                      )
                    : const SizedBox.shrink(),
              ),
              Icon(leadingIcon, size: 16, color: iconColor),
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
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        ReviewControls(
                            store: store, path: path, nodeLabel: nodeLabel),
                        Text(typeLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace')),
                        if (sectionId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(sectionId!,
                                style: const TextStyle(
                                    fontSize: 10, fontFamily: 'monospace')),
                          ),
                        for (final chip in chips) _ChipWidget(chip),
                      ],
                    ),
                    if (doc != null && doc!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          doc!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
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
    if (chip.onTap == null) return body;
    return InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: chip.onTap,
      child: body,
    );
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
