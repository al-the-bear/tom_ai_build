import 'package:flutter/material.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import '../model/review_store.dart';
import 'spec_tree.dart';

/// The application start page. Hosts a tab bar whose first tab is the
/// "Document Structures" browser; further tabs are reserved for later.
class StartPage extends StatelessWidget {
  /// The class graph whose document roots become the browsable trees.
  final SpecModel model;

  /// The observation store the tree reads markings from and writes them to.
  final ReviewStore store;

  /// Evaluation instant for the snapshot-age check, injectable so tests can
  /// age a fixture without touching the clock.
  final DateTime? now;

  /// Builds the start page.
  ///
  /// [now] is the only optional argument, and exists solely so a test can age
  /// a fixture without touching the clock.
  const StartPage({
    super.key,
    required this.model,
    required this.store,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final check = model.checkStamp(now: now);
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TomSpecs Reviewer'),
          actions: [
            AnimatedBuilder(
              animation: store,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text('${store.count} reviewed',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.account_tree), text: 'Document Structures'),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModelStampBar(model: model, check: check),
            Expanded(
              child: TabBarView(
                children: [
                  _DocumentStructuresTab(model: model, store: store),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Identifies the snapshot the reviewer is working against, and says so loudly
/// when it can no longer be trusted.
///
/// Why it is always visible rather than tucked into an "about" dialog: review
/// observations are keyed by structural path, so feedback recorded against a
/// superseded snapshot is silently mis-filed. The reviewer has to be able to
/// see which model they are judging without going looking for it.
class ModelStampBar extends StatelessWidget {
  /// The snapshot being reported on — its `generatedAt`, counts and container
  /// root are what the bar displays.
  final SpecModel model;

  /// The staleness verdict for [model], computed once by the caller.
  ///
  /// Passed in rather than recomputed here so the bar and the page it sits on
  /// cannot disagree about whether the snapshot is stale.
  final SpecModelStampCheck check;

  /// Builds the bar for [model] under the already-computed [check].
  const ModelStampBar({super.key, required this.model, required this.check});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stale = check.isStale;
    return Material(
      color: stale ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  stale ? Icons.warning_amber_rounded : Icons.verified_outlined,
                  size: 16,
                  color: stale ? scheme.onErrorContainer : scheme.outline,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _stampLine(model, check),
                    style: TextStyle(
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color:
                          stale ? scheme.onErrorContainer : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            for (final warning in check.warnings)
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 2),
                child: Text(
                  warning,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The one-line stamp: which model, exported when, and how big.
///
/// Every part degrades independently — an older snapshot that declares no
/// counts simply contributes no count segment rather than rendering `null`.
String _stampLine(SpecModel model, SpecModelStampCheck check) {
  final parts = <String>[
    'Model ${model.modelVersionString}',
    if (model.modelVersionLabel != null) '(${model.modelVersionLabel})',
  ];
  final generated = model.generatedAt;
  parts.add(generated == null
      ? 'generated: unknown'
      : 'generated ${_formatTimestamp(generated)}'
          '${check.age == null ? '' : ' · ${_formatAge(check.age!)}'}');
  parts.add('${check.actualClassCount} classes');
  parts.add('${check.actualRootCount} roots');
  if (model.containerRoot != null) {
    parts.add('container ${model.containerRoot}');
  }
  return parts.join(' · ');
}

/// `2026-07-27 09:23 UTC` — minute precision is as fine as a freshness read
/// ever needs, and the seconds only add noise.
String _formatTimestamp(DateTime utc) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)} UTC';
}

/// A coarse "how long ago", in the largest unit that still reads naturally.
String _formatAge(Duration age) {
  if (age.inDays >= 1) {
    return '${age.inDays} day${age.inDays == 1 ? '' : 's'} ago';
  }
  if (age.inHours >= 1) {
    return '${age.inHours} hour${age.inHours == 1 ? '' : 's'} ago';
  }
  if (age.inMinutes >= 1) {
    return '${age.inMinutes} min ago';
  }
  return 'just now';
}

/// Master-detail view: list of document roots on the left, the selected
/// document's structure tree on the right.
class _DocumentStructuresTab extends StatefulWidget {
  final SpecModel model;
  final ReviewStore store;

  const _DocumentStructuresTab({required this.model, required this.store});

  @override
  State<_DocumentStructuresTab> createState() => _DocumentStructuresTabState();
}

class _DocumentStructuresTabState extends State<_DocumentStructuresTab> {
  SpecRoot? _selected;

  /// 2b: suppress subsections at `@DetailedIn` hand-off points.
  bool _cutAtDetails = false;

  /// 2d: suppress subsections at `@MapsTo` hand-off points.
  bool _cutAtMaps = false;

  /// Reveal `@SerializationOrder` ordinals in the tree.
  ///
  /// Held here rather than inside [SpecTree] so it keeps its value for the
  /// whole session: the tree is keyed by document type and is rebuilt from
  /// scratch on every document switch.
  bool _showSerializationOrder = false;

  /// 2c: class to reveal/scroll-to after a hand-off jump (cleared on manual
  /// document selection).
  String? _navTargetType;

  void _selectRoot(SpecRoot root, {String? navTargetType}) {
    setState(() {
      _selected = root;
      _navTargetType = navTargetType;
    });
  }

  /// Handles a hand-off marker tap: switch to [targetRoot] and reveal
  /// [targetType] within it.
  void _onHandoffTap(String targetRoot, String targetType) {
    SpecRoot? root;
    for (final r in widget.model.roots) {
      if (r.type == targetRoot) {
        root = r;
        break;
      }
    }
    if (root == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No document for "$targetRoot"')),
      );
      return;
    }
    _selectRoot(root, navTargetType: targetType);
  }

  @override
  Widget build(BuildContext context) {
    final roots = widget.model.roots;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 280,
          child: Material(
            elevation: 1,
            child: ListView.separated(
              itemCount: roots.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final root = roots[i];
                final selected = root == _selected;
                final projection =
                    widget.model.classNamed(root.type)?.isCodeSpecsProjection ??
                        false;
                return ListTile(
                  dense: true,
                  selected: selected,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(root.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      Flexible(
                        child: Text(
                          root.sectionId != null
                              ? '${root.sectionId} · ${root.type}'
                              : root.type,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      if (projection) ...[
                        const SizedBox(width: 6),
                        const _ProjectionBadge(),
                      ],
                    ],
                  ),
                  onTap: () => _selectRoot(root),
                );
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                elevation: 1,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ToolbarToggle(
                        label: 'Cut at detail hand-offs',
                        value: _cutAtDetails,
                        color: Colors.deepOrange,
                        onChanged: (v) => setState(() => _cutAtDetails = v),
                      ),
                      _ToolbarToggle(
                        label: 'Cut at maps hand-offs',
                        value: _cutAtMaps,
                        color: Colors.purple,
                        onChanged: (v) => setState(() => _cutAtMaps = v),
                      ),
                      _ToolbarToggle(
                        label: kSerializationOrderToggleLabel,
                        value: _showSerializationOrder,
                        color: Colors.blueGrey,
                        onChanged: (v) =>
                            setState(() => _showSerializationOrder = v),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _selected == null
                    ? const Center(
                        child:
                            Text('Select a document to browse its structure'))
                    : SpecTree(
                        key: ValueKey(_selected!.type),
                        model: widget.model,
                        root: _selected!,
                        store: widget.store,
                        cutAtDetails: _cutAtDetails,
                        cutAtMaps: _cutAtMaps,
                        showSerializationOrder: _showSerializationOrder,
                        navTargetType: _navTargetType,
                        onHandoffTap: _onHandoffTap,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact labelled switch in the tree toolbar. The [color] dot ties the
/// switch to what it affects — orange = detail hand-offs, purple = maps
/// hand-offs, blue-grey = the serialization-order badges.
class _ToolbarToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _ToolbarToggle({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: value, onChanged: onChanged, activeThumbColor: color),
        const SizedBox(width: 4),
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Badge marking a `@CodeSpecsProjection` root in the document list.
///
/// The tree shows the same word on the root node, so a reviewer meets the
/// projection before opening it and again once inside.
class _ProjectionBadge extends StatelessWidget {
  const _ProjectionBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: kProjectionExplanation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          border: Border.all(color: Colors.teal.shade300),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          kProjectionLabel,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade800),
        ),
      ),
    );
  }
}
