/// Section 7: Business Object and Data Model. Seeds → IFM.
///
/// Conceptual overview of the business data the system manages.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/authorization_requirement.dart';
import '../document_stubs.dart';

/// Lifecycle role of a business-object state (`ObjectStateEntry.stateType`).
///
/// A closed choice of lifecycle roles. Unlike `ScreenElementEntry` /
/// `ScreenElementFieldSpec`, an `ObjectStateEntry` carries no per-kind
/// alternative subsections, so this is modelled as a plain closed-choice enum
/// form field (no `@OneOf`/`@Case` group).
enum ObjectLifecycleKind {
  /// The state an instance is created in. Exactly one per lifecycle, and the
  /// one `BJOEN-LIFE.initialState` names; nothing may transition *into* it,
  /// because arriving there a second time would mean the instance had been
  /// re-created rather than moved.
  initial,

  /// A state the instance passes through — entered and left again. The only
  /// role for which both an inbound and an outbound transition are expected,
  /// which is what makes "this state can never be left" a detectable defect
  /// rather than a design choice.
  intermediate,

  /// A state in which the lifecycle ends by design: the order was closed, the
  /// claim was settled. It has no outbound transition, so marking a state
  /// terminal is also the assertion that no further business event can move
  /// the instance.
  terminal,

  /// A state reached because something failed rather than because the intended
  /// path completed. Kept apart from [terminal] because it is not necessarily
  /// an end: an instance may be repaired and resume. What distinguishes it is
  /// the reason for arrival, not whether anything leads out — which is why the
  /// two cannot be collapsed into one "final" flag.
  error,
}

/// The closed set of logical attribute data types (`DataAttributeEntry`,
/// csra4).
///
/// The discriminator enum for the `DataAttributeEntry` `@OneOf` group: it picks
/// which type-specific options subsection applies — a text attribute carries
/// `textTypeOptions`, a numeric one `numericTypeOptions`, a temporal one
/// `temporalTypeOptions`, a binary one `binaryTypeOptions`, a file reference
/// `fileReferenceOptions`, an enumerated one `enumerationTypeOptions`.
/// [boolean], [uuid] and [json] carry no per-kind attributes and so bind no
/// case; each says below why, so the validator's coverage warning reads as a
/// decision rather than an omission. Replaces the former free-text `dataType`.
enum DataAttributeKind {
  // Text facet.
  /// Character data of bounded length. Binds
  /// [DataAttributeEntry.textTypeOptions], whose two attributes are what a text
  /// column cannot be emitted without: the length fixes the physical
  /// `VARCHAR(n)`, and the collation fixes how comparison and sorting behave
  /// (`codespecs_mapping.md` §5.13).
  string,
  // Numeric facet.
  /// An exact whole number. Shares [DataAttributeEntry.numericTypeOptions] with
  /// [decimal], which carries precision and scale; an integer attribute leaves
  /// the scale at zero. It stays a constant of its own rather than a decimal
  /// with scale zero because the emitted column type differs, and because
  /// "whole number" is a statement about the domain that a zero scale only
  /// implies.
  integer,
  /// An exact fixed-point number. The distinction from [integer] is the scale:
  /// only a decimal may set a non-zero one, and the scale is a business fact —
  /// a monetary amount rounded to two places and one rounded to four are
  /// different specifications, and the difference is invisible in the physical
  /// type alone.
  decimal,
  // Temporal facet.
  /// A calendar date with no time of day. Shares
  /// [DataAttributeEntry.temporalTypeOptions] with [dateTime], but the timezone
  /// attribute that option set carries is inert here: a date names a day, not
  /// an instant, so it must not shift when read in another zone. Storing a date
  /// as an instant to reuse one type is the classic way to make a birthday
  /// move.
  date,
  /// An instant — a date together with a time of day. The kind for which the
  /// shared temporal timezone attribute is load-bearing: one instant renders as
  /// two different wall-clock readings in two zones, so the specification has
  /// to say which reading is stored (`ISO 8601-1:2019` is the representation
  /// authority named on that option set).
  dateTime,
  // Binary facet.
  /// Raw bytes held in the record itself, so what a specification constrains is
  /// their stored size — see [DataAttributeEntry.binaryTypeOptions]. Bytes held
  /// *outside* the record are [fileReference], which is a separate kind rather
  /// than a storage mode of this one.
  binary,

  /// An attribute whose stored value is the **address of a stored file**, not
  /// the file's content (csra10).
  ///
  /// Separate from [binary] on the axis of *what the record holds*: a binary
  /// attribute holds the bytes, so its options constrain their stored size; a
  /// file reference holds an address, so its options say where the file is
  /// filed, which store holds it, whether it dies with the record and what may
  /// be uploaded into it. Nothing in the binary option set answers any of
  /// those, which is why this is a kind of its own rather than a mode of
  /// [binary].
  fileReference,

  /// A two-valued attribute. It binds no case because a truth value has nothing
  /// to constrain: no length, no precision, no range, no value set. The whole
  /// of its CE-DB surface is its value type (`codespecs_mapping.md` §5.13),
  /// which the discriminator itself already states.
  boolean,

  /// An attribute holding a generated unique identifier. It binds no case
  /// because a specification chooses nothing about one: the value is machine-
  /// generated rather than authored, in the same way a file reference's stored
  /// address is derived and never authored (`codespecs_mapping.md` §5.13.1).
  /// Whether the identifier is the entity's key is the entity's identity
  /// attribute, not this attribute's type option.
  uuid,

  /// An attribute whose stored value is a structured document rather than a
  /// scalar. It binds no case because `codespecs_mapping.md` §5.13's attribute
  /// surface carries the kind as a single flag — the substrate's
  /// `TomDbColumn.isJson` — with no payload beside it, and the flag follows
  /// from this constant. It deliberately carries **no schema reference**: a
  /// JSON payload whose shape is known is modelled as nested data entities, and
  /// one whose shape is only *checked* is checked by a constraint
  /// (`DataAttributeConstraintEntry`, CE-VA), so a schema attribute here would
  /// be a second home for one of those two answers.
  json,

  /// An attribute drawn from a declared value set — a domain enum.
  ///
  /// It binds [DataAttributeEntry.enumerationTypeOptions], which names
  /// **which** domain enum the attribute is typed by. That is not optional
  /// detail: the emitted column's value type *is* the generated enum type
  /// (`TomDbColumn<DART_TYPE, …>`), so without the name the column cannot be
  /// emitted at all. Naming the registry entry rather than restating its values
  /// keeps the single source `DomainEnumRegistry` declares, and matches how
  /// every other enumerated value in the model is typed — an operation member
  /// (`SVOPM.domainEnum`) and a report parameter (`codespecs_mapping.md`
  /// §5.13's sibling surface) both name the enum rather than listing it.
  ///
  /// Narrowing — this attribute permitting only *some* of the enum's values —
  /// is a constraint, so it stays in the `constraints` list
  /// (`DATAA.allowedValues`) where every other per-attribute restriction lives.
  enumeration,
}

/// The closed set of schema-migration artifact kinds
/// (`SchemaMigrationStepEntry`).
///
/// The discriminator enum for the `SchemaMigrationStepEntry` `@OneOf` group.
/// The three kinds are not variants of one shape — each authors a different
/// thing, so each binds its own case subsection:
///
/// - [initialDdl] establishes the baseline schema. There is no prior state, so
///   it has nothing to backfill and nothing to roll back to.
/// - [referenceData] inserts *rows*, not schema. It cannot be authored in a
///   form whose fields are named for schema statements.
/// - [schemaChange] evolves an existing schema, and is the only kind for which
///   affected entities, backfill and reversibility are meaningful.
enum MigrationArtifactKind {
  /// The baseline schema definition — the tables, indexes and constraints the
  /// system starts from.
  initialDdl,

  /// The new system's own initial reference data — lookup values, defaults and
  /// built-in roles. Not business-data migration from a legacy system, which
  /// stays in the migration-mapping sections (`MIGME`).
  referenceData,

  /// An append-only schema-evolution step applied on top of the baseline.
  schemaChange,
}

