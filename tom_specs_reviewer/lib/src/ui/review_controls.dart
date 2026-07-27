import 'package:flutter/material.dart';

import '../model/review_store.dart';

/// Badge text for a `@CodeSpecsProjection` root (`codespecs_mapping.md` §8.4).
const String kProjectionLabel = 'projection';

/// Why a projection is shallow, in the reviewer's own terms.
///
/// A projection re-references subtrees authored elsewhere rather than
/// specifying anything itself, which is why the validator exempts it from the
/// detail-count check. Stating that where the reviewer works turns the
/// exemption from tribal knowledge into something visible on screen.
const String kProjectionExplanation =
    'CodeSpecs projection — this root re-references sections authored '
    'elsewhere, so shallow nodes are correct by construction and the '
    'detail-count check does not apply.';

/// Replacement subtitle for the "Add details" control inside a projection.
///
/// The control stays usable — disabling it would trap a value recorded in an
/// earlier session with no way to clear it — but it must not read as an
/// invitation.
const String kProjectionDetailSubtitle =
    'Detail belongs on the source section, not on this re-reference';

/// Colour associated with each review scope, used for the indicator dot.
Color scopeColor(ReviewScope scope) {
  switch (scope) {
    case ReviewScope.none:
      return Colors.grey.shade400;
    case ReviewScope.onlyPd:
      return Colors.blue.shade600;
    case ReviewScope.global:
      return Colors.green.shade600;
    case ReviewScope.globalWithAdaptations:
      return Colors.orange.shade700;
  }
}

/// Inline review controls shown on every tree node, immediately behind its
/// headline.
///
/// Layout: an **edit** button (scope dot + pencil — opens the flags/comment
/// dialog), a separate **reviewed** checkmark toggle (progress tracking), and a
/// compact **summary** of the comment and any checked boxes. All three reflect
/// the live [ReviewEntry] for [path] and update when the store changes.
class ReviewControls extends StatelessWidget {
  final ReviewStore store;
  final String path;
  final String nodeLabel;

  /// Whether this node sits inside a `@CodeSpecsProjection` root, in which case
  /// the detail-oriented controls are caveated rather than offered plainly.
  final bool isProjection;

  const ReviewControls({
    super.key,
    required this.store,
    required this.path,
    required this.nodeLabel,
    this.isProjection = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final entry = store.entryFor(path);
        final scope = entry?.scope ?? ReviewScope.none;
        final reviewed = entry?.reviewed ?? false;
        final summary = _summary(entry);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: _tooltip(entry),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => _openDialog(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dot(scope, entry?.stopHere ?? false),
                      const SizedBox(width: 2),
                      Icon(Icons.edit_note,
                          size: 16, color: Colors.grey.shade700),
                    ],
                  ),
                ),
              ),
            ),
            Tooltip(
              message:
                  reviewed ? 'Reviewed — click to clear' : 'Mark as reviewed',
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () =>
                    store.update(path, (e) => e.reviewed = !e.reviewed),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Icon(
                    reviewed
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    size: 17,
                    color: reviewed
                        ? Colors.green.shade600
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            if (summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  summary,
                  style: TextStyle(
                      fontSize: 11, color: Colors.blueGrey.shade700),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _dot(ReviewScope scope, bool stopHere) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: scopeColor(scope),
        shape: BoxShape.circle,
        border: stopHere
            ? Border.all(color: Colors.red.shade700, width: 2.5)
            : Border.all(color: Colors.black26, width: 1),
      ),
    );
  }

  /// One-line summary of the comment and checked boxes, shown behind the
  /// buttons.
  String _summary(ReviewEntry? entry) {
    if (entry == null || entry.isEmpty) return '';
    final parts = <String>[];
    if (entry.scope != ReviewScope.none) parts.add(entry.scope.label);
    if (entry.stopHere) parts.add('stop');
    if (entry.addDetails) parts.add('+details');
    if (entry.mustBeList) parts.add('must-be-list');
    if (entry.singleEntry) parts.add('single-entry');
    if (entry.mustBeContentString) parts.add('content-not-form');
    if (entry.convertFormToContent) parts.add('→content-subsection');
    if (entry.comment.trim().isNotEmpty) {
      var c = entry.comment.trim().replaceAll('\n', ' ');
      if (c.length > 60) c = '${c.substring(0, 60)}…';
      parts.add('“$c”');
    }
    return parts.join(' · ');
  }

  String _tooltip(ReviewEntry? entry) {
    if (entry == null || entry.isEmpty) return 'Not reviewed — click to set';
    final summary = _summary(entry);
    return summary.isEmpty ? 'Edit review' : summary;
  }

  void _openDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _ReviewDialog(
        store: store,
        path: path,
        nodeLabel: nodeLabel,
        isProjection: isProjection,
      ),
    );
  }
}

