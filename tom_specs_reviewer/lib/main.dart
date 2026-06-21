import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'src/model/review_store.dart';
import 'src/model/spec_model.dart';
import 'src/ui/start_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final raw = await rootBundle.loadString('assets/spec_model.json');
  final model = SpecModel.fromJson(json.decode(raw) as Map<String, dynamic>);
  final store = ReviewStore.resolveDefault()..load();
  runApp(SpecsEditorApp(model: model, store: store));
}

/// Root application widget for the TomSpecs structure editor.
class SpecsEditorApp extends StatelessWidget {
  final SpecModel model;
  final ReviewStore store;

  const SpecsEditorApp({super.key, required this.model, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TomSpecs Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
      ),
      home: StartPage(model: model, store: store),
    );
  }
}
