// Every form in the Blueprint holds the fields the model marks required, and
// its int, bool and enum fields hold values of their type.
//
// The validator's tiers do not enforce required fields of forms declared on a
// section's `content` member, so this check walks the model metadata
// (`spec_model.meta.json`) over the Blueprint itself. It can be retired once
// the validator reports those fields.
import 'dart:convert';

import 'package:yaml/yaml.dart';

/// The check's result: how many forms it read and what they lack.
class RequiredFieldsReport {
  /// The number of forms the walk checked.
  int forms = 0;

  /// The required fields that are absent or empty, as `<form path>: <field>`.
  final List<String> missing = [];

  /// The int, bool and enum fields whose value does not read as their type,
  /// as `<form path>: <field> = <value>`.
  final List<String> badTypes = [];
}

String _norm(String key) {
  final space = key.indexOf(' ');
  return space < 0 ? key : key.substring(space + 1);
}

/// Checks [blueprintYaml] against the model classes of [metaJson], starting
/// at the root class [rootClass].
RequiredFieldsReport checkRequiredFields(
  String blueprintYaml,
  String metaJson, {
  String rootClass = 'D00SolutionBlueprint',
}) {
  final classes =
      (jsonDecode(metaJson) as Map<String, dynamic>)['classes']
          as Map<String, dynamic>;
  final report = RequiredFieldsReport();
  final doc = ((loadYaml(blueprintYaml) as YamlMap)['document'] as YamlMap)
      .values
      .first;

  void checkForm(String path, List<dynamic> formFields, Object? value) {
    report.forms++;
    for (final f in formFields.cast<Map<String, dynamic>>()) {
      final name = f['name'] as String;
      final present = value is YamlMap && value.containsKey(name);
      final v = present ? value[name] : null;
      if (f['required'] == true && (!present || v == null || v == '')) {
        report.missing.add('$path: $name');
      }
      if (!present) continue;
      final text = '$v'.trim();
      if (f['type'] == 'int' &&
          !(v is int || RegExp(r'^-?\d+$').hasMatch(text))) {
        report.badTypes.add('$path: $name = $v');
      }
      if (f['type'] == 'bool' &&
          !(v is bool || text == 'true' || text == 'false')) {
        report.badTypes.add('$path: $name = $v');
      }
      final enumValues = f['enumValues'] as List?;
      if (enumValues != null &&
          enumValues.isNotEmpty &&
          !enumValues.contains(text)) {
        report.badTypes.add('$path: $name = $v');
      }
    }
  }

  void walk(String cls, Object? node, String path) {
    if (node is! YamlMap) return;
    final byField = {for (final e in node.entries) _norm('${e.key}'): e.value};
    for (final f
        in ((classes[cls] as Map<String, dynamic>)['fields'] as List)
            .cast<Map<String, dynamic>>()) {
      final name = f['name'] as String;
      if (!byField.containsKey(name)) continue;
      final v = byField[name];
      switch (f['kind']) {
        case 'form':
          checkForm('$path/$name', f['formFields'] as List, v);
        case 'complex':
          walk(f['type'] as String, v, '$path/$name');
        case 'list':
          if (f['elementIsComplex'] == true && v is YamlMap) {
            v.forEach(
              (k, item) => walk(f['elementType'] as String, item, '$path/$k'),
            );
          }
      }
    }
  }

  walk(rootClass, doc, 'SBP');
  return report;
}
