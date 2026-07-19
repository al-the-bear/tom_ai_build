/// Section 7: Business Object and Data Model. Seeds → IFM.
///
/// Conceptual overview of the business data the system manages.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

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
- Entity Overview — Comprehensive entity definitions with 7 form groups (41+ fields per entity)
- Entity Relationships — Relationship specifications with cardinality and referential integrity
- ER Diagram — Visual entity-relationship diagram (Mermaid)
- Data Classification — Security classification framework with handling requirements

**Entity Coverage per Entry:**
- Core Identity (name, table, alias, description, stereotype)
- Classification (category, bounded context, domain, ownership)
- Volume Metrics (record count, growth rate, storage estimates)
- Lifecycle Policy (retention, archival, anonymization, audit)
- Compliance Requirements (sensitivity, PII/PHI, encryption, access)
- Relationships Summary (parent, child, referenced, cross-domain)
- Technical Characteristics (indexing, caching, consistency, scaling)
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

  /// 7.1.3. Entity-Relationship Diagram (mermaid).
  @SerializationOrder(3)
  ErDiagramSection erDiagram = ErDiagramSection();

  /// 7.1.4. Data Classification.
  @SerializationOrder(4)
  DataClassification dataClassification = DataClassification();

  /// 7.1.5. Data Dictionary..
  @SerializationOrder(5)
  DataDictionary dataDictionary = DataDictionary();

  /// 7.1.6. Validation Constraints.
  ///
  /// One whole-catalog content section (mirrors `dataDictionary`); collapsed
  /// from `List<ValidationConstraints>` (L34C-12 SR-25).
  @SerializationOrder(6)
  ValidationConstraints validationConstraints = ValidationConstraints();

  /// 7.1.7. Integrity Constraints.
  ///
  /// One whole-catalog content section (mirrors `dataDictionary`); collapsed
  /// from `List<IntegrityConstraints>` (L34C-12 SR-25).
  @SerializationOrder(7)
  IntegrityConstraints integrityConstraints = IntegrityConstraints();
}

/// A data entity entry (form).
///
/// Comprehensive entity specification following data modeling best practices.
/// Captures conceptual, logical, and physical design aspects.
@StandardReferences(
  [
    'ER modeling (Chen / Barker notation)',
    'Domain-Driven Design — aggregates/entities/value objects',
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ],
  'A single data entity with its identity, classification, volume, lifecycle, compliance, and technical characteristics.',
)
@SectionId('DAENT')
@CodeSpecKind([CodeSpecPart.dataAccess])
class DataEntityEntry extends DocSpecsSection {
  // ---------------------------------------------------------------------------
  // Core Identity (5 fields)
  // ---------------------------------------------------------------------------
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
      hint:
          'Entity pattern: AggregateRoot | Entity | ValueObject | Event | View | Bridge',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Classification (6 fields)
  // ---------------------------------------------------------------------------
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
      hint: 'Domain-driven design bounded context this entity belongs to',
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
  @SerializationOrder(1)
  DocSpecsSection? classification;

  // ---------------------------------------------------------------------------
  // Volume and Growth (6 fields)
  // ---------------------------------------------------------------------------
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
  // Lifecycle and Retention (8 fields)
  // ---------------------------------------------------------------------------
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
  // Compliance and Security (6 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(4)
  List<ComplianceRequirementEntry> complianceRequirements = [];

  // ---------------------------------------------------------------------------
  // Relationships Summary (4 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(5)
  DocSpecsSection? relationshipSummary;

  // ---------------------------------------------------------------------------
  // Technical Characteristics (6 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(6)
  List<TechnicalCharacteristicEntry> technicalCharacteristics = [];

  /// Contains 0+× DataAttribute.
  @StandardReferences([
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'DAMA-DMBOK2 — data management body of knowledge',
  ], 'The data attributes (fields) that belong to this entity.')
  @SectionId('DAATT-ATTR-LST')
  @SectionIdPattern('DAATT-ATTR-xxx')
  @ContentHelp('Add one entry per data attribute.')
  @SerializationOrder(7)
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
  @SerializationOrder(8)
  List<KeyAttributeEntry> keyAttributes = [];