/// 7. Business Object and Data Model. Seeds → IFM.
@StandardReferences(
  [
    'DAMA-DMBOK2 — data management body of knowledge',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ],
  'Captures the complete information and data model for the target system, seeding the Information Model (IFM) document.',
)
@SectionId('INDM')
@Comment('Seeds → IFM')
@MapsTo(D03InformationModel)
@NoArtifact(
  NoArtifactReason.container,
  note:
      'chapter node; its children are routed individually because they feed '
      'different parts',
)
class InformationAndDataModel extends DocSpecsSection {
  @ContentHelp('''
Conceptual overview of the business data the system manages. This chapter
establishes the foundation for all data-related specifications and seeds the
IFM (Information Model) document.

**Key Components:**
- **Data Model** — Entity definitions with attributes, keys, indexes, and relationships
- **Business Object Model** — Domain objects with lifecycle states, operations, and invariants
- **Function Model** — Business functions with decomposition and data access matrix

**Best Practices:**
- Follow Domain-Driven Design patterns (AggregateRoot, Entity, ValueObject)
- Use SBVR-style business rule statements
- Apply data classification framework (ISO 27001, NIST)
- Document CRUD access patterns in function-to-data matrix
- Include compliance frameworks (GDPR, HIPAA, SOX, PCI-DSS) for PII/PHI data
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.1. Data Model.
  @SerializationOrder(1)
  DataModel dataModel = DataModel();

  /// 7.2. Business Object Model.
  @SerializationOrder(2)
  BusinessObjectModel businessObjectModel = BusinessObjectModel();

  /// 7.3. Function Model.
  @SerializationOrder(3)
  FunctionModel functionModel = FunctionModel();

  /// 7.4. Schema Versioning and Migration.
  @SerializationOrder(4)
  SchemaVersioningAndMigration schemaVersioningAndMigration =
      SchemaVersioningAndMigration();

  /// 7.5. Domain Enum Registry.
  @SerializationOrder(5)
  DomainEnumRegistry domainEnumRegistry = DomainEnumRegistry();

  /// 7.6. Error Code Registry.
  @SerializationOrder(6)
  ErrorCodeRegistry errorCodeRegistry = ErrorCodeRegistry();

  /// 7.7. Result Envelope.
  @SerializationOrder(7)
  ResultEnvelope resultEnvelope = ResultEnvelope();

  /// 7.8. Message Key Registry.
  @SerializationOrder(8)
  MessageKeyRegistry messageKeyRegistry = MessageKeyRegistry();

  /// 7.9. Server Operation Registry.
  ///
  /// The system's **own** operation surface (CE-API): one entry per operation
  /// the server answers, with its request/response members, the data entity it
  /// primarily writes, and its authorization requirement.
  @SerializationOrder(9)
  ServerOperationRegistry serverOperationRegistry = ServerOperationRegistry();

  /// 7.10. Data Model Follow-up Facets.
  ///
  /// Per-entity operational/governance facets (volume, compliance, technical
  /// characteristics, migration mappings) and the model-wide ER diagram —
  /// separated from `dataModel` so the entity/attribute subtree stays purely
  /// CE-DB / CE-VA generation-owned while these follow-up facets are authored
  /// alongside, keyed back to their source entity.
  @SerializationOrder(10)
  DataModelFollowUp dataModelFollowUp = DataModelFollowUp();
}

// ---------------------------------------------------------------------------
// 7.1 Data Model
// ---------------------------------------------------------------------------

/// 7.1. Data Model.
@StandardReferences(
  [
    'DAMA-DMBOK2 — data management body of knowledge',
    'ER modeling (Chen / Barker notation)',
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ],
  'Defines the conceptual data model: entities, attributes, relationships, and constraints representing core business data.',
)
@SectionId('DATMD')
@MapsTo(D03InformationModel)
@CodeSpecKind([CodeSpecPart.dataAccess])
class DataModel extends DocSpecsSection {
  @ContentHelp('''
Conceptual data model from a business perspective. Defines the entities,
attributes, relationships, and constraints that represent core business data.

**Subsections:**
- Entity Overview — Comprehensive entity definitions with attributes, keys, indexes, and constraints
- Entity Relationships — Relationship specifications with cardinality and referential integrity
- Data Classification — Security classification framework with handling requirements

**Entity Coverage per Entry:**
- Core Identity (name, table, alias, description, stereotype)
- Classification (category, bounded context, domain, ownership)
- Lifecycle Policy (retention, archival, anonymization, audit)
- Relationships Summary (parent, child, referenced, cross-domain)
- Attributes, key attributes, indexes, and constraints

Per-entity operational facets (volume metrics, compliance requirements,
technical characteristics, migration mappings) and the model-wide ER diagram
are authored in the Data Model Follow-up Facets section (7.9).
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.1.1. Entity Overview — contains 1+× Data Entity.
  @StandardReferences([
    'ER modeling (Chen / Barker notation)',
    'DAMA-DMBOK2 — data management body of knowledge',
  ], 'The data entities that make up the logical data model.')
  @SectionId('DAENT-ENTI-LST')
  @SectionIdPattern('DAENT-ENTI-xxx')
  @Min(1)
  @ContentHelp('Add one entry per data entity.')
  @SerializationOrder(1)
  List<DataEntityEntry> entities = [];

  /// 7.1.2. Entity Relationships.
  @SerializationOrder(2)
  EntityRelationships entityRelationships = EntityRelationships();

  /// 7.1.3. Data Classification.
  @SerializationOrder(3)
  DataClassification dataClassification = DataClassification();

  /// 7.1.4. Data Dictionary..
  @SerializationOrder(4)
  DataDictionary dataDictionary = DataDictionary();

  /// 7.1.5. Validation Constraints.
  ///
  /// One whole-catalog content section (mirrors `dataDictionary`); collapsed
  /// from `List<ValidationConstraints>` (L34C-12 SR-25).
  @SerializationOrder(5)
  ValidationConstraints validationConstraints = ValidationConstraints();

  /// 7.1.6. Integrity Constraints.
  ///
  /// One whole-catalog content section (mirrors `dataDictionary`); collapsed
  /// from `List<IntegrityConstraints>` (L34C-12 SR-25).
  @SerializationOrder(6)
  IntegrityConstraints integrityConstraints = IntegrityConstraints();
}

// ---------------------------------------------------------------------------
// 7.10 Data Model Follow-up Facets
// ---------------------------------------------------------------------------

/// 7.10. Data Model Follow-up Facets.
///
/// Operational and governance facets that accompany the data model but are not
/// part of the generation-owned entity/attribute schema: the model-wide ER
/// diagram plus per-entity volume, compliance, technical, and migration
/// facets. Each per-entity block references its source entity by name/alias so
/// the facets stay correlated with `dataModel.entities` without being nested
/// inside the generation-owned `DataEntityEntry`.
@StandardReferences(
  [
    'DAMA-DMBOK2 — data management body of knowledge',
    'ER modeling (Chen / Barker notation)',
  ],
  'Per-entity operational/governance follow-up facets and the model-wide ER diagram, kept separate from the generation-owned data model.',
)
@FollowUpKind([
  FollowUpProcess.doc,
  FollowUpProcess.cap,
  FollowUpProcess.cmp,
  FollowUpProcess.mig,
])
@SectionId('DMFU')
class DataModelFollowUp extends DocSpecsSection {
  @ContentHelp('''
Follow-up facets for the data model. These describe operational, capacity,
compliance, and migration concerns that accompany — but are not part of — the
core entity/attribute schema.

**Subsections:**
- ER Diagram — Visual entity-relationship diagram (Mermaid)
- Per-entity follow-up facets — Volume, compliance, technical characteristics,
  and migration mappings for each entity in the data model
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.10.1. Entity-Relationship Diagram (mermaid).
  @SerializationOrder(1)
  ErDiagramSection erDiagram = ErDiagramSection();

  /// 7.10.2. Per-Entity Follow-up Facets — contains 0+× Entity Follow-up.
  @StandardReferences([
    'DAMA-DMBOK2 — data management body of knowledge',
    'ISO/IEC 25012 — data quality',
  ], 'Per-entity operational, compliance, technical, and migration facets keyed to the source entity.')
  @SectionId('DMFUE-ENFU-LST')
  @SectionIdPattern('DMFUE-ENFU-xxx')
  @ContentHelp('Add one entry per entity that carries follow-up facets.')
  @SerializationOrder(2)
  List<EntityFollowUpEntry> entityFollowUps = [];
}

/// A per-entity follow-up facet block (form + lists).
///
/// Groups the volume, compliance, technical, and migration facets for a single
/// data entity, correlated back to `dataModel.entities` by name/alias.
@StandardReferences(
  [
    'DAMA-DMBOK2 — data management body of knowledge',
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
  ],
  'The operational, compliance, technical, and migration follow-up facets for one data entity.',
)
@SectionId('DMFUE')
class EntityFollowUpEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this entity\'s follow-up facets — operational context '
    'the volume, compliance, technical and migration lists below do not '
    'capture.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  // ---------------------------------------------------------------------------
  // Entity reference (2 fields)
  // ---------------------------------------------------------------------------
  /// Which entity these follow-up facets describe.
  ///
  /// The facets below are operational and governance material rather than part
  /// of the generation-owned entity schema, which is why the block sits outside
  /// [DataEntityEntry] rather than inside it — and that is exactly what makes a
  /// correlation key necessary. The entry headline carries the entity name and
  /// this band carries the short alias used in diagrams and narrative. Point it
  /// at the wrong entity and both halves stay well-formed on their own, so
  /// nothing detects the error; it is worth checking against
  /// `dataModel.entities` when the block is written.
  @SectionId('DMFUE-ENTI')
  @Form([
    Field(
      'entityAlias',
      String,
      'Alias/Abbreviation',
      hint: 'Short alias of the referenced entity (e.g., CUST, ORD)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? entityRef;

  // ---------------------------------------------------------------------------
  // Volume and Growth
  // ---------------------------------------------------------------------------
  /// How much data this entity accumulates, and how fast.
  ///
  /// Sizing evidence rather than schema: record counts, growth rates and
  /// storage estimates are what an infrastructure, indexing or archival
  /// decision is argued from, and they change with the business rather than
  /// with the model. A list because one entity is sized differently per
  /// environment and per planning horizon, and each figure needs its own basis
  /// to be trusted. The retention policy that acts on these numbers is authored
  /// on the entity itself (`DAENT-LIFE`), not here.
  @StandardReferences(
    [
      'DAMA-DMBOK2 — data management body of knowledge',
      'ISO/IEC 25012 — data quality',
    ],
    'Volume and growth metrics for the entity, such as record counts, growth rate, and storage estimates.',
  )
  @SectionId('VOLUM-VOLU-LST')
  @SectionIdPattern('VOLUM-VOLU-xxx')
  @ContentHelp('Add one entry per volume metric.')
  @SerializationOrder(2)
  List<VolumeMetricEntry> volumeMetrics = [];

  // ---------------------------------------------------------------------------
  // Compliance and Security
  // ---------------------------------------------------------------------------
  /// The regulatory obligations this entity's data carries.
  ///
  /// The per-entity view — "this entity holds PII, therefore these rules apply
  /// to it". The scheme the rules are drawn from is authored once in
  /// [DataClassification], and individual attributes carry their own
  /// sensitivity in `DAATT-SECU`; an entry here is what ties a named regulation
  /// to a named entity, which is the link an audit follows and the one a
  /// classification level on its own cannot supply.
  @StandardReferences(
    [
      'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
      'ISO/IEC 27001 / NIST — data classification',
    ],
    'Compliance and security requirements for the entity, covering sensitivity, PII/PHI, encryption, and access.',
  )
  @SectionId('CRE-COMP-LST')
  @SectionIdPattern('CRE-COMP-xxx')
  @ContentHelp('Add one entry per compliance requirement.')
  @SerializationOrder(3)
  List<ComplianceRequirementEntry> complianceRequirements = [];

  // ---------------------------------------------------------------------------
  // Technical Characteristics
  // ---------------------------------------------------------------------------
  /// Runtime behaviour expected of this entity's storage — indexing, caching,
  /// consistency and scaling.
  ///
  /// Separated from the entity's `ENIDX` index list by who decides it: an index
  /// is a concrete schema object the data-access derivation emits
  /// (`codespecs_mapping.md` §5.13), while a characteristic here is an
  /// operational expectation an implementation may satisfy in more than one
  /// way. Keeping it out of the generation-owned model is deliberate — stated
  /// there it would read as an instruction to emit something.
  @StandardReferences(
    [
      'DAMA-DMBOK2 — data management body of knowledge',
      'ISO/IEC 25012 — data quality',
    ],
    'Technical characteristics of the entity, such as indexing, caching, consistency, and scaling behavior.',
  )
  @SectionId('TECHN-TECH-LST')
  @SectionIdPattern('TECHN-TECH-xxx')
  @ContentHelp('Add one entry per technical characteristic.')
  @SerializationOrder(4)
  List<TechnicalCharacteristicEntry> technicalCharacteristics = [];

  // ---------------------------------------------------------------------------
  // Migration Mappings
  // ---------------------------------------------------------------------------
  /// Where this entity's data comes from when a legacy system is replaced.
  ///
  /// Source-to-target field mappings, one per source field, so a cutover can be
  /// planned and its coverage checked field by field. Distinct from the
  /// per-attribute lineage in `DAATT-MIGR`, which records the standing
  /// provenance of one attribute; this list is the plan for a one-off load and
  /// is expected to be retired once it has run. Evolution of the *new* system's
  /// own schema is a third subject and lives in [SchemaMigrationStepEntry]
  /// (`codespecs_mapping.md` §5.27).
  @StandardReferences(
    [
      'DAMA-DMBOK2 — data management body of knowledge',
      'ISO/IEC 25012 — data quality',
    ],
    'Source-to-target field mappings for planning the migration of data into this entity.',
  )
  @SectionId('MIGME-MIGR-LST')
  @SectionIdPattern('MIGME-MIGR-xxx')
  @ContentHelp('Add one entry per migration mapping.')
  @SerializationOrder(5)
  List<MigrationMappingEntry> migrationMappings = [];
}

/// A data entity entry (form).
///
/// Comprehensive entity specification following data modeling best practices.
/// Captures conceptual, logical, and physical design aspects.
///
/// **The aggregate is authored, not inferred.** `DAENT-CLAS.aggregateRoot`
/// names the root entity of the aggregate this entity belongs to, and a root
/// names itself — so "is this a root?" is the string equality
/// `aggregateRoot == entityName`, not a judgment about lifecycles and
/// cardinalities. That matters because the aggregate is the **ownership key**
/// for three separate CodeSpecs areas (`codespecs_mapping.md` §5.1): it fixes
/// which `@CsServiceUnit` exists and what it is called, which CE-DB tables and
/// repositories that unit owns, and which CE-API operations land on it. A
/// derivation that had to guess the grouping would guess it three times, once
/// per area, with nothing making the three agree.
///
/// `DAENT-CLAS.serviceUnitAggregate` is the one place the grouping is allowed
/// to be adjusted: business-process cohesion sometimes merges two aggregates
/// into one unit or splits one across two, and stating that per entity keeps
/// even the exception readable. Empty means no adjustment.
@StandardReferences(
  [
    'ER modeling (Chen / Barker notation)',
    'Domain-Driven Design — aggregates/entities/value objects',
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ],
  'A single data entity with its identity, classification, lifecycle, relationships, attributes, keys, indexes, and constraints.',
)
@SectionId('DAENT')
@CodeSpecKind(
  [CodeSpecPart.dataAccess, CodeSpecPart.serviceUnit, CodeSpecPart.serverApi],
  note: 'Entity + attributes → CE-DB table/columns; the aggregate fields in '
      'DAENT-CLAS → the CE-SU unit boundary and its ownership key '
      '(codespecs_mapping.md §5.1). An entity a server-operation member is '
      'typed by (SVOPM.dataEntity) also crosses the wire as the shared '
      'CE-API entity wire DTO (codespecs_derivation_contract.md §3.2.11), '
      'which is why the entity facts reach the CE-API extract.',
)
class DataEntityEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this data entity — what it represents in the business, '
    'beyond the identity, attribute and key facets recorded below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  // ---------------------------------------------------------------------------
  // Core Identity (5 fields)
  // ---------------------------------------------------------------------------
  /// What this entity is called, in each vocabulary that needs a name for it.
  ///
  /// One entity is named four times over — logically, physically, in diagrams,
  /// and as a design pattern — and a model that keeps only one of those names
  /// makes every later reader re-derive the rest. The logical name is what the
  /// rest of the model refers to; the physical name is what the CE-DB table is
  /// emitted as (`codespecs_mapping.md` §5.13). Aggregate-root-ness is
  /// deliberately not part of the stereotype recorded here: it is read from
  /// `DAENT-CLAS.aggregateRoot`, the only field that states it.
  @SectionId('DAENT-IDEN')
  @Form([
    Field(
      'entityName',
      String,
      'Entity Name',
      required: true,
      hint: 'Singular noun or noun phrase (e.g., Customer, OrderItem)',
    ),
    Field(
      'tableName',
      String,
      'Physical Table Name',
      hint: 'Database table name if different from logical name',
    ),
    Field(
      'entityAlias',
      String,
      'Alias/Abbreviation',
      hint: 'Short alias for diagrams and references (e.g., CUST, ORD)',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Clear definition of what this entity represents',
    ),
    Field(
      'entityStereoType',
      String,
      'Stereotype',
      hint: 'Entity pattern: Entity | ValueObject | Event | View | Bridge. '
          'Aggregate-root-ness is not a stereotype here — it is read from '
          'aggregateRoot below, which is the only field that states it',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Classification (6 fields)
  // ---------------------------------------------------------------------------
  /// Where this entity sits in the domain, and who answers for it.
  ///
  /// Grouping and accountability, as against the naming in `DAENT-IDEN` and the
  /// shape in the attribute list. It is a band of its own because its first
  /// fields are read by something other than a human — the bounded context and
  /// the aggregate root fix the service-unit boundary and its ownership key
  /// (`codespecs_mapping.md` §5.1), as the class comment above sets out — while
  /// the owner, steward and source-system fields are governance facts no
  /// derivation reads. Both halves answer the same question, whose entity is
  /// this, which is why they share a band rather than being split apart.
  @SectionId('DAENT-CLAS')
  @Form([
    Field(
      'category',
      String,
      'Category',
      hint:
          'Data category: MasterData | TransactionData | ReferenceData | ConfigurationData | AuditData',
    ),
    Field(
      'boundedContext',
      String,
      'Bounded Context',
      refersTo: ['BCE.contextName'],
      hint: 'Context Name of the bounded context this entity belongs to. This '
          'is the outer bound on service-unit grouping: aggregates in different '
          'contexts are never served by one service unit',
    ),
    Field(
      'aggregateRoot',
      String,
      'Aggregate Root',
      required: true,
      refersTo: ['DAENT.entityName'],
      hint: 'Entity Name of the root of the aggregate this entity belongs to '
          '— a root names itself, so an entity with no enclosing aggregate '
          'names its own Entity Name. This is the ownership key: the service '
          'unit that owns the aggregate owns this entity, its repository, and '
          'every operation that primarily writes it',
    ),
    Field(
      'serviceUnitAggregate',
      String,
      'Service Unit Aggregate',
      refersTo: ['DAENT.entityName'],
      hint: 'Only when business-process cohesion overrides the default '
          'grouping: Entity Name of the aggregate root whose service unit '
          'serves this entity. Several aggregates naming one root is a merge; '
          'one aggregate whose entities name different roots is a split. '
          'Empty means the aggregate named above',
    ),
    Field(
      'owningDomain',
      String,
      'Owning Domain',
      hint: 'Business domain responsible for this entity',
    ),
    Field(
      'dataOwner',
      String,
      'Data Owner',
      hint: 'Role or team accountable for data quality',
    ),
    Field(
      'dataSteward',
      String,
      'Data Steward',
      hint: 'Person or role responsible for data governance',
    ),
    Field(
      'sourceSystem',
      String,
      'Source System',
      hint: 'System of record or originating system for migration',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? classification;

  // ---------------------------------------------------------------------------
  // Lifecycle and Retention (8 fields)
  // ---------------------------------------------------------------------------
  /// What becomes of this entity's rows over time: how long they are kept,
  /// where they go next, and what is recorded about the change.
  ///
  /// Separate from the classification band because retention is decided by a
  /// different authority on a different clock — a statute or a privacy
  /// regulation sets the period, and it changes when the regulation changes,
  /// not when the model does. It is authored per entity rather than per
  /// sensitivity level because two entities at the same level routinely carry
  /// different statutory periods; where a level imposes a floor on all of them,
  /// that floor is stated once in [DataClassificationEntry] instead.
  @SectionId('DAENT-LIFE')
  @Form([
    Field(
      'lifecyclePhases',
      String,
      'Lifecycle Phases',
      hint:
          'Phases: Active → Archived → Purged, or Active → Soft-deleted → Hard-deleted',
    ),
    Field(
      'retentionPolicy',
      String,
      'Retention Policy',
      hint:
          'How long data is retained and why (e.g., 7 years per tax regulations)',
    ),
    Field(
      'archivalTrigger',
      String,
      'Archival Trigger',
      hint:
          'Condition for moving to archive (e.g., 2 years after last activity)',
    ),
    Field(
      'archivalDestination',
      String,
      'Archival Destination',
      hint: 'Where archived data goes: ColdStorage | Archive | DataLake',
    ),
    Field(
      'purgePolicy',
      String,
      'Purge Policy',
      hint: 'When and how data is permanently deleted',
    ),
    Field(
      'anonymizationPolicy',
      String,
      'Anonymization Policy',
      hint: 'PII anonymization rules (e.g., hash email after deletion)',
    ),
    Field(
      'auditRequirements',
      String,
      'Audit Requirements',
      hint:
          'What changes must be tracked: None | KeyFields | AllFields | FullHistory',
    ),
    Field(
      'auditRetention',
      String,
      'Audit Retention',
      hint: 'How long audit records are kept',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? lifecyclePolicy;

  // ---------------------------------------------------------------------------
  // Relationships Summary (4 fields)
  // ---------------------------------------------------------------------------
  /// The entity's relationships as seen from this entity — a digest, not the
  /// authority.
  ///
  /// The authored relationship is [EntityRelationshipEntry], which states each
  /// one once with its cardinality, referential integrity and navigation. This
  /// band exists so a reader of a single entity can see what it depends on
  /// without assembling that list in their head. The consequence is that it
  /// must never be the only place a relationship appears: anything recorded
  /// here and nowhere else is invisible to every consumer that reads the
  /// relationship entries, and stale content here is a documentation defect
  /// rather than a model change.
  @SectionId('DAENT-RELA')
  @Form([
    Field(
      'parentEntities',
      String,
      'Parent Entities',
      hint: 'Entities this depends on (e.g., Order depends on Customer)',
    ),
    Field(
      'childEntities',
      String,
      'Child Entities',
      hint: 'Entities that depend on this (e.g., OrderItem depends on Order)',
    ),
    Field(
      'referencedEntities',
      String,
      'Referenced Entities',
      hint: 'Lookup/reference entities used (e.g., OrderStatus, PaymentMethod)',
    ),
    Field(
      'crossDomainRelationships',
      String,
      'Cross-Domain Relationships',
      hint: 'Relationships that cross bounded context boundaries',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? relationshipSummary;

  /// Contains 0+× DataAttribute.
  @StandardReferences([
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'DAMA-DMBOK2 — data management body of knowledge',
  ], 'The data attributes (fields) that belong to this entity.')
  @SectionId('DAATT-ATTR-LST')
  @SectionIdPattern('DAATT-ATTR-xxx')
  @ContentHelp('Add one entry per data attribute.')
  @SerializationOrder(5)
  List<DataAttributeEntry> attributes = [];

  /// Contains 0+× KeyAttribute.
  @StandardReferences(
    [
      'ER modeling (Chen / Barker notation)',
      'ISO/IEC 11179 — metadata registries / data element definitions',
    ],
    'The key attributes (primary, foreign, alternate, composite) that identify or reference this entity.',
  )
  @SectionId('KEATT-KEYA-LST')
  @SectionIdPattern('KEATT-KEYA-xxx')
  @ContentHelp('Add one entry per key attribute.')
  @SerializationOrder(6)
  List<KeyAttributeEntry> keyAttributes = [];

  /// Contains 0+× EntityIndex.
  @StandardReferences([
    'DAMA-DMBOK2 — data management body of knowledge',
    'ISO/IEC 25012 — data quality',
  ], 'The database indexes defined on this entity for query optimization.')
  @SectionId('ENIDX-INDE-LST')
  @SectionIdPattern('ENIDX-INDE-xxx')
  @ContentHelp('Add one entry per entity index.')
  @SerializationOrder(7)
  List<EntityIndexEntry> indexes = [];

  /// Contains 0+× EntityConstraint.
  @StandardReferences(
    ['SBVR — business rule statements', 'ISO/IEC 25012 — data quality'],
    'Business and technical constraints on the entity beyond keys, such as check, unique, and exclusion constraints.',
  )
  @SectionId('ENCNS-CONS-LST')
  @SectionIdPattern('ENCNS-CONS-xxx')
  @ContentHelp('Add one entry per entity constraint.')
  @SerializationOrder(8)
  List<EntityConstraintEntry> constraints = [];
}

/// A data attribute entry (form).
///
/// Comprehensive attribute specification for data dictionary and schema design.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'DAMA-DMBOK2 — data management body of knowledge',
    'ISO/IEC 25012 — data quality',
  ],
  'A single data attribute with its data type, constraints, derivation, security classification, lineage, and display properties.',
)
@SectionId('DAATT')
@OneOf(
  discriminator: 'dataType',
  noCase: [
    DataAttributeKind.boolean,
    DataAttributeKind.uuid,
    DataAttributeKind.json,
  ],
  note:
      'Attribute data-type closed choice (csra4): the logical type selects its '
      'promoted options subsection (text / numeric / temporal / binary / file '
      'reference / enumeration); boolean, uuid and json carry only the common '
      'type and constraint subsections, each for the reason stated at its '
      'constant.',
)
@CodeSpecKind([CodeSpecPart.dataAccess, CodeSpecPart.serverApi],
    note: 'A persisted attribute becomes a table column; a file-reference '
        'attribute becomes a file-reference column (csra10); display/label '
        'detail feeds CE-TX/CE-ST via DisplayPropertyEntry. The attribute '
        'set also types the CE-API entity wire DTO of an entity that '
        'crosses the wire (codespecs_derivation_contract.md §3.2.11).')
class DataAttributeEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this attribute — what it means and how it is used, '
    'beyond the type, constraint and lineage facets recorded below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  // ---------------------------------------------------------------------------
  // Core Identity (5 fields)
  // ---------------------------------------------------------------------------
  /// What this attribute is called and what it means, in business terms.
  ///
  /// The band that answers "what is this field?" for a reader who is not
  /// looking at a database: the physical column name, the definition, the
  /// glossary term it maps to, and concrete example values. It is deliberately
  /// free of type and constraint information — those are the two bands below —
  /// because this is the part a domain expert reviews, and the only part that
  /// survives a change of storage technology unchanged. The attribute's own
  /// name is the entry headline, not a field here.
  @SectionId('DAATT-IDEN')
  @Form([
    Field(
      'columnName',
      String,
      'Physical Column Name',
      hint: 'Database column name if different (e.g., snake_case)',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Clear definition of what this attribute represents',
    ),
    Field(
      'businessTerm',
      String,
      'Business Term',
      hint: 'Business glossary term this maps to',
    ),
    Field(
      'exampleValues',
      String,
      'Example Values',
      hint: 'Comma-separated examples (e.g., "Draft, Confirmed, Shipped")',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Data Type Specification — the @OneOf discriminator plus the attributes
  // that apply to every logical type (csra4).
  // ---------------------------------------------------------------------------
  /// The logical type of the attribute, and the physical form it is realised
  /// in.
  ///
  /// This band carries the `@OneOf` discriminator, so it is the one place in
  /// the entry that changes the entry's own shape: choosing the logical type
  /// selects which per-kind options subsection applies. What stays here is only
  /// what every kind has — the logical type, the database type it becomes
  /// (`codespecs_mapping.md` §5.13), and the display or storage format. A
  /// length, a precision or a timezone belongs to its kind's options, not here,
  /// so that an attribute can never carry a constraint its type cannot honour.
  @SectionId('DAATT-DATA')
  @Form([
    Field(
      'dataType',
      DataAttributeKind,
      'Data Type',
      hint: 'The logical type — selects the promoted options subsection.',
    ),
    Field(
      'physicalType',
      String,
      'Physical Type',
      hint: 'Database type: VARCHAR(255), BIGINT, DECIMAL(10,2), TIMESTAMP',
    ),
    Field(
      'format',
      String,
      'Format',
      hint: 'Display or storage format (e.g., YYYY-MM-DD, E.164 for phone)',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? dataTypeSpec;

  /// Text-kind type options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for the `string` logical type; carries only the character
  /// length and collation attributes (no numeric precision, no timezone).
  @SectionId('DAATT-DTTX')
  @StandardReferences(
    [
      'ISO/IEC 11179 — permissible value and representation of a data element',
      'ISO/IEC 25012 — data quality characteristics for stored text',
    ],
    'The character length and collation constraints for a text attribute.',
  )
  @Case(DataAttributeKind.string)
  @Form([
    Field(
      'length',
      String,
      'Length',
      hint: 'Maximum character length',
    ),
    Field(
      'collation',
      String,
      'Collation',
      hint: 'Character collation for text (e.g., utf8_general_ci)',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? textTypeOptions;

  /// Numeric-kind type options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for numeric logical types; carries only the precision and
  /// scale attributes (no length, collation or timezone).
  @SectionId('DAATT-DTNU')
  @StandardReferences(
    [
      'ISO/IEC 11179 — permissible value and representation of a data element',
      'ISO 80000-1 — quantities and units, on numeric precision',
    ],
    'The precision and scale constraints for a numeric attribute.',
  )
  @Case(DataAttributeKind.integer)
  @Case(DataAttributeKind.decimal)
  @Form([
    Field(
      'precision',
      String,
      'Precision',
      hint: 'Total digits for numeric types',
    ),
    Field('scale', String, 'Scale', hint: 'Decimal places for numeric types'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? numericTypeOptions;

  /// Temporal-kind type options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for date/time logical types; carries only the timezone
  /// handling attribute.
  @SectionId('DAATT-DTTM')
  @StandardReferences(
    [
      'ISO 8601-1:2019 — representation of dates and times',
      'ISO 8601-2:2019 — extensions including time-zone offsets',
    ],
    'The timezone handling for a date or date-time attribute.',
  )
  @Case(DataAttributeKind.date)
  @Case(DataAttributeKind.dateTime)
  @Form([
    Field(
      'timezone',
      String,
      'Timezone',
      hint: 'For datetime: UTC | Local | WithOffset',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? temporalTypeOptions;

  /// Binary-kind type options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for the `binary` logical type — the record holds the **bytes
  /// themselves** — so it carries only the stored size. Separated from the text
  /// `length` because a byte size and a character length are different
  /// constraints on different types. An attribute that holds a file's *address*
  /// instead is `DataAttributeKind.fileReference` (csra10), not a storage mode
  /// of this one: a mode field would restate the logical type and could then
  /// disagree with it.
  @SectionId('DAATT-DTBI')
  @StandardReferences(
    ['ISO/IEC 11179 — permissible value and representation of a data element'],
    'The stored size constraints for a binary attribute.',
  )
  @Case(DataAttributeKind.binary)
  @Form([
    Field(
      'maxSizeBytes',
      String,
      'Max Size (Bytes)',
      hint: 'Maximum stored size in bytes',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? binaryTypeOptions;

  /// File-reference type options — a promoted `@OneOf` case (csra10).
  ///
  /// Present only for the `fileReference` logical type: the attribute stores
  /// the **address of a stored file**, so what a specification must say is
  /// where the file is filed, which store holds it, whether it dies with its
  /// record, and what may be uploaded into it.
  ///
  /// The address itself is never authored — it is generated when the file is
  /// stored, so a specification chooses only the group it is filed under. The
  /// vocabulary here is deliberately storage-neutral (`codespecs_mapping.md`
  /// §1.2): a *file store* is named, never a storage technology.
  ///
  /// Two decisions that look like they belong here are elsewhere by design:
  /// **who may fetch the file** is the attribute's own access classification —
  /// the address is an ordinary attribute, so its security classification
  /// already governs it — and **how the file appears on screen** (a thumbnail,
  /// a link, a download) is a screen-element concern, authored where the
  /// element is.
  @SectionId('DAATT-DTFR')
  @StandardReferences(
    [
      'ISO/IEC 11179 — permissible value and representation of a data element',
      'RFC 6838 — media type specifications and registration procedures',
    ],
    'Where a referenced file is stored, how long it lives and what may be '
    'uploaded into it.',
  )
  @Case(DataAttributeKind.fileReference)
  @Form([
    Field(
      'storageGroup',
      String,
      'Storage Group',
      required: true,
      hint: 'Naming group the files are filed under — sets their retention and '
          'access partition (e.g. documents/attachment)',
    ),
    Field(
      'fileStore',
      String,
      'File Store',
      hint: 'Name of the configured file store holding the files; empty means '
          'the deployment default store',
    ),
    Field(
      'deleteWithRecord',
      String,
      'Delete With Record',
      hint: 'Yes | No — whether deleting the record also deletes the file '
          '(Yes unless the file outlives its reference by design)',
    ),
    Field(
      'acceptedContentKinds',
      String,
      'Accepted Content Kinds',
      hint: 'Comma-separated content kinds accepted on upload (e.g. PDF, PNG); '
          'empty means unrestricted',
    ),
    Field(
      'defaultContentKind',
      String,
      'Default Content Kind',
      hint: 'Content kind recorded when an upload declares none',
    ),
    Field(
      'maxFileSizeBytes',
      String,
      'Max File Size (Bytes)',
      hint: 'Maximum accepted file size in bytes',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? fileReferenceOptions;

  /// Enumeration-kind type options — a promoted `@OneOf` case.
  ///
  /// Present only for the `enumeration` logical type, and carrying exactly one
  /// thing: **which** domain enum the attribute is typed by. The emitted
  /// column's value type *is* the generated enum type, so an enumerated
  /// attribute that names no enum cannot be emitted — which is why this is a
  /// required field rather than a hint.
  ///
  /// The enum is **named, never restated**. `DomainEnumRegistry` is the single
  /// source for closed value sets, and its entries are what the `domainEnum`
  /// member kind is generated from; listing the values again here would be a
  /// second source that could disagree with the first. The same choice is made
  /// wherever else the model types a value by an enum — an operation request or
  /// response member (`SVOPM.domainEnum`) names its entry the same way.
  ///
  /// How the value is **stored** is not authored here either: the backing type
  /// belongs to the enum (`DMENE.backingType`), so every attribute typed by it
  /// stores it the same way. And *narrowing* — this attribute permitting only
  /// some of the enum's values — is a constraint, authored in the `constraints`
  /// list where every other per-attribute restriction lives.
  @SectionId('DAATT-DTEN')
  @StandardReferences(
    [
      'ISO/IEC 11179 — permissible value and representation of a data element',
    ],
    'The declared value set a domain-enum attribute draws from.',
  )
  @Case(DataAttributeKind.enumeration)
  @Form([
    Field(
      'domainEnum',
      String,
      'Domain Enum',
      required: true,
      hint: 'DomainEnumEntry.enumName this attribute is typed by (e.g. '
          'OrderStatus) — declared once in the domain enum register, not '
          'restated here',
      refersTo: ['DMENE.enumName'],
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? enumerationTypeOptions;

  // ---------------------------------------------------------------------------
  // Constraints and Validation (8 fields)
  // ---------------------------------------------------------------------------
  /// The rules a value of this attribute must satisfy.
  ///
  /// A list rather than a band of fields because an attribute carries an open
  /// number of independent restrictions — nullability, a range, a pattern, an
  /// allowed value set — and each needs its own message and severity to be
  /// usable. This is the CE-VA field-rule surface (`codespecs_mapping.md`
  /// §5.19): a restriction stated here becomes a validator on the emitted
  /// field, whereas one stated only in the attribute's description becomes
  /// nothing. Narrowing an enumerated attribute to a subset of its domain
  /// enum's values belongs here too, not in the type options.
  @StandardReferences(
    ['SBVR — business rule statements', 'ISO/IEC 25012 — data quality'],
    'Validation constraints on this attribute, such as nullability, ranges, patterns, and default values.',
  )
  @SectionId('DATAA-CONS-LST')
  @SectionIdPattern('DATAA-CONS-xxx')
  @ContentHelp('Add one entry per attribute constraint.')
  @SerializationOrder(9)
  List<DataAttributeConstraintEntry> constraints = [];

  // ---------------------------------------------------------------------------
  // Computed and Derived (4 fields)
  // ---------------------------------------------------------------------------
  /// Whether the attribute holds an authored value at all, or one produced from
  /// other values.
  ///
  /// A computed or derived attribute inverts the usual contract: nothing writes
  /// it, so its constraints read as consequences rather than as checks, its
  /// migration mapping is empty by construction, and offering it for editing on
  /// a form is a defect. Left empty, the attribute is ordinary stored data —
  /// which is the common case, and the reason this is a band of its own rather
  /// than fields folded into the type specification, where an empty formula
  /// would look like a missing answer.
  @SectionId('DAATT-DERI')
  @Form([
    Field(
      'isComputed',
      String,
      'Is Computed',
      hint: 'Whether value is computed: Yes | No',
    ),
    Field(
      'computeFormula',
      String,
      'Compute Formula',
      hint: 'Formula or expression for computed fields',
    ),
    Field(
      'isDerived',
      String,
      'Is Derived',
      hint: 'Whether derived from other attributes: Yes | No',
    ),
    Field(
      'derivationLogic',
      String,
      'Derivation Logic',
      hint: 'How derived value is calculated',
    ),
  ])
  @SerializationOrder(10)
  DocSpecsSection? derivation;

  // ---------------------------------------------------------------------------
  // Classification and Security (5 fields)
  // ---------------------------------------------------------------------------
  /// How exposed this single attribute is, independently of its entity.
  ///
  /// Sensitivity is an attribute-level fact. An otherwise ordinary customer
  /// record holds one national-identifier column, and classifying the whole
  /// entity at that column's level over-protects everything else while
  /// classifying it at the entity's level under-protects the column. This band
  /// is therefore where masking, field-level encryption and audit depth are
  /// decided per column. The level names it uses come from the scheme authored
  /// in [DataClassification]; the rules that follow from each level are stated
  /// there once instead of being repeated on every attribute.
  @SectionId('DAATT-SECU')
  @Form([
    Field(
      'sensitivityLevel',
      String,
      'Sensitivity Level',
      hint: 'Public | Internal | Confidential | Restricted | PII | PHI',
    ),
    Field(
      'isPii',
      String,
      'Is PII',
      hint: 'Personally identifiable information: Yes | No',
    ),
    Field(
      'maskingRule',
      String,
      'Masking Rule',
      hint: 'How to mask in logs/displays: None | Partial | Full | Hash',
    ),
    Field(
      'encryptionLevel',
      String,
      'Encryption Level',
      hint: 'Field-level encryption: None | Encrypted | Tokenized',
    ),
    Field(
      'auditLevel',
      String,
      'Audit Level',
      hint: 'Change tracking: None | ValueChanges | FullHistory',
    ),
  ])
  @SerializationOrder(11)
  DocSpecsSection? securityClassification;

  // ---------------------------------------------------------------------------
  // Migration and Lineage (5 fields)
  // ---------------------------------------------------------------------------
  /// Where this attribute's values come from — upstream system, source field
  /// and the transformation applied.
  ///
  /// Provenance, kept beside the attribute so it outlives the migration that
  /// produced it: months later the question is not "how do we load this?" but
  /// "why does this column say that?", and the transformation rule recorded
  /// here is the answer. It sits at attribute level because a transformation is
  /// per-field; the entity-level plan that scopes and schedules the load is
  /// [MigrationMappingEntry] in the follow-up section.
  @SectionId('DAATT-MIGR')
  @Form([
    Field(
      'sourceSystem',
      String,
      'Source System',
      hint: 'Originating system for data lineage',
    ),
    Field(
      'sourceAttribute',
      String,
      'Source Attribute',
      hint: 'Source field name for migration mapping',
    ),
    Field(
      'transformationRule',
      String,
      'Transformation Rule',
      hint: 'Transformation applied during migration/ETL',
    ),
    Field(
      'dataLineage',
      String,
      'Data Lineage',
      hint: 'Upstream sources that feed this attribute',
    ),
    Field(
      'qualityRules',
      String,
      'Quality Rules',
      hint: 'Data quality checks (e.g., completeness, accuracy)',
    ),
  ])
  @SerializationOrder(12)
  DocSpecsSection? migrationLineage;

  // ---------------------------------------------------------------------------
  // UI and Display (4 fields)
  // ---------------------------------------------------------------------------
  /// How this attribute is presented to a user.
  ///
  /// Labels, formatting, ordering and visibility — facts a screen needs and the
  /// data model does not, kept out of the identity band so that changing a
  /// label never looks like renaming a column. A list because one attribute is
  /// shown in more than one place — a grid column, a detail form, a report —
  /// and each presentation has its own label and ordering. This is the material
  /// the screen-element derivation reads (`codespecs_mapping.md` §5.18); an
  /// attribute with no entry here is not hidden, it merely takes the defaults.
  @StandardReferences(
    ['ISO/IEC 11179 — metadata registries / data element definitions'],
    'UI and display properties for this attribute, such as labels, formatting, ordering, and visibility.',
  )
  @SectionId('DISPL-DISP-LST')
  @SectionIdPattern('DISPL-DISP-xxx')
  @ContentHelp('Add one entry per display property.')
  @SerializationOrder(13)
  List<DisplayPropertyEntry> displayProperties = [];
}

/// A key attribute entry (form).
///
/// Specification for primary, foreign, alternate, and composite keys.
@StandardReferences(
  [
    'ER modeling (Chen / Barker notation)',
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ],
  'A single key attribute defining a primary, foreign, alternate, or composite key with its generation, reference, and governance settings.',
)
@SectionId('KEATT')
@CodeSpecKind([CodeSpecPart.dataAccess])
class KeyAttributeEntry extends DocSpecsSection {
  @Form([
    Field(
      'keyType',
      String,
      'Key Type',
      hint: 'Primary | Foreign | Alternate | Composite | Natural | Surrogate',
    ),
    Field(
      'keyColumns',
      String,
      'Key Column(s)',
      hint: 'Column(s) comprising the key, comma-separated for composite',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Purpose and usage of this key',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Key generation settings.
  @SectionId('KEAGN')
  @StandardReferences(
    [
      'ER modeling (Chen / Barker notation)',
      'ISO/IEC 11179 — metadata registries / data element definitions',
    ],
    'The key-value generation strategy (auto, sequence, UUID, natural) for a key attribute.',
  )
  @Form([
    Field(
      'generationStrategy',
      String,
      'Generation Strategy',
      hint: 'Auto | Sequence | UUID | ULID | Custom | Natural',
    ),
    Field(
      'sequenceName',
      String,
      'Sequence Name',
      hint: 'Database sequence name if applicable',
    ),
    Field(
      'isNaturalKey',
      String,
      'Is Natural Key',
      hint: 'Whether key has business meaning: Yes | No',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? generation;

  /// Foreign-key reference and cascade behavior.
  @SectionId('KEARF')
  @StandardReferences(
    [
      'ER modeling (Chen / Barker notation)',
      'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
    ],
    'The foreign-key reference target and its referential cascade behavior (on delete/update) for a key attribute.',
  )
  @Form([
    Field(
      'referencedEntity',
      String,
      'Referenced Entity',
      hint: 'For foreign keys: target entity name',
    ),
    Field(
      'referencedKey',
      String,
      'Referenced Key',
      hint: 'For foreign keys: target key/column name',
    ),
    Field(
      'onDeleteAction',
      String,
      'On Delete Action',
      hint: 'Cascade | SetNull | Restrict | NoAction | SetDefault',
    ),
    Field(
      'onUpdateAction',
      String,
      'On Update Action',
      hint: 'Cascade | SetNull | Restrict | NoAction | SetDefault',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? reference;

  /// Constraint semantics and business meaning.
  @SectionId('KEAGV')
  @StandardReferences(
    ['SBVR — business rule statements', 'ER modeling (Chen / Barker notation)'],
    'The constraint semantics and business governance meaning of a key attribute, such as deferrability.',
  )
  @Form([
    Field(
      'deferrable',
      String,
      'Deferrable',
      hint: 'Whether constraint check can be deferred: Yes | No',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;

  /// The resolved link to the entity a foreign key points at.
  ///
  /// The `referencedEntity` field of the reference band holds the target's name
  /// as text; this member is the followable edge to that entity's section,
  /// which the outliner shows in place of the target subtree rather than
  /// recursing into it, and which the schema generator validates. It is what
  /// makes an entity name that resolves to nothing a detected error rather than
  /// a dangling string. Empty for every key type but a foreign key — a primary
  /// or alternate key references nothing outside its own entity.
  @SectionId('KEATT-REFE-REF')
  @Reference('referencedEntity')
  @SerializationOrder(4)
  DocSpecsSection? referencedEntityRef;
}

/// An entity index entry (form).
///
/// Database index specification for query optimization.
@StandardReferences(
  [
    'DAMA-DMBOK2 — data management body of knowledge',
    'ISO/IEC 25012 — data quality',
  ],
  'A single database index specification (type, columns, uniqueness, clustering) for query optimization.',
)
@SectionId('ENIDX')
@CodeSpecKind([CodeSpecPart.dataAccess])
class EntityIndexEntry extends DocSpecsSection {
  @Form([
    Field(
      'indexType',
      String,
      'Index Type',
      hint: 'BTree | Hash | GiST | GIN | FullText | Spatial',
    ),
    Field(
      'columns',
      String,
      'Column(s)',
      hint:
          'Indexed columns in order, with direction (e.g., "created_at DESC")',
    ),
    Field(
      'includeColumns',
      String,
      'Include Columns',
      hint: 'Non-key columns to include (covering index)',
    ),
    Field(
      'isUnique',
      String,
      'Is Unique',
      hint: 'Whether index enforces uniqueness: Yes | No',
    ),
    Field(
      'isClustered',
      String,
      'Is Clustered',
      hint: 'Whether index determines physical row order: Yes | No',
    ),
    Field(
      'filterCondition',
      String,
      'Filter Condition',
      hint: 'Partial index WHERE clause',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      hint: 'Query patterns this index optimizes',
    ),
    Field(
      'estimatedSize',
      String,
      'Estimated Size',
      hint: 'Expected index size',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// An entity constraint entry (form).
///
/// Business and technical constraints beyond keys.
@StandardReferences(
  ['SBVR — business rule statements', 'ISO/IEC 25012 — data quality'],
  'A single entity constraint (check, unique, exclusion) with its expression, enforcement level, and business rule reference.',
)
@SectionId('ENCNS')
@CodeSpecKind([CodeSpecPart.dataAccess],
    note: 'DB-level constraint on the table; distinct from CE-VA field rules.')
class EntityConstraintEntry extends DocSpecsSection {
  @Form([
    Field(
      'constraintType',
      String,
      'Constraint Type',
      hint: 'Check | Unique | Exclusion | Custom',
    ),
    Field(
      'expression',
      String,
      'Expression',
      hint: 'Constraint expression or rule',
    ),
    Field(
      'errorMessage',
      String,
      'Error Message',
      hint: 'User-friendly message when constraint violated',
    ),
    Field(
      'enforcementLevel',
      String,
      'Enforcement Level',
      hint: 'Database | Application | Both',
    ),
    Field(
      'isDeferred',
      String,
      'Is Deferred',
      hint: 'Whether check can be deferred to transaction end: Yes | No',
    ),
    Field(
      'businessRule',
      String,
      'Business Rule Reference',
      hint:
          'The related business rule — a business rule section id '
          '(BIRU-BUSI-…)',
      refersTo: ['BIRU.@sectionId'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A migration mapping entry (form).
///
/// Maps source system data to target entity for data migration planning.
@StandardReferences(
  [
    'DAMA-DMBOK2 — data management body of knowledge',
    'ISO/IEC 25012 — data quality',
  ],
  'A single source-to-target mapping (with transformation and validation rules) for planning data migration.',
)
@SectionId('MIGME')
class MigrationMappingEntry extends DocSpecsSection {
  @Form([
    Field(
      'sourceSystem',
      String,
      'Source System',
      required: true,
      hint: 'Name of the source system',
    ),
    Field(
      'sourceTable',
      String,
      'Source Table',
      hint: 'Source table or file name',
    ),
    Field(
      'sourceField',
      String,
      'Source Field',
      hint: 'Source column or field name',
    ),
    Field(
      'targetAttribute',
      String,
      'Target Attribute',
      hint: 'Target attribute name in this entity',
    ),
    Field(
      'transformationType',
      String,
      'Transformation Type',
      hint: 'Direct | Lookup | Computed | Merged | Split | Default',
    ),
    Field(
      'transformationLogic',
      String,
      'Transformation Logic',
      hint: 'Detailed transformation rules',
    ),
    Field(
      'defaultOnMissing',
      String,
      'Default On Missing',
      hint: 'Value to use when source is null or missing',
    ),
    Field(
      'validationRule',
      String,
      'Validation Rule',
      hint: 'Post-migration validation',
    ),
    Field(
      'migrationPriority',
      String,
      'Migration Priority',
      hint: 'Required | Important | Optional',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional migration considerations',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 7.1.2. Entity Relationships.
@StandardReferences(
  [
    'ER modeling (Chen / Barker notation)',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ],
  'Specifies the relationships between data entities, capturing cardinality, referential integrity, and navigation patterns.',
)
@SectionId('ENREL')
@DetailedIn(D03InformationModel)
@CodeSpecKind([CodeSpecPart.dataAccess])
class EntityRelationships extends DocSpecsSection {
  @ContentHelp('''
Relationship specifications between data entities. Captures cardinality,
referential integrity rules, and navigation patterns.

**Per Relationship (29 fields):**
- Identity — name, type, description, justification, implementation type
- Participants — source/target entities with role names
- Cardinality — source/target cardinality, participation (mandatory/optional)
- Referential Integrity — ON DELETE/UPDATE actions, enforcement, cascade scope
- Navigation — bidirectional/unidirectional, loading strategy, FK location
- Relationship Attributes — for relationships with their own properties

**Relationship Types:**
- Association — general relationship between entities
- Aggregation — "has-a" with independent lifecycle
- Composition — "owns-a" with dependent lifecycle
- Generalization — inheritance/specialization
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× EntityRelationship.
  @StandardReferences(
    [
      'ER modeling (Chen / Barker notation)',
      'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
    ],
    'The individual entity-relationship entries that make up the relationship model.',
  )
  @SectionId('ENRLE-ITEM-LST')
  @SectionIdPattern('ENRLE-ITEM-xxx')
  @ContentHelp('Add one entry per entity relationship.')
  @SerializationOrder(1)
  List<EntityRelationshipEntry> items = [];
}

/// An entity relationship entry (form).
///
/// Comprehensive relationship specification following ER modeling best
/// practices.
@StandardReferences(
  [
    'ER modeling (Chen / Barker notation)',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
    'Domain-Driven Design — aggregates/entities/value objects',
  ],
  'A single entity relationship with its participants, cardinality, referential integrity, navigation, and relationship attributes.',
)
@SectionId('ENRLE')
@CodeSpecKind([CodeSpecPart.dataAccess],
    note: 'Foreign-key / association between tables.')
class EntityRelationshipEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this relationship — the business fact it records, beyond '
    'the cardinality and referential-integrity facets below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  // ---------------------------------------------------------------------------
  // Relationship Identity (5 fields)
  // ---------------------------------------------------------------------------
  /// What kind of relationship this is, and why it exists.
  ///
  /// The band keeps apart two things that are easily conflated. The
  /// *conceptual* kind — association, aggregation, composition, generalization,
  /// dependency — decides whether one end can outlive the other. The
  /// *implementation* kind — foreign key, junction table, embedded, reference —
  /// decides what the schema looks like. Neither can be inferred from the
  /// other: a composition realised through a junction table is a legitimate
  /// combination. The business justification sits with them so the reason for
  /// the edge is recorded where the edge is, rather than only in the chapter
  /// narrative.
  @SectionId('ENRLE-IDEN')
  @Form([
    Field(
      'relationshipType',
      String,
      'Relationship Type',
      hint:
          'Association | Aggregation | Composition | Generalization | Dependency',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Business meaning of this relationship',
    ),
    Field(
      'businessJustification',
      String,
      'Business Justification',
      hint: 'Why this relationship exists from business perspective',
    ),
    Field(
      'implementationType',
      String,
      'Implementation Type',
      hint: 'ForeignKey | JunctionTable | Embedded | Reference',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Participating Entities (4 fields)
  // ---------------------------------------------------------------------------
  /// The entities at each end, with the role each one plays.
  ///
  /// A list rather than a source/target pair of fields, because the role name
  /// is per-participant and is what a navigation property ends up being named
  /// after — a self-relationship between two rows of one entity is
  /// distinguishable only by its roles, "employer" and "employee". The
  /// entities themselves are additionally reachable as resolved links
  /// ([sourceEntityRef], [targetEntityRef]).
  @StandardReferences([
    'ER modeling (Chen / Barker notation)',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ], 'The entities participating in this relationship, with their role names.')
  @SectionId('PARTI-PART-LST')
  @SectionIdPattern('PARTI-PART-xxx')
  @ContentHelp('Add one entry per participating entity.')
  @SerializationOrder(2)
  List<ParticipantEntry> participants = [];

  // ---------------------------------------------------------------------------
  // Cardinality and Participation (6 fields)
  // ---------------------------------------------------------------------------
  /// How many instances may stand at each end, and whether either end may stand
  /// empty.
  ///
  /// Two independent questions, which is why the band carries two pairs of
  /// fields rather than one notation. *Cardinality* is the count on each side;
  /// *participation* is whether taking part is mandatory at all. `0..*` and
  /// `1..*` differ only in the second, and it is the second that decides
  /// whether the foreign key may be null — so a model that records only the
  /// count leaves the schema underdetermined.
  @SectionId('ENRLE-CARD')
  @Form([
    Field(
      'sourceCardinality',
      String,
      'Source Cardinality',
      hint: 'Source side: 1 | 0..1 | 0..* | 1..* | n..m',
    ),
    Field(
      'targetCardinality',
      String,
      'Target Cardinality',
      hint: 'Target side: 1 | 0..1 | 0..* | 1..* | n..m',
    ),
    Field(
      'sourceParticipation',
      String,
      'Source Participation',
      hint: 'Mandatory | Optional (whether source must participate)',
    ),
    Field(
      'targetParticipation',
      String,
      'Target Participation',
      hint: 'Mandatory | Optional (whether target must participate)',
    ),
    Field(
      'minSourceInstances',
      String,
      'Min Source Instances',
      hint: 'Minimum number of source entity instances',
    ),
    Field(
      'maxTargetInstances',
      String,
      'Max Target Instances',
      hint: 'Maximum number of related target instances',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? cardinality;

  // ---------------------------------------------------------------------------
  // Referential Integrity (6 fields)
  // ---------------------------------------------------------------------------
  /// What happens to the far end when a row is deleted or its key changes, and
  /// who enforces it.
  ///
  /// The band that turns the relationship from a description into a runtime
  /// guarantee. Its enforcement level is what decides whether the guarantee
  /// exists at all: enforced in the database, a violation is impossible;
  /// enforced in the application, only writers that go through the application
  /// are covered; enforced nowhere, the cardinality above is documentation.
  /// Cascade scope and orphan handling are stated separately from the delete
  /// action because a cascade that reaches every descendant and one that
  /// reaches only direct children are very different amounts of data loss under
  /// the same word.
  @SectionId('ENRLE-REFE')
  @Form([
    Field(
      'onDeleteAction',
      String,
      'On Delete Action',
      hint: 'Cascade | SetNull | Restrict | NoAction | SetDefault | Archive',
    ),
    Field(
      'onUpdateAction',
      String,
      'On Update Action',
      hint: 'Cascade | SetNull | Restrict | NoAction',
    ),
    Field(
      'enforcementLevel',
      String,
      'Enforcement Level',
      hint: 'Database | Application | Both | None',
    ),
    Field(
      'isDeferrable',
      String,
      'Is Deferrable',
      hint: 'Whether constraint check can be deferred: Yes | No',
    ),
    Field(
      'cascadeScope',
      String,
      'Cascade Scope',
      hint: 'For cascading: DirectOnly | AllDescendants | Custom',
    ),
    Field(
      'orphanHandling',
      String,
      'Orphan Handling',
      hint: 'How orphaned records are handled: Prevent | Allow | AssignDefault',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? referentialIntegrity;

  // ---------------------------------------------------------------------------
  // Navigation and Implementation (5 fields)
  // ---------------------------------------------------------------------------
  /// How the relationship is traversed in code, and where the key physically
  /// sits.
  ///
  /// The implementation-facing band: which directions are navigable, whether
  /// the far end is loaded eagerly or on demand, which table actually holds the
  /// foreign key, and what the inverse is called. It is kept apart from the
  /// cardinality band because none of it changes what the data means — a
  /// relationship is the same relationship whether it is navigated from one
  /// side or both — while all of it changes how the relationship performs, and
  /// it is revisited on that basis alone.
  @SectionId('ENRLE-NAVI')
  @Form([
    Field(
      'navigability',
      String,
      'Navigability',
      hint: 'Bidirectional | SourceToTarget | TargetToSource',
    ),
    Field(
      'loadingStrategy',
      String,
      'Loading Strategy',
      hint: 'Eager | Lazy | Explicit | None',
    ),
    Field(
      'foreignKeyLocation',
      String,
      'Foreign Key Location',
      hint: 'Where FK resides: Source | Target | JunctionTable',
    ),
    Field(
      'junctionTableName',
      String,
      'Junction Table Name',
      hint: 'For many-to-many: name of the junction/bridge table',
    ),
    Field(
      'inverseRelationship',
      String,
      'Inverse Relationship',
      hint: 'Name of the relationship from the other side',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? navigation;

  // ---------------------------------------------------------------------------
  // Relationship Attributes (3 fields) — for relationships with properties
  // ---------------------------------------------------------------------------
  /// Attributes belonging to the relationship itself rather than to either end.
  ///
  /// A many-to-many link that carries data — an enrolment date on
  /// student-to-course, a quantity on order-to-product — has nowhere to put it
  /// on either participant without misstating who owns it. This list is that
  /// place, and a non-empty list is the signal that the junction table is a
  /// real entity with columns of its own rather than a pure join. Empty for
  /// every relationship that carries no data, which is most of them.
  @StandardReferences(
    [
      'ER modeling (Chen / Barker notation)',
      'ISO/IEC 11179 — metadata registries / data element definitions',
    ],
    'Attributes that belong to the relationship itself, for relationships that carry their own properties.',
  )
  @SectionId('RELAT-RELA-LST')
  @SectionIdPattern('RELAT-RELA-xxx')
  @ContentHelp('Add one entry per relationship attribute.')
  @SerializationOrder(6)
  List<RelationshipAttributeEntry> relationshipAttributes = [];

  /// The resolved link to the entity at the source end.
  ///
  /// The participant list names the ends for a reader; this is the
  /// machine-followable edge to the source entity's section, shown by the
  /// outliner without recursing into it and validated by the schema generator
  /// against the entity list. It is what makes an entity name that resolves to
  /// nothing a detected error instead of a dangling string.
  @SectionId('ENRLE-SOUR-REF')
  @Reference('sourceEntityName')
  @SerializationOrder(7)
  DocSpecsSection? sourceEntityRef;

  /// The resolved link to the entity at the target end.
  ///
  /// The mirror of [sourceEntityRef], with one asymmetry worth knowing: which
  /// end is "source" is not arbitrary. It is the end the relationship is read
  /// from, and it is what `ENRLE-CARD.sourceCardinality` and
  /// `ENRLE-NAVI.foreignKeyLocation` are stated relative to — so swapping the
  /// two ends changes what the cardinality band asserts even though the
  /// business fact is unchanged.
  @SectionId('ENRLE-TARG-REF')
  @Reference('targetEntityName')
  @SerializationOrder(8)
  DocSpecsSection? targetEntityRef;
}

/// 7.1.4. Data Classification.
@StandardReferences(
  [
    'ISO/IEC 27001 / NIST — data classification',
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
  ],
  'Defines the data classification framework, its sensitivity levels, and the handling requirements for classified data.',
)
@SectionId('DATCL')
@DetailedIn(D03InformationModel)
@CodeSpecKind([CodeSpecPart.authorization],
    note: 'Data classification drives access restrictions → authorization; '
        'retention/handling policy is governance (non-codespecs).')
class DataClassification extends DocSpecsSection {
  @ContentHelp(
    'Introduce the classification framework before the individual levels '
    'below. Cover who classifies data and when a classification is '
    'reviewed.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  // ---------------------------------------------------------------------------
  // Classification Overview (4 fields)
  // ---------------------------------------------------------------------------
  /// The framework the classification levels are drawn from, and who maintains
  /// them.
  ///
  /// Properties of the *scheme* rather than of any one level, which is why they
  /// sit above the level list: which published standard the levels come from,
  /// what unclassified data defaults to, who may classify or reclassify, and
  /// how often assignments are revisited. The default is the load-bearing
  /// field — without one, data nobody has classified is governed by nothing at
  /// all, which is the gap this whole section exists to close.
  @SectionId('DATCL-OVER')
  @Form([
    Field(
      'classificationFramework',
      String,
      'Classification Framework',
      hint: 'Standard used: Custom | ISO27001 | NIST | IndustrySpecific',
    ),
    Field(
      'defaultClassification',
      String,
      'Default Classification',
      hint: 'Default sensitivity for unclassified data',
    ),
    Field(
      'classificationOwner',
      String,
      'Classification Owner',
      hint: 'Role responsible for data classification decisions',
    ),
    Field(
      'reviewFrequency',
      String,
      'Review Frequency',
      hint:
          'How often classifications are reviewed: Annually | Quarterly | OnChange',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Contains 0+× DataClassificationEntry.
  @StandardReferences(
    [
      'ISO/IEC 27001 / NIST — data classification',
      'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
    ],
    'The individual data-classification entries (sensitivity levels) that make up the classification scheme.',
  )
  @SectionId('DCLSE-ITEM-LST')
  @SectionIdPattern('DCLSE-ITEM-xxx')
  @ContentHelp('Add one entry per data classification level.')
  @SerializationOrder(2)
  List<DataClassificationEntry> items = [];
}

/// A data classification entry (form).
///
/// Comprehensive data classification for security and compliance.
@StandardReferences(
  [
    'ISO/IEC 27001 / NIST — data classification',
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
  ],
  'A single data-classification level with its storage, access control, retention, compliance, handling, and access-restriction rules.',
)
@SectionId('DCLSE')
@CodeSpecKind([CodeSpecPart.authorization])
class DataClassificationEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this classification level — what kind of data belongs in '
    'it, beyond the storage, access and retention rules below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  // ---------------------------------------------------------------------------
  // Classification Identity (5 fields)
  // ---------------------------------------------------------------------------
  /// What this level means and what belongs in it.
  ///
  /// The band a person uses to *assign* the level — its name, its definition,
  /// the categories of data it covers, and worked examples — as against the
  /// bands below, which say what follows once a level has been assigned.
  /// Examples carry more weight here than elsewhere in the model: a
  /// classification scheme is applied by people working quickly, and a level
  /// with no examples is applied inconsistently however precise its definition
  /// is.
  @SectionId('DCLSE-IDEN')
  @Form([
    Field(
      'classificationLevel',
      String,
      'Classification Level',
      hint:
          'Sensitivity: Public | Internal | Confidential | Restricted | TopSecret',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this classification means',
    ),
    Field(
      'dataCategories',
      String,
      'Data Categories',
      hint:
          'Types of data in this class: PII | PHI | Financial | Legal | Technical',
    ),
    Field(
      'examples',
      String,
      'Examples',
      hint: 'Examples of data at this classification',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Storage and Transmission (5 fields)
  // ---------------------------------------------------------------------------
  /// Where data at this level may physically live, and how it is protected on
  /// the way there.
  ///
  /// Encryption at rest and in transit, permitted storage locations, data
  /// residency and backup handling. They are grouped because they are the
  /// controls a hosting and infrastructure decision has to satisfy, and they
  /// are verified once at deployment rather than per request — which is what
  /// separates them from the access-control band below. Geographic restriction
  /// is stated with the level rather than left to the deployment document
  /// because it can invalidate an otherwise-finished architecture, and by then
  /// the level is what has to be re-read.
  @SectionId('DCLSE-STOR')
  @Form([
    Field(
      'encryptionAtRest',
      String,
      'Encryption At Rest',
      hint:
          'Encryption requirement for storage: None | Standard | Strong | FieldLevel',
    ),
    Field(
      'encryptionInTransit',
      String,
      'Encryption In Transit',
      hint: 'Encryption for transmission: TLS | mTLS | EndToEnd',
    ),
    Field(
      'storageLocations',
      String,
      'Allowed Storage Locations',
      hint: 'Where data can be stored: OnPremise | Cloud | Either | Restricted',
    ),
    Field(
      'geographicRestrictions',
      String,
      'Geographic Restrictions',
      hint: 'Data residency requirements (e.g., EU only)',
    ),
    Field(
      'backupRequirements',
      String,
      'Backup Requirements',
      hint: 'Special backup considerations',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? storageTransmission;

  // ---------------------------------------------------------------------------
  // Access Control (5 fields)
  // ---------------------------------------------------------------------------
  /// Who may reach data at this level, how they prove who they are, and what is
  /// recorded when they do.
  ///
  /// The per-request half of the level's controls: authentication strength,
  /// authorization model, audit depth, and the process by which access is
  /// granted in the first place. This is the material the authorization
  /// derivation reads (`codespecs_mapping.md` §5.15). Stating it once per level
  /// rather than per entity is the point of having levels at all — it is what
  /// stops the same access rule being re-invented, slightly differently, on
  /// every entity that happens to hold sensitive data.
  @SectionId('DCLSE-ACCE')
  @Form([
    Field(
      'accessLevels',
      String,
      'Access Levels',
      hint:
          'Who can access: AllEmployees | RoleRestricted | NeedToKnow | SystemOnly',
    ),
    Field(
      'authenticationRequirements',
      String,
      'Authentication Requirements',
      hint: 'Required auth: Basic | MFA | CertificateBased | Biometric',
    ),
    Field(
      'authorizationModel',
      String,
      'Authorization Model',
      hint: 'RBAC | ABAC | MAC | DAC',
    ),
    Field(
      'auditRequirements',
      String,
      'Audit Requirements',
      hint: 'Access audit: None | ReadAudit | WriteAudit | FullAudit',
    ),
    Field(
      'accessRequestProcess',
      String,
      'Access Request Process',
      hint:
          'How access is granted: SelfService | ManagerApproval | SecurityApproval',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? accessControl;

  // ---------------------------------------------------------------------------
  // Retention and Disposal (5 fields)
  // ---------------------------------------------------------------------------
  /// How long data at this level is kept, and how it is destroyed.
  ///
  /// Separated from the entity-level lifecycle policy (`DAENT-LIFE`) by scope
  /// and authority: this is the floor that applies to everything classified at
  /// the level, while an entity states its own period where a specific statute
  /// demands a different one. The disposal method matters as much as the
  /// period — deletion, anonymization and crypto-erase are not
  /// interchangeable once backups exist, and only some of them survive a
  /// restore.
  @SectionId('DCLSE-RETE')
  @Form([
    Field(
      'retentionPeriod',
      String,
      'Retention Period',
      hint: 'How long data is retained (e.g., 7 years)',
    ),
    Field(
      'retentionBasis',
      String,
      'Retention Basis',
      hint: 'Legal | Regulatory | Business | CustomerContract',
    ),
    Field(
      'archivalPolicy',
      String,
      'Archival Policy',
      hint: 'When and how to archive: AfterPeriod | OnInactivity | Never',
    ),
    Field(
      'disposalMethod',
      String,
      'Disposal Method',
      hint: 'How data is disposed: Delete | Anonymize | Shred | CryptoErase',
    ),
    Field(
      'disposalApproval',
      String,
      'Disposal Approval',
      hint: 'Who approves disposal: Automatic | DataOwner | Legal',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? retentionDisposal;

  // ---------------------------------------------------------------------------
  // Compliance (4 fields)
  // ---------------------------------------------------------------------------
  /// The named regulations that impose this level, and the duties that come
  /// with them.
  ///
  /// The band that connects the scheme to the outside world: which regulations
  /// apply, what they require, how fast a breach must be reported, and which
  /// data-subject rights must be honoured. It is stated per level rather than
  /// per entity because the obligation attaches to the *kind* of data; an
  /// entity inherits it by being classified. The breach-notification field is a
  /// duration and must be authored as one — an answer like "as soon as
  /// possible" cannot be met or missed, which is the only thing the field is
  /// for.
  @SectionId('DCLSE-COMP')
  @Form([
    Field(
      'applicableRegulations',
      String,
      'Applicable Regulations',
      hint: 'Regulations: GDPR | HIPAA | SOX | PCI-DSS | CCPA | FERPA',
    ),
    Field(
      'complianceRequirements',
      String,
      'Compliance Requirements',
      hint: 'Specific compliance requirements',
    ),
    Field(
      'breachNotificationSla',
      String,
      'Breach Notification SLA',
      hint: 'Time to notify on breach (e.g., 72 hours for GDPR)',
    ),
    Field(
      'dataSubjectRights',
      String,
      'Data Subject Rights',
      hint: 'Applicable rights: Access | Rectification | Erasure | Portability',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? compliance;

  /// Contains 0+× HandlingRequirement.
  @StandardReferences([
    'ISO/IEC 27001 / NIST — data classification',
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
  ], 'The handling procedures required for data at this classification level.')
  @SectionId('HNDRE-HAND-LST')
  @SectionIdPattern('HNDRE-HAND-xxx')
  @ContentHelp('Add one entry per handling requirement.')
  @SerializationOrder(6)
  List<HandlingRequirementEntry> handlingRequirements = [];

  /// Contains 0+× AccessRestriction.
  @StandardReferences([
    'ISO/IEC 27001 / NIST — data classification',
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
  ], 'The access restrictions that apply to data at this classification level.')
  @SectionId('ACRSE-ACCE-LST')
  @SectionIdPattern('ACRSE-ACCE-xxx')
  @ContentHelp('Add one entry per access restriction.')
  @SerializationOrder(7)
  List<AccessRestrictionEntry> accessRestrictions = [];
}

/// A data handling requirement entry (form).
///
/// Specific handling procedures for classified data.
@StandardReferences(
  [
    'ISO/IEC 27001 / NIST — data classification',
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
  ],
  'A single handling requirement (processing, storage, transmission, display, disposal) with its rationale and enforcement.',
)
@SectionId('HNDRE')
@CodeSpecKind(
  [CodeSpecPart.authorization],
  note:
      'one handling requirement constraining access to classified data',
)
class HandlingRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'requirementType',
      String,
      'Requirement Type',
      hint: 'Processing | Storage | Transmission | Display | Disposal',
    ),
    Field(
      'requirement',
      String,
      'Requirement',
      required: true,
      hint: 'The specific handling requirement',
    ),
    Field(
      'rationale',
      String,
      'Rationale',
      hint: 'Why this requirement exists',
    ),
    Field(
      'enforcementMechanism',
      String,
      'Enforcement Mechanism',
      hint: 'How this is enforced: Technical | Procedural | Both',
    ),
    Field(
      'validationMethod',
      String,
      'Validation Method',
      hint: 'How compliance is verified',
    ),
    Field(
      'exceptionProcess',
      String,
      'Exception Process',
      hint: 'How exceptions are handled',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// An access restriction entry (form).
///
/// Specific access restrictions for classified data.
@StandardReferences(
  [
    'ISO/IEC 27001 / NIST — data classification',
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
  ],
  'A single access restriction (role, geographic, temporal, contextual) with its scope, enforcement, and override policy.',
)
@SectionId('ACRSE')
@CodeSpecKind([CodeSpecPart.authorization])
class AccessRestrictionEntry extends DocSpecsSection {
  @Form([
    Field(
      'restrictionType',
      String,
      'Restriction Type',
      hint: 'Role | Geographic | Temporal | Contextual | DataBased',
    ),
    Field(
      'restriction',
      String,
      'Restriction',
      required: true,
      hint: 'The specific access restriction',
    ),
    Field('scope', String, 'Scope', hint: 'What the restriction applies to'),
    Field(
      'enforcement',
      String,
      'Enforcement',
      hint: 'How restriction is enforced: Policy | Technical | IAM',
    ),
    Field(
      'effectiveConditions',
      String,
      'Effective Conditions',
      hint: 'When restriction applies (e.g., during business hours)',
    ),
    Field(
      'overridePolicy',
      String,
      'Override Policy',
      hint: 'How overrides are handled: None | BreakGlass | ApprovalRequired',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.2 Business Object Model
// ---------------------------------------------------------------------------

/// 7.2. Business Object Model.
@StandardReferences(
  [
    'Domain-Driven Design — aggregates/entities/value objects',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ],
  'The catalog of key business objects with their attributes, states, behaviors and lifecycles, modeled in the domain-driven design style.',
)
@SectionId('BJOMD')
@MapsTo(D03InformationModel)
@CodeSpecKind([CodeSpecPart.viewState],
    note: 'DDD domain object catalog → observable view-model (CE-ST). Physical '
        'persistence is DataEntity (CE-DB); AggregateRoot entries are the CE-SU '
        'root aggregate (codespecs_mapping.md §5.17).')
class BusinessObjectModel extends DocSpecsSection {
  @ContentHelp('''
Key business objects, their properties, states, and behaviors. Following
Domain-Driven Design patterns for rich domain modeling.

**Object Catalog Structure (per entry):**
- Core Identity — name, alias, category, DDD stereotype (AggregateRoot, Entity, ValueObject)
- Domain Context — bounded context, owning domain, ubiquitous language term
- Lifecycle Summary — key states, transitions, terminal states
- Behavior & Rules — invariants, operations, validation, calculated properties
- Ownership & Versioning — data owner, concurrency control, audit trail
- Integration Points — APIs exposed, events published/subscribed

**Sub-elements per Object:**
- Attributes — business-level attribute specifications (12 fields each)
- States — detailed state definitions with entry/exit conditions
- Business Rules — rules governing the object (8 fields each)
- Lifecycle Transitions — state transitions with guards and actions (13 fields each)
- Operations — domain operations with pre/post conditions (13 fields each)
- Invariants — conditions that must always hold (7 fields each)
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.2.1. Object Catalog — contains 1+× Business Object.
  @StandardReferences([
    'Domain-Driven Design — aggregates/entities/value objects',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ], 'The business objects that make up the domain model.')
  @SectionId('BJOEN-OBJE-LST')
  @SectionIdPattern('BJOEN-OBJE-xxx')
  @Min(1)
  @ContentHelp('Add one entry per business object.')
  @SerializationOrder(1)
  List<BusinessObjectEntry> objects = [];

  /// 7.2.2. Business Object Diagram (mermaid).
  @SerializationOrder(2)
  DiagramSection objectDiagram = DiagramSection();
}

/// A business object entry (form).
///
/// Comprehensive business object specification following domain-driven design
/// patterns. Business objects represent key domain concepts with behavior,
/// state, and business rules.
@StandardReferences(
  [
    'Domain-Driven Design — aggregates/entities/value objects',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ],
  'A single business object in the domain model, with its identity, attributes, states, rules and operations.',
)
@SectionId('BJOEN')
@CodeSpecKind([CodeSpecPart.viewState])
class BusinessObjectEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this business object — its role in the domain, beyond '
    'the attribute, state, rule and operation facets recorded below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  // ---------------------------------------------------------------------------
  // Core Identity (6 fields)
  // ---------------------------------------------------------------------------
  /// What this business object is called in the business, and which pattern it
  /// follows.
  ///
  /// The conceptual-side counterpart of [DataEntityEntry]'s identity band. A
  /// business object is named by the business and may have no table at all, so
  /// the band carries the glossary term and the domain-driven-design stereotype
  /// where the entity carries a physical name. Where the two chapters describe
  /// the same thing, the object is the meaning and the entity is the storage;
  /// the alias is what lets a reader line the two up.
  @SectionId('BJOEN-IDEN')
  @Form([
    Field(
      'objectAlias',
      String,
      'Alias/Abbreviation',
      hint: 'Short alias for diagrams (e.g., ORD, CUST)',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Clear business definition of what this object represents',
    ),
    Field(
      'businessGlossaryTerm',
      String,
      'Business Glossary Term',
      hint: 'Official business glossary term if different',
    ),
    Field(
      'category',
      String,
      'Category',
      hint:
          'Transaction | MasterData | ReferenceData | Aggregate | ValueObject | Event',
    ),
    Field(
      'stereotypePattern',
      String,
      'Stereotype/Pattern',
      hint:
          'DDD pattern: AggregateRoot | Entity | ValueObject | DomainEvent | Saga',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Domain Context (5 fields)
  // ---------------------------------------------------------------------------
  /// Which part of the business this object belongs to, and who speaks for it.
  ///
  /// The band that places the object in the ubiquitous language: its bounded
  /// context, the owning domain, the named expert who decides what it means,
  /// and the term the business actually uses. It is separate from the identity
  /// above because these fields are about *authority over the definition*
  /// rather than about the object. It is also what makes a word that means two
  /// different things in two contexts visible as such, instead of forcing one
  /// of the two to be renamed.
  @SectionId('BJOEN-DOMA')
  @Form([
    Field(
      'boundedContext',
      String,
      'Bounded Context',
      refersTo: ['BCE.contextName'],
      hint: 'Context Name of the bounded context this object belongs to',
    ),
    Field(
      'owningDomain',
      String,
      'Owning Domain',
      hint: 'Business domain responsible for this object',
    ),
    Field(
      'domainExpert',
      String,
      'Domain Expert',
      hint: 'Business expert who defines this object',
    ),
    Field(
      'ubiquitousLanguageTerm',
      String,
      'Ubiquitous Language Term',
      hint: 'How this is referred to in the ubiquitous language',
    ),
    Field(
      'relatedObjects',
      String,
      'Related Objects',
      hint: 'Key related business objects',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? domainContext;

  // ---------------------------------------------------------------------------
  // Lifecycle Summary (5 fields)
  // ---------------------------------------------------------------------------
  /// The object's states at a glance — the digest, not the authority.
  ///
  /// The authored lifecycle is the state list together with
  /// [LifecycleTransitionEntry], each transition carrying its own guard. This
  /// band is the summary a reader needs before descending into them: where an
  /// instance starts, which states end it, and who owns the progression.
  /// Because it is a digest it can go stale, and a state added below but not
  /// reflected here is a documentation defect rather than a change to the
  /// model.
  @SectionId('BJOEN-LIFE')
  @Form([
    Field(
      'keyStates',
      String,
      'Key States',
      hint:
          'Primary lifecycle states (e.g., Draft → Submitted → Confirmed → Closed)',
    ),
    Field(
      'initialState',
      String,
      'Initial State',
      hint: 'State when object is created',
    ),
    Field(
      'terminalStates',
      String,
      'Terminal States',
      hint: 'States where lifecycle ends (e.g., Closed, Cancelled, Deleted)',
    ),
    Field(
      'stateTransitionRules',
      String,
      'State Transition Rules',
      hint: 'Summary of allowed state transitions',
    ),
    Field(
      'lifecycleOwner',
      String,
      'Lifecycle Owner',
      hint: 'System or process responsible for lifecycle management',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? lifecycleSummary;

  // ---------------------------------------------------------------------------
  // Behavior and Rules (5 fields)
  // ---------------------------------------------------------------------------
  /// What the object does, and what it refuses to do.
  ///
  /// Behaviour intrinsic to this object, as against the policies catalogued in
  /// [BusinessRuleEntry] and cited from [BusinessRuleReferenceEntry]. The
  /// dividing line is ownership: a catalogued rule may govern several objects
  /// and is versioned, owned and reviewed in its own right, while an entry here
  /// has no meaning apart from this object. A rule that starts here and turns
  /// out to govern a second object belongs in the catalogue instead — leaving
  /// it here is how one policy comes to have two divergent statements.
  @StandardReferences([
    'SBVR — business rule statements',
    'Domain-Driven Design — aggregates/entities/value objects',
  ], 'The behavior rules that govern how this object acts.')
  @SectionId('BEHAV-BEHA-LST')
  @SectionIdPattern('BEHAV-BEHA-xxx')
  @ContentHelp('Add one entry per behavior rule.')
  @SerializationOrder(4)
  List<BehaviorRuleEntry> behaviorRules = [];

  // ---------------------------------------------------------------------------
  // Ownership and Versioning (5 fields)
  // ---------------------------------------------------------------------------
  /// Who is accountable for the object's data, and how concurrent change is
  /// handled.
  ///
  /// Two subjects share the band because both answer "what happens when this
  /// object changes": the human chain (owner, steward) and the mechanical one
  /// (versioning strategy, concurrency control, audit trail). The concurrency
  /// choice is the consequential one — optimistic and pessimistic control move
  /// the conflict to different places, one to the writer at commit time and one
  /// to the reader at lock time — and it should follow this object's usage
  /// pattern rather than a house style, which is why it is authored per object.
  @SectionId('BJOEN-OWNE')
  @Form([
    Field(
      'dataOwner',
      String,
      'Data Owner',
      hint: 'Business role accountable for this object',
    ),
    Field(
      'dataSteward',
      String,
      'Data Steward',
      hint: 'Role responsible for data quality',
    ),
    Field(
      'versioningStrategy',
      String,
      'Versioning Strategy',
      hint: 'None | Sequential | Timestamp | Optimistic | EventSourced',
    ),
    Field(
      'concurrencyControl',
      String,
      'Concurrency Control',
      hint: 'Optimistic | Pessimistic | None',
    ),
    Field(
      'auditTrail',
      String,
      'Audit Trail',
      hint:
          'What changes are tracked: None | StateChanges | AllChanges | FullHistory',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? ownership;

  // ---------------------------------------------------------------------------
  // Integration Points (4 fields)
  // ---------------------------------------------------------------------------
  /// Where this object is exposed outside its own service — the APIs it offers
  /// and the events it publishes or consumes.
  ///
  /// A list because each exposure is negotiated separately and has its own
  /// consumer: an object may be readable through one endpoint, published as
  /// three events, and subscribed to none. The list doubles as the object's
  /// stability contract — anything named here has an external consumer, so it
  /// can no longer be changed by reasoning about this chapter alone, and
  /// surfacing that fact is much of why the band exists.
  @StandardReferences(
    [
      'Domain-Driven Design — aggregates/entities/value objects',
      'BPMN 2.0 — business process model & notation',
    ],
    'The integration points where this object exposes APIs or publishes and subscribes to events.',
  )
  @SectionId('INTEG-INTE-LST')
  @SectionIdPattern('INTEG-INTE-xxx')
  @ContentHelp('Add one entry per integration point.')
  @SerializationOrder(6)
  List<IntegrationPointEntry> integrationPoints = [];

  /// Contains 0+× BusinessObjectAttribute.
  @StandardReferences([
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'Domain-Driven Design — aggregates/entities/value objects',
  ], 'The business-level attributes that describe this object.')
  @SectionId('BIOBAT-ATTR-LST')
  @SectionIdPattern('BIOBAT-ATTR-xxx')
  @ContentHelp('Add one entry per business object attribute.')
  @SerializationOrder(7)
  List<BusinessObjectAttributeEntry> attributes = [];

  /// Contains 0+× ObjectState.
  @StandardReferences([
    'UML state machines — object lifecycle/state modeling',
  ], 'The key lifecycle states this object can occupy.')
  @SectionId('OBST-KEYS-LST')
  @SectionIdPattern('OBST-KEYS-xxx')
  @ContentHelp('Add one entry per object state.')
  @SerializationOrder(8)
  List<ObjectStateEntry> keyStates = [];

  /// Contains 0+× BusinessRuleReference.
  @StandardReferences([
    'SBVR — business rule statements',
  ], 'The business rules that govern this object.')
  @SectionId('BIRURE-KEYB-LST')
  @SectionIdPattern('BIRURE-KEYB-xxx')
  @ContentHelp('Add one entry per business rule reference.')
  @SerializationOrder(9)
  List<BusinessRuleReferenceEntry> keyBusinessRules = [];

  /// Contains 0+× LifecycleTransition.
  @StandardReferences([
    'UML state machines — object lifecycle/state modeling',
  ], 'The allowed state transitions in this object lifecycle.')
  @SectionId('LFTRS-LIFE-LST')
  @SectionIdPattern('LFTRS-LIFE-xxx')
  @ContentHelp('Add one entry per lifecycle transition.')
  @SerializationOrder(10)
  List<LifecycleTransitionEntry> lifecycleTransitions = [];

  /// Contains 0+× ObjectOperation.
  @StandardReferences([
    'Domain-Driven Design — aggregates/entities/value objects',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ], 'The domain operations that can be performed on this object.')
  @SectionId('OBOP-OPER-LST')
  @SectionIdPattern('OBOP-OPER-xxx')
  @ContentHelp('Add one entry per object operation.')
  @SerializationOrder(11)
  List<ObjectOperationEntry> operations = [];

  /// Contains 0+× ObjectInvariant.
  @StandardReferences([
    'SBVR — business rule statements',
    'Domain-Driven Design — aggregates/entities/value objects',
  ], 'The invariants that must always hold true for this object.')
  @SectionId('OBINV-INVA-LST')
  @SectionIdPattern('OBINV-INVA-xxx')
  @ContentHelp('Add one entry per object invariant.')
  @SerializationOrder(12)
  List<ObjectInvariantEntry> invariants = [];
}

/// A business object attribute entry (form).
///
/// Business-level attribute specification focusing on business meaning and
/// rules.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'Domain-Driven Design — aggregates/entities/value objects',
  ],
  'A single business-level attribute of an object, describing its meaning, type and rules.',
)
@SectionId('BIOBAT')
@CodeSpecKind([CodeSpecPart.viewState])
class BusinessObjectAttributeEntry extends DocSpecsSection {
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'Business meaning of this attribute',
    ),
    Field(
      'type',
      String,
      'Type',
      hint:
          'Business type: Text | Number | Money | Date | DateTime | Boolean | Enum | Reference',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Format and requirement details.
  @SectionId('BOAED')
  @StandardReferences(
    ['ISO/IEC 11179 — metadata registries / data element definitions'],
    'The format, requirement level and default value details of a business object attribute.',
  )
  @Form([
    Field(
      'format',
      String,
      'Format',
      hint: 'Business format (e.g., currency, percentage, phone)',
    ),
    Field(
      'mandatory',
      String,
      'Mandatory',
      hint: 'Required | Optional | ConditionallyRequired',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'Default value or derivation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? definition;

  /// Validation and derivation rules.
  @SectionId('BOAEV')
  @StandardReferences(
    [
      'SBVR — business rule statements',
      'ISO/IEC 11179 — metadata registries / data element definitions',
    ],
    'The validation rules, allowed values and derivation logic that constrain a business object attribute.',
  )
  @Form([
    Field(
      'validationRules',
      String,
      'Validation Rules',
      hint: 'Business validation rules',
    ),
    Field(
      'allowedValues',
      String,
      'Allowed Values',
      hint: 'Enumerated values or range',
    ),
    Field(
      'businessRules',
      String,
      'Business Rules',
      hint: 'Rules affecting this attribute',
    ),
    Field(
      'derivation',
      String,
      'Derivation',
      hint: 'How value is derived if calculated',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? validation;

  /// Sensitivity and presentation guidance.
  @SectionId('BOAEG')
  @StandardReferences(
    [
      'ISO/IEC 27001 / NIST — data classification',
      'DAMA-DMBOK2 — data management body of knowledge',
    ],
    'The sensitivity classification and presentation ordering that govern a business object attribute.',
  )
  @Form([
    Field(
      'sensitivityLevel',
      String,
      'Sensitivity Level',
      hint: 'Public | Internal | Confidential | PII | PHI',
    ),
    Field(
      'displayOrder',
      String,
      'Display Order',
      hint: 'Order for UI presentation',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;
}

/// An object state entry (form).
///
/// Detailed state specification for business object lifecycle.
@StandardReferences(
  ['UML state machines — object lifecycle/state modeling'],
  'A single lifecycle state of a business object, with its entry/exit conditions and allowed operations.',
)
@SectionId('OBST')
@CodeSpecKind([CodeSpecPart.domainEnum],
    note: 'Closed lifecycle state set → domain enum.')
class ObjectStateEntry extends DocSpecsSection {
  @Form([
    Field(
      'stateCode',
      String,
      'State Code',
      hint: 'Technical state code or enum value',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this state means in business terms',
    ),
    Field(
      'stateType',
      ObjectLifecycleKind,
      'State Type',
      hint: 'Lifecycle role of this state',
    ),
    Field(
      'entryConditions',
      String,
      'Entry Conditions',
      hint: 'Conditions required to enter this state',
    ),
    Field(
      'exitConditions',
      String,
      'Exit Conditions',
      hint: 'Conditions required to exit this state',
    ),
    Field(
      'allowedOperations',
      String,
      'Allowed Operations',
      hint: 'What operations can be performed in this state',
    ),
    Field(
      'restrictedOperations',
      String,
      'Restricted Operations',
      hint: 'What operations are not allowed in this state',
    ),
    Field(
      'slaRequirements',
      String,
      'SLA Requirements',
      hint: 'Any time-bound requirements for this state',
    ),
    Field(
      'notificationTriggers',
      String,
      'Notification Triggers',
      hint: 'Events that trigger notifications in this state',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A business rule reference entry (form).
///
/// Reference to business rules that govern this object.
@StandardReferences(
  ['SBVR — business rule statements'],
  'A reference to a business rule that governs this object, including its trigger and consequence on violation.',
)
@SectionId('BIRURE')
@CodeSpecKind([CodeSpecPart.validation])
class BusinessRuleReferenceEntry extends DocSpecsSection {
  @Form([
    Field(
      'ruleId',
      String,
      'Rule ID',
      hint:
          'The business rule this applies — a business rule section id '
          '(BIRU-BUSI-…)',
      refersTo: ['BIRU.@sectionId'],
    ),
    Field(
      'ruleType',
      String,
      'Rule Type',
      hint: 'Validation | Calculation | Constraint | Authorization | Workflow',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Brief description of the rule',
    ),
    Field(
      'enforcement',
      String,
      'Enforcement',
      hint: 'Automated | Manual | Hybrid',
    ),
    Field(
      'triggerCondition',
      String,
      'Trigger Condition',
      hint: 'When this rule is evaluated',
    ),
    Field(
      'affectedAttributes',
      String,
      'Affected Attributes',
      hint: 'Attributes involved in this rule',
    ),
    Field(
      'consequenceOnViolation',
      String,
      'Consequence On Violation',
      hint: 'What happens when rule is violated',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// The resolved link to the business rule this entry cites.
  ///
  /// The entry's `ruleId` field holds the rule's section id as text; this
  /// member is the followable edge to that rule's section, so a citation can be
  /// validated rather than trusted. The outliner shows it without recursing —
  /// which is the whole point of the entry: the rule is stated once in
  /// [BusinessRuleEntry] and cited from every object it governs, instead of
  /// being copied into each of them and drifting.
  @SectionId('BIRURE-RULE-REF')
  @Reference('ruleId')
  @SerializationOrder(1)
  DocSpecsSection? ruleRef;
}

/// A lifecycle transition entry (form).
///
/// Detailed state transition specification.
@StandardReferences(
  ['UML state machines — object lifecycle/state modeling'],
  'A single state transition in an object lifecycle, from a source state to a target state.',
)
@SectionId('LFTRS')
@CodeSpecKind([CodeSpecPart.action],
    note: 'Guarded state transition → action; the state-machine/workflow view '
        'is deferred to CE-WF.')
class LifecycleTransitionEntry extends DocSpecsSection {
  @Form([
    Field(
      'fromState',
      String,
      'From State',
      required: true,
      hint: 'Source state',
    ),
    Field('toState', String, 'To State', required: true, hint: 'Target state'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Triggering event details.
  @SectionId('LTET')
  @StandardReferences([
    'UML state machines — object lifecycle/state modeling',
  ], 'The event that triggers a lifecycle transition and its trigger type.')
  @Form([
    Field('trigger', String, 'Trigger', hint: 'What initiates this transition'),
    Field(
      'triggerType',
      String,
      'Trigger Type',
      hint: 'UserAction | SystemEvent | Timer | ExternalEvent',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? trigger;

  /// Transition conditions and guarantees.
  @SectionId('LTEC')
  @StandardReferences(
    [
      'UML state machines — object lifecycle/state modeling',
      'SBVR — business rule statements',
    ],
    'The guard, pre- and post-conditions that constrain and guarantee a lifecycle transition.',
  )
  @Form([
    Field(
      'guardConditions',
      String,
      'Guard Conditions',
      hint: 'Conditions that must be true for transition',
    ),
    Field(
      'preConditions',
      String,
      'Pre-Conditions',
      hint: 'What must be true before transition',
    ),
    Field(
      'postConditions',
      String,
      'Post-Conditions',
      hint: 'What is guaranteed after transition',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? conditions;

  /// Actions, actors, and rollback handling.
  @SectionId('LTEE')
  @StandardReferences(
    [
      'UML state machines — object lifecycle/state modeling',
      'BPMN 2.0 — business process model & notation',
    ],
    'The actions, side effects, allowed actors and rollback strategy executed during a lifecycle transition.',
  )
  @Form([
    Field(
      'actions',
      String,
      'Actions',
      hint: 'Actions performed during transition',
    ),
    Field(
      'sideEffects',
      String,
      'Side Effects',
      hint: 'Events published, notifications sent',
    ),
    Field(
      'allowedActors',
      String,
      'Allowed Actors',
      hint: 'Who can trigger this transition',
    ),
    Field(
      'rollbackStrategy',
      String,
      'Rollback Strategy',
      hint: 'How to handle transition failure',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? execution;
}

/// An object operation entry (form).
///
/// Business operations that can be performed on the object.
@StandardReferences(
  [
    'Domain-Driven Design — aggregates/entities/value objects',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ],
  'A single domain operation that can be performed on the object, as a command, query or event.',
)
@SectionId('OBOP')
@CodeSpecKind([CodeSpecPart.action],
    note: 'Domain operation (pre/post) → action; the server realisation is '
        'CE-SC/CE-SU (derived).')
class ObjectOperationEntry extends DocSpecsSection {
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'What this operation does',
    ),
    Field(
      'operationType',
      String,
      'Operation Type',
      hint: 'Command | Query | Event',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Execution contract for this operation.
  @SectionId('OOEE')
  @StandardReferences(
    [
      'Domain-Driven Design — aggregates/entities/value objects',
      'SBVR — business rule statements',
    ],
    'The pre- and post-conditions, inputs and outputs that form the execution contract of an object operation.',
  )
  @Form([
    Field(
      'preconditions',
      String,
      'Preconditions',
      hint: 'What must be true before operation',
    ),
    Field(
      'postconditions',
      String,
      'Postconditions',
      hint: 'What is guaranteed after operation',
    ),
    Field(
      'inputParameters',
      String,
      'Input Parameters',
      hint: 'Required inputs for this operation',
    ),
    Field(
      'outputResult',
      String,
      'Output Result',
      hint: 'What the operation returns',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? execution;

  /// State and event lifecycle details.
  @SectionId('OOEL')
  @StandardReferences(
    [
      'UML state machines — object lifecycle/state modeling',
      'Domain-Driven Design — aggregates/entities/value objects',
    ],
    'The business rules applied, state transitions and domain events produced when an object operation runs.',
  )
  @Form([
    Field(
      'businessRulesApplied',
      String,
      'Business Rules Applied',
      hint: 'Rules evaluated during operation',
    ),
    Field(
      'stateTransitions',
      String,
      'State Transitions',
      hint: 'Possible state changes',
    ),
    Field(
      'eventsPublished',
      String,
      'Events Published',
      hint: 'Domain events triggered',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? lifecycle;

  /// Authorization and usage boundaries.
  @SectionId('OOEG')
  @StandardReferences(
    [
      'ISO/IEC 27001 / NIST — data classification',
      'UML state machines — object lifecycle/state modeling',
    ],
    'The states in which an object operation is permitted, who may perform it and whether it is idempotent.',
  )
  @Form([
    Field(
      'allowedInStates',
      String,
      'Allowed In States',
      hint: 'States where operation is permitted',
    ),
    Field(
      'authorization',
      String,
      'Authorization',
      hint: 'Who can perform this operation',
    ),
    Field(
      'idempotent',
      String,
      'Idempotent',
      hint: 'Whether operation is idempotent: Yes | No',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;
}

/// An object invariant entry (form).
///
/// Business invariants that must always hold true.
@StandardReferences(
  [
    'SBVR — business rule statements',
    'Domain-Driven Design — aggregates/entities/value objects',
  ],
  'A single business invariant that must always hold true, with its expression, scope and violation action.',
)
@SectionId('OBINV')
@CodeSpecKind([CodeSpecPart.validation],
    note: 'Object invariant (must-always-hold) → validation rule.')
class ObjectInvariantEntry extends DocSpecsSection {
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'What this invariant means',
    ),
    Field(
      'expression',
      String,
      'Expression',
      hint: 'Logic or pseudo-code expressing the invariant',
    ),
    Field(
      'scope',
      String,
      'Scope',
      hint: 'Single | AcrossStates | AcrossObjects',
    ),
    Field(
      'enforcementPoint',
      String,
      'Enforcement Point',
      hint: 'When invariant is checked',
    ),
    Field(
      'violationAction',
      String,
      'Violation Action',
      hint: 'What happens on violation: Reject | Compensate | Alert',
    ),
    Field(
      'businessJustification',
      String,
      'Business Justification',
      hint: 'Why this invariant exists',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.3 Function Model
// ---------------------------------------------------------------------------

/// 7.3. Function Model.
///
/// Business functions, their decomposition, and relationships to data objects.
@StandardReferences(
  [
    'Structured Analysis (DeMarco/Yourdon) — functional decomposition',
    'IEEE 830 / ISO/IEC/IEEE 29148 — functional requirements',
    'CRUD matrix — function/data interaction mapping',
  ],
  'The function model decomposes the system into business functions and maps how they interact with data.',
)
@SectionId('FUMO')
@MapsTo(D03InformationModel)
@CodeSpecKind([CodeSpecPart.serviceUnit],
    note: 'Business function decomposition → logical service unit (codespecs_mapping.md §5.17).')
class FunctionModel extends DocSpecsSection {
  @ContentHelp(
    'Introduce the function model before the decomposition, matrix and rule '
    'lists below. Cover how deep the decomposition goes and how functions '
    'are mapped onto data.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  // ---------------------------------------------------------------------------
  // Function Decomposition Overview (4 fields)
  // ---------------------------------------------------------------------------
  /// How the function hierarchy was cut, and how deep it goes.
  ///
  /// Method rather than content: the criterion by which a function was split
  /// into sub-functions, the number of levels, and the top-level areas the tree
  /// starts from. It is a band of its own because the criterion has to be
  /// chosen once and applied throughout — a hierarchy whose first level is
  /// business capability and whose second is organizational unit cannot be
  /// compared across branches, and no individual function entry can reveal
  /// that.
  @SectionId('FUMO-DECO')
  @Form([
    Field(
      'decompositionApproach',
      String,
      'Decomposition Approach',
      hint:
          'How functions are decomposed: Hierarchical | ProcessBased | CapabilityBased',
    ),
    Field(
      'decompositionDepth',
      String,
      'Decomposition Depth',
      hint: 'Number of levels in the hierarchy',
    ),
    Field(
      'topLevelFunctions',
      String,
      'Top-Level Functions',
      hint: 'Summary of major function areas',
    ),
    Field(
      'decompositionBasis',
      String,
      'Decomposition Basis',
      hint:
          'Criteria for breaking down: BusinessCapability | ProcessStep | OrganizationalUnit',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? decompositionOverview;

  // ---------------------------------------------------------------------------
  // Function-to-Data Matrix Overview (4 fields)
  // ---------------------------------------------------------------------------
  /// How to read the function-to-data matrix, and how much of the system it
  /// covers.
  ///
  /// The matrix entries are dense and close to unreadable without this band:
  /// which notation the cells use, which functions were included, and which
  /// access patterns the result is meant to expose. Scope is the field that
  /// fixes what an empty cell means — in a matrix scoped to core functions a
  /// blank is "not examined", while in one scoped to all functions it is "this
  /// function does not touch this entity", which is a far stronger claim and
  /// the one a data-ownership argument rests on.
  @SectionId('FUMO-MATR')
  @Form([
    Field(
      'crudNotation',
      String,
      'CRUD Notation',
      hint: 'Notation used: CRUD | CRUDx | Custom',
    ),
    Field(
      'matrixScope',
      String,
      'Matrix Scope',
      hint: 'What\'s covered: CoreFunctions | AllFunctions | UserFacing',
    ),
    Field(
      'primaryAccessPatterns',
      String,
      'Primary Access Patterns',
      hint: 'Summary of major access patterns',
    ),
    Field(
      'dataOwnership',
      String,
      'Data Ownership',
      hint: 'Which functions own which data',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? matrixOverview;

  /// 7.3.1. Function Decomposition — contains 0+× Function.
  @StandardReferences([
    'Structured Analysis (DeMarco/Yourdon) — functional decomposition',
    'IEEE 830 / ISO/IEC/IEEE 29148 — functional requirements',
  ], 'The business functions the system provides, decomposed hierarchically.')
  @SectionId('FUNCT-FUNC-LST')
  @SectionIdPattern('FUNCT-FUNC-xxx')
  @ContentHelp('Add one entry per function.')
  @SerializationOrder(3)
  List<FunctionEntry> functions = [];

  /// 7.3.2. Function-to-Data Matrix Entries — contains 0+× MatrixEntry.
  @StandardReferences(
    ['CRUD matrix — function/data interaction mapping'],
    'The rows of the CRUD matrix mapping each function to the data entities it accesses.',
  )
  @SectionId('FNDMX-MATR-LST')
  @SectionIdPattern('FNDMX-MATR-xxx')
  @ContentHelp('Add one entry per function/data matrix mapping.')
  @SerializationOrder(4)
  List<FunctionDataMatrixEntry> matrixEntries = [];

  /// 7.3.3. Business Rules — contains 1+× Business Rule.
  @StandardReferences([
    'SBVR — business rule statements',
    'IEEE 830 / ISO/IEC/IEEE 29148 — functional requirements',
  ], 'The business rules that govern the behaviour of the system.')
  @SectionId('BIRU-BUSI-LST')
  @SectionIdPattern('BIRU-BUSI-xxx')
  @Min(1)
  @ContentHelp('Add one entry per business rule.')
  @SerializationOrder(5)
  List<BusinessRuleEntry> businessRules = [];
}

/// A function entry (form).
///
/// Business function specification in the functional decomposition.
@StandardReferences(
  [
    'Structured Analysis (DeMarco/Yourdon) — functional decomposition',
    'IEEE 830 / ISO/IEC/IEEE 29148 — functional requirements',
  ],
  'A single business function, described by name, purpose, and its place in the hierarchy.',
)
@SectionId('FUNCT')
@CodeSpecKind([CodeSpecPart.serviceUnit])
class FunctionEntry extends DocSpecsSection {
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'What this function accomplishes',
    ),
    Field(
      'parentFunction',
      String,
      'Parent Function',
      hint: 'Parent function in hierarchy',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Decomposition position and classification.
  @SectionId('FUENCL')
  @StandardReferences([
    'Structured Analysis (DeMarco/Yourdon) — functional decomposition',
  ], 'The hierarchy level, function type, and owning process of a function.')
  @Form([
    Field('level', String, 'Level', hint: 'Hierarchy level: 1 | 2 | 3 etc.'),
    Field(
      'functionType',
      String,
      'Function Type',
      hint: 'Operational | Support | Management | Information',
    ),
    Field(
      'owningProcess',
      String,
      'Owning Process',
      hint: 'Business process this belongs to',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Execution profile and criticality.
  @SectionId('FUENOP')
  @StandardReferences([
    'IEEE 830 / ISO/IEC/IEEE 29148 — functional requirements',
  ], 'The execution frequency, volume, and business criticality of a function.')
  @Form([
    Field(
      'frequency',
      String,
      'Frequency',
      hint: 'How often executed: Continuous | Daily | OnDemand | Periodic',
    ),
    Field(
      'volumeEstimate',
      String,
      'Volume Estimate',
      hint: 'Estimated execution frequency/volume',
    ),
    Field(
      'criticalityLevel',
      String,
      'Criticality Level',
      hint: 'Business criticality: Critical | High | Medium | Low',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? operations;

  /// Automation and data handling summary.
  @SectionId('FUENIM')
  @StandardReferences([
    'CRUD matrix — function/data interaction mapping',
    'IEEE 830 / ISO/IEC/IEEE 29148 — functional requirements',
  ], 'The automation level and data entities a function accesses.')
  @Form([
    Field(
      'automationLevel',
      String,
      'Automation Level',
      hint: 'Manual | SemiAutomated | FullyAutomated',
    ),
    Field(
      'dataAccess',
      String,
      'Data Access',
      hint: 'Summary of data entities accessed with CRUD',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? implementation;

  /// Sub-functions — contains 0+× SubFunction.
  @StandardReferences([
    'Structured Analysis (DeMarco/Yourdon) — functional decomposition',
  ], 'The lower-level sub-functions this function decomposes into.')
  @SectionId('SUFN-SUBF-LST')
  @SectionIdPattern('SUFN-SUBF-xxx')
  @ContentHelp('Add one entry per sub-function.')
  @SerializationOrder(4)
  List<SubFunctionEntry> subFunctions = [];
}

/// A sub-function entry (form).
///
/// Lower-level function in the decomposition.
@StandardReferences([
  'Structured Analysis (DeMarco/Yourdon) — functional decomposition',
], 'A lower-level sub-function within the functional decomposition.')
@SectionId('SUFN')
@CodeSpecKind([CodeSpecPart.serviceUnit])
class SubFunctionEntry extends DocSpecsSection {
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'What this sub-function does',
    ),
    Field(
      'dataAccess',
      String,
      'Data Access',
      hint: 'Entities accessed with CRUD notation',
    ),
    Field(
      'systemSupport',
      String,
      'System Support',
      hint: 'Systems that support this function',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A function-to-data matrix entry (form).
///
/// Maps a function to the data entities it accesses.
@StandardReferences(
  ['CRUD matrix — function/data interaction mapping'],
  'A single cell of the CRUD matrix, recording how one function accesses one data entity.',
)
@SectionId('FNDMX')
@CodeSpecKind([CodeSpecPart.serviceUnit],
    note: 'Function×data CRUD matrix → feeds CE-SU owned-entity/operation '
        'derivation.')
class FunctionDataMatrixEntry extends DocSpecsSection {
  @Form([
    Field(
      'entityName',
      String,
      'Entity Name',
      required: true,
      hint: 'Data entity being accessed',
    ),
    Field(
      'accessType',
      String,
      'Access Type',
      hint: 'CRUD access: C | R | U | D or combinations',
    ),
    Field(
      'accessFrequency',
      String,
      'Access Frequency',
      hint: 'How often function accesses this entity',
    ),
    Field(
      'isOwner',
      String,
      'Is Owner',
      hint: 'Whether this function owns the entity: Yes | No',
    ),
    Field(
      'accessReason',
      String,
      'Access Reason',
      hint: 'Why this function needs this access',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A business rule entry (form).
///
/// Comprehensive business rule specification following SBVR-like patterns.
@StandardReferences(
  [
    'SBVR — business rule statements',
    'IEEE 830 / ISO/IEC/IEEE 29148 — functional requirements',
  ],
  'A single business rule with its logic, enforcement, exceptions, and governance.',
)
@SectionId('BIRU')
@CodeSpecKind([CodeSpecPart.validation],
    note: 'Business rule → validation (field/form rule).')
class BusinessRuleEntry extends DocSpecsSection {
  @ContentHelp(
    'Narrative for this business rule — the intent behind it, beyond the '
    'logic, enforcement and governance facets recorded below.',
  )
  @override
  @SerializationOrder(0)
  String? content;

  // ---------------------------------------------------------------------------
  // Rule Identity (5 fields)
  // ---------------------------------------------------------------------------
  /// The rule's own statement, in the words of the business, and its version.
  ///
  /// Two statements are kept deliberately: a description precise enough to
  /// implement against, and the natural-language statement the business
  /// recognises as its own policy. They drift, and a rule whose two statements
  /// have drifted is the usual root of a "the system is wrong" dispute that
  /// turns out to be a specification defect. The version sits here rather than
  /// in the governance band because it identifies *which* statement is being
  /// cited when the rule is referenced from an object or a function.
  @SectionId('BIRU-IDEN')
  @Form([
    Field(
      'ruleVersion',
      String,
      'Rule Version',
      hint: 'Version number for change tracking',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Full statement of the business rule',
    ),
    Field(
      'businessStatement',
      String,
      'Business Statement',
      hint: 'Natural language statement from business perspective',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Classification (5 fields)
  // ---------------------------------------------------------------------------
  /// What kind of rule this is, how binding it is, and where it came from.
  ///
  /// The band that decides how the rule is *treated* rather than what it says.
  /// The type and category say what the rule produces — a check, a computed
  /// value, an inference, an enabled action — and therefore which derivation
  /// reads it. The enforcement level separates a rule the system must refuse to
  /// violate from a guideline it may only warn about. The source decides who is
  /// entitled to change it, since a rule originating in a regulation cannot be
  /// relaxed by the project at all. Priority is the tiebreak when two
  /// applicable rules disagree.
  @SectionId('BIRU-CLAS')
  @Form([
    Field(
      'ruleType',
      String,
      'Rule Type',
      hint:
          'Structural | Derivation | Constraint | Authorization | Workflow | Calculation',
    ),
    Field(
      'ruleCategory',
      String,
      'Rule Category',
      hint: 'Validation | Computation | Inference | Action-Enabling',
    ),
    Field(
      'enforcementLevel',
      String,
      'Enforcement Level',
      hint: 'Mandatory | Guideline | Advisory',
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'When rules conflict: 1 (highest) to 5 (lowest)',
    ),
    Field(
      'source',
      String,
      'Source',
      hint:
          'Where rule originates: Regulation | Policy | Contract | BestPractice',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? classification;

  // ---------------------------------------------------------------------------
  // Rule Logic (5 fields)
  // ---------------------------------------------------------------------------
  /// The rule as a condition and its consequences — IF, THEN, and otherwise.
  ///
  /// The executable heart of the entry, held in a fixed shape so rules can be
  /// compared and tested rather than only read. Separating the trigger from the
  /// action is what makes the rule testable at all: a worked example
  /// ([RuleExampleEntry]) supplies inputs for the condition and asserts the
  /// action, which is the form a test derivation needs. Parameters are named
  /// apart from the condition text so a threshold can be changed without
  /// restating the rule.
  @SectionId('BIRU-RULE')
  @Form([
    Field(
      'condition',
      String,
      'Condition (IF)',
      hint: 'Trigger condition in natural language or pseudo-code',
    ),
    Field(
      'action',
      String,
      'Action (THEN)',
      hint: 'What happens when condition is true',
    ),
    Field(
      'elseAction',
      String,
      'Else Action (ELSE)',
      hint: 'What happens when condition is false',
    ),
    Field(
      'expression',
      String,
      'Formal Expression',
      hint: 'Formalized rule logic',
    ),
    Field(
      'parameters',
      String,
      'Parameters',
      hint: 'Configurable values in the rule',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? ruleLogic;

  // ---------------------------------------------------------------------------
  // Implementation (5 fields)
  // ---------------------------------------------------------------------------
  /// Where and how the rule is actually enforced, and whether that can be
  /// tested.
  ///
  /// The gap this band closes is that a rule can be stated perfectly and
  /// enforced nowhere. Naming the enforcing systems turns "the rule exists"
  /// into a checkable claim; the testability field states up front whether the
  /// check can be automated at all. A rule marked manual-only will never fail a
  /// build, and that is a fact the acceptance plan has to know before the rule
  /// is relied on as a control.
  @SectionId('BIRU-IMPL')
  @Form([
    Field(
      'enforcement',
      String,
      'Enforcement',
      hint:
          'How enforced: DatabaseConstraint | ApplicationLogic | Workflow | Manual',
    ),
    Field(
      'implementationPoint',
      String,
      'Implementation Point',
      hint: 'Where implemented: UI | API | Service | Database | Integration',
    ),
    Field(
      'validationTiming',
      String,
      'Validation Timing',
      hint:
          'When validated: OnInput | OnSave | OnSubmit | Scheduled | RealTime',
    ),
    Field(
      'systemsInvolved',
      String,
      'Systems Involved',
      hint: 'Which systems enforce this rule',
    ),
    Field(
      'testability',
      String,
      'Testability',
      hint:
          'How rule can be tested: UnitTestable | IntegrationRequired | ManualOnly',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? implementation;

  // ---------------------------------------------------------------------------
  // Exception Handling (4 fields)
  // ---------------------------------------------------------------------------
  /// What happens when the rule is violated, and whether it may be waived.
  ///
  /// Every enforceable rule eventually meets a legitimate exception, and a
  /// specification that says nothing about them gets one invented at runtime by
  /// whoever is under pressure. The band records both halves: the automatic
  /// consequence of a violation, and the human path — who may override, who
  /// approves it, where it escalates. An empty override policy means no
  /// override exists, which is a stronger statement than it looks and should be
  /// chosen rather than defaulted into.
  @SectionId('BIRU-EXCE')
  @Form([
    Field(
      'exceptionHandling',
      String,
      'Exception Handling',
      hint: 'How violations are handled',
    ),
    Field(
      'overridePolicy',
      String,
      'Override Policy',
      hint: 'Whether and how rule can be overridden',
    ),
    Field(
      'overrideApproval',
      String,
      'Override Approval',
      hint: 'Who can approve overrides',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path',
      hint: 'How exceptions are escalated',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? exceptionHandling;

  // ---------------------------------------------------------------------------
  // Governance (4 fields)
  // ---------------------------------------------------------------------------
  /// Who owns the rule, and for how long it holds.
  ///
  /// A business rule is not permanent: it takes effect on a date, may expire on
  /// another, and is re-examined on a cadence. Recording the dates is what
  /// makes the rule *temporal* — a decision taken before its effective date was
  /// not a violation, which is precisely what an audit has to be able to
  /// establish. The owner is whoever may change the statement above; the review
  /// frequency is what stops a policy that has lapsed from being enforced
  /// indefinitely because nobody looked.
  @SectionId('BIRU-GOVE')
  @Form([
    Field(
      'ruleOwner',
      String,
      'Rule Owner',
      hint: 'Business owner responsible for this rule',
    ),
    Field(
      'effectiveDate',
      String,
      'Effective Date',
      hint: 'When rule becomes/became effective',
    ),
    Field(
      'expirationDate',
      String,
      'Expiration Date',
      hint: 'When rule expires (if applicable)',
    ),
    Field(
      'reviewFrequency',
      String,
      'Review Frequency',
      hint: 'How often rule is reviewed: Annually | OnChange | Never',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? governance;

  /// Contains 0+× AffectedObject.
  @StandardReferences([
    'SBVR — business rule statements',
  ], 'The business objects this rule validates, constrains, or modifies.')
  @SectionId('AFOB-AFFE-LST')
  @SectionIdPattern('AFOB-AFFE-xxx')
  @ContentHelp('Add one entry per affected object.')
  @SerializationOrder(7)
  List<AffectedObjectEntry> affectedObjects = [];

  /// Contains 0+× AffectedFunction.
  @StandardReferences([
    'SBVR — business rule statements',
    'CRUD matrix — function/data interaction mapping',
  ], 'The functions where this rule is triggered and applied.')
  @SectionId('AFFN-AFFE-LST')
  @SectionIdPattern('AFFN-AFFE-xxx')
  @ContentHelp('Add one entry per affected function.')
  @SerializationOrder(8)
  List<AffectedFunctionEntry> affectedFunctions = [];

  /// Contains 0+× RuleExample.
  @StandardReferences([
    'SBVR — business rule statements',
  ], 'Worked examples that illustrate how this rule evaluates.')
  @SectionId('RULEXM-EXAM-LST')
  @SectionIdPattern('RULEXM-EXAM-xxx')
  @ContentHelp('Add one entry per rule example.')
  @SerializationOrder(9)
  List<RuleExampleEntry> examples = [];
}

/// An affected object reference entry (form).
///
/// Business objects affected by this rule.
@StandardReferences([
  'SBVR — business rule statements',
], 'A business object affected by a rule, and how it is impacted.')
@SectionId('AFOB')
@CodeSpecKind([CodeSpecPart.validation])
class AffectedObjectEntry extends DocSpecsSection {
  @Form([
    Field(
      'affectedAttributes',
      String,
      'Affected Attributes',
      hint: 'Specific attributes affected',
    ),
    Field(
      'impact',
      String,
      'Impact',
      hint:
          'How the object is impacted: Validated | Constrained | Modified | Created',
    ),
    Field('accessType', String, 'Access Type', hint: 'Read | Write | Both'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// The resolved link to the business object this rule acts on.
  ///
  /// The surrounding entry says *how* the object is affected — which
  /// attributes, whether it is validated, constrained, modified or created, and
  /// whether the access is a read or a write. This member is the followable
  /// edge to the object itself, which is what lets a rule's impact set be
  /// computed rather than read: given a rule, every object it touches, and
  /// given an object, every rule that touches it.
  @SectionId('AFOB-OBJE-REF')
  @Reference('objectName')
  @SerializationOrder(1)
  DocSpecsSection? objectRef;
}

/// An affected function reference entry (form).
///
/// Functions where this rule applies.
@StandardReferences([
  'SBVR — business rule statements',
  'IEEE 830 / ISO/IEC/IEEE 29148 — functional requirements',
], 'A function where a rule applies, with its trigger point and impact.')
@SectionId('AFFN')
@CodeSpecKind([CodeSpecPart.validation])
class AffectedFunctionEntry extends DocSpecsSection {
  @Form([
    Field(
      'triggerPoint',
      String,
      'Trigger Point',
      hint: 'When in the function rule is triggered',
    ),
    Field('impact', String, 'Impact', hint: 'How the function is impacted'),
    Field(
      'isMandatory',
      String,
      'Is Mandatory',
      hint: 'Whether check is required in this function: Yes | No',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// The resolved link to the function in which this rule fires.
  ///
  /// The object side of a rule ([AffectedObjectEntry]) says what it acts on;
  /// this side says where in the flow it is evaluated, which is what gives the
  /// trigger point and the mandatory flag their meaning. Both are needed: one
  /// rule may guard an entity that three functions write, and only one of those
  /// functions may be entitled to skip the check.
  @SectionId('AFFN-FUNC-REF')
  @Reference('functionName')
  @SerializationOrder(1)
  DocSpecsSection? functionRef;
}

/// A rule example entry (form).
///
/// Examples illustrating rule application.
@StandardReferences([
  'SBVR — business rule statements',
], 'A worked example illustrating how a rule evaluates for given inputs.')
@SectionId('RULEXM')
@CodeSpecKind([CodeSpecPart.validation],
    note: 'Rule example → validation test case (Phase 5 derivation).')
class RuleExampleEntry extends DocSpecsSection {
  @Form([
    Field(
      'scenario',
      String,
      'Scenario',
      hint: 'Description of the example scenario',
    ),
    Field('inputData', String, 'Input Data', hint: 'Example input values'),
    Field(
      'expectedOutcome',
      String,
      'Expected Outcome',
      hint: 'Expected result of rule evaluation',
    ),
    Field(
      'exampleType',
      String,
      'Example Type',
      hint: 'Positive | Negative | EdgeCase | BoundaryCondition',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.1.5 Data Dictionary
// ---------------------------------------------------------------------------

/// 7.1.5. Data Dictionary.
///
/// Attribute-level dictionary that complements the entity overview
///..
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'DAMA-DMBOK2 — data management body of knowledge',
  ],
  'An authoritative registry of the data attributes used across the model, each with its definition, type, and provenance.',
)
@SectionId('DADI')
@DetailedIn(D03InformationModel)
@CodeSpecKind([CodeSpecPart.dataAccess])
class DataDictionary extends DocSpecsSection {
  @ContentHelp('''
Single authoritative registry for data attributes across the system.

**What to capture:**
- Attribute name, data type, and allowed values
- Source entity, semantic description, and synonyms
- Business rules that constrain the attribute
- Provenance (where the attribute is first set, where it is read)
- Format / unit / precision conventions
- Default value and required-ness
- Cross-references to validation constraints
''')
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.1.6 Validation Constraints
// ---------------------------------------------------------------------------

/// 7.1.6. Validation Constraints.
///
/// Cross-entity validation policy. Per-field validation lives in entity
/// form fields; this section captures rules that span multiple fields or
/// entities.
@StandardReferences(
  ['SBVR — business rule statements', 'ISO/IEC 25012 — data quality'],
  'Business-level validation rules that span multiple fields or entities, distinct from schema and per-field UI checks.',
)
@SectionId('VACO')
@DetailedIn(D03InformationModel)
@CodeSpecKind([CodeSpecPart.validation])
class ValidationConstraints extends DocSpecsSection {
  @ContentHelp('''
Business-level validation rules enforced on data. Distinct from schema
constraints (which are database-level) and from per-field form hints
(which are UI-level).

**What to capture:**
- Rule catalog (name, scope, severity)
- Cross-field rules (field A must match format of field B)
- Cross-entity rules (order total must match line-item sum)
- Conditional rules (required only when X, forbidden when Y)
- Validation trigger points (on entry, on save, on batch, on publish)
- Error-message catalog for each rule
''')
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.1.7 Integrity Constraints
// ---------------------------------------------------------------------------

/// 7.1.7. Integrity Constraints.
///
/// Cross-entity integrity rules beyond simple referential integrity.
@StandardReferences(
  ['ER modeling (Chen / Barker notation)', 'SBVR — business rule statements'],
  'Cross-entity invariants (referential, uniqueness, temporal, conservation) that must hold in every persistent state.',
)
@SectionId('INCO')
@DetailedIn(D03InformationModel)
@CodeSpecKind([CodeSpecPart.validation])
class IntegrityConstraints extends DocSpecsSection {
  @ContentHelp('''
Integrity rules that preserve invariants across the data model.
Stronger guarantees than validation (which is typically user-facing);
integrity constraints must hold in every persistent state.

**What to capture:**
- Referential integrity (which references must never dangle)
- Uniqueness constraints (per scope / tenant)
- State-machine invariants (entity cannot skip states)
- Aggregate-boundary rules (what must be atomic together)
- Temporal constraints (effective-from ≤ effective-to)
- Conservation rules (sums / counts that must balance)
''')
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single behavior rule entry.
@StandardReferences(
  [
    'SBVR — business rule statements',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ],
  'The business rules, invariants, key operations, and derived properties that govern a domain object\'s behavior.',
)
@SectionId('BEHAV')
@CodeSpecKind([CodeSpecPart.validation],
    note: 'Behavior rule governing an object → validation rule.')
class BehaviorRuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'keyBusinessRules',
      String,
      'Key Business Rules',
      hint: 'Primary business rules governing this object',
    ),
    Field(
      'invariants',
      String,
      'Invariants',
      hint: 'Conditions that must always be true',
    ),
    Field(
      'keyOperations',
      String,
      'Key Operations',
      hint: 'Main operations/behaviors (e.g., Submit, Approve, Cancel)',
    ),
    Field(
      'validationRules',
      String,
      'Validation Rules',
      hint: 'Rules for validating object state',
    ),
    Field(
      'calculatedProperties',
      String,
      'Calculated Properties',
      hint: 'Derived/calculated attributes (e.g., orderTotal, age)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single integration point entry.
///
/// How a domain object connects to the outside world. It describes *outward
/// connections* — which interfaces surface the object, which events it takes
/// part in, how it maps onto external systems — and deliberately declares no
/// operation of the application's own: those live in the server operation
/// registry (SVOPR), which is the one place an operation is named and given its
/// request/response shapes.
@StandardReferences(
  ['UML 2.5.1 (ISO/IEC 19505) — class/object modeling'],
  'How a domain object connects to the outside world: the APIs that expose it, events it publishes or subscribes to, and external-system mappings.',
)
@SectionId('INTEG')
@CodeSpecKind([CodeSpecPart.serverCall],
    note: 'CE-SC — the consumed side of an integration point: the external '
        "systems this object is exchanged with. The application's own "
        'operations are declared in the server operation registry (SVOPR), '
        'not here.')
class IntegrationPointEntry extends DocSpecsSection {
  @Form([
    Field(
      'exposedInApis',
      String,
      'Exposed In APIs',
      hint: 'Which APIs expose this object: Internal | Public | Partner',
    ),
    Field(
      'eventPublished',
      String,
      'Events Published',
      hint: 'Domain events this object publishes',
    ),
    Field(
      'eventSubscribed',
      String,
      'Events Subscribed',
      hint: 'Events this object reacts to',
    ),
    Field(
      'externalSystemMapping',
      String,
      'External System Mapping',
      hint: 'How this maps to external systems',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single constraint entry.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'ISO/IEC 25012 — data quality',
  ],
  'The constraints on a single data attribute: nullability, uniqueness, defaults, allowed values, and validation expressions.',
)
@SectionId('DATAA')
@CodeSpecKind([
  CodeSpecPart.validation,
  CodeSpecPart.dataAccess,
  CodeSpecPart.serverApi,
], note: 'Attribute-level constraint → CE-VA field rule (required, range, '
    'pattern, type). The storage facts (nullable, length, format) feed the '
    'CE-DB column (codespecs_derivation_contract.md §3.3.2) and the CE-API '
    'entity wire DTO (§3.2.11), so both extracts carry them.')
class DataAttributeConstraintEntry extends DocSpecsSection {
  @Form([
    Field(
      'mandatory',
      String,
      'Mandatory',
      hint:
          'Whether attribute is required: Required | Optional | ConditionallyRequired',
    ),
    Field(
      'nullable',
      String,
      'Nullable',
      hint: 'Whether database allows NULL: Yes | No',
    ),
    Field(
      'unique',
      String,
      'Unique',
      hint: 'Uniqueness constraint: Unique | UniqueWithinParent | NotUnique',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'Default value or expression (e.g., NOW(), 0, "Draft")',
    ),
    Field(
      'validationRules',
      String,
      'Validation Rules',
      hint: 'Business validation rules (e.g., must be positive, max 100)',
    ),
    Field(
      'constraintExpression',
      String,
      'Constraint Expression',
      hint: 'CHECK constraint (e.g., amount > 0, status IN ("Draft","Active"))',
    ),
    // Why: this narrows a value set, it never declares one. An attribute typed
    // by a domain enum names its enum in `DAATT-DTEN`, and the enum's values are
    // declared once in the domain enum register (`DMEVA`); listing them again
    // here would be a second source. What belongs here is the *subset* this
    // attribute permits, which is a constraint like any other.
    Field(
      'allowedValues',
      String,
      'Allowed Values',
      hint: 'The subset of values this attribute permits — value ids from the '
          'domain enum it is typed by, or the permitted literals for a '
          'non-enumerated attribute; empty means unrestricted',
    ),
    Field(
      'patternRegex',
      String,
      'Pattern/Regex',
      hint: r'Regex for validation (e.g., ^[A-Z]{2}-\d{6}$ for order IDs)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single display property entry.
@StandardReferences(
  ['ISO/IEC 11179 — metadata registries / data element definitions'],
  'How an attribute is presented in the UI: its label, ordering, grouping, and help text.',
)
@SectionId('DISPL')
@CodeSpecKind([CodeSpecPart.viewState],
    note: 'Display/formatting properties bind an attribute to view-model state; '
        'label/help copy also feeds CE-TX.')
class DisplayPropertyEntry extends DocSpecsSection {
  @Form([
    Field(
      'displayOrder',
      String,
      'Display Order',
      hint: 'Order when displaying in forms/tables',
    ),
    Field(
      'displayGroup',
      String,
      'Display Group',
      hint: 'Grouping for UI layout',
    ),
    Field(
      'helpText',
      String,
      'Help Text',
      hint: 'User assistance text for forms',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single volume metric entry.
@StandardReferences(
  ['DAMA-DMBOK2 — data management body of knowledge'],
  'The expected data volumes for an entity: record counts, growth rate, peak transaction volume, and storage estimates for capacity planning.',
)
@SectionId('VOLUM')
class VolumeMetricEntry extends DocSpecsSection {
  @Form([
    Field(
      'estimatedRecordCount',
      String,
      'Estimated Record Count',
      hint: 'Initial record count with source (e.g., 120,000 from migration)',
    ),
    Field(
      'growthRate',
      String,
      'Growth Rate',
      hint: 'Expected growth rate (e.g., 10% annually, 5,000/month)',
    ),
    Field(
      'peakTransactionVolume',
      String,
      'Peak Transaction Volume',
      hint: 'Maximum transactions per time period (e.g., 1,000 orders/hour)',
    ),
    Field(
      'averageRecordSize',
      String,
      'Average Record Size',
      hint: 'Typical record size in bytes for storage planning',
    ),
    Field(
      'storageEstimate',
      String,
      'Storage Estimate',
      hint: 'Projected storage requirements (e.g., 50GB initial, 10GB/year)',
    ),
    Field(
      'partitioningStrategy',
      String,
      'Partitioning Strategy',
      hint: 'How data should be partitioned: ByDate | ByRange | ByHash | None',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single compliance requirement entry.
@StandardReferences(
  [
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
    'ISO/IEC 27001 / NIST — data classification',
  ],
  'The compliance profile of an entity: its sensitivity level, PII/PHI content, applicable frameworks, and encryption and access requirements.',
)
@SectionId('CRE')
class ComplianceRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'sensitivityLevel',
      String,
      'Sensitivity Level',
      hint: 'Data sensitivity: Public | Internal | Confidential | Restricted',
    ),
    Field(
      'containsPii',
      String,
      'Contains PII',
      hint:
          'Whether entity contains personally identifiable information: Yes | No',
    ),
    Field(
      'containsPhi',
      String,
      'Contains PHI',
      hint: 'Whether entity contains protected health information: Yes | No',
    ),
    Field(
      'complianceFrameworks',
      String,
      'Compliance Frameworks',
      hint: 'Applicable regulations: GDPR | HIPAA | SOX | PCI-DSS | CCPA',
    ),
    Field(
      'encryptionRequirements',
      String,
      'Encryption Requirements',
      hint: 'AtRest | InTransit | Both | FieldLevel | None',
    ),
    Field(
      'accessRestrictions',
      String,
      'Access Restrictions',
      hint:
          'Who can access: AllUsers | AuthenticatedUsers | RoleRestricted | SystemOnly',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single technical characteristic entry.
@StandardReferences(
  ['DAMA-DMBOK2 — data management body of knowledge'],
  'The technical implementation traits of an entity: indexing, caching, consistency, replication, backup, and scaling strategies.',
)
@SectionId('TECHN')
class TechnicalCharacteristicEntry extends DocSpecsSection {
  @Form([
    Field(
      'indexingStrategy',
      String,
      'Indexing Strategy',
      hint: 'Primary index and secondary indexes planned',
    ),
    Field(
      'cachingStrategy',
      String,
      'Caching Strategy',
      hint: 'Cache policy: NoCache | ReadThrough | WriteThrough | CacheAside',
    ),
    Field(
      'consistencyRequirements',
      String,
      'Consistency Requirements',
      hint: 'Strong | Eventual | ReadYourWrites',
    ),
    Field(
      'replicationStrategy',
      String,
      'Replication Strategy',
      hint: 'How data is replicated across regions or nodes',
    ),
    Field(
      'backupRequirements',
      String,
      'Backup Requirements',
      hint: 'Backup frequency and recovery point objective',
    ),
    Field(
      'scalingApproach',
      String,
      'Scaling Approach',
      hint: 'How entity scales: Vertical | Horizontal | Sharding',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single participant entry.
@StandardReferences(
  [
    'ER modeling (Chen / Barker notation)',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ],
  'The two ends of a relationship: the source and target entities and the role each plays.',
)
@SectionId('PARTI')
@CodeSpecKind(
  [CodeSpecPart.dataAccess],
  note:
      'one participant in a data relationship',
)
class ParticipantEntry extends DocSpecsSection {
  @Form([
    Field(
      'sourceEntityName',
      String,
      'Source Entity',
      hint: 'Name of the source/parent entity',
    ),
    Field(
      'sourceRole',
      String,
      'Source Role',
      hint:
          'Role name on the source end (e.g., "placer" in Customer places Order)',
    ),
    Field(
      'targetEntityName',
      String,
      'Target Entity',
      hint: 'Name of the target/child entity',
    ),
    Field(
      'targetRole',
      String,
      'Target Role',
      hint:
          'Role name on the target end (e.g., "placed" in Customer places Order)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single relationship attribute entry.
@StandardReferences(
  [
    'ER modeling (Chen / Barker notation)',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ],
  'Attributes carried by the relationship itself (as on an association class), including any temporal or versioning aspects.',
)
@SectionId('RELAT')
@CodeSpecKind([CodeSpecPart.dataAccess])
class RelationshipAttributeEntry extends DocSpecsSection {
  @Form([
    Field(
      'hasRelationshipAttributes',
      String,
      'Has Relationship Attributes',
      hint: 'Whether the relationship has its own attributes: Yes | No',
    ),
    Field(
      'relationshipAttributes',
      String,
      'Relationship Attributes',
      hint:
          'Attributes on the relationship itself (e.g., quantity on OrderItem)',
    ),
    Field(
      'temporalAspects',
      String,
      'Temporal Aspects',
      hint: 'Effective dates, versioning: None | EffectiveDates | FullHistory',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.4 Schema Versioning and Migration
// ---------------------------------------------------------------------------

/// 7.4. Schema Versioning and Migration.
///
/// Records how the database schema is *versioned and migrated* as the data
/// model evolves — the versioning policy, the data source / schema targets, and
/// the ordered artifact set that establishes and evolves the schema. This is
/// distinct from business-data migration between systems (see
/// `MigrationMappingEntry` for old→new field mapping): here the subject is the
/// schema's own evolution over releases.
@StandardReferences(
  [
    'DAMA-DMBOK2 — data management body of knowledge',
    'Evolutionary Database Design (Ambler & Sadalage) — database refactoring',
  ],
  'Captures the schema versioning strategy, the data source / schema targets, and the ordered migration artifacts derived from the data model’s evolution — the schema’s own history, not business-data migration between systems.',
)
@SectionId('SCHMG')
@CodeSpecKind([CodeSpecPart.schemaMigration],
    note: 'CE-MG — schema migration artifacts derived from the data model '
        'evolution: @CsMigration-marked SQL files (initial DDL, base/seed '
        'data, iteration scripts), server locus, built on the '
        'tom_core_server migration engine (TomDbMigrations, mapping doc '
        'codespecs_mapping.md §5.27). MIGTG supplies the datasource/schema '
        'directory placement; SCMST.artifactKind supplies CsMigrationKind and '
        'SCMST.environments the filename environment tag.')
class SchemaVersioningAndMigration extends DocSpecsSection {
  @ContentHelp('''
Describe how the database schema is versioned and how schema changes are
authored, ordered, and applied as the data model evolves across releases.

**Covers:**
- The versioning strategy (sequential, timestamped, semantic)
- Whether down/rollback steps are supported (forward-only vs reversible)
- The baseline schema version and any zero-downtime approach (expand/contract)
- The data sources and schemas the artifacts target (7.4.1)
- The ordered artifact set itself (7.4.2)

The migration artifact set spans three kinds:
- **Initial DDL** — the baseline schema (tables, indexes, constraints)
- **Reference data** — the initial reference data of the NEW system (lookup
  tables, defaults, built-in roles)
- **Schema change** — the append-only evolution steps applied per release

**The migration engine is fixed, so there is no tooling decision to record
here.** Artifacts are applied by the framework's own migration engine; this
section says *what* to apply and *where*, never *with what*.

**Applied artifacts are immutable.** The engine records each applied artifact
and, on re-encountering it, verifies rather than re-applies it. An artifact
that has been applied anywhere is never edited — a further schema change is
always a *new* artifact with the next version. Author revisions of an already
released artifact as an additional entry, not as a change to the existing one.

**The artifact chain must converge on the data model.** The cumulative effect
of a schema's artifacts must produce exactly the shape the entities and
attributes of the Data Model (7.1) declare. That convergence is a mechanical
check, so a divergence is a defect in one of the two — not a matter of
authoring judgement.

This section is derived from the evolution of the entities in the Data Model
(7.1). It is NOT business-data migration between systems: reference data is
the new system's own initial data, while old→new data mapping and cutover from
legacy systems stay in the migration-mapping sections (MIGME).
''')
  @Form([
    Field(
      'versioningStrategy',
      String,
      'Versioning Strategy',
      hint: 'Sequential numbered | Timestamped | Semantic',
    ),
    Field(
      'forwardOnly',
      bool,
      'Forward-Only',
      hint: 'Whether schema changes are forward-only (no down steps)',
    ),
    Field(
      'baselineVersion',
      String,
      'Baseline Version',
      hint: 'The initial/baseline schema version later artifacts build on',
    ),
    Field(
      'zeroDowntimeApproach',
      String,
      'Zero-Downtime Approach',
      hint: 'Expand/contract, online DDL, blue-green schema, or None',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.4.1. Migration Targets — the data source / schema pairs artifacts apply
  /// to.
  @StandardReferences([
    'ISO/IEC 9075 (SQL) — schema as the named container of database objects',
    'DAMA-DMBOK2 — data management body of knowledge',
  ], 'The data sources and schemas the migration artifacts target, each named so that individual artifacts can reference one.')
  @SectionId('MIGTG-TARG-LST')
  @SectionIdPattern('MIGTG-TARG-xxx')
  @ContentHelp('Add one entry per data source / schema pair that migration '
      'artifacts apply to. Every artifact in 7.4.2 names one of these targets.')
  @SerializationOrder(1)
  List<MigrationTargetEntry> migrationTargets = [];

  /// 7.4.2. Schema Migration Steps — one entry per versioned artifact.
  @StandardReferences([
    'Evolutionary Database Design (Ambler & Sadalage) — database refactoring',
  ], 'The ordered schema migration artifacts that establish and evolve the database over releases.')
  @SectionId('SCMST-STEP-LST')
  @SectionIdPattern('SCMST-STEP-xxx')
  @ContentHelp('Add one entry per versioned migration artifact.')
  @SerializationOrder(2)
  List<SchemaMigrationStepEntry> migrationSteps = [];
}

/// A single migration target — one data source / schema pair (form).
///
/// Migration artifacts are filed per data source and per schema within it, so a
/// system with several databases — or several database *types* — needs no extra
/// specification surface beyond naming each target once here. Every artifact in
/// 7.4.2 then names the target it applies to rather than repeating the pair.
@StandardReferences(
  [
    'ISO/IEC 9075 (SQL) — schema as the named container of database objects',
    'DAMA-DMBOK2 — data management body of knowledge',
  ],
  'A named data source / schema pair that migration artifacts are filed under and applied to.',
)
@SectionId('MIGTG')
@CodeSpecKind(
  [CodeSpecPart.schemaMigration],
  note:
      'one migration target schema',
)
class MigrationTargetEntry extends DocSpecsSection {
  @Form([
    Field(
      'targetName',
      String,
      'Target Name',
      required: true,
      hint: 'The identifier migration artifacts use to name this target',
    ),
    Field(
      'dataSourceName',
      String,
      'Data Source Name',
      required: true,
      hint: 'The registered data source the artifacts are applied against',
    ),
    Field(
      'schemaName',
      String,
      'Schema Name',
      required: true,
      hint: 'The schema within that data source the artifacts act on',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      hint: 'What this data source / schema holds and why it is separate',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single migration artifact (form).
///
/// One versioned artifact in the migration set: what it is (baseline schema,
/// reference data, or a schema change), which target it applies to, and which
/// deployment environments it is restricted to. The kind-specific detail lives
/// in the promoted case subsection its `artifactKind` selects.
@StandardReferences(
  [
    'Evolutionary Database Design (Ambler & Sadalage) — database refactoring',
    'DAMA-DMBOK2 — data management body of knowledge',
  ],
  'A single versioned migration artifact: its kind, target, environment restriction, and the kind-specific definition it carries.',
)
@SectionId('SCMST')
@OneOf(
  discriminator: 'artifactKind',
  note:
      'Migration artifact-kind closed choice: the kind selects its promoted '
      'definition subsection — a baseline schema definition, a reference-data '
      'definition, or a schema change. Each kind authors a different thing, so '
      'every kind binds a case.',
)
@CodeSpecKind(
  [CodeSpecPart.schemaMigration],
  note:
      'one step of a schema migration',
)
class SchemaMigrationStepEntry extends DocSpecsSection {
  @ContentHelp('''
One artifact in the migration set.

**Ordering.** Artifacts are applied in ascending version order across the whole
set for a target, so the version is what places this artifact in the sequence.

**Environments.** Leave *Environments* empty to apply the artifact everywhere.
Naming one or more deployment environments restricts it to those — the way to
seed development or test data that must never reach production. Use the
environment names exactly as they are configured; they are matched verbatim.

**Immutability.** Once this artifact has been applied anywhere, do not edit it.
Author the further change as a new entry with the next version.
''')
  @Form([
    Field(
      'version',
      String,
      'Version',
      required: true,
      hint: 'The version that orders this artifact in the set (e.g. 7, 42)',
    ),
    Field(
      'description',
      String,
      'Description',
      required: true,
      hint: 'What this artifact does and why',
    ),
    Field(
      'artifactKind',
      MigrationArtifactKind,
      'Artifact Kind',
      required: true,
      hint: 'What this artifact is — selects the definition subsection below',
    ),
    Field(
      'migrationTarget',
      String,
      'Migration Target',
      required: true,
      refersTo: ['MIGTG.targetName'],
      hint: 'The data source / schema target from 7.4.1 this applies to',
    ),
    Field(
      'environments',
      String,
      'Environments',
      hint: 'Comma-separated deployment environments this is restricted to, '
          'or empty to apply everywhere',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Baseline schema definition — a promoted `@OneOf` case.
  ///
  /// Present only for the `initialDdl` kind. It establishes the schema, so
  /// there is no prior state: no affected-entity delta, no backfill, and
  /// nothing to roll back to.
  @SectionId('SCMST-BASE')
  @StandardReferences(
    [
      'ISO/IEC 9075 (SQL) — schema definition statements',
      'DAMA-DMBOK2 — data management body of knowledge',
    ],
    'The baseline schema this artifact establishes: the entities it creates and the keys, indexes and constraints it defines.',
  )
  @Case(MigrationArtifactKind.initialDdl)
  @Form([
    Field(
      'createdEntities',
      String,
      'Created Entities',
      required: true,
      refersTo: ['DAENT.entityName'],
      hint: 'The Data Model entities this baseline creates',
    ),
    Field(
      'schemaStatements',
      String,
      'Schema Statements',
      hint: 'The schema definition statements that create the tables',
    ),
    Field(
      'indexesAndConstraints',
      String,
      'Indexes and Constraints',
      hint: 'Keys, indexes and constraints established with the baseline',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? baselineSchema;

  /// Reference-data definition — a promoted `@OneOf` case.
  ///
  /// Present only for the `referenceData` kind. This artifact inserts rows, not
  /// schema, so it authors the value set rather than schema statements. It is
  /// the new system's own initial data — legacy business-data migration stays
  /// in the migration-mapping sections (`MIGME`).
  @SectionId('SCMST-REFD')
  @StandardReferences(
    [
      'DAMA-DMBOK2 — reference and master data management',
      'ISO/IEC 11179 — permissible values of a data element',
    ],
    'The reference data this artifact loads: the entities it populates, the value set, and how re-application is made harmless.',
  )
  @Case(MigrationArtifactKind.referenceData)
  @Form([
    Field(
      'targetEntities',
      String,
      'Target Entities',
      required: true,
      refersTo: ['DAENT.entityName'],
      hint: 'The Data Model entities this artifact populates',
    ),
    Field(
      'valueSet',
      String,
      'Value Set',
      required: true,
      hint: 'The reference values loaded — lookup values, defaults, built-in '
          'roles — or where the authoritative list is kept',
    ),
    Field(
      'identityKey',
      String,
      'Identity Key',
      hint: 'The key that identifies an existing row, so that re-applying the '
          'artifact updates rather than duplicates',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? referenceData;

  /// Schema change — a promoted `@OneOf` case.
  ///
  /// Present only for the `schemaChange` kind: an evolution step on top of an
  /// existing schema. This is the only kind for which a delta of affected
  /// entities, a data backfill and reversibility are meaningful.
  @StandardReferences(
    [
      'Evolutionary Database Design (Ambler & Sadalage) — database refactoring',
      'ISO/IEC 9075 (SQL) — schema definition statements',
    ],
    'The schema change this artifact applies: its statements, the entities it touches, any accompanying data backfill, and whether it is reversible.',
  )
  @SectionId('SCMST-CHNG')
  @Case(MigrationArtifactKind.schemaChange)
  @Form([
    Field(
      'schemaStatements',
      String,
      'Schema Statements',
      required: true,
      hint: 'The schema changes performed on tables, columns, indexes and '
          'constraints',
    ),
    Field(
      'affectedEntities',
      String,
      'Affected Entities',
      required: true,
      refersTo: ['DAENT.entityName'],
      hint: 'The Data Model entities this change touches',
    ),
    Field(
      'dataBackfill',
      String,
      'Data Backfill',
      hint: 'Any data population or transformation performed as part of the '
          'change, or None',
    ),
    Field(
      'reversible',
      bool,
      'Reversible',
      hint: 'Whether a rollback step is provided for this change',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? schemaChange;
}

// ---------------------------------------------------------------------------
// 7.5 Domain Enum Registry
// ---------------------------------------------------------------------------

/// 7.5. Domain Enum Registry.
///
/// The first-class SOM home for the system's **domain enums** — the closed
/// value sets the business data model relies on (order status, currency,
/// account type, …). Before this registry existed, closed value sets could
/// only be captured as free-text `@Form` hints (`dataType`/`elementType`) or
/// inline option lists, so the `domainEnum` CodeSpecs member kind had no
/// expressible home and the closed-choice mechanism had no real enum to use as
/// a discriminator.
///
/// This registry serves **two** roles:
///
/// 1. **`domainEnum` home** — each [DomainEnumEntry] carries the enum's name, backing
///    type and default, and its [DomainEnumEntry.values] each carry a value id,
///    a backing value and a copy reference into the CE-TX message registry.
/// 2. **Closed-choice discriminator source** — because each enum is *named* and
///    exposes an *enumerable* set of value ids, a future `@OneOf`
///    discriminator (csm-7-4) can name a `DomainEnumEntry` as its source and
///    match its `@Case`s to `DomainEnumValueEntry.valueId`. This registry
///    provides that source; the `@OneOf`/`@Case` annotations themselves are a
///    separate part.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / value-domain enumerations',
    'Domain-Driven Design — value objects / enumerations',
  ],
  'The registry of domain enums (closed value sets): each enum with its named, backed values — the `domainEnum` home and the closed-choice discriminator source.',
)
@SectionId('DOMEN')
@CodeSpecKind(
  [CodeSpecPart.domainEnum],
  note:
      'the registry of domain enums',
)
class DomainEnumRegistry extends DocSpecsSection {
  @ContentHelp('''
Catalogue the domain enums — the closed value sets the data model relies on
(e.g. OrderStatus, Currency, AccountType). Add one entry per enum; each enum
lists its members with a stable value id, an optional backing value (the
persisted/serialized code) and a copy reference for the display label.

Domain enums authored here are the single source for:
- `domainEnum` code generation — an enum type per entry;
- the closed-choice (`@OneOf`) discriminator — an enum entry names the choice
  set, its value ids are the cases.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.5.1. Domain Enums — one entry per closed value set.
  @StandardReferences([
    'ISO/IEC 11179 — metadata registries / value-domain enumerations',
  ], 'The catalogued domain enums, each a named closed value set.')
  @SectionId('DMENE-ENUM-LST')
  @SectionIdPattern('DMENE-ENUM-xxx')
  @ContentHelp('Add one entry per domain enum (closed value set).')
  @SerializationOrder(1)
  List<DomainEnumEntry> enums = [];
}

/// A single domain enum (form + values).
///
/// One named closed value set: its name, backing value type, default value and
/// the ordered list of members. Maps to the `domainEnum` **member kind** — the
/// enum name becomes the generated enum type and each member becomes a constant
/// — and doubles as a closed-choice discriminator source (csm-7-4): the enum
/// name identifies the choice set and [values] supply the cases.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / value-domain enumerations',
    'Domain-Driven Design — value objects / enumerations',
  ],
  'A single domain enum: its name, backing type, default, and named member values.',
)
@SectionId('DMENE')
@CodeSpecKind([CodeSpecPart.domainEnum],
    note: 'A closed value set becomes a domain enum / value type: the '
        'enum name is the generated type, each value id + backing value a '
        'constant, and each member copy resolves via CE-TX. The enum also '
        'serves as the closed-choice (@OneOf) discriminator source (csm-7-4).')
class DomainEnumEntry extends DocSpecsSection {
  @Form([
    Field(
      'enumName',
      String,
      'Enum Name',
      required: true,
      hint: 'Logical enum name in PascalCase (e.g. OrderStatus, Currency)',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this value set represents and where it is used',
    ),
    Field(
      'backingType',
      String,
      'Backing Type',
      hint: 'Type of the persisted/serialized code: String | Integer',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'The value id used as the default, if any',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.5.x. Enum Values — one entry per member of the value set.
  @StandardReferences([
    'ISO/IEC 11179 — metadata registries / value-domain enumerations',
  ], 'The member values of this domain enum, each with a stable id, backing value, and copy reference.')
  @SectionId('DMEVA-VALU-LST')
  @SectionIdPattern('DMEVA-VALU-xxx')
  @Min(1)
  @ContentHelp('Add one entry per enum value.')
  @SerializationOrder(1)
  List<DomainEnumValueEntry> values = [];
}

/// A single domain-enum value (form).
///
/// One member of a [DomainEnumEntry]: a stable value id (the generated enum
/// constant and the `@Case` discriminator token), an optional backing value
/// (the persisted/serialized code), and a copy reference — a message key into
/// the CE-TX message registry (csm-7-3) rather than an inline literal, so the
/// display label is authored once and referenced everywhere (csm5 cross-cutting
/// finding #1).
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / value-domain enumerations',
    'ISO 9241-13:1998 — user guidance / clear labelling',
  ],
  'A single domain-enum member: its stable value id, backing value, and copy-key reference.',
)
@SectionId('DMEVA')
@CodeSpecKind(
  [CodeSpecPart.domainEnum],
  note:
      'one value of a domain enum',
)
class DomainEnumValueEntry extends DocSpecsSection {
  @Form([
    Field(
      'valueId',
      String,
      'Value Id',
      required: true,
      hint: 'Stable value identifier (the enum constant / @Case token)',
    ),
    Field(
      'backingValue',
      String,
      'Backing Value',
      hint: 'Persisted/serialized code (int or string), if distinct from the id',
    ),
    Field(
      'copyKey',
      String,
      'Copy Key',
      hint: 'MessageKeyEntry.key into the CE-TX Message Key Registry (MSGKR) '
          'for the display label (author copy once, reference here)',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this value means',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.6 Error Code Registry
// ---------------------------------------------------------------------------

/// 7.6. Error Code Registry.
///
/// The single, shared **application error-code vocabulary** — the spine that
/// CE-VA (validation), CE-ER (the Result envelope) and CE-TX (error copy) all
/// reference so they never invent divergent code strings (csm5 cross-cutting
/// finding #2; `codespecs_mapping.md` §5.21).
///
/// This is distinct from D09's `SystemErrorCodeEntry`, which is framed as a
/// *system/network/display* error catalogue (HTTP status, presentation,
/// recovery). This registry is the **application-level** error vocabulary a
/// success-or-error [ResultEnvelope] carries:
///
/// - a CE-VA field/form rule names its "error code on fail" from here rather
///   than minting a literal;
/// - a CE-ER [ResultEnvelope] error arm carries one of these codes;
/// - CE-TX error copy is keyed by the same code, so client message and server
///   error share one source.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / value-domain enumerations',
    'ISO/IEC 27001:2022 — error codes classify events so they can be logged and correlated',
  ],
  'The registry of shared application error codes referenced by validation rules (CE-VA), the Result envelope (CE-ER), and error copy (CE-TX).',
)
@SectionId('ERCRG')
@CodeSpecKind(
  [CodeSpecPart.errorResult],
  note:
      'the registry of error codes',
)
class ErrorCodeRegistry extends DocSpecsSection {
  @ContentHelp('''
Catalogue the shared application error codes. Add one entry per code; each
code is referenced by:
- CE-VA validation rules (a rule's error code on fail),
- the CE-ER Result envelope (the error arm's `code`),
- CE-TX error copy (the message keyed by the code).

Author the code **once here**; everything else references it by id so the
vocabulary never diverges. This is the *application* error registry — distinct
from D09's system/network/display error catalogue.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.6.1. Error Codes — one entry per shared application error code.
  @StandardReferences([
    'ISO/IEC 11179 — metadata registries / value-domain enumerations',
  ], 'The catalogued shared application error codes.')
  @SectionId('ERCEN-CODE-LST')
  @SectionIdPattern('ERCEN-CODE-xxx')
  @ContentHelp('Add one entry per shared application error code.')
  @SerializationOrder(1)
  List<ErrorCodeEntry> errorCodes = [];
}

/// A single shared application error code (form).
///
/// One entry in the [ErrorCodeRegistry]: a stable machine `code` (the join key
/// referenced by CE-VA rules, the CE-ER error arm and CE-TX copy), a category,
/// a default severity, a retryable hint, an optional HTTP-status hint and a
/// copy-key reference into the CE-TX message registry (csm-7-3). Maps to the
/// CE-ER `errorResult` part — the code vocabulary the Result envelope's error
/// arm draws from.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'ISO/IEC 27001:2022 — error codes classify events so they can be logged and correlated',
  ],
  'A single shared application error code: its stable id, category, default severity, retryable hint, HTTP-status hint, and copy-key reference.',
)
@SectionId('ERCEN')
@CodeSpecKind([CodeSpecPart.errorResult],
    note: 'CE-ER — the shared error-code vocabulary the Result envelope error '
        'arm carries. Also cross-referenced by CE-VA rule error codes and CE-TX '
        'error copy (one code, three consumers).')
class ErrorCodeEntry extends DocSpecsSection {
  @Form([
    Field(
      'code',
      String,
      'Code',
      required: true,
      hint: 'Stable machine error code (e.g. USER_NOT_FOUND, VALIDATION_FAILED) '
          '— the join key for CE-VA rules, CE-ER and CE-TX copy',
    ),
    Field(
      'category',
      String,
      'Category',
      hint: 'Grouping: Validation | Authorization | NotFound | Conflict | '
          'BusinessRule | System',
    ),
    Field(
      'severity',
      String,
      'Default Severity',
      hint: 'Default severity: Info | Warning | Error | Fatal',
    ),
    Field(
      'retryable',
      bool,
      'Retryable',
      hint: 'Whether retrying the same operation may reasonably succeed',
    ),
    Field(
      'httpStatusHint',
      int,
      'HTTP Status Hint',
      hint: 'Optional transport-status hint (application errors ride in a 2xx '
          'body; 5xx are transport failures)',
    ),
    Field(
      'copyKey',
      String,
      'Copy Key',
      hint: 'MessageKeyEntry.key into the CE-TX Message Key Registry (MSGKR) '
          'for the default user-facing message (author copy once, reference here)',
      refersTo: ['MSGKE.key'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.7 Result Envelope
// ---------------------------------------------------------------------------

/// 7.7. Result Envelope.
///
/// The SOM home for the canonical **success-or-error Result envelope** (CE-ER,
/// the `codespecs_mapping.md` §7 server contract). This is the model-side
/// counterpart of the result/error envelope authored per application in
/// `<app>_codespec_shared` (csmb4): every application outcome — success *or*
/// structured error — is returned in a normal (2xx-transport) body as this one
/// envelope; only 5xx are transport failures.
///
/// The envelope has two arms, distinguished by an **is-success discriminator**:
///
/// 1. **success** — carries a value payload;
/// 2. **error** — carries a code (from the [ErrorCodeRegistry]), a
///    retryable/severity hint, and an optional list of field-level details
///    ([ResultFieldDetailEntry]) for input-attributable failures.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description (interface contracts)',
    'REST / RPC result-envelope patterns — success-or-error response modelling',
  ],
  'The canonical success-or-error Result envelope (CE-ER, codespecs_mapping.md §7): a success arm, an is-success discriminator, a field-level detail list, and retryable/severity on the error arm.',
)
@SectionId('RSLTE')
@CodeSpecKind([CodeSpecPart.errorResult],
    note: 'CE-ER — the canonical codespecs_mapping.md §7 Result/ErrorResult envelope: a success arm '
        'or a structured error arm carrying a code (from the error-code '
        'registry), field-level details, and retryable/severity. Realised per '
        'application in <app>_codespec_shared; no framework counterpart '
        '(csmb4).')
class ResultEnvelope extends DocSpecsSection {
  @Form([
    Field(
      'discriminatorField',
      String,
      'Is-Success Discriminator',
      required: true,
      hint: 'The boolean field that distinguishes the arms (default: success)',
    ),
    Field(
      'successArm',
      String,
      'Success Arm',
      hint: 'The success payload — the value type carried when success is true '
          '(may be empty for operations returning nothing)',
    ),
    Field(
      'errorArm',
      String,
      'Error Arm',
      hint: 'The structured error carried when success is false — its code '
          'references the error-code registry (ERCRG)',
    ),
    Field(
      'retryable',
      bool,
      'Carries Retryable Flag',
      hint: 'Whether the error arm carries a retryable flag',
    ),
    Field(
      'severity',
      String,
      'Severity Value Set',
      hint: 'The error severity value set: Info | Warning | Error | Fatal',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.7.1. Field-Level Details — the per-field error detail the error arm may
  /// carry (e.g. form-validation failures).
  @StandardReferences([
    'ISO 9241-143:2012 — form-based interaction and input validation',
  ], 'The field-level error details the Result envelope error arm may carry.')
  @SectionId('RSFDE-FLDD-LST')
  @SectionIdPattern('RSFDE-FLDD-xxx')
  @ContentHelp('Add one entry per field-level detail the error arm may report.')
  @SerializationOrder(1)
  List<ResultFieldDetailEntry> fieldDetails = [];
}

/// A single field-level error detail (form).
///
/// One entry in a [ResultEnvelope] error arm's field-detail list: the offending
/// field path, an error code referencing the [ErrorCodeRegistry], and an
/// optional default message (user copy resolves from the code via CE-TX). The
/// model-side counterpart of the per-application field-error type authored in
/// `<app>_codespec_shared` beside the envelope (csmb4).
@StandardReferences(
  [
    'ISO 9241-143:2012 — form-based interaction and input validation',
    'ISO 9241-13:1998 — user guidance / clear and specific feedback',
  ],
  'A single field-level error detail: the offending field path, an error-code reference, and an optional default message.',
)
@SectionId('RSFDE')
@CodeSpecKind(
  [CodeSpecPart.errorResult],
  note:
      'one field detail carried by a result envelope',
)
class ResultFieldDetailEntry extends DocSpecsSection {
  @Form([
    Field(
      'fieldPath',
      String,
      'Field Path',
      required: true,
      hint: 'The field (or dotted path) the error applies to (e.g. email, '
          'address.postalCode)',
    ),
    Field(
      'errorCodeRef',
      String,
      'Error Code',
      hint: 'Reference into the error-code registry (ERCRG) — ErrorCodeEntry.code',
      refersTo: ['ERCEN.code'],
    ),
    Field(
      'message',
      String,
      'Default Message',
      hint: 'Optional default message; user-facing copy resolves from the code '
          'via CE-TX',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.8 Message Key Registry
// ---------------------------------------------------------------------------

/// 7.8. Message Key Registry.
///
/// The single **author-copy-once, reference-everywhere** home for user-facing
/// copy — the CE-TX (`text`) part. Before this registry existed, copy was
/// scattered across per-field `*Resource` keys and `ValidationMessageTemplate`
/// as unvalidated free text, so the "author once, reference everywhere"
/// invariant could not hold and the same string could diverge between the
/// screen element, the validation message and the error copy (csm5
/// cross-cutting finding #1; `codespecs_mapping.md` §5.21).
///
/// Each [MessageKeyEntry] declares a stable message key, its default (base
/// locale) copy, and any [MessageKeyEntry.localeVariants] — so a single key
/// resolves to the right copy in each locale. The other CodeSpecs parts stop
/// carrying inline copy and instead reference a key here:
///
/// - **CE-EL / CE-AC** element and action labels, placeholders and help copy;
/// - **`domainEnum`** value labels (`DomainEnumValueEntry.copyKey`);
/// - **CE-ER** error copy keyed by error code (`ErrorCodeEntry.copyKey`);
/// - **CE-VA** validation-failure messages.
///
/// csmb3 and csmb5 already modelled their `copyKey` references as plain
/// message-key strings anticipating this registry; those keys now resolve
/// against `MessageKeyEntry.key`.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'W3C Internationalization (i18n) — message catalogues / externalised strings',
    'Unicode CLDR / BCP 47 — locale identification and localized message data',
  ],
  'The registry of message keys (author copy once, reference everywhere): each key with its default copy and locale variants — the single CE-TX home referenced by CE-EL/CE-AC/CE-ER/CE-VA and `domainEnum` copy attributes.',
)
@SectionId('MSGKR')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'the registry of message keys',
)
class MessageKeyRegistry extends DocSpecsSection {
  @ContentHelp('''
Catalogue the user-facing copy as message keys. Add one entry per key; each key
carries its default (base-locale) copy and any per-locale variants.

Author each string **once here** and reference it by key everywhere it appears:
- CE-EL/CE-AC element and action labels, placeholders and help text,
- `domainEnum` value labels (`DomainEnumValueEntry.copyKey`),
- CE-ER error copy keyed by error code (`ErrorCodeEntry.copyKey`),
- CE-VA validation-failure messages.

Referencing the registry by key keeps copy consistent, translatable and
validated — no more free-text `*Resource` keys that can silently diverge.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.8.1. Message Keys — one entry per author-once copy string.
  @StandardReferences([
    'W3C Internationalization (i18n) — message catalogues / externalised strings',
  ], 'The catalogued message keys, each with its default copy and locale variants.')
  @SectionId('MSGKE-MKEY-LST')
  @SectionIdPattern('MSGKE-MKEY-xxx')
  @ContentHelp('Add one entry per message key (author-once copy string).')
  @SerializationOrder(1)
  List<MessageKeyEntry> messageKeys = [];
}

/// A single message key (form + locale variants).
///
/// One author-once copy string: a stable `key` (the token every consumer
/// references), the default base-locale copy, an optional list of named
/// placeholders the copy interpolates, and its
/// [MessageKeyEntry.localeVariants]. Maps to the CE-TX `text` part — the copy
/// the generated code resolves per locale.
@StandardReferences(
  [
    'W3C Internationalization (i18n) — message catalogues / externalised strings',
    'ISO 9241-13:1998 — user guidance / clear and specific wording',
  ],
  'A single message key: its stable token, default copy, placeholders, and locale variants.',
)
@SectionId('MSGKE')
@CodeSpecKind([CodeSpecPart.text],
    note: 'CE-TX — the author-once copy string every consumer references. The '
        'key is the join token: CE-EL/CE-AC labels, domainEnum value copy '
        '(DomainEnumValueEntry.copyKey), CE-ER error copy (ErrorCodeEntry.copyKey) '
        'and CE-VA messages all resolve here. The default copy plus locale '
        'variants become the generated message catalogue.')
class MessageKeyEntry extends DocSpecsSection {
  @Form([
    Field(
      'key',
      String,
      'Message Key',
      required: true,
      hint: 'Stable message key referenced everywhere (e.g. '
          'order.status.pending, error.user.notFound). Dotted, namespaced.',
    ),
    Field(
      'defaultCopy',
      String,
      'Default Copy',
      required: true,
      hint: 'The default (base-locale) user-facing text. May contain named '
          'placeholders like {count} or {name}.',
    ),
    Field(
      'placeholders',
      String,
      'Placeholders',
      hint: 'Comma-separated named parameters the copy interpolates (e.g. '
          'count, name), if any',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Where this copy is used and any translator guidance',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.8.x. Locale Variants — one entry per non-default locale.
  @StandardReferences([
    'Unicode CLDR / BCP 47 — locale identification and localized message data',
  ], 'The per-locale copy variants of this message key (the default copy is the base locale).')
  @SectionId('MSGLV-LOCV-LST')
  @SectionIdPattern('MSGLV-LOCV-xxx')
  @ContentHelp('Add one entry per non-default locale.')
  @SerializationOrder(1)
  List<MessageLocaleVariantEntry> localeVariants = [];
}

/// A single locale variant of a message key (form).
///
/// One localized rendering of a [MessageKeyEntry]: a BCP-47 locale tag and the
/// copy for that locale. The base-locale copy lives on
/// `MessageKeyEntry.defaultCopy`; each variant here overrides it for one
/// locale.
@StandardReferences(
  [
    'Unicode CLDR / BCP 47 — locale identification and localized message data',
    'W3C Internationalization (i18n) — message catalogues / externalised strings',
  ],
  'A single locale variant: a BCP-47 locale tag and the copy for that locale.',
)
@SectionId('MSGLV')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'one locale variant of a message key',
)
class MessageLocaleVariantEntry extends DocSpecsSection {
  @Form([
    Field(
      'locale',
      String,
      'Locale',
      required: true,
      hint: 'BCP-47 locale tag (e.g. en, en-US, de, fr-CA)',
    ),
    Field(
      'copy',
      String,
      'Copy',
      required: true,
      hint: 'The user-facing text for this locale',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 7.9 Server Operation Registry
// ---------------------------------------------------------------------------

/// 7.9. Server Operation Registry.
///
/// The authoring home for the **application's own** operation surface — the
/// CE-API (`serverApi`) part. Every operation the system answers is declared
/// once here; the client side (CE-SC) only *cites* an operation, and the
/// service unit that owns it (CE-SU) is *derived* from the entity each
/// operation primarily writes (`codespecs_mapping.md` §5.17). Neither can
/// declare an operation, so without this registry the system's server API would
/// be code with no specification source.
///
/// This is distinct from the **external** interface inventory under
/// `ExternalInterfaces` (D07 IIS), which describes third-party interfaces the
/// system talks to. Those carry a transport verb and a path because a
/// third-party API really has them; the application's own contract does not —
/// `codespecs_mapping.md` §7 fixes every operation as a single transport shape
/// whose **operation name** carries the intent, and `codespecs_mapping.md`
/// §5.14 drops transport plumbing from the spec surface.
///
/// **What is deliberately not authored here** (all fixed by
/// `codespecs_mapping.md` §7 / `codespecs_mapping.md` §5.14):
///
/// - no transport method and no path — the operation name is the identifier;
/// - no response status codes — every application outcome, success *or* error,
///   rides in the [ResultEnvelope]; only infrastructure failures are transport
///   errors;
/// - no encoding, header, redirect, CORS or credential plumbing — framework
///   transport members, never spec input.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description (interface contracts)',
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ],
  "The registry of the application's own server operations (CE-API): each with its operation name, request and response members, primary written data entity, and authorization requirement.",
)
@SectionId('SVOPR')
@CodeSpecKind(
  [CodeSpecPart.serverApi],
  note:
      'the registry of server operations',
)
class ServerOperationRegistry extends DocSpecsSection {
  @ContentHelp('''
Catalogue the operations the system itself answers. Add one entry per
operation; each one declares:
- the **operation name** — the single identifier callers use,
- the **request members** and **response members** that make up its shapes,
- the **primary data entity** it writes (this determines which service unit
  owns it — never list ownership by hand),
- its **authorization requirement**,
- the **error codes** it may return, from the error-code registry (ERCRG).

Do **not** author a transport method, a path or response status codes: the
operation name carries the intent, and every outcome — success or structured
error — is returned in the Result envelope (RSLTE).

This registry is for the system's **own** operations. Interfaces to third-party
systems are inventoried under External Interfaces (EXIN) instead.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.9.1. Operations — one entry per operation the system answers.
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description (interface contracts)',
  ], "The catalogued operations the application's own server surface answers.")
  @SectionId('SVOPE-OPER-LST')
  @SectionIdPattern('SVOPE-OPER-xxx')
  @ContentHelp('Add one entry per operation the system answers.')
  @SerializationOrder(1)
  List<ServerOperationEntry> operations = [];
}

/// A single server operation (form + request/response members).
///
/// One entry in the [ServerOperationRegistry]: the operation name that
/// identifies it, its purpose, the data entity it primarily writes, its
/// authorization requirement, the error codes it may return, and the members
/// that make up its request and response shapes.
///
/// The operation name is the join token the rest of the model references: the
/// ISC step entries cite it as the target of a client call (CE-SC), and the
/// service unit that owns the operation follows from
/// `ServerOperationEntry.primaryDataEntity` rather than from a hand-written
/// list (`codespecs_mapping.md` §5.17).
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description (interface contracts)',
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ],
  'A single server operation: its name, purpose, primary written data entity, authorization requirement, error codes, and its request and response members.',
)
@SectionId('SVOPE')
@CodeSpecKind(
  [CodeSpecPart.serverApi],
  note:
      "CE-API — the application's own operation surface. Under the "
      'codespecs_mapping.md §7 contract the operation name is the sole '
      'identifier (no method, no path) and the response is always the CE-ER '
      'Result envelope, so only the name, the two typed shapes, the primary '
      'written entity, the CE-AZ requirement and the returnable error codes '
      'are authored. The request/response member shapes generate into the '
      'shared project; the operation itself into the server project (§4.2).',
)
class ServerOperationEntry extends DocSpecsSection {
  @Form([
    Field(
      'operationName',
      String,
      'Operation Name',
      required: true,
      hint: 'The single identifier callers use, e.g., placeOrder — a stable '
          'token of the specified system, not a restatement of the headline',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      hint: 'What the operation does, from the caller\'s point of view',
    ),
    Field(
      'primaryDataEntity',
      String,
      'Primary Data Entity',
      hint: 'DataEntityEntry.entityName of the entity this operation primarily '
          'writes — the service unit that owns that entity owns this '
          'operation (ownership is derived, never listed by hand)',
      refersTo: ['DAENT.entityName'],
    ),
    Field(
      'descriptionKey',
      String,
      'Description Copy Key',
      hint: 'MessageKeyEntry.key into the message key registry (MSGKR) for the '
          "operation's user-facing description (author copy once, reference "
          'here)',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'errorCodes',
      String,
      'Error Codes',
      hint: 'Comma-separated ErrorCodeEntry.code values from the error-code '
          'registry (ERCRG) that this operation may return in the error arm '
          'of the Result envelope',
      refersTo: ['ERCEN.code'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// 7.9.x. Authorization — what a caller must satisfy to invoke this
  /// operation.
  ///
  /// The shared CE-AZ requirement section, not a per-operation restatement.
  /// There is no default: an operation with no requirement authored is a
  /// specification defect.
  @SerializationOrder(1)
  AuthorizationRequirementSpec authorization = AuthorizationRequirementSpec();

  /// 7.9.x. Request Members — the members that make up the request shape.
  @StandardReferences([
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ], 'The members that make up this operation\'s request shape.')
  @SectionId('SVOPM-REQM-LST')
  @SectionIdPattern('SVOPM-REQM-xxx')
  @ContentHelp('Add one entry per member of the request shape.')
  @SerializationOrder(2)
  List<ServerOperationMemberEntry> requestMembers = [];

  /// 7.9.x. Response Members — the members the success payload carries.
  ///
  /// These members *are* the success payload the Result envelope wraps; the
  /// envelope itself is fixed by `codespecs_mapping.md` §7 and is never
  /// authored per operation.
  @StandardReferences([
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ], 'The members that make up the success payload this operation returns.')
  @SectionId('SVOPM-RESM-LST')
  @SectionIdPattern('SVOPM-RESM-xxx')
  @ContentHelp('Add one entry per member of the success payload. Leave empty '
      'for an operation that returns nothing but success or error.')
  @SerializationOrder(3)
  List<ServerOperationMemberEntry> responseMembers = [];
}

/// A single member of an operation's request or response shape (form).
///
/// One named, typed member: its name, its type, whether it must be present, and
/// — when the type is a domain concept rather than a primitive — the data
/// entity or domain enum it draws from. The same shape serves both the request
/// and the response side of a [ServerOperationEntry], so a member reads the
/// same way whichever direction it travels.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'ISO/IEC/IEEE 42010 — architecture description (interface contracts)',
  ],
  "A single member of an operation's request or response shape: its name, type, presence requirement, and the data entity or domain enum it draws from.",
)
@SectionId('SVOPM')
@CodeSpecKind(
  [CodeSpecPart.serverApi],
  note: 'CE-API — one member of an operation request or response shape. The '
      'members of a shape become the shared request/response type both sides '
      'depend on (§4.2 shared locus); a member typed by a domain enum reuses '
      'that declaration by plain type, and a member typed by a data entity is '
      'typed by that entity\'s shared wire DTO '
      '(codespecs_derivation_contract.md §3.2.11), never the server-only '
      'entity class.',
)
class ServerOperationMemberEntry extends DocSpecsSection {
  @Form([
    Field(
      'memberType',
      String,
      'Member Type',
      required: true,
      hint: 'Text | Number | Integer | Decimal | Boolean | Date | Timestamp | '
          'Binary | DataEntity | DomainEnum. For DataEntity or DomainEnum, '
          'name the source in the field below.',
    ),
    Field(
      'multiValued',
      bool,
      'Multi-Valued',
      hint: 'Whether the member carries a collection of the type rather than a '
          'single value',
    ),
    Field(
      'required',
      bool,
      'Required',
      hint: 'Whether the member must be present',
    ),
    Field(
      'dataEntity',
      String,
      'Data Entity',
      hint: 'DataEntityEntry.entityName the member is typed by, when its type '
          'is DataEntity',
      refersTo: ['DAENT.entityName'],
    ),
    Field(
      'domainEnum',
      String,
      'Domain Enum',
      hint: 'DomainEnumEntry.enumName the member is typed by, when its type is '
          'DomainEnum',
      refersTo: ['DMENE.enumName'],
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What the member means and any authoring guidance',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
