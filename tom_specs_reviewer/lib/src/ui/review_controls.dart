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

/// Headings of the four collapsible feedback sections of the review dialog.
///
/// The dialog carries far more judgements than fit on one screen, so the
/// axis-specific ones are grouped and collapsed. A section that already holds a
/// value opens expanded — a collapsed section hiding recorded feedback is the
/// one failure mode this layout must not have.
const String kStructureSectionLabel = 'Structure';
const String kAnnotationsSectionLabel = 'Annotations';
const String kCodeSpecsSectionLabel = 'CodeSpecs mapping';
/// Note the trailing noun: the *destination* choice already offers a plain
/// "Follow-up", and two identical labels in one dialog would name two different
/// decisions.
const String kFollowUpSectionLabel = 'Follow-up mapping';

/// Label of the always-visible destination choice.
const String kDestinationLabel = 'Destination';

/// Labels of the three CodeSpecs-mapping judgements and the kind picker.
///
/// Named constants rather than inline literals so the tests assert the same
/// strings the dialog renders.
const String kCodeSpecKindMissingLabel = 'Should carry a kind (none declared)';
const String kCodeSpecKindWrongLabel = 'Declared kinds are wrong or incomplete';
const String kNotCodeSpecsLabel = 'Not CodeSpecs — do not realise as code';
const String kSuggestedKindsLabel = 'Suggested kinds';

/// Labels of the follow-up judgements and their picker.
const String kFollowUpKindMissingLabel =
    'Should carry a follow-up process (none declared)';
const String kFollowUpKindWrongLabel =
    'Declared follow-up processes are wrong or incomplete';
const String kSuggestedFollowUpKindsLabel = 'Suggested follow-up processes';

/// Shown when a proposed follow-up code is outside `FollowUpProcess`.
///
/// Deliberately not an error: the taxonomy is extensible, so proposing an
/// unknown code is a legitimate finding. The reviewer just needs to see that
/// they are extending the vocabulary rather than picking from it.
const String kUnknownFollowUpWarning =
    'Proposes extending the taxonomy — code not in FollowUpProcess';

/// Labels of the closed-choice judgements (`@OneOf` / `@Case`).
const String kShouldBeOneOfLabel = 'These siblings are really alternatives';
const String kCaseSetIncompleteLabel = 'The closed set is missing a case';