  /// Contains 0+× EntityIndex.
  @StandardReferences([
    'DAMA-DMBOK2 — data management body of knowledge',
    'ISO/IEC 25012 — data quality',
  ], 'The database indexes defined on this entity for query optimization.')
  @SectionId('ENIDX-INDE-LST')
  @SectionIdPattern('ENIDX-INDE-xxx')
  @ContentHelp('Add one entry per entity index.')
  @SerializationOrder(9)
  List<EntityIndexEntry> indexes = [];

  /// Contains 0+× EntityConstraint.
  @StandardReferences(
    ['SBVR — business rule statements', 'ISO/IEC 25012 — data quality'],
    'Business and technical constraints on the entity beyond keys, such as check, unique, and exclusion constraints.',
  )
  @SectionId('ENCNS-CONS-LST')
  @SectionIdPattern('ENCNS-CONS-xxx')
  @ContentHelp('Add one entry per entity constraint.')
  @SerializationOrder(10)
  List<EntityConstraintEntry> constraints = [];

  /// Contains 0+× MigrationMapping for data migration planning.
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
  @SerializationOrder(11)
  List<MigrationMappingEntry> migrationMappings = [];
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
@CodeSpecKind([CodeSpecPart.dataAccess],
    note: 'A persisted attribute becomes a table column; display/label detail '
        'feeds CE-TX/CE-ST via DisplayPropertyEntry.')
class DataAttributeEntry extends DocSpecsSection {
  // ---------------------------------------------------------------------------
  // Core Identity (5 fields)
  // ---------------------------------------------------------------------------
  @SectionId('DAATT-IDEN')
  @Form([
    Field(
      'attributeName',
      String,
      'Attribute Name',
      required: true,
      hint: 'Logical attribute name in camelCase',
    ),
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
  @SerializationOrder(0)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Data Type Specification (8 fields)
  // ---------------------------------------------------------------------------
  @SectionId('DAATT-DATA')
  @Form([
    Field(
      'dataType',
      String,
      'Data Type',
      hint:
          'Logical type: String | Integer | Decimal | Boolean | Date | DateTime | UUID | JSON | Binary',
    ),
    Field(
      'physicalType',
      String,
      'Physical Type',
      hint: 'Database type: VARCHAR(255), BIGINT, DECIMAL(10,2), TIMESTAMP',
    ),
    Field(
      'length',
      String,
      'Length/Size',
      hint: 'Maximum length for strings or size for binary',
    ),
    Field(
      'precision',
      String,
      'Precision',
      hint: 'Total digits for numeric types',
    ),
    Field('scale', String, 'Scale', hint: 'Decimal places for numeric types'),
    Field(
      'collation',
      String,
      'Collation',
      hint: 'Character collation for text (e.g., utf8_general_ci)',
    ),
    Field(
      'timezone',
      String,
      'Timezone',
      hint: 'For datetime: UTC | Local | WithOffset',
    ),
    Field(
      'format',
      String,
      'Format',
      hint: 'Display or storage format (e.g., YYYY-MM-DD, E.164 for phone)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dataTypeSpec;

  // ---------------------------------------------------------------------------
  // Constraints and Validation (8 fields)
  // ---------------------------------------------------------------------------
  @StandardReferences(
    ['SBVR — business rule statements', 'ISO/IEC 25012 — data quality'],
    'Validation constraints on this attribute, such as nullability, ranges, patterns, and default values.',
  )
  @SectionId('DATAA-CONS-LST')
  @SectionIdPattern('DATAA-CONS-xxx')
  @ContentHelp('Add one entry per attribute constraint.')
  @SerializationOrder(2)
  List<DataAttributeConstraintEntry> constraints = [];

  // ---------------------------------------------------------------------------
  // Computed and Derived (4 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(3)
  DocSpecsSection? derivation;

  // ---------------------------------------------------------------------------
  // Classification and Security (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(4)
  DocSpecsSection? securityClassification;

  // ---------------------------------------------------------------------------
  // Migration and Lineage (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(5)
  DocSpecsSection? migrationLineage;

  // ---------------------------------------------------------------------------
  // UI and Display (4 fields)
  // ---------------------------------------------------------------------------
  @StandardReferences(
    ['ISO/IEC 11179 — metadata registries / data element definitions'],
    'UI and display properties for this attribute, such as labels, formatting, ordering, and visibility.',
  )
  @SectionId('DISPL-DISP-LST')
  @SectionIdPattern('DISPL-DISP-xxx')
  @ContentHelp('Add one entry per display property.')
  @SerializationOrder(6)
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
      'keyName',
      String,
      'Key Name',
      required: true,
      hint: 'Identifier for this key constraint',
    ),
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
      'indexName',
      String,
      'Index Name',
      required: true,
      hint: 'Unique identifier for the index',
    ),
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
      'constraintName',
      String,
      'Constraint Name',
      required: true,
      hint: 'Unique identifier for the constraint',
    ),
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
      hint: 'Related business rule ID',
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
/// Comprehensive relationship specification following ER modeling best practices.
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
  // ---------------------------------------------------------------------------
  // Relationship Identity (5 fields)
  // ---------------------------------------------------------------------------
  @SectionId('ENRLE-IDEN')
  @Form([
    Field(
      'relationshipName',
      String,
      'Relationship Name',
      required: true,
      hint:
          'Verb phrase describing the relationship (e.g., "places", "contains")',
    ),
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
  @SerializationOrder(0)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Participating Entities (4 fields)
  // ---------------------------------------------------------------------------
  @StandardReferences([
    'ER modeling (Chen / Barker notation)',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ], 'The entities participating in this relationship, with their role names.')
  @SectionId('PARTI-PART-LST')
  @SectionIdPattern('PARTI-PART-xxx')
  @ContentHelp('Add one entry per participating entity.')
  @SerializationOrder(1)
  List<ParticipantEntry> participants = [];

  // ---------------------------------------------------------------------------
  // Cardinality and Participation (6 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(2)
  DocSpecsSection? cardinality;

  // ---------------------------------------------------------------------------
  // Referential Integrity (6 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(3)
  DocSpecsSection? referentialIntegrity;

  // ---------------------------------------------------------------------------
  // Navigation and Implementation (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(4)
  DocSpecsSection? navigation;

  // ---------------------------------------------------------------------------
  // Relationship Attributes (3 fields) — for relationships with properties
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(5)
  List<RelationshipAttributeEntry> relationshipAttributes = [];

  @SectionId('ENRLE-SOUR-REF')
  @Reference('sourceEntityName')
  @SerializationOrder(6)
  DocSpecsSection? sourceEntityRef;

  @SectionId('ENRLE-TARG-REF')
  @Reference('targetEntityName')
  @SerializationOrder(7)
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
class DataClassification extends DocSpecsSection {
  // ---------------------------------------------------------------------------
  // Classification Overview (4 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(0)
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
  @SerializationOrder(1)
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
class DataClassificationEntry extends DocSpecsSection {
  // ---------------------------------------------------------------------------
  // Classification Identity (5 fields)
  // ---------------------------------------------------------------------------
  @SectionId('DCLSE-IDEN')
  @Form([
    Field(
      'classificationName',
      String,
      'Classification Name',
      required: true,
      hint: 'Name of this classification level',
    ),
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
  @SerializationOrder(0)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Storage and Transmission (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(1)
  DocSpecsSection? storageTransmission;

  // ---------------------------------------------------------------------------
  // Access Control (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(2)
  DocSpecsSection? accessControl;

  // ---------------------------------------------------------------------------
  // Retention and Disposal (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(3)
  DocSpecsSection? retentionDisposal;

  // ---------------------------------------------------------------------------
  // Compliance (4 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(4)
  DocSpecsSection? compliance;

  /// Contains 0+× HandlingRequirement.
  @StandardReferences([
    'ISO/IEC 27001 / NIST — data classification',
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
  ], 'The handling procedures required for data at this classification level.')
  @SectionId('HNDRE-HAND-LST')
  @SectionIdPattern('HNDRE-HAND-xxx')
  @ContentHelp('Add one entry per handling requirement.')
  @SerializationOrder(5)
  List<HandlingRequirementEntry> handlingRequirements = [];

  /// Contains 0+× AccessRestriction.
  @StandardReferences([
    'ISO/IEC 27001 / NIST — data classification',
    'GDPR / HIPAA / SOX / PCI-DSS — compliance (PII/PHI)',
  ], 'The access restrictions that apply to data at this classification level.')
  @SectionId('ACRSE-ACCE-LST')
  @SectionIdPattern('ACRSE-ACCE-xxx')
  @ContentHelp('Add one entry per access restriction.')
  @SerializationOrder(6)
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
class HandlingRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'requirementId',
      String,
      'Requirement ID',
      hint: 'Unique identifier for this requirement',
    ),
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
class AccessRestrictionEntry extends DocSpecsSection {
  @Form([
    Field(
      'restrictionId',
      String,
      'Restriction ID',
      hint: 'Unique identifier for this restriction',
    ),
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
class BusinessObjectEntry extends DocSpecsSection {
  // ---------------------------------------------------------------------------
  // Core Identity (6 fields)
  // ---------------------------------------------------------------------------
  @SectionId('BJOEN-IDEN')
  @Form([
    Field(
      'objectName',
      String,
      'Object Name',
      required: true,
      hint: 'Business name in PascalCase (e.g., Order, Customer)',
    ),
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
  @SerializationOrder(0)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Domain Context (5 fields)
  // ---------------------------------------------------------------------------
  @SectionId('BJOEN-DOMA')
  @Form([
    Field(
      'boundedContext',
      String,
      'Bounded Context',
      hint: 'DDD bounded context this object belongs to',
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
  @SerializationOrder(1)
  DocSpecsSection? domainContext;

  // ---------------------------------------------------------------------------
  // Lifecycle Summary (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(2)
  DocSpecsSection? lifecycleSummary;

  // ---------------------------------------------------------------------------
  // Behavior and Rules (5 fields)
  // ---------------------------------------------------------------------------
  @StandardReferences([
    'SBVR — business rule statements',
    'Domain-Driven Design — aggregates/entities/value objects',
  ], 'The behavior rules that govern how this object acts.')
  @SectionId('BEHAV-BEHA-LST')
  @SectionIdPattern('BEHAV-BEHA-xxx')
  @ContentHelp('Add one entry per behavior rule.')
  @SerializationOrder(3)
  List<BehaviorRuleEntry> behaviorRules = [];

  // ---------------------------------------------------------------------------
  // Ownership and Versioning (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(4)
  DocSpecsSection? ownership;

  // ---------------------------------------------------------------------------
  // Integration Points (4 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(5)
  List<IntegrationPointEntry> integrationPoints = [];

  /// Contains 0+× BusinessObjectAttribute.
  @StandardReferences([
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'Domain-Driven Design — aggregates/entities/value objects',
  ], 'The business-level attributes that describe this object.')
  @SectionId('BIOBAT-ATTR-LST')
  @SectionIdPattern('BIOBAT-ATTR-xxx')
  @ContentHelp('Add one entry per business object attribute.')
  @SerializationOrder(6)
  List<BusinessObjectAttributeEntry> attributes = [];

  /// Contains 0+× ObjectState.
  @StandardReferences([
    'UML state machines — object lifecycle/state modeling',
  ], 'The key lifecycle states this object can occupy.')
  @SectionId('OBST-KEYS-LST')
  @SectionIdPattern('OBST-KEYS-xxx')
  @ContentHelp('Add one entry per object state.')
  @SerializationOrder(7)
  List<ObjectStateEntry> keyStates = [];

  /// Contains 0+× BusinessRuleReference.
  @StandardReferences([
    'SBVR — business rule statements',
  ], 'The business rules that govern this object.')
  @SectionId('BIRURE-KEYB-LST')
  @SectionIdPattern('BIRURE-KEYB-xxx')
  @ContentHelp('Add one entry per business rule reference.')
  @SerializationOrder(8)
  List<BusinessRuleReferenceEntry> keyBusinessRules = [];

  /// Contains 0+× LifecycleTransition.
  @StandardReferences([
    'UML state machines — object lifecycle/state modeling',
  ], 'The allowed state transitions in this object lifecycle.')
  @SectionId('LFTRS-LIFE-LST')
  @SectionIdPattern('LFTRS-LIFE-xxx')
  @ContentHelp('Add one entry per lifecycle transition.')
  @SerializationOrder(9)
  List<LifecycleTransitionEntry> lifecycleTransitions = [];

  /// Contains 0+× ObjectOperation.
  @StandardReferences([
    'Domain-Driven Design — aggregates/entities/value objects',
    'UML 2.5.1 (ISO/IEC 19505) — class/object modeling',
  ], 'The domain operations that can be performed on this object.')
  @SectionId('OBOP-OPER-LST')
  @SectionIdPattern('OBOP-OPER-xxx')
  @ContentHelp('Add one entry per object operation.')
  @SerializationOrder(10)
  List<ObjectOperationEntry> operations = [];

  /// Contains 0+× ObjectInvariant.
  @StandardReferences([
    'SBVR — business rule statements',
    'Domain-Driven Design — aggregates/entities/value objects',
  ], 'The invariants that must always hold true for this object.')
  @SectionId('OBINV-INVA-LST')
  @SectionIdPattern('OBINV-INVA-xxx')
  @ContentHelp('Add one entry per object invariant.')
  @SerializationOrder(11)
  List<ObjectInvariantEntry> invariants = [];
}

/// A business object attribute entry (form).
///
/// Business-level attribute specification focusing on business meaning and rules.
@StandardReferences(
  [
    'ISO/IEC 11179 — metadata registries / data element definitions',
    'Domain-Driven Design — aggregates/entities/value objects',
  ],
  'A single business-level attribute of an object, describing its meaning, type and rules.',
)
@SectionId('BIOBAT')
class BusinessObjectAttributeEntry extends DocSpecsSection {
  @Form([
    Field(
      'attributeName',
      String,
      'Attribute Name',
      required: true,
      hint: 'Business attribute name',
    ),
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
class ObjectStateEntry extends DocSpecsSection {
  @Form([
    Field(
      'stateName',
      String,
      'State Name',
      required: true,
      hint: 'Name of the state (e.g., Draft, Submitted)',
    ),
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
      String,
      'State Type',
      hint: 'Initial | Intermediate | Terminal | Error',
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
class BusinessRuleReferenceEntry extends DocSpecsSection {
  @Form([
    Field(
      'ruleId',
      String,
      'Rule ID',
      hint: 'Reference to the business rule definition',
    ),
    Field(
      'ruleName',
      String,
      'Rule Name',
      required: true,
      hint: 'Name of the business rule',
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
class LifecycleTransitionEntry extends DocSpecsSection {
  @Form([
    Field(
      'transitionId',
      String,
      'Transition ID',
      hint: 'Unique identifier for this transition',
    ),
    Field(
      'transitionName',
      String,
      'Transition Name',
      hint: 'Descriptive name (e.g., "Submit Order")',
    ),
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
class ObjectOperationEntry extends DocSpecsSection {
  @Form([
    Field(
      'operationName',
      String,
      'Operation Name',
      required: true,
      hint: 'Name of the operation (e.g., Submit, Approve)',
    ),
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
class ObjectInvariantEntry extends DocSpecsSection {
  @Form([
    Field(
      'invariantName',
      String,
      'Invariant Name',
      required: true,
      hint: 'Name of the invariant',
    ),
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
class FunctionModel extends DocSpecsSection {
  // ---------------------------------------------------------------------------
  // Function Decomposition Overview (4 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(0)
  DocSpecsSection? decompositionOverview;

  // ---------------------------------------------------------------------------
  // Function-to-Data Matrix Overview (4 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(1)
  DocSpecsSection? matrixOverview;

  /// 7.3.1. Function Decomposition — contains 0+× Function.
  @StandardReferences([
    'Structured Analysis (DeMarco/Yourdon) — functional decomposition',
    'IEEE 830 / ISO/IEC/IEEE 29148 — functional requirements',
  ], 'The business functions the system provides, decomposed hierarchically.')
  @SectionId('FUNCT-FUNC-LST')
  @SectionIdPattern('FUNCT-FUNC-xxx')
  @ContentHelp('Add one entry per function.')
  @SerializationOrder(2)
  List<FunctionEntry> functions = [];

  /// 7.3.2. Function-to-Data Matrix Entries — contains 0+× MatrixEntry.
  @StandardReferences(
    ['CRUD matrix — function/data interaction mapping'],
    'The rows of the CRUD matrix mapping each function to the data entities it accesses.',
  )
  @SectionId('FNDMX-MATR-LST')
  @SectionIdPattern('FNDMX-MATR-xxx')
  @ContentHelp('Add one entry per function/data matrix mapping.')
  @SerializationOrder(3)
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
  @SerializationOrder(4)
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
class FunctionEntry extends DocSpecsSection {
  @Form([
    Field(
      'functionId',
      String,
      'Function ID',
      hint: 'Unique function identifier',
    ),
    Field(
      'functionName',
      String,
      'Function Name',
      required: true,
      hint: 'Verb-noun phrase (e.g., Process Order)',
    ),
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
class SubFunctionEntry extends DocSpecsSection {
  @Form([
    Field(
      'subFunctionName',
      String,
      'Sub-Function Name',
      required: true,
      hint: 'Name of the sub-function',
    ),
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
class FunctionDataMatrixEntry extends DocSpecsSection {
  @Form([
    Field(
      'functionName',
      String,
      'Function Name',
      required: true,
      hint: 'Function being mapped',
    ),
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
class BusinessRuleEntry extends DocSpecsSection {
  // ---------------------------------------------------------------------------
  // Rule Identity (5 fields)
  // ---------------------------------------------------------------------------
  @SectionId('BIRU-IDEN')
  @Form([
    Field(
      'ruleId',
      String,
      'Rule ID',
      required: true,
      hint: 'Unique rule identifier (e.g., BR-001)',
    ),
    Field(
      'ruleName',
      String,
      'Rule Name',
      required: true,
      hint: 'Descriptive name',
    ),
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
  @SerializationOrder(0)
  DocSpecsSection? identity;

  // ---------------------------------------------------------------------------
  // Classification (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(1)
  DocSpecsSection? classification;

  // ---------------------------------------------------------------------------
  // Rule Logic (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(2)
  DocSpecsSection? ruleLogic;

  // ---------------------------------------------------------------------------
  // Implementation (5 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(3)
  DocSpecsSection? implementation;

  // ---------------------------------------------------------------------------
  // Exception Handling (4 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(4)
  DocSpecsSection? exceptionHandling;

  // ---------------------------------------------------------------------------
  // Governance (4 fields)
  // ---------------------------------------------------------------------------
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
  @SerializationOrder(5)
  DocSpecsSection? governance;

  /// Contains 0+× AffectedObject.
  @StandardReferences([
    'SBVR — business rule statements',
  ], 'The business objects this rule validates, constrains, or modifies.')
  @SectionId('AFOB-AFFE-LST')
  @SectionIdPattern('AFOB-AFFE-xxx')
  @ContentHelp('Add one entry per affected object.')
  @SerializationOrder(6)
  List<AffectedObjectEntry> affectedObjects = [];

  /// Contains 0+× AffectedFunction.
  @StandardReferences([
    'SBVR — business rule statements',
    'CRUD matrix — function/data interaction mapping',
  ], 'The functions where this rule is triggered and applied.')
  @SectionId('AFFN-AFFE-LST')
  @SectionIdPattern('AFFN-AFFE-xxx')
  @ContentHelp('Add one entry per affected function.')
  @SerializationOrder(7)
  List<AffectedFunctionEntry> affectedFunctions = [];

  /// Contains 0+× RuleExample.
  @StandardReferences([
    'SBVR — business rule statements',
  ], 'Worked examples that illustrate how this rule evaluates.')
  @SectionId('RULEXM-EXAM-LST')
  @SectionIdPattern('RULEXM-EXAM-xxx')
  @ContentHelp('Add one entry per rule example.')
  @SerializationOrder(8)
  List<RuleExampleEntry> examples = [];
}

/// An affected object reference entry (form).
///
/// Business objects affected by this rule.
@StandardReferences([
  'SBVR — business rule statements',
], 'A business object affected by a rule, and how it is impacted.')
@SectionId('AFOB')
class AffectedObjectEntry extends DocSpecsSection {
  @Form([
    Field(
      'objectName',
      String,
      'Object Name',
      required: true,
      hint: 'Name of the affected business object',
    ),
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
class AffectedFunctionEntry extends DocSpecsSection {
  @Form([
    Field(
      'functionName',
      String,
      'Function Name',
      required: true,
      hint: 'Name of the affected function',
    ),
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
class RuleExampleEntry extends DocSpecsSection {
  @Form([
    Field(
      'exampleName',
      String,
      'Example Name',
      required: true,
      hint: 'Name for this example',
    ),
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
@StandardReferences(
  ['UML 2.5.1 (ISO/IEC 19505) — class/object modeling'],
  'How a domain object connects to the outside world: the APIs that expose it, events it publishes or subscribes to, and external-system mappings.',
)
@SectionId('INTEG')
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
@CodeSpecKind([CodeSpecPart.validation],
    note: 'Attribute-level constraint → CE-VA field rule (required, range, '
        'pattern, type).')
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
    Field(
      'allowedValues',
      String,
      'Allowed Values',
      hint: 'Enumerated values if applicable',
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
      'displayLabel',
      String,
      'Display Label',
      hint: 'User-friendly label for UI',
    ),
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
/// model evolves — the ordered DDL / migration steps and the tooling and
/// policy that govern them. This is distinct from business-data migration
/// between systems (see `MigrationMappingEntry` for old→new field mapping):
/// here the subject is the schema's own evolution over releases.
@StandardReferences(
  [
    'DAMA-DMBOK2 — data management body of knowledge',
    'Evolutionary Database Design (Ambler & Sadalage) — database refactoring',
  ],
  'Captures the schema versioning strategy and the ordered migration steps derived from the data model’s evolution — the DDL history, not business-data migration between systems.',
)
@SectionId('SCHMG')
class SchemaVersioningAndMigration extends DocSpecsSection {
  @ContentHelp('''
Describe how the database schema is versioned and how migrations are authored,
ordered, and applied as the data model evolves across releases.

**Covers:**
- The migration tooling and where migration scripts live
- The versioning strategy (sequential, timestamped, semantic)
- Whether down/rollback migrations are supported (forward-only vs reversible)
- The baseline schema version and any zero-downtime approach (expand/contract)

This section is derived from the evolution of the entities in the Data Model
(7.1). It is NOT business-data migration between systems.
''')
  @Form([
    Field(
      'migrationTooling',
      String,
      'Migration Tooling',
      hint: 'Flyway, Liquibase, Prisma Migrate, Alembic, custom DDL scripts',
    ),
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
      hint: 'Whether migrations are forward-only (no down migrations)',
    ),
    Field(
      'baselineVersion',
      String,
      'Baseline Version',
      hint: 'The initial/baseline schema version migrations build on',
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

  /// 7.4.1. Schema Migration Steps — one entry per versioned migration.
  @StandardReferences([
    'Evolutionary Database Design (Ambler & Sadalage) — database refactoring',
  ], 'The ordered schema migration steps that evolve the database over releases.')
  @SectionId('SCMST-STEP-LST')
  @SectionIdPattern('SCMST-STEP-xxx')
  @ContentHelp('Add one entry per versioned schema migration step.')
  @SerializationOrder(1)
  List<SchemaMigrationStepEntry> migrationSteps = [];
}

/// A single schema migration step (form).
///
/// One versioned change to the database schema — the DDL operations it applies,
/// the entities it touches, whether it is reversible, and any data backfill it
/// performs as part of the schema change.
@StandardReferences(
  [
    'Evolutionary Database Design (Ambler & Sadalage) — database refactoring',
    'DAMA-DMBOK2 — data management body of knowledge',
  ],
  'A single versioned schema migration step: its DDL operations, affected entities, reversibility, and any accompanying data backfill.',
)
@SectionId('SCMST')
class SchemaMigrationStepEntry extends DocSpecsSection {
  @Form([
    Field(
      'version',
      String,
      'Version',
      hint: 'The schema version this step produces (e.g. V7, 2026-07-19-01)',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this migration changes and why',
    ),
    Field(
      'ddlOperations',
      String,
      'DDL Operations',
      hint: 'CREATE/ALTER/DROP performed (tables, columns, indexes, constraints)',
    ),
    Field(
      'affectedEntities',
      String,
      'Affected Entities',
      hint: 'The Data Model entities this step touches',
    ),
    Field(
      'dataBackfill',
      String,
      'Data Backfill',
      hint: 'Any data population/transformation done as part of the step, or None',
    ),
    Field(
      'reversible',
      bool,
      'Reversible',
      hint: 'Whether a down/rollback migration is provided',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