/// Editing dialog for a single node's review entry. Each change is written
/// straight through to the store (which persists immediately).
class _ReviewDialog extends StatefulWidget {
  final ReviewStore store;
  final String path;
  final String nodeLabel;
  final bool isProjection;

  const _ReviewDialog({
    required this.store,
    required this.path,
    required this.nodeLabel,
    required this.isProjection,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late final TextEditingController _comment;

  @override
  void initState() {
    super.initState();
    final entry = widget.store.entryFor(widget.path);
    _comment = TextEditingController(text: entry?.comment ?? '');
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  ReviewEntry get _current =>
      widget.store.entryFor(widget.path) ?? ReviewEntry();

  /// Banner shown above the detail controls inside a projection root.
  Widget _projectionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        border: Border.all(color: Colors.teal.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.alt_route, size: 16, color: Colors.teal.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              kProjectionExplanation,
              style: TextStyle(fontSize: 12, color: Colors.teal.shade900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _current;
    return AlertDialog(
      title: const Text('Review node'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.nodeLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              SelectableText(
                widget.path,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace'),
              ),
              const Divider(height: 20),
              const Text('Scope',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              RadioGroup<ReviewScope>(
                groupValue: entry.scope,
                onChanged: (value) {
                  if (value == null) return;
                  widget.store.update(widget.path, (e) => e.scope = value);
                  setState(() {});
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final scope in ReviewScope.values)
                      RadioListTile<ReviewScope>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: scope,
                        title: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: scopeColor(scope),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(scope.label),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 20),
              if (widget.isProjection) _projectionBanner(),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: entry.stopHere,
                title: const Text('Stop here'),
                subtitle: Text(widget.isProjection
                    ? 'Do not descend further into this re-referenced branch'
                    : 'Do not descend further into this branch'),
                onChanged: (value) {
                  widget.store
                      .update(widget.path, (e) => e.stopHere = value ?? false);
                  setState(() {});
                },
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: entry.addDetails,
                title: const Text('Add details'),
                subtitle: Text(widget.isProjection
                    ? kProjectionDetailSubtitle
                    : 'This node needs further specification'),
                onChanged: (value) {
                  widget.store.update(
                      widget.path, (e) => e.addDetails = value ?? false);
                  setState(() {});
                },
              ),
              const Divider(height: 20),
              const Text('Structure',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: entry.mustBeList,
                title: const Text('Must be a list'),
                onChanged: (value) {
                  widget.store.update(
                      widget.path, (e) => e.mustBeList = value ?? false);
                  setState(() {});
                },
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: entry.singleEntry,
                title: const Text('Is only a single entry (not a list)'),
                onChanged: (value) {
                  widget.store.update(
                      widget.path, (e) => e.singleEntry = value ?? false);
                  setState(() {});
                },
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: entry.mustBeContentString,
                title: const Text('Must be a content string (not a form field)'),
                onChanged: (value) {
                  widget.store.update(widget.path,
                      (e) => e.mustBeContentString = value ?? false);
                  setState(() {});
                },
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: entry.convertFormToContent,
                title: const Text(
                    'Convert form field → content string subsection'),
                onChanged: (value) {
                  widget.store.update(widget.path,
                      (e) => e.convertFormToContent = value ?? false);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _comment,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (value) {
                  widget.store
                      .update(widget.path, (e) => e.comment = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
