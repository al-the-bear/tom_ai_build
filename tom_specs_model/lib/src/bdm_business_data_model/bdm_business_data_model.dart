/// BDM — Business Data Model.
///
/// Phase 3 DocSpec root class. Aggregates 12 top-level sections from
/// PD00-BUS (single seed, flattened two levels deep) per §5.5 of
/// second_wave_documents.md — top-levels are at PD00-BUS-{DAT,BUS,FUN}-*
/// level to avoid duplication with their parent containers.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// BDM00 Business Data Model.
///
/// Full business data model: entities, relationships, ER diagram, data
/// classification, business objects, function decomposition, function-
/// to-data matrix, business rules, data dictionary, and validation /
/// integrity constraints.
@Document(
  name: 'Business Data Model',
  description: 'Complete business data model — entities, relationships, '
      'data classification, business objects, functions, rules, '
      'dictionary, and validation/integrity constraints.',
  basedOn: [ProjectDefinition],
)
@SectionId('BDM')
class BusinessDataModel {
  @ContentHelp('Executive overview of the business data model.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  // ─── From PD00-BUS-DAT (Data Model) ──────────────────────────────────────

  /// Entity inventory — PD00-BUS-DAT-ENT (list).
  @SectionId('DAENT-ENTI-LST')
  @SectionIdPattern('DAENT-ENTI-xxx')
  @Min(1)
  List<DataEntityEntry> entities = [];

  /// Entity relationships — PD00-BUS-DAT-REL.
  EntityRelationships entityRelationships = EntityRelationships();

  /// Entity-relationship diagram — PD00-BUS-DAT-DIA.
  ErDiagramSection erDiagram = ErDiagramSection();

  /// Data classification — PD00-BUS-DAT-CLA.
  DataClassification dataClassification = DataClassification();

  // ─── From PD00-BUS-BUS (Business Object Model) ───────────────────────────

  /// Business object catalog — PD00-BUS-BUS-CAT (list).
  @SectionId('BJOEN-OBJE-LST')
  @SectionIdPattern('BJOEN-OBJE-xxx')
  @Min(1)
  List<BusinessObjectEntry> objectCatalog = [];

  /// Business object diagram — PD00-BUS-BUS-DIA.
  DiagramSection objectDiagram = DiagramSection();

  // ─── From PD00-BUS-FUN (Function Model) ──────────────────────────────────

  /// Function decomposition — PD00-BUS-FUN-DEC (list).
  @SectionId('FUNCT-FUNC-LST')
  @SectionIdPattern('FUNCT-FUNC-xxx')
  List<FunctionEntry> functionDecomposition = [];

  /// Function-to-data matrix — PD00-BUS-FUN-MAT (list).
  @SectionId('FNDMX-FUNC-LST')
  @SectionIdPattern('FNDMX-FUNC-xxx')
  List<FunctionDataMatrixEntry> functionToDataMatrix = [];

  /// Business rules catalog — PD00-BUS-FUN-RUL (list).
  @SectionId('BIRU-BUSI-LST')
  @SectionIdPattern('BIRU-BUSI-xxx')
  @Min(1)
  List<BusinessRuleEntry> businessRules = [];

  // ─── Added in Phase A §7 (Track 1 + Track 3 under PD00-BUS-DAT) ──────────

  /// Data dictionary — PD00-BUS-DAT-DIC.
  DataDictionary dataDictionary = DataDictionary();

  /// Validation constraints — PD00-BUS-DAT-VAL.
  @SectionId('VACO-VALI-LST')
  @SectionIdPattern('VACO-VALI-xxx')
  List<ValidationConstraints> validationConstraints = [];

  /// Integrity constraints — PD00-BUS-DAT-CON.
  @SectionId('INCO-INTE-LST')
  @SectionIdPattern('INCO-INTE-xxx')
  List<IntegrityConstraints> integrityConstraints = [];
}
