/// Fields a Phase-2 Blueprint of an unreleased, gate-driven system cannot
/// always answer are optional (`tom_specs_model_rules.md` §6.2.7): an empty
/// field is the explicit "not yet known", so the model must not force a
/// placeholder into it. RB-1 holds each of them to `required: false` in the
/// shipped meta, so a later edit that makes one required again fails here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final meta =
      jsonDecode(
            File(
              '../tom_som_dart_v0/meta/spec_model.meta.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final classes = meta['classes'] as Map<String, dynamic>;

  /// (class, form field) pairs that must stay optional.
  const optional = [
    ('BusinessGoalEntry', 'targetDate'),
    ('GoalMilestoneEntry', 'targetDate'),
    ('StageEntry', 'plannedStartDate'),
    ('StageEntry', 'plannedEndDate'),
    ('StageEntry', 'targetGoLiveDate'),
    ('StageSummaryEntry', 'plannedStartDate'),
    ('StageSummaryEntry', 'plannedEndDate'),
    ('MigrationPhaseEntry', 'plannedStartDate'),
    ('MigrationPhaseEntry', 'plannedEndDate'),
    ('BrowserCompatibilityEntry', 'minVersion'),
    ('BrowserRequirementEntry', 'minVersion'),
    ('BuildToolchainEntry', 'minimumVersion'),
    ('DatabaseCompatibilityEntry', 'minVersion'),
    ('DesktopOsRequirementEntry', 'minVersion'),
    ('FrameworkRequirementEntry', 'minimumVersion'),
    ('MobileCompatibilityEntry', 'minVersion'),
    ('OsCompatibilityEntry', 'minVersion'),
    ('ProgrammingLanguageEntry', 'minimumVersion'),
    ('TargetPlatformEntry', 'minimumVersion'),
    ('DataGrowthProjections', 'currentDataVolume'),
    ('UserGrowthProjections', 'currentActiveUsers'),
  ];

  for (final (cls, field) in optional) {
    test('RB-1: $cls.$field is optional', () {
      final c = classes[cls] as Map<String, dynamic>?;
      expect(c, isNotNull, reason: 'class $cls');
      final matches = [
        for (final f in c!['fields'] as List)
          for (final ff in ((f as Map)['formFields'] as List?) ?? const [])
            if ((ff as Map)['name'] == field) ff,
      ];
      expect(matches, isNotEmpty, reason: '$cls declares $field');
      for (final ff in matches) {
        expect(ff['required'] ?? false, isFalse);
      }
    });
  }
}
