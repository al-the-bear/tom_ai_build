// The feature register's consistency rules, read from the Blueprint's YAML.
//
// The feature register (`DTRO > … > FPE-ITEM-*`) is the unit the delivery plan
// schedules, so every functional requirement has to land in exactly one
// feature: in none, it is never scheduled; in two, it is counted twice and its
// wave is ambiguous. The links are plain id lists (`FETR > linkedRequirements`)
// that no tier of the validator resolves, so this check does.
//
// It reads the YAML text directly rather than the decoded model: the rules are
// about ids and the id lists that hold them, which the YAML states as they are.
import 'package:yaml/yaml.dart';

/// One broken rule, with the id it concerns.
class FeatureRegisterFinding {
  /// Binds the broken rule, the id it concerns and the message.
  const FeatureRegisterFinding(this.rule, this.id, this.message);

  /// `unassigned`, `assignedTwice`, `unknownRequirement`, `emptyFeature`,
  /// `unknownFeature` or `countMismatch`.
  final String rule;

  /// The id the finding concerns: the feature, the functional requirement,
  /// the prototype feature, or `FPE` for a count mismatch.
  final String id;

  /// What is wrong, phrased to follow the id.
  final String message;

  @override
  String toString() => '$rule [$id] — $message';
}

/// The figures the check found, for the summary line.
class FeatureRegisterReport {
  /// Binds the figures and the findings.
  FeatureRegisterReport(
    this.features,
    this.functionalRequirements,
    this.prototypeFeatures,
    this.findings,
  );

  /// The number of features in the register (`FPE-ITEM-*` items).
  final int features;

  /// The number of functional requirements (`FRE-REQU-*` items).
  final int functionalRequirements;

  /// The number of prototype features (`PFE-FEAT-*` items) that name a
  /// `featureId`.
  final int prototypeFeatures;

  /// Every broken rule, grouped by rule in the order the check runs them.
  final List<FeatureRegisterFinding> findings;
}

final RegExp _itemKey = RegExp(
  r'^([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)+)(?: [A-Za-z]\w*)?$',
);

/// Checks the feature register of the Blueprint in [yamlText].
FeatureRegisterReport checkFeatureRegister(String yamlText) {
  final root = loadYaml(yamlText);
  final ids = <String>{};
  final functional = <String>[];
  final featureLinks = <String, List<String>>{};
  final prototypeRefs = <String, String>{};
  String? statedTotal;

  void walk(Object? node, String? feature, String? prototype) {
    if (node is! YamlMap) return;
    for (final entry in node.entries) {
      final key = '${entry.key}';
      final value = entry.value;
      final match = _itemKey.firstMatch(key);
      var currentFeature = feature;
      var currentPrototype = prototype;
      if (match != null && !key.contains(' ')) {
        final id = match.group(1)!;
        ids.add(id);
        if (id.startsWith('FRE-REQU-')) functional.add(id);
        if (id.startsWith('FPE-ITEM-') && !id.endsWith('-LST')) {
          currentFeature = id;
          featureLinks.putIfAbsent(id, () => <String>[]);
        }
        if (id.startsWith('PFE-FEAT-') && !id.endsWith('-LST')) {
          currentPrototype = id;
        }
      }
      if (key == 'linkedRequirements' && currentFeature != null) {
        featureLinks[currentFeature]!.addAll(_idList('$value'));
      }
      if (key == 'featureId' && currentPrototype != null) {
        prototypeRefs[currentPrototype] = '$value'.trim();
      }
      if (key == 'totalRegisteredFeatures') statedTotal = '$value'.trim();
      walk(value, currentFeature, currentPrototype);
    }
  }

  walk(root, null, null);

  final findings = <FeatureRegisterFinding>[];
  final owners = <String, List<String>>{};
  featureLinks.forEach((feature, links) {
    if (links.isEmpty) {
      findings.add(
        FeatureRegisterFinding('emptyFeature', feature, 'links no requirement'),
      );
    }
    for (final link in links) {
      if (!ids.contains(link)) {
        findings.add(
          FeatureRegisterFinding(
            'unknownRequirement',
            feature,
            'links $link, which the document does not contain',
          ),
        );
      }
      if (link.startsWith('FRE-REQU-')) {
        owners.putIfAbsent(link, () => <String>[]).add(feature);
      }
    }
  });
  for (final requirement in functional) {
    final featuresOf = owners[requirement] ?? const <String>[];
    if (featuresOf.isEmpty) {
      findings.add(
        FeatureRegisterFinding(
          'unassigned',
          requirement,
          'is linked by no feature',
        ),
      );
    } else if (featuresOf.length > 1) {
      findings.add(
        FeatureRegisterFinding(
          'assignedTwice',
          requirement,
          'is linked by ${featuresOf.join(', ')}',
        ),
      );
    }
  }
  prototypeRefs.forEach((prototype, featureId) {
    if (!featureLinks.containsKey(featureId)) {
      findings.add(
        FeatureRegisterFinding(
          'unknownFeature',
          prototype,
          'names $featureId, which is not a feature of the register',
        ),
      );
    }
  });
  if (statedTotal != null && statedTotal != '${featureLinks.length}') {
    findings.add(
      FeatureRegisterFinding(
        'countMismatch',
        'FPE',
        'totalRegisteredFeatures says $statedTotal, the register has '
            '${featureLinks.length}',
      ),
    );
  }
  return FeatureRegisterReport(
    featureLinks.length,
    functional.length,
    prototypeRefs.length,
    findings,
  );
}

List<String> _idList(String text) => text
    .split(RegExp(r'[,\s]+'))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();
