import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'src/model/review_store.dart';
import 'src/ui/start_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final raw = await rootBundle.loadString('assets/spec_model.json');
  final model = SpecModel.fromJson(json.decode(raw) as Map<String, dynamic>);
  final store = ReviewStore.resolveDefault()..load();
  runApp(SpecsReviewerApp(model: model, store: store));
}

/// Root application widget for the TomSpecs structure reviewer.
class SpecsReviewerApp extends StatelessWidget {
  /// The exported class graph being reviewed, decoded from the bundled
  /// `assets/spec_model.json` snapshot.
  ///
  /// A committed snapshot, not a live read of `tom_specs_model` — which is why
  /// `ModelStampBar` exists to say which one, and why an observation recorded
  /// against a superseded snapshot is a real hazard rather than a theoretical
  /// one.
  final SpecModel model;

  /// The review observations, already loaded from disk.
  ///
  /// Loaded before `runApp` rather than during the first build, so the tree
  /// never renders a frame with empty markings that then fill in.
  final ReviewStore store;

  /// Builds the application over an already-loaded [model] and [store].
  ///
  /// Both are required: this widget performs no loading of its own, so there
  /// is no sensible default for either.
  const SpecsReviewerApp({super.key, required this.model, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TomSpecs Reviewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
      ),
      home: StartPage(model: model, store: store),
    );
  }
}
