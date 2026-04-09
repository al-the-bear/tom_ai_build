import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectDefinition', () {
    test('can be constructed with all defaults', () {
      final pd = ProjectDefinition();
      expect(pd.header.documentId, isNull);
      expect(pd.currentStateAnalysis.content, isNull);
      expect(pd.systemOverview.content, isNull);
    });

    test('header fields are all String?', () {
      final header = DocumentHeader()
        ..documentId = 'PD00'
        ..project = 'Test Project'
        ..version = '0.1'
        ..date = '2026-04-07'
        ..author = 'Test'
        ..status = 'Draft';
      expect(header.documentId, 'PD00');
      expect(header.date, '2026-04-07');
    });

    test('section classes have content field', () {
      final section = CurrentStateAnalysis()
        ..content = 'Overview of current state.';
      expect(section.content, 'Overview of current state.');
      expect(section.existingSystemsLandscape.content, isNull);
    });

    test('plural fields are lists of entry types', () {
      final goal = BusinessGoalEntry()
        ..goalId = 'BG-001'
        ..goalName = 'Increase revenue';
      final goals = Goals()..businessGoals = [goal];
      final overview = SystemOverview()..goals = goals;
      expect(overview.goals.businessGoals, hasLength(1));
      expect(overview.goals.businessGoals.first.goalId, 'BG-001');
    });

    test('stage entry uses String? fields', () {
      final stage = StageEntry()
        ..stageNumber = '1'
        ..stageName = 'Foundation'
        ..scopeSummary = 'Core infrastructure'
        ..featureScope = 'Login, CRUD, orders';
      expect(stage.stageNumber, '1');
      expect(stage.featureScope, isNotNull);
    });
  });
}