/// Labels of the annotation-level judgements.
const String kIdPatternWrongLabel = 'Section id / pattern is wrong or collides';
const String kHandoffWrongLabel = 'Handoff points at the wrong target';
const String kContentTypeWrongLabel = 'Content type is wrong for this content';
const String kStandardRefWrongLabel = 'Standard references are wrong';
const String kStandardRefMissingLabel = 'Standard references are missing';
const String kUnusedConfirmedLabel = 'Unused is correct — can be dropped';
const String kUnusedRejectedLabel = 'Unused is wrong — must be kept';

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
    if (entry.shouldBeOneOf) parts.add('one-of');
    if (entry.caseSetIncomplete) parts.add('case-set✗');
    if (entry.idPatternWrong) parts.add('id✗');
    if (entry.handoffWrong) parts.add('handoff✗');
    if (entry.contentTypeWrong) parts.add('content-type✗');
    if (entry.standardRefWrong) parts.add('std-ref✗');
    if (entry.standardRefMissing) parts.add('std-ref?');
    if (entry.unusedConfirmed) parts.add('unused✓');
    if (entry.unusedRejected) parts.add('unused✗');
    if (entry.destination != ReviewDestination.unset) {
      parts.add('→${entry.destination.label}');
    }
    if (entry.codeSpecKindMissing) parts.add('cs-kind?');
    if (entry.codeSpecKindWrong) parts.add('cs-kind✗');
    if (entry.notCodeSpecs) parts.add('not-codespecs');
    if (entry.suggestedCodeSpecKinds.isNotEmpty) {
      parts.add('cs→${entry.suggestedCodeSpecKinds.join(",")}');
    }
    if (entry.followUpKindMissing) parts.add('fu-kind?');
    if (entry.followUpKindWrong) parts.add('fu-kind✗');
    if (entry.suggestedFollowUpKinds.isNotEmpty) {
      parts.add('fu→${entry.suggestedFollowUpKinds.join(",")}');
    }
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
  late final TextEditingController _followUpCode;

  /// Headings of the sections currently open.
  ///
  /// Expansion is held here rather than left to `ExpansionTile`'s own state so
  /// that "a section carrying feedback opens" is decided by the entry every
  /// time the dialog is built, and cannot be overridden by remembered UI state.
  late final Set<String> _expanded;

  @override
  void initState() {
    super.initState();
    final entry = widget.store.entryFor(widget.path) ?? ReviewEntry();
    _comment = TextEditingController(text: entry.comment);
    _followUpCode = TextEditingController();
    _expanded = {
      if (_structureCarriesFeedback(entry)) kStructureSectionLabel,
      if (_annotationsCarryFeedback(entry)) kAnnotationsSectionLabel,
      if (_codeSpecsCarryFeedback(entry)) kCodeSpecsSectionLabel,
      if (_followUpCarriesFeedback(entry)) kFollowUpSectionLabel,
    };
  }

  @override
  void dispose() {
    _comment.dispose();
    _followUpCode.dispose();
    super.dispose();
  }

  static bool _structureCarriesFeedback(ReviewEntry e) =>
      e.mustBeList ||
      e.singleEntry ||
      e.mustBeContentString ||
      e.convertFormToContent ||
      e.shouldBeOneOf ||
      e.caseSetIncomplete;

  static bool _annotationsCarryFeedback(ReviewEntry e) =>
      e.idPatternWrong ||
      e.handoffWrong ||
      e.contentTypeWrong ||
      e.standardRefWrong ||
      e.standardRefMissing ||
      e.unusedConfirmed ||
      e.unusedRejected;

  static bool _codeSpecsCarryFeedback(ReviewEntry e) =>
      e.codeSpecKindMissing ||
      e.codeSpecKindWrong ||
      e.notCodeSpecs ||
      e.suggestedCodeSpecKinds.isNotEmpty;

  static bool _followUpCarriesFeedback(ReviewEntry e) =>
      e.followUpKindMissing ||
      e.followUpKindWrong ||
      e.suggestedFollowUpKinds.isNotEmpty;

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

  /// The suggested-kind picker: the chosen kinds as removable chips, plus a
  /// dropdown over the kinds not yet chosen.
  ///
  /// Offering only the remaining vocabulary makes an invalid token
  /// unreachable from the UI — the store's validation then guards the file and
  /// API paths, not the reviewer's typing.
  Widget _suggestedKinds(ReviewEntry entry) {
    final chosen = entry.suggestedCodeSpecKinds;
    final remaining = kCodeSpecPartTokens.where((t) => !chosen.contains(t))
        .toList()
      ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(kSuggestedKindsLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        if (chosen.isEmpty)
          Text('none proposed',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600))
        else
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final kind in chosen)
                InputChip(
                  label: Text(kind, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  onDeleted: () {
                    widget.store.update(widget.path,
                        (e) => e.toggleSuggestedCodeSpecKind(kind));
                    setState(() {});
                  },
                ),
            ],
          ),
        if (remaining.isNotEmpty)
          DropdownButton<String>(
            value: null,
            isDense: true,
            hint: const Text('Add a kind…', style: TextStyle(fontSize: 12)),
            items: [
              for (final kind in remaining)
                DropdownMenuItem(
                  value: kind,
                  child: Text(kind, style: const TextStyle(fontSize: 12)),
                ),
            ],
            onChanged: (kind) {
              if (kind == null) return;
              widget.store.update(
                  widget.path, (e) => e.toggleSuggestedCodeSpecKind(kind));
              setState(() {});
            },
          ),
      ],
    );
  }

  /// The follow-up picker: chosen codes as removable chips, a dropdown over the
  /// known vocabulary, and a free-text field for a code that vocabulary lacks.
  ///
  /// The free-text field is the point: `FollowUpProcess` is extensible, so
  /// "this belongs to a process we have not named" must be recordable, and a
  /// dropdown alone would make it unsayable.
  Widget _suggestedFollowUpKinds(ReviewEntry entry) {
    final chosen = entry.suggestedFollowUpKinds;
    final unknown = entry.unknownFollowUpKinds.toSet();
    final remaining =
        kFollowUpProcessTokens.where((t) => !chosen.contains(t)).toList()
          ..sort();

    void propose(String raw) {
      final code = raw.trim();
      if (code.isEmpty) return;
      widget.store
          .update(widget.path, (e) => e.toggleSuggestedFollowUpKind(code));
      _followUpCode.clear();
      setState(() {});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(kSuggestedFollowUpKindsLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        if (chosen.isEmpty)
          Text('none proposed',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600))
        else
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final kind in chosen)
                InputChip(
                  label: Text(kind, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      unknown.contains(kind) ? Colors.amber.shade100 : null,
                  onDeleted: () => propose(kind),
                ),
            ],
          ),
        if (entry.hasUnknownFollowUpKind)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: Colors.amber.shade800),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(kUnknownFollowUpWarning,
                      style: TextStyle(
                          fontSize: 11, color: Colors.amber.shade900)),
                ),
              ],
            ),
          ),
        if (remaining.isNotEmpty)
          DropdownButton<String>(
            value: null,
            isDense: true,
            hint: const Text('Add a process…', style: TextStyle(fontSize: 12)),
            items: [
              for (final kind in remaining)
                DropdownMenuItem(
                  value: kind,
                  child: Text(kind, style: const TextStyle(fontSize: 12)),
                ),
            ],
            onChanged: (kind) => propose(kind ?? ''),
          ),
        TextField(
          controller: _followUpCode,
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Propose a new process code',
            border: OutlineInputBorder(),
          ),
          onSubmitted: propose,
        ),
      ],
    );
  }

  /// A dense checkbox bound to one boolean axis of the entry.
  Widget _check(
    String title,
    bool value,
    void Function(ReviewEntry, bool) apply, {
    String? subtitle,
  }) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: value,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      onChanged: (v) {
        widget.store.update(widget.path, (e) => apply(e, v ?? false));
        setState(() {});
      },
    );
  }

  /// One collapsible feedback section.
  Widget _section(String label, List<Widget> children) {
    final expanded = _expanded.contains(label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 16),
        InkWell(
          onTap: () => setState(() {
            if (!_expanded.remove(label)) _expanded.add(label);
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        if (expanded) ...children,
      ],
    );
  }

  /// The always-visible destination choice — where this subtree belongs.
  Widget _destination(ReviewEntry entry) {
    return Column(
      key: const ValueKey('destination-options'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(kDestinationLabel,
            style: TextStyle(fontWeight: FontWeight.w600)),
        RadioGroup<ReviewDestination>(
          groupValue: entry.destination,
          onChanged: (value) {
            if (value == null) return;
            widget.store.update(widget.path, (e) => e.destination = value);
            setState(() {});
          },
          child: Wrap(
            children: [
              for (final destination in ReviewDestination.values)
                SizedBox(
                  width: 160,
                  child: RadioListTile<ReviewDestination>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: destination,
                    title: Text(destination.label,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _current;
    return AlertDialog(
      title: const Text('Review node'),
      content: SizedBox(
        width: 520,
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
              _destination(entry),
              _section(kStructureSectionLabel, [
                _check('Must be a list', entry.mustBeList,
                    (e, v) => e.mustBeList = v),
                _check('Is only a single entry (not a list)', entry.singleEntry,
                    (e, v) => e.singleEntry = v),
                _check('Must be a content string (not a form field)',
                    entry.mustBeContentString,
                    (e, v) => e.mustBeContentString = v),
                _check('Convert form field → content string subsection',
                    entry.convertFormToContent,
                    (e, v) => e.convertFormToContent = v),
                _check(kShouldBeOneOfLabel, entry.shouldBeOneOf,
                    (e, v) => e.shouldBeOneOf = v),
                _check(kCaseSetIncompleteLabel, entry.caseSetIncomplete,
                    (e, v) => e.caseSetIncomplete = v,
                    subtitle: 'Closure is the point of a closed choice'),
              ]),
              _section(kAnnotationsSectionLabel, [
                _check(kIdPatternWrongLabel, entry.idPatternWrong,
                    (e, v) => e.idPatternWrong = v),
                _check(kHandoffWrongLabel, entry.handoffWrong,
                    (e, v) => e.handoffWrong = v),
                _check(kContentTypeWrongLabel, entry.contentTypeWrong,
                    (e, v) => e.contentTypeWrong = v),
                _check(kStandardRefWrongLabel, entry.standardRefWrong,
                    (e, v) => e.standardRefWrong = v),
                _check(kStandardRefMissingLabel, entry.standardRefMissing,
                    (e, v) => e.standardRefMissing = v),
                _check(kUnusedConfirmedLabel, entry.unusedConfirmed,
                    (e, v) => e.unusedConfirmed = v),
                _check(kUnusedRejectedLabel, entry.unusedRejected,
                    (e, v) => e.unusedRejected = v),
              ]),
              _section(kCodeSpecsSectionLabel, [
                _check(kCodeSpecKindMissingLabel, entry.codeSpecKindMissing,
                    (e, v) => e.codeSpecKindMissing = v),
                _check(kCodeSpecKindWrongLabel, entry.codeSpecKindWrong,
                    (e, v) => e.codeSpecKindWrong = v),
                _check(kNotCodeSpecsLabel, entry.notCodeSpecs,
                    (e, v) => e.notCodeSpecs = v),
                const SizedBox(height: 6),
                _suggestedKinds(entry),
              ]),
              _section(kFollowUpSectionLabel, [
                _check(kFollowUpKindMissingLabel, entry.followUpKindMissing,
                    (e, v) => e.followUpKindMissing = v),
                _check(kFollowUpKindWrongLabel, entry.followUpKindWrong,
                    (e, v) => e.followUpKindWrong = v),
                const SizedBox(height: 6),
                _suggestedFollowUpKinds(entry),
              ]),
              const SizedBox(height: 12),
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
