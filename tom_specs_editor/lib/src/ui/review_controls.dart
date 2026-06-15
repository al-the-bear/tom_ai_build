import 'package:flutter/material.dart';

import '../model/review_store.dart';

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

/// A compact, tappable review indicator shown on every tree node.
///
/// It reflects the current [ReviewEntry] for [path] (scope colour, a "stop"
/// ring, an "add details" plus-badge, and a comment glyph) and opens the edit
/// dialog when tapped. It listens to the store so edits made elsewhere on the
/// same path update it live.
class ReviewIndicator extends StatelessWidget {
  final ReviewStore store;
  final String path;
  final String nodeLabel;

  const ReviewIndicator({
    super.key,
    required this.store,
    required this.path,
    required this.nodeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final entry = store.entryFor(path);
        final scope = entry?.scope ?? ReviewScope.none;
        final hasComment = (entry?.comment.trim().isNotEmpty) ?? false;
        return Tooltip(
          message: _tooltip(entry),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _openDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(scope, entry?.stopHere ?? false),
                  if (entry?.addDetails ?? false)
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Icon(Icons.add, size: 12, color: Colors.teal),
                    ),
                  if (hasComment)
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Icon(Icons.chat_bubble,
                          size: 11, color: Colors.brown),
                    ),
                ],
              ),
            ),
          ),
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

  String _tooltip(ReviewEntry? entry) {
    if (entry == null || entry.isEmpty) return 'Not reviewed — click to set';
    final parts = <String>[entry.scope.label];
    if (entry.stopHere) parts.add('stop here');
    if (entry.addDetails) parts.add('add details');
    if (entry.comment.trim().isNotEmpty) parts.add('“${entry.comment.trim()}”');
    return parts.join(' · ');
  }

  void _openDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _ReviewDialog(
        store: store,
        path: path,
        nodeLabel: nodeLabel,
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

  const _ReviewDialog({
    required this.store,
    required this.path,
    required this.nodeLabel,
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
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: entry.stopHere,
                title: const Text('Stop here'),
                subtitle: const Text('Do not descend further into this branch'),
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
                subtitle: const Text('This node needs further specification'),
                onChanged: (value) {
                  widget.store.update(
                      widget.path, (e) => e.addDetails = value ?? false);
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
