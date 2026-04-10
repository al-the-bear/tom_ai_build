import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectDefinition', () {
    test('can be constructed with all defaults', () {
      final pd = ProjectDefinition();
      expect(pd.header.content, isNull);
      expect(pd.currentStateAnalysis.content, isNull);
      expect(pd.systemOverview.content, isNull);
    });

    test('header has @Form annotation on content', () {
      final header = DocumentHeader()
        ..content = 'PD00 — Test Project v0.1 by Test (Draft)';
      expect(header.content, contains('PD00'));
    });

    test('section classes have content field', () {
      final section = CurrentStateAnalysis()
        ..content = 'Overview of current state.';
      expect(section.content, 'Overview of current state.');
      expect(section.existingSystemsLandscape.content, isNull);
    });

    test('form entry classes use content with @Form', () {
      final goal = BusinessGoalEntry()
        ..content = 'BG-001 — Increase revenue';
      final goals = Goals()..businessGoals = [goal];
      final overview = SystemOverview()..goals = goals;
      expect(overview.goals.businessGoals, hasLength(1));
      expect(overview.goals.businessGoals.first.content, contains('BG-001'));
    });

    test('stage entry uses content and TextSection fields', () {
      final stage = StageEntry()
        ..content = 'Stage 1 — Foundation — Core infrastructure';
      stage.featureScope.content = 'Login, CRUD, orders';
      expect(stage.content, contains('Foundation'));
      expect(stage.featureScope, isA<TextSection>());
      expect(stage.featureScope.content, isNotNull);
    });
  });
}
