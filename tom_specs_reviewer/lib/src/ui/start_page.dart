import 'package:flutter/material.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import '../model/review_store.dart';
import 'spec_tree.dart';

/// The application start page. Hosts a tab bar whose first tab is the
/// "Document Structures" browser; further tabs are reserved for later.
class StartPage extends StatelessWidget {
  final SpecModel model;
  final ReviewStore store;

  const StartPage({super.key, required this.model, required this.store});

  @override
  Widget build(BuildContext context) {
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
        body: TabBarView(
          children: [
            _DocumentStructuresTab(model: model, store: store),
          ],
        ),
      ),
    );
  }
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
                return ListTile(
                  dense: true,
                  selected: selected,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(root.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    root.sectionId != null
                        ? '${root.sectionId} · ${root.type}'
                        : root.type,
                    style: const TextStyle(fontSize: 11),
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
                      _CutToggle(
                        label: 'Cut at detail hand-offs',
                        value: _cutAtDetails,
                        color: Colors.deepOrange,
                        onChanged: (v) => setState(() => _cutAtDetails = v),
                      ),
                      _CutToggle(
                        label: 'Cut at maps hand-offs',
                        value: _cutAtMaps,
                        color: Colors.purple,
                        onChanged: (v) => setState(() => _cutAtMaps = v),
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

/// A compact labelled switch used in the cut toolbar. The [color] dot ties the
/// switch to its hand-off marker colour (orange = detail, purple = maps).
class _CutToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _CutToggle({
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
