import 'package:tom_specs_model/tom_specs_model.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectDefinition', () {
    test('can be constructed with defaults', () {
      final pd = ProjectDefinition(
        header: DocumentHeader(
          documentId: 'PD00',
          project: 'Test Project',
          version: '0.1',
          date: DateTime(2026, 4, 7),
          author: 'Test',
          status: 'Draft',
        ),
      );
      expect(pd.header.documentId, 'PD00');
      expect(pd.currentStateAnalysis.systemInventory, isEmpty);
      expect(pd.systemOverview.requirements.functional, isEmpty);
    });

    test('FunctionalRequirement extends Requirement', () {
      const req = FunctionalRequirement(
        requirementId: 'REQ-F001',
        title: 'User Registration',
        description: 'System shall allow registration',
        priority: Priority.must,
        source: 'Workshop',
        acceptanceCriteria: 'User can register',
        relatedUseCase: 'UC-001',
        affectedDataEntities: 'User',
      );
      expect(req.requirementId, 'REQ-F001');
      expect(req.relatedUseCase, 'UC-001');
      expect(req.status, Status.draft);
    });

    test('Stage model captures all fields', () {
      const stage = Stage(
        stageNumber: 1,
        stageName: 'Foundation',
        scopeSummary: 'Core infrastructure',
        featureScope: 'Login, CRUD, orders',
      );
      expect(stage.stageNumber, 1);
      expect(stage.featureScope, isNotNull);
    });
  });
}
