import 'package:flutter/material.dart';

import '../model/review_store.dart';
import '../model/spec_model.dart';
import 'review_controls.dart';

/// Structural-path segment standing in for "any element of this list".
///
/// All visual instances of a list element share this one segment so a review
/// decision targets the *structure*, not a particular rendered instance.
const String kListItemSegment = '§item';

/// Renders the structure tree for a single document root.
class SpecTree extends StatelessWidget {
  final SpecModel model;
  final SpecRoot root;
  final ReviewStore store;

  const SpecTree({
    super.key,
    required this.model,
    required this.root,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final cls = model.classNamed(root.type);
    if (cls == null) {
      return Center(child: Text('Root type "${root.type}" not found in model'));
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _ClassNode(
          model: model,
          store: store,
          cls: cls,
          path: root.type,
          ancestors: {root.type},
          depth: 0,
          initiallyExpanded: true,
          titleOverride: root.title,
        ),
      ],
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
  final String? titleOverride;

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
  });

  @override
  State<_ClassNode> createState() => _ClassNodeState();
}

class _ClassNodeState extends State<_ClassNode> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final cls = widget.cls;
    final hasFields = cls.fields.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeRow(
          depth: widget.depth,
          expandable: hasFields,
          expanded: _expanded,
          onToggle: hasFields ? () => setState(() => _expanded = !_expanded) : null,
          leadingIcon: Icons.account_tree,
          iconColor: Colors.indigo,
          label: widget.titleOverride ?? cls.name,
          typeLabel: cls.name,
          sectionId: cls.sectionId,
          chips: [
            if (cls.mapsTo != null) _Chip('maps→ ${cls.mapsTo}', Colors.purple),
            if (cls.detailedIn != null)
              _Chip('detail→ ${cls.detailedIn}', Colors.deepOrange),
          ],
          doc: cls.doc ?? cls.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: cls.name,
        ),
        if (_expanded)
          for (final field in cls.fields)
            _FieldNode(
              model: widget.model,
              store: widget.store,
              field: field,
              path: '${widget.path}/${field.name}',
              ancestors: widget.ancestors,
              depth: widget.depth + 1,
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

  const _FieldNode({
    required this.model,
    required this.store,
    required this.field,
    required this.path,
    required this.ancestors,
    required this.depth,
  });

  @override
  State<_FieldNode> createState() => _FieldNodeState();
}

class _FieldNodeState extends State<_FieldNode> {
  bool _expanded = false;

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
        if (_expanded)
          for (var i = 0; i < 3; i++)
            _buildListItem(f, cls, elementType, i),
      ],
    );
  }

  Widget _buildListItem(
      SpecField f, SpecClass? cls, String? elementType, int index) {
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
    final recursive = widget.ancestors.contains(cls.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeRow(
          depth: widget.depth,
          expandable: true,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
          leadingIcon: Icons.account_tree_outlined,
          iconColor: Colors.indigo,
          label: f.name,
          typeLabel: cls.name,
          sectionId: f.sectionId,
          chips: [if (recursive) _Chip('recursive', Colors.red)],
          doc: f.doc ?? f.help,
          store: widget.store,
          path: widget.path,
          nodeLabel: f.name,
        ),
        if (_expanded)
          _ClassNode(
            model: widget.model,
            store: widget.store,
            cls: cls,
            path: widget.path,
            ancestors: recursive
                ? widget.ancestors
                : {...widget.ancestors, cls.name},
            depth: widget.depth + 1,
            initiallyExpanded: true,
          ),
      ],
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
          padding: EdgeInsets.only(left: 16.0 * (widget.depth + 1) + 24, top: 2, bottom: 4),
          child: _FormPanel(fields: f.formFields),
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
class _Chip {
  final String text;
  final Color color;
  const _Chip(this.text, this.color);
}

/// The common single-line header used by every node kind.
class _NodeRow extends StatelessWidget {
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
    return InkWell(
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
                      for (final chip in chips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: chip.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(chip.text,
                              style: TextStyle(
                                  fontSize: 10, color: chip.color)),
                        ),
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
            ReviewIndicator(
                store: store, path: path, nodeLabel: nodeLabel),
          ],
        ),
      ),
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

/// Renders all fields of a `@Form` content section so they are visible at once.
class _FormPanel extends StatelessWidget {
  final List<FormFieldSpec> fields;
  const _FormPanel({required this.fields});

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
                  Row(
                    children: [
                      Text(field.label,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text(field.type,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace')),
                      if (field.required)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('*',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ),
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
