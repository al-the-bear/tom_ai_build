import 'package:flutter/material.dart';

import '../model/review_store.dart';
import '../model/spec_model.dart';
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
          title: const Text('TomSpecs Editor'),
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

  /// 2b: suppress subsections at hand-off points to other documents.
  bool _cutAtHandoff = false;

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
                  child: Row(
                    children: [
                      Switch(
                        value: _cutAtHandoff,
                        onChanged: (v) => setState(() => _cutAtHandoff = v),
                      ),
                      const SizedBox(width: 4),
                      const Text('Cut at hand-offs',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '(hide subsections detailed in other documents)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
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
                        cutAtHandoff: _cutAtHandoff,
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
