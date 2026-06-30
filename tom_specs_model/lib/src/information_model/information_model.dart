/// D03 — Information Model.
///
/// Phase 3 DocSpec root class. Aggregates 12 top-level sections projected
/// (flattened two levels deep) from the Solution Blueprint business
/// data, business-object, and function-model sections — promoting the
/// leaf groups so they don't duplicate their parent containers.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// IFM00 Information Model.
///
/// Full business data model: entities, relationships, ER diagram, data
/// classification, business objects, function decomposition, function-
/// to-data matrix, business rules, data dictionary, and validation /
/// integrity constraints.
@Document(
  name: 'Information Model',
  description: 'Complete business data model — entities, relationships, '
      'data classification, business objects, functions, rules, '
      'dictionary, and validation/integrity constraints.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('IFM')
class D03InformationModel {
  @ContentHelp('Executive overview of the business data model.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── Data Model ──────────────────────────────────────────────────────────

  /// Entity inventory (list).
  @SectionId('DAENT-ENTI-LST')
  @SectionIdPattern('DAENT-ENTI-xxx')
  @Min(1)
  List<DataEntityEntry> entities = [];

  /// Entity relationships.
  EntityRelationships entityRelationships = EntityRelationships();

  /// Entity-relationship diagram.
  ErDiagramSection erDiagram = ErDiagramSection();

  /// Data classification.
  DataClassification dataClassification = DataClassification();

  // ─── Business Object Model ───────────────────────────────────────────────

  /// Business object catalog (list).
  @SectionId('BJOEN-OBJE-LST')
  @SectionIdPattern('BJOEN-OBJE-xxx')
  @Min(1)
  List<BusinessObjectEntry> objectCatalog = [];

  /// Business object diagram.
  DiagramSection objectDiagram = DiagramSection();

  // ─── Function Model ──────────────────────────────────────────────────────

  /// Function decomposition (list).
  @SectionId('FUNCT-FUNC-LST')
  @SectionIdPattern('FUNCT-FUNC-xxx')
  List<FunctionEntry> functionDecomposition = [];

  /// Function-to-data matrix (list).
  @SectionId('FNDMX-FUNC-LST')
  @SectionIdPattern('FNDMX-FUNC-xxx')
  List<FunctionDataMatrixEntry> functionToDataMatrix = [];

  /// Business rules catalog (list).
  @SectionId('BIRU-BUSI-LST')
  @SectionIdPattern('BIRU-BUSI-xxx')
  @Min(1)
  List<BusinessRuleEntry> businessRules = [];

  // ─── Data dictionary and constraints ─────────────────────────────────────

  /// Data dictionary.
  DataDictionary dataDictionary = DataDictionary();

  /// Validation constraints.
  ///
  /// One whole-catalog content section (mirrors `dataDictionary` and the
  /// collapsed SBP source); collapsed from `List<ValidationConstraints>`
  /// (L34C-12 SR-25).
  ValidationConstraints validationConstraints = ValidationConstraints();

  /// Integrity constraints.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<IntegrityConstraints>` (L34C-12 SR-25).
  IntegrityConstraints integrityConstraints = IntegrityConstraints();
}
