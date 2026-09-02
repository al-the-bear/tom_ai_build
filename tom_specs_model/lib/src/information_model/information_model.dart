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
@StandardReferences(
  [
    'DAMA-DMBOK — data modeling and management',
    'ISO/IEC 19505:2012 — UML entity-relationship modeling',
  ],
  'The complete business data model covering entities, relationships, business objects, functions, rules, dictionary, and validation constraints.',
)
@Document(
  name: 'Information Model',
  description: 'Complete business data model — entities, relationships, '
      'data classification, business objects, functions, rules, '
      'dictionary, and validation/integrity constraints.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('IFM')
class D03InformationModel extends DocSpecsSection {
  @ContentHelp('Executive overview of the business data model.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  // ─── Data Model ──────────────────────────────────────────────────────────

  /// Entity inventory (list).
  @SectionId('DAENT-ENTI-LST')
  @SectionIdPattern('DAENT-ENTI-xxx')
  @Min(1)
  @SerializationOrder(2)
  List<DataEntityEntry> entities = [];

  /// Entity relationships.
  @SerializationOrder(3)
  EntityRelationships entityRelationships = EntityRelationships();

  /// Entity-relationship diagram.
  @SerializationOrder(4)
  ErDiagramSection erDiagram = ErDiagramSection();

  /// Data classification.
  @SerializationOrder(5)
  DataClassification dataClassification = DataClassification();

  // ─── Business Object Model ───────────────────────────────────────────────

  /// Business object catalog (list).
  @SectionId('BJOEN-OBJE-LST')
  @SectionIdPattern('BJOEN-OBJE-xxx')
  @Min(1)
  @SerializationOrder(6)
  List<BusinessObjectEntry> objectCatalog = [];

  /// Business object diagram.
  @SerializationOrder(7)
  DiagramSection objectDiagram = DiagramSection();

  // ─── Function Model ──────────────────────────────────────────────────────

  /// Function decomposition (list).
  @SectionId('FUNCT-FUNC-LST')
  @SectionIdPattern('FUNCT-FUNC-xxx')
  @SerializationOrder(8)
  List<FunctionEntry> functionDecomposition = [];

  /// Function-to-data matrix (list).
  @SectionId('FNDMX-FUNC-LST')
  @SectionIdPattern('FNDMX-FUNC-xxx')
  @SerializationOrder(9)
  List<FunctionDataMatrixEntry> functionToDataMatrix = [];

  /// Business rules catalog (list).
  @SectionId('BIRU-BUSI-LST')
  @SectionIdPattern('BIRU-BUSI-xxx')
  @Min(1)
  @SerializationOrder(10)
  List<BusinessRuleEntry> businessRules = [];

  // ─── Data dictionary and constraints ─────────────────────────────────────

  /// Data dictionary.
  @SerializationOrder(11)
  DataDictionary dataDictionary = DataDictionary();

  /// Validation constraints.
  ///
  /// One whole-catalog content section (mirrors `dataDictionary` and the
  /// collapsed SBP source); collapsed from `List<ValidationConstraints>`
  /// (L34C-12 SR-25).
  @SerializationOrder(12)
  ValidationConstraints validationConstraints = ValidationConstraints();

  /// Integrity constraints.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<IntegrityConstraints>` (L34C-12 SR-25).
  @SerializationOrder(13)
  IntegrityConstraints integrityConstraints = IntegrityConstraints();

  /// Domain enum registry — the closed value sets the data model relies on
  /// (`domainEnum` home + closed-choice discriminator source, csmb3).
  @SerializationOrder(14)
  DomainEnumRegistry domainEnumRegistry = DomainEnumRegistry();

  /// Error code registry — the shared application error-code vocabulary
  /// referenced by CE-VA rules, the CE-ER Result envelope, and CE-TX copy
  /// (csmb5).
  @SerializationOrder(15)
  ErrorCodeRegistry errorCodeRegistry = ErrorCodeRegistry();

  /// Result envelope — the canonical CE-ER `codespecs_mapping.md` §7 contract.
  ///
  /// The success-or-error `Result` envelope; CE-ER home. Realised per
  /// application in `<app>_codespec_shared` — a response envelope is
  /// application domain, so no framework type backs it (csmb5).
  @SerializationOrder(16)
  ResultEnvelope resultEnvelope = ResultEnvelope();

  /// Message key registry — the single author-copy-once home for user-facing
  /// copy (CE-TX), referenced by CE-EL/CE-AC/CE-ER/CE-VA and `domainEnum` copy attributes
  /// (csmb7).
  @SerializationOrder(17)
  MessageKeyRegistry messageKeyRegistry = MessageKeyRegistry();

  /// Server operation registry — the system's own operation surface (CE-API):
  /// one entry per operation the server answers.
  ///
  /// Projected here rather than into a separate document because an operation is
  /// defined by the entity it reads and writes, which this document owns.
  @SerializationOrder(18)
  ServerOperationRegistry serverOperationRegistry = ServerOperationRegistry();

  /// Schema versioning and migration — the CE-MG home: the versioning policy,
  /// the data source / schema targets, and the ordered artifact set that
  /// establishes and evolves the schema.
  ///
  /// Projected here because the artifact chain must converge on the entity and
  /// attribute model this document owns.
  @SerializationOrder(19)
  SchemaVersioningAndMigration schemaVersioningAndMigration =
      SchemaVersioningAndMigration();
}
