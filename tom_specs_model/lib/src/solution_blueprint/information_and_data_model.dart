/// Section 7: Business Object and Data Model. Seeds → IFM.
///
/// Conceptual overview of the business data the system manages.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';



/// 7. Business Object and Data Model. Seeds → IFM.
@SectionId('BODM')
@Comment('Seeds → IFM')
@MapsTo(D03InformationModel)
class InformationAndDataModel {
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
  String? content;

  /// 7.1. Data Model.
  DataModel dataModel = DataModel();

  /// 7.2. Business Object Model.
  BusinessObjectModel businessObjectModel = BusinessObjectModel();

  /// 7.3. Function Model.
  FunctionModel functionModel = FunctionModel();
}

// ---------------------------------------------------------------------------
// 7.1 Data Model
// ---------------------------------------------------------------------------

/// 7.1. Data Model.
@SectionId('DATMD')
@MapsTo(D03InformationModel)
class DataModel {
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
  String? content;

  /// 7.1.1. Entity Overview — contains 1+× Data Entity.
  @SectionId('DAENT-ENTI-LST')
  @SectionIdPattern('DAENT-ENTI-xxx')
  @Min(1)
  List<DataEntityEntry> entities = [];

  /// 7.1.2. Entity Relationships.
  EntityRelationships entityRelationships = EntityRelationships();

  /// 7.1.3. Entity-Relationship Diagram (mermaid).
  ErDiagramSection erDiagram = ErDiagramSection();

  /// 7.1.4. Data Classification.
  DataClassification dataClassification = DataClassification();

  /// 7.1.5. Data Dictionary..
  DataDictionary dataDictionary = DataDictionary();

  /// 7.1.6. Validation Constraints.
  @SectionId('VACO-VALI-LST')
  @SectionIdPattern('VACO-VALI-xxx')
  List<ValidationConstraints> validationConstraints = [];

  /// 7.1.7. Integrity Constraints.
  @SectionId('INCO-INTE-LST')
  @SectionIdPattern('INCO-INTE-xxx')
  List<IntegrityConstraints> integrityConstraints = [];
}

/// A data entity entry (form).
///
/// Comprehensive entity specification following data modeling best practices.
/// Captures conceptual, logical, and physical design aspects.
@SectionId('DAENT')
class DataEntityEntry {
  // ---------------------------------------------------------------------------
  // Core Identity (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('entityName', String, 'Entity Name',
        required: true,
        hint: 'Singular noun or noun phrase (e.g., Customer, OrderItem)'),
    Field('tableName', String, 'Physical Table Name',
        hint: 'Database table name if different from logical name'),
    Field('entityAlias', String, 'Alias/Abbreviation',
        hint: 'Short alias for diagrams and references (e.g., CUST, ORD)'),
    Field('description', String, 'Description',
        hint: 'Clear definition of what this entity represents'),
    Field('entityStereoType', String, 'Stereotype',
        hint:
            'Entity pattern: AggregateRoot | Entity | ValueObject | Event | View | Bridge'),
  ])
  String? identity;

  // ---------------------------------------------------------------------------
  // Classification (6 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('category', String, 'Category',
        hint:
            'Data category: MasterData | TransactionData | ReferenceData | ConfigurationData | AuditData'),
    Field('boundedContext', String, 'Bounded Context',
        hint: 'Domain-driven design bounded context this entity belongs to'),
    Field('owningDomain', String, 'Owning Domain',
        hint: 'Business domain responsible for this entity'),
    Field('dataOwner', String, 'Data Owner',
        hint: 'Role or team accountable for data quality'),
    Field('dataSteward', String, 'Data Steward',
        hint: 'Person or role responsible for data governance'),
    Field('sourceSystem', String, 'Source System',
        hint: 'System of record or originating system for migration'),
  ])
  String? classification;

  // ---------------------------------------------------------------------------
  // Volume and Growth (6 fields)
  // ---------------------------------------------------------------------------
  @SectionId('VOLUM-VOLU-LST')
  @SectionIdPattern('VOLUM-VOLU-xxx')
  List<VolumeMetricEntry> volumeMetrics = [];

  // ---------------------------------------------------------------------------
  // Lifecycle and Retention (8 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('lifecyclePhases', String, 'Lifecycle Phases',
        hint: 'Phases: Active → Archived → Purged, or Active → Soft-deleted → Hard-deleted'),
    Field('retentionPolicy', String, 'Retention Policy',
        hint: 'How long data is retained and why (e.g., 7 years per tax regulations)'),
    Field('archivalTrigger', String, 'Archival Trigger',
        hint: 'Condition for moving to archive (e.g., 2 years after last activity)'),
    Field('archivalDestination', String, 'Archival Destination',
        hint: 'Where archived data goes: ColdStorage | Archive | DataLake'),
    Field('purgePolicy', String, 'Purge Policy',
        hint: 'When and how data is permanently deleted'),
    Field('anonymizationPolicy', String, 'Anonymization Policy',
        hint: 'PII anonymization rules (e.g., hash email after deletion)'),
    Field('auditRequirements', String, 'Audit Requirements',
        hint: 'What changes must be tracked: None | KeyFields | AllFields | FullHistory'),
    Field('auditRetention', String, 'Audit Retention',
        hint: 'How long audit records are kept'),
  ])
  String? lifecyclePolicy;

  // ---------------------------------------------------------------------------
  // Compliance and Security (6 fields)
  // ---------------------------------------------------------------------------
  @SectionId('COMPL1-COMP-LST')
  @SectionIdPattern('COMPL1-COMP-xxx')
  List<ComplianceRequirementEntry> complianceRequirements = [];

  // ---------------------------------------------------------------------------
  // Relationships Summary (4 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('parentEntities', String, 'Parent Entities',
        hint: 'Entities this depends on (e.g., Order depends on Customer)'),
    Field('childEntities', String, 'Child Entities',
        hint: 'Entities that depend on this (e.g., OrderItem depends on Order)'),
    Field('referencedEntities', String, 'Referenced Entities',
        hint: 'Lookup/reference entities used (e.g., OrderStatus, PaymentMethod)'),
    Field('crossDomainRelationships', String, 'Cross-Domain Relationships',
        hint: 'Relationships that cross bounded context boundaries'),
  ])
  String? relationshipSummary;

  // ---------------------------------------------------------------------------
  // Technical Characteristics (6 fields)
  // ---------------------------------------------------------------------------
  @SectionId('TECHN-TECH-LST')
  @SectionIdPattern('TECHN-TECH-xxx')
  List<TechnicalCharacteristicEntry> technicalCharacteristics = [];

  /// Contains 0+× DataAttribute.
  @SectionId('DAATT-ATTR-LST')
  @SectionIdPattern('DAATT-ATTR-xxx')
  List<DataAttributeEntry> attributes = [];

  /// Contains 0+× KeyAttribute.
  @SectionId('KEATT-KEYA-LST')
  @SectionIdPattern('KEATT-KEYA-xxx')
  List<KeyAttributeEntry> keyAttributes = [];

  /// Contains 0+× EntityIndex.
  @SectionId('ENIDX-INDE-LST')
  @SectionIdPattern('ENIDX-INDE-xxx')
  List<EntityIndexEntry> indexes = [];

  /// Contains 0+× EntityConstraint.
  @SectionId('ENCNS-CONS-LST')
  @SectionIdPattern('ENCNS-CONS-xxx')
  List<EntityConstraintEntry> constraints = [];

  /// Contains 0+× MigrationMapping for data migration planning.
  @SectionId('MIGME-MIGR-LST')
  @SectionIdPattern('MIGME-MIGR-xxx')
  List<MigrationMappingEntry> migrationMappings = [];
}

/// A data attribute entry (form).
///
/// Comprehensive attribute specification for data dictionary and schema design.
@SectionId('DAATT')
class DataAttributeEntry {
  // ---------------------------------------------------------------------------
  // Core Identity (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('attributeName', String, 'Attribute Name',
        required: true, hint: 'Logical attribute name in camelCase'),
    Field('columnName', String, 'Physical Column Name',
        hint: 'Database column name if different (e.g., snake_case)'),
    Field('description', String, 'Description',
        hint: 'Clear definition of what this attribute represents'),
    Field('businessTerm', String, 'Business Term',
        hint: 'Business glossary term this maps to'),
    Field('exampleValues', String, 'Example Values',
        hint: 'Comma-separated examples (e.g., "Draft, Confirmed, Shipped")'),
  ])
  String? identity;

  // ---------------------------------------------------------------------------
  // Data Type Specification (8 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('dataType', String, 'Data Type',
        hint: 'Logical type: String | Integer | Decimal | Boolean | Date | DateTime | UUID | JSON | Binary'),
    Field('physicalType', String, 'Physical Type',
        hint: 'Database type: VARCHAR(255), BIGINT, DECIMAL(10,2), TIMESTAMP'),
    Field('length', String, 'Length/Size',
        hint: 'Maximum length for strings or size for binary'),
    Field('precision', String, 'Precision',
        hint: 'Total digits for numeric types'),
    Field('scale', String, 'Scale',
        hint: 'Decimal places for numeric types'),
    Field('collation', String, 'Collation',
        hint: 'Character collation for text (e.g., utf8_general_ci)'),
    Field('timezone', String, 'Timezone',
        hint: 'For datetime: UTC | Local | WithOffset'),
    Field('format', String, 'Format',
        hint: 'Display or storage format (e.g., YYYY-MM-DD, E.164 for phone)'),
  ])
  String? dataTypeSpec;

  // ---------------------------------------------------------------------------
  // Constraints and Validation (8 fields)
  // ---------------------------------------------------------------------------
  @SectionId('DATAA-CONS-LST')
  @SectionIdPattern('DATAA-CONS-xxx')
  List<DataAttributeConstraintEntry> constraints = [];

  // ---------------------------------------------------------------------------
  // Computed and Derived (4 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('isComputed', String, 'Is Computed',
        hint: 'Whether value is computed: Yes | No'),
    Field('computeFormula', String, 'Compute Formula',
        hint: 'Formula or expression for computed fields'),
    Field('isDerived', String, 'Is Derived',
        hint: 'Whether derived from other attributes: Yes | No'),
    Field('derivationLogic', String, 'Derivation Logic',
        hint: 'How derived value is calculated'),
  ])
  String? derivation;

  // ---------------------------------------------------------------------------
  // Classification and Security (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('sensitivityLevel', String, 'Sensitivity Level',
        hint: 'Public | Internal | Confidential | Restricted | PII | PHI'),
    Field('isPii', String, 'Is PII',
        hint: 'Personally identifiable information: Yes | No'),
    Field('maskingRule', String, 'Masking Rule',
        hint: 'How to mask in logs/displays: None | Partial | Full | Hash'),
    Field('encryptionLevel', String, 'Encryption Level',
        hint: 'Field-level encryption: None | Encrypted | Tokenized'),
    Field('auditLevel', String, 'Audit Level',
        hint: 'Change tracking: None | ValueChanges | FullHistory'),
  ])
  String? securityClassification;

  // ---------------------------------------------------------------------------
  // Migration and Lineage (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('sourceSystem', String, 'Source System',
        hint: 'Originating system for data lineage'),
    Field('sourceAttribute', String, 'Source Attribute',
        hint: 'Source field name for migration mapping'),
    Field('transformationRule', String, 'Transformation Rule',
        hint: 'Transformation applied during migration/ETL'),
    Field('dataLineage', String, 'Data Lineage',
        hint: 'Upstream sources that feed this attribute'),
    Field('qualityRules', String, 'Quality Rules',
        hint: 'Data quality checks (e.g., completeness, accuracy)'),
  ])
  String? migrationLineage;

  // ---------------------------------------------------------------------------
  // UI and Display (4 fields)
  // ---------------------------------------------------------------------------
  @SectionId('DISPL-DISP-LST')
  @SectionIdPattern('DISPL-DISP-xxx')
  List<DisplayPropertyEntry> displayProperties = [];
}

/// A key attribute entry (form).
///
/// Specification for primary, foreign, alternate, and composite keys.
@SectionId('KEATT')
class KeyAttributeEntry {
  @Form([
    Field('keyName', String, 'Key Name',
        required: true, hint: 'Identifier for this key constraint'),
    Field('keyType', String, 'Key Type',
        hint: 'Primary | Foreign | Alternate | Composite | Natural | Surrogate'),
    Field('keyColumns', String, 'Key Column(s)',
        hint: 'Column(s) comprising the key, comma-separated for composite'),
    Field('description', String, 'Description',
        hint: 'Purpose and usage of this key'),
  ])
  String? content;

  /// Key generation settings.
  KeyAttributeEntryGeneration generation = KeyAttributeEntryGeneration();

  /// Foreign-key reference and cascade behavior.
  KeyAttributeEntryReference reference = KeyAttributeEntryReference();

  /// Constraint semantics and business meaning.
  KeyAttributeEntryGovernance governance = KeyAttributeEntryGovernance();

  @Reference('referencedEntity')
  String? referencedEntityRef;
}

/// Key generation settings.
@SectionId('KEAGN')
class KeyAttributeEntryGeneration {
  @Form([
    Field('generationStrategy', String, 'Generation Strategy',
        hint: 'Auto | Sequence | UUID | ULID | Custom | Natural'),
    Field('sequenceName', String, 'Sequence Name',
        hint: 'Database sequence name if applicable'),
    Field('isNaturalKey', String, 'Is Natural Key',
        hint: 'Whether key has business meaning: Yes | No'),
  ])
  String? content;
}

/// Foreign-key reference and cascade behavior.
@SectionId('KEARF')
class KeyAttributeEntryReference {
  @Form([
    Field('referencedEntity', String, 'Referenced Entity',
        hint: 'For foreign keys: target entity name'),
    Field('referencedKey', String, 'Referenced Key',
        hint: 'For foreign keys: target key/column name'),
    Field('onDeleteAction', String, 'On Delete Action',
        hint: 'Cascade | SetNull | Restrict | NoAction | SetDefault'),
    Field('onUpdateAction', String, 'On Update Action',
        hint: 'Cascade | SetNull | Restrict | NoAction | SetDefault'),
  ])
  String? content;
}

/// Constraint semantics and business meaning.
@SectionId('KEAGV')
class KeyAttributeEntryGovernance {
  @Form([
    Field('deferrable', String, 'Deferrable',
        hint: 'Whether constraint check can be deferred: Yes | No'),
  ])
  String? content;
}

/// An entity index entry (form).
///
/// Database index specification for query optimization.
@SectionId('ENIDX')
class EntityIndexEntry {
  @Form([
    Field('indexName', String, 'Index Name',
        required: true, hint: 'Unique identifier for the index'),
    Field('indexType', String, 'Index Type',
        hint: 'BTree | Hash | GiST | GIN | FullText | Spatial'),
    Field('columns', String, 'Column(s)',
        hint: 'Indexed columns in order, with direction (e.g., "created_at DESC")'),
    Field('includeColumns', String, 'Include Columns',
        hint: 'Non-key columns to include (covering index)'),
    Field('isUnique', String, 'Is Unique',
        hint: 'Whether index enforces uniqueness: Yes | No'),
    Field('isClustered', String, 'Is Clustered',
        hint: 'Whether index determines physical row order: Yes | No'),
    Field('filterCondition', String, 'Filter Condition',
        hint: 'Partial index WHERE clause'),
    Field('purpose', String, 'Purpose',
        hint: 'Query patterns this index optimizes'),
    Field('estimatedSize', String, 'Estimated Size',
        hint: 'Expected index size'),
  ])
  String? content;
}

/// An entity constraint entry (form).
///
/// Business and technical constraints beyond keys.
@SectionId('ENCNS')
class EntityConstraintEntry {
  @Form([
    Field('constraintName', String, 'Constraint Name',
        required: true, hint: 'Unique identifier for the constraint'),
    Field('constraintType', String, 'Constraint Type',
        hint: 'Check | Unique | Exclusion | Custom'),
    Field('expression', String, 'Expression',
        hint: 'Constraint expression or rule'),
    Field('errorMessage', String, 'Error Message',
        hint: 'User-friendly message when constraint violated'),
    Field('enforcementLevel', String, 'Enforcement Level',
        hint: 'Database | Application | Both'),
    Field('isDeferred', String, 'Is Deferred',
        hint: 'Whether check can be deferred to transaction end: Yes | No'),
    Field('businessRule', String, 'Business Rule Reference',
        hint: 'Related business rule ID'),
  ])
  String? content;
}

/// A migration mapping entry (form).
///
/// Maps source system data to target entity for data migration planning.
@SectionId('MIGME')
class MigrationMappingEntry {
  @Form([
    Field('sourceSystem', String, 'Source System',
        required: true, hint: 'Name of the source system'),
    Field('sourceTable', String, 'Source Table',
        hint: 'Source table or file name'),
    Field('sourceField', String, 'Source Field',
        hint: 'Source column or field name'),
    Field('targetAttribute', String, 'Target Attribute',
        hint: 'Target attribute name in this entity'),
    Field('transformationType', String, 'Transformation Type',
        hint: 'Direct | Lookup | Computed | Merged | Split | Default'),
    Field('transformationLogic', String, 'Transformation Logic',
        hint: 'Detailed transformation rules'),
    Field('defaultOnMissing', String, 'Default On Missing',
        hint: 'Value to use when source is null or missing'),
    Field('validationRule', String, 'Validation Rule',
        hint: 'Post-migration validation'),
    Field('migrationPriority', String, 'Migration Priority',
        hint: 'Required | Important | Optional'),
    Field('notes', String, 'Notes',
        hint: 'Additional migration considerations'),
  ])
  String? content;
}

/// 7.1.2. Entity Relationships.
@SectionId('ENREL')
@DetailedIn(D03InformationModel)
@SecondLevelSectionId(D03InformationModel, 'BDM-REL')
class EntityRelationships {
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
  String? content;

  /// Contains 0+× EntityRelationship.
  @SectionId('ENRLE-ITEM-LST')
  @SectionIdPattern('ENRLE-ITEM-xxx')
  List<EntityRelationshipEntry> items = [];
}

/// An entity relationship entry (form).
///
/// Comprehensive relationship specification following ER modeling best practices.
@SectionId('ENRLE')
class EntityRelationshipEntry {
  // ---------------------------------------------------------------------------
  // Relationship Identity (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('relationshipName', String, 'Relationship Name',
        required: true, hint: 'Verb phrase describing the relationship (e.g., "places", "contains")'),
    Field('relationshipType', String, 'Relationship Type',
        hint: 'Association | Aggregation | Composition | Generalization | Dependency'),
    Field('description', String, 'Description',
        hint: 'Business meaning of this relationship'),
    Field('businessJustification', String, 'Business Justification',
        hint: 'Why this relationship exists from business perspective'),
    Field('implementationType', String, 'Implementation Type',
        hint: 'ForeignKey | JunctionTable | Embedded | Reference'),
  ])
  String? identity;

  // ---------------------------------------------------------------------------
  // Participating Entities (4 fields)
  // ---------------------------------------------------------------------------
  @SectionId('PARTI-PART-LST')
  @SectionIdPattern('PARTI-PART-xxx')
  List<ParticipantEntry> participants = [];

  // ---------------------------------------------------------------------------
  // Cardinality and Participation (6 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('sourceCardinality', String, 'Source Cardinality',
        hint: 'Source side: 1 | 0..1 | 0..* | 1..* | n..m'),
    Field('targetCardinality', String, 'Target Cardinality',
        hint: 'Target side: 1 | 0..1 | 0..* | 1..* | n..m'),
    Field('sourceParticipation', String, 'Source Participation',
        hint: 'Mandatory | Optional (whether source must participate)'),
    Field('targetParticipation', String, 'Target Participation',
        hint: 'Mandatory | Optional (whether target must participate)'),
    Field('minSourceInstances', String, 'Min Source Instances',
        hint: 'Minimum number of source entity instances'),
    Field('maxTargetInstances', String, 'Max Target Instances',
        hint: 'Maximum number of related target instances'),
  ])
  String? cardinality;

  // ---------------------------------------------------------------------------
  // Referential Integrity (6 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('onDeleteAction', String, 'On Delete Action',
        hint: 'Cascade | SetNull | Restrict | NoAction | SetDefault | Archive'),
    Field('onUpdateAction', String, 'On Update Action',
        hint: 'Cascade | SetNull | Restrict | NoAction'),
    Field('enforcementLevel', String, 'Enforcement Level',
        hint: 'Database | Application | Both | None'),
    Field('isDeferrable', String, 'Is Deferrable',
        hint: 'Whether constraint check can be deferred: Yes | No'),
    Field('cascadeScope', String, 'Cascade Scope',
        hint: 'For cascading: DirectOnly | AllDescendants | Custom'),
    Field('orphanHandling', String, 'Orphan Handling',
        hint: 'How orphaned records are handled: Prevent | Allow | AssignDefault'),
  ])
  String? referentialIntegrity;

  // ---------------------------------------------------------------------------
  // Navigation and Implementation (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('navigability', String, 'Navigability',
        hint: 'Bidirectional | SourceToTarget | TargetToSource'),
    Field('loadingStrategy', String, 'Loading Strategy',
        hint: 'Eager | Lazy | Explicit | None'),
    Field('foreignKeyLocation', String, 'Foreign Key Location',
        hint: 'Where FK resides: Source | Target | JunctionTable'),
    Field('junctionTableName', String, 'Junction Table Name',
        hint: 'For many-to-many: name of the junction/bridge table'),
    Field('inverseRelationship', String, 'Inverse Relationship',
        hint: 'Name of the relationship from the other side'),
  ])
  String? navigation;

  // ---------------------------------------------------------------------------
  // Relationship Attributes (3 fields) — for relationships with properties
  // ---------------------------------------------------------------------------
  @SectionId('RELAT-RELA-LST')
  @SectionIdPattern('RELAT-RELA-xxx')
  List<RelationshipAttributeEntry> relationshipAttributes = [];

  @Reference('sourceEntityName')
  String? sourceEntityRef;

  @Reference('targetEntityName')
  String? targetEntityRef;
}

/// 7.1.4. Data Classification.
@SectionId('DATCL')
@DetailedIn(D03InformationModel)
@SecondLevelSectionId(D03InformationModel, 'BDM-CLA')
class DataClassification {
  // ---------------------------------------------------------------------------
  // Classification Overview (4 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('classificationFramework', String, 'Classification Framework',
        hint: 'Standard used: Custom | ISO27001 | NIST | IndustrySpecific'),
    Field('defaultClassification', String, 'Default Classification',
        hint: 'Default sensitivity for unclassified data'),
    Field('classificationOwner', String, 'Classification Owner',
        hint: 'Role responsible for data classification decisions'),
    Field('reviewFrequency', String, 'Review Frequency',
        hint: 'How often classifications are reviewed: Annually | Quarterly | OnChange'),
  ])
  String? overview;

  /// Contains 0+× DataClassificationEntry.
  @SectionId('DCLSE-ITEM-LST')
  @SectionIdPattern('DCLSE-ITEM-xxx')
  List<DataClassificationEntry> items = [];
}

/// A data classification entry (form).
///
/// Comprehensive data classification for security and compliance.
@SectionId('DCLSE')
class DataClassificationEntry {
  // ---------------------------------------------------------------------------
  // Classification Identity (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('classificationName', String, 'Classification Name',
        required: true, hint: 'Name of this classification level'),
    Field('classificationLevel', String, 'Classification Level',
        hint: 'Sensitivity: Public | Internal | Confidential | Restricted | TopSecret'),
    Field('description', String, 'Description',
        hint: 'What this classification means'),
    Field('dataCategories', String, 'Data Categories',
        hint: 'Types of data in this class: PII | PHI | Financial | Legal | Technical'),
    Field('examples', String, 'Examples',
        hint: 'Examples of data at this classification'),
  ])
  String? identity;

  // ---------------------------------------------------------------------------
  // Storage and Transmission (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('encryptionAtRest', String, 'Encryption At Rest',
        hint: 'Encryption requirement for storage: None | Standard | Strong | FieldLevel'),
    Field('encryptionInTransit', String, 'Encryption In Transit',
        hint: 'Encryption for transmission: TLS | mTLS | EndToEnd'),
    Field('storageLocations', String, 'Allowed Storage Locations',
        hint: 'Where data can be stored: OnPremise | Cloud | Either | Restricted'),
    Field('geographicRestrictions', String, 'Geographic Restrictions',
        hint: 'Data residency requirements (e.g., EU only)'),
    Field('backupRequirements', String, 'Backup Requirements',
        hint: 'Special backup considerations'),
  ])
  String? storageTransmission;

  // ---------------------------------------------------------------------------
  // Access Control (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('accessLevels', String, 'Access Levels',
        hint: 'Who can access: AllEmployees | RoleRestricted | NeedToKnow | SystemOnly'),
    Field('authenticationRequirements', String, 'Authentication Requirements',
        hint: 'Required auth: Basic | MFA | CertificateBased | Biometric'),
    Field('authorizationModel', String, 'Authorization Model',
        hint: 'RBAC | ABAC | MAC | DAC'),
    Field('auditRequirements', String, 'Audit Requirements',
        hint: 'Access audit: None | ReadAudit | WriteAudit | FullAudit'),
    Field('accessRequestProcess', String, 'Access Request Process',
        hint: 'How access is granted: SelfService | ManagerApproval | SecurityApproval'),
  ])
  String? accessControl;

  // ---------------------------------------------------------------------------
  // Retention and Disposal (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('retentionPeriod', String, 'Retention Period',
        hint: 'How long data is retained (e.g., 7 years)'),
    Field('retentionBasis', String, 'Retention Basis',
        hint: 'Legal | Regulatory | Business | CustomerContract'),
    Field('archivalPolicy', String, 'Archival Policy',
        hint: 'When and how to archive: AfterPeriod | OnInactivity | Never'),
    Field('disposalMethod', String, 'Disposal Method',
        hint: 'How data is disposed: Delete | Anonymize | Shred | CryptoErase'),
    Field('disposalApproval', String, 'Disposal Approval',
        hint: 'Who approves disposal: Automatic | DataOwner | Legal'),
  ])
  String? retentionDisposal;

  // ---------------------------------------------------------------------------
  // Compliance (4 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('applicableRegulations', String, 'Applicable Regulations',
        hint: 'Regulations: GDPR | HIPAA | SOX | PCI-DSS | CCPA | FERPA'),
    Field('complianceRequirements', String, 'Compliance Requirements',
        hint: 'Specific compliance requirements'),
    Field('breachNotificationSla', String, 'Breach Notification SLA',
        hint: 'Time to notify on breach (e.g., 72 hours for GDPR)'),
    Field('dataSubjectRights', String, 'Data Subject Rights',
        hint: 'Applicable rights: Access | Rectification | Erasure | Portability'),
  ])
  String? compliance;

  /// Contains 0+× HandlingRequirement.
  @SectionId('HNDRE-HAND-LST')
  @SectionIdPattern('HNDRE-HAND-xxx')
  List<HandlingRequirementEntry> handlingRequirements = [];

  /// Contains 0+× AccessRestriction.
  @SectionId('ACRSE-ACCE-LST')
  @SectionIdPattern('ACRSE-ACCE-xxx')
  List<AccessRestrictionEntry> accessRestrictions = [];
}

/// A data handling requirement entry (form).
///
/// Specific handling procedures for classified data.
@SectionId('HNDRE')
class HandlingRequirementEntry {
  @Form([
    Field('requirementId', String, 'Requirement ID',
        hint: 'Unique identifier for this requirement'),
    Field('requirementType', String, 'Requirement Type',
        hint: 'Processing | Storage | Transmission | Display | Disposal'),
    Field('requirement', String, 'Requirement',
        required: true, hint: 'The specific handling requirement'),
    Field('rationale', String, 'Rationale',
        hint: 'Why this requirement exists'),
    Field('enforcementMechanism', String, 'Enforcement Mechanism',
        hint: 'How this is enforced: Technical | Procedural | Both'),
    Field('validationMethod', String, 'Validation Method',
        hint: 'How compliance is verified'),
    Field('exceptionProcess', String, 'Exception Process',
        hint: 'How exceptions are handled'),
  ])
  String? content;
}

/// An access restriction entry (form).
///
/// Specific access restrictions for classified data.
@SectionId('ACRSE')
class AccessRestrictionEntry {
  @Form([
    Field('restrictionId', String, 'Restriction ID',
        hint: 'Unique identifier for this restriction'),
    Field('restrictionType', String, 'Restriction Type',
        hint: 'Role | Geographic | Temporal | Contextual | DataBased'),
    Field('restriction', String, 'Restriction',
        required: true, hint: 'The specific access restriction'),
    Field('scope', String, 'Scope',
        hint: 'What the restriction applies to'),
    Field('enforcement', String, 'Enforcement',
        hint: 'How restriction is enforced: Policy | Technical | IAM'),
    Field('effectiveConditions', String, 'Effective Conditions',
        hint: 'When restriction applies (e.g., during business hours)'),
    Field('overridePolicy', String, 'Override Policy',
        hint: 'How overrides are handled: None | BreakGlass | ApprovalRequired'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 7.2 Business Object Model
// ---------------------------------------------------------------------------

/// 7.2. Business Object Model.
@SectionId('BJOMD')
@MapsTo(D03InformationModel)
class BusinessObjectModel {
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
  String? content;

  /// 7.2.1. Object Catalog — contains 1+× Business Object.
  @SectionId('BJOEN-OBJE-LST')
  @SectionIdPattern('BJOEN-OBJE-xxx')
  @Min(1)
  List<BusinessObjectEntry> objects = [];

  /// 7.2.2. Business Object Diagram (mermaid).
  DiagramSection objectDiagram = DiagramSection();
}

/// A business object entry (form).
///
/// Comprehensive business object specification following domain-driven design
/// patterns. Business objects represent key domain concepts with behavior,
/// state, and business rules.
@SectionId('BJOEN')
class BusinessObjectEntry {
  // ---------------------------------------------------------------------------
  // Core Identity (6 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('objectName', String, 'Object Name',
        required: true, hint: 'Business name in PascalCase (e.g., Order, Customer)'),
    Field('objectAlias', String, 'Alias/Abbreviation',
        hint: 'Short alias for diagrams (e.g., ORD, CUST)'),
    Field('description', String, 'Description',
        hint: 'Clear business definition of what this object represents'),
    Field('businessGlossaryTerm', String, 'Business Glossary Term',
        hint: 'Official business glossary term if different'),
    Field('category', String, 'Category',
        hint: 'Transaction | MasterData | ReferenceData | Aggregate | ValueObject | Event'),
    Field('stereotypePattern', String, 'Stereotype/Pattern',
        hint: 'DDD pattern: AggregateRoot | Entity | ValueObject | DomainEvent | Saga'),
  ])
  String? identity;

  // ---------------------------------------------------------------------------
  // Domain Context (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('boundedContext', String, 'Bounded Context',
        hint: 'DDD bounded context this object belongs to'),
    Field('owningDomain', String, 'Owning Domain',
        hint: 'Business domain responsible for this object'),
    Field('domainExpert', String, 'Domain Expert',
        hint: 'Business expert who defines this object'),
    Field('ubiquitousLanguageTerm', String, 'Ubiquitous Language Term',
        hint: 'How this is referred to in the ubiquitous language'),
    Field('relatedObjects', String, 'Related Objects',
        hint: 'Key related business objects'),
  ])
  String? domainContext;

  // ---------------------------------------------------------------------------
  // Lifecycle Summary (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('keyStates', String, 'Key States',
        hint: 'Primary lifecycle states (e.g., Draft → Submitted → Confirmed → Closed)'),
    Field('initialState', String, 'Initial State',
        hint: 'State when object is created'),
    Field('terminalStates', String, 'Terminal States',
        hint: 'States where lifecycle ends (e.g., Closed, Cancelled, Deleted)'),
    Field('stateTransitionRules', String, 'State Transition Rules',
        hint: 'Summary of allowed state transitions'),
    Field('lifecycleOwner', String, 'Lifecycle Owner',
        hint: 'System or process responsible for lifecycle management'),
  ])
  String? lifecycleSummary;

  // ---------------------------------------------------------------------------
  // Behavior and Rules (5 fields)
  // ---------------------------------------------------------------------------
  @SectionId('BEHAV-BEHA-LST')
  @SectionIdPattern('BEHAV-BEHA-xxx')
  List<BehaviorRuleEntry> behaviorRules = [];

  // ---------------------------------------------------------------------------
  // Ownership and Versioning (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('dataOwner', String, 'Data Owner',
        hint: 'Business role accountable for this object'),
    Field('dataSteward', String, 'Data Steward',
        hint: 'Role responsible for data quality'),
    Field('versioningStrategy', String, 'Versioning Strategy',
        hint: 'None | Sequential | Timestamp | Optimistic | EventSourced'),
    Field('concurrencyControl', String, 'Concurrency Control',
        hint: 'Optimistic | Pessimistic | None'),
    Field('auditTrail', String, 'Audit Trail',
        hint: 'What changes are tracked: None | StateChanges | AllChanges | FullHistory'),
  ])
  String? ownership;

  // ---------------------------------------------------------------------------
  // Integration Points (4 fields)
  // ---------------------------------------------------------------------------
  @SectionId('INTEG-INTE-LST')
  @SectionIdPattern('INTEG-INTE-xxx')
  List<IntegrationPointEntry> integrationPoints = [];

  /// Contains 0+× BusinessObjectAttribute.
  @SectionId('BIOBAT-ATTR-LST')
  @SectionIdPattern('BIOBAT-ATTR-xxx')
  List<BusinessObjectAttributeEntry> attributes = [];

  /// Contains 0+× ObjectState.
  @SectionId('OBST-KEYS-LST')
  @SectionIdPattern('OBST-KEYS-xxx')
  List<ObjectStateEntry> keyStates = [];

  /// Contains 0+× BusinessRuleReference.
  @SectionId('BIRURE-KEYB-LST')
  @SectionIdPattern('BIRURE-KEYB-xxx')
  List<BusinessRuleReferenceEntry> keyBusinessRules = [];

  /// Contains 0+× LifecycleTransition.
  @SectionId('LFTRS-LIFE-LST')
  @SectionIdPattern('LFTRS-LIFE-xxx')
  List<LifecycleTransitionEntry> lifecycleTransitions = [];

  /// Contains 0+× ObjectOperation.
  @SectionId('OBOP-OPER-LST')
  @SectionIdPattern('OBOP-OPER-xxx')
  List<ObjectOperationEntry> operations = [];

  /// Contains 0+× ObjectInvariant.
  @SectionId('OBINV-INVA-LST')
  @SectionIdPattern('OBINV-INVA-xxx')
  List<ObjectInvariantEntry> invariants = [];
}

/// A business object attribute entry (form).
///
/// Business-level attribute specification focusing on business meaning and rules.
@SectionId('BIOBAT')
class BusinessObjectAttributeEntry {
  @Form([
    Field('attributeName', String, 'Attribute Name',
        required: true, hint: 'Business attribute name'),
    Field('description', String, 'Description',
        hint: 'Business meaning of this attribute'),
    Field('type', String, 'Type',
        hint: 'Business type: Text | Number | Money | Date | DateTime | Boolean | Enum | Reference'),
  ])
  String? content;

  /// Format and requirement details.
  BusinessObjectAttributeEntryDefinition definition =
      BusinessObjectAttributeEntryDefinition();

  /// Validation and derivation rules.
  BusinessObjectAttributeEntryValidation validation =
      BusinessObjectAttributeEntryValidation();

  /// Sensitivity and presentation guidance.
  BusinessObjectAttributeEntryGovernance governance =
      BusinessObjectAttributeEntryGovernance();
}

/// Format and requirement details for a business object attribute.
@SectionId('BOAED')
class BusinessObjectAttributeEntryDefinition {
  @Form([
    Field('format', String, 'Format',
        hint: 'Business format (e.g., currency, percentage, phone)'),
    Field('mandatory', String, 'Mandatory',
        hint: 'Required | Optional | ConditionallyRequired'),
    Field('defaultValue', String, 'Default Value',
        hint: 'Default value or derivation'),
  ])
  String? content;
}

/// Validation and derivation rules for a business object attribute.
@SectionId('BOAEV')
class BusinessObjectAttributeEntryValidation {
  @Form([
    Field('validationRules', String, 'Validation Rules',
        hint: 'Business validation rules'),
    Field('allowedValues', String, 'Allowed Values',
        hint: 'Enumerated values or range'),
    Field('businessRules', String, 'Business Rules',
        hint: 'Rules affecting this attribute'),
    Field('derivation', String, 'Derivation',
        hint: 'How value is derived if calculated'),
  ])
  String? content;
}

/// Sensitivity and presentation guidance for a business object attribute.
@SectionId('BOAEG')
class BusinessObjectAttributeEntryGovernance {
  @Form([
    Field('sensitivityLevel', String, 'Sensitivity Level',
        hint: 'Public | Internal | Confidential | PII | PHI'),
    Field('displayOrder', String, 'Display Order',
        hint: 'Order for UI presentation'),
  ])
  String? content;
}

/// An object state entry (form).
///
/// Detailed state specification for business object lifecycle.
@SectionId('OBST')
class ObjectStateEntry {
  @Form([
    Field('stateName', String, 'State Name',
        required: true, hint: 'Name of the state (e.g., Draft, Submitted)'),
    Field('stateCode', String, 'State Code',
        hint: 'Technical state code or enum value'),
    Field('description', String, 'Description',
        hint: 'What this state means in business terms'),
    Field('stateType', String, 'State Type',
        hint: 'Initial | Intermediate | Terminal | Error'),
    Field('entryConditions', String, 'Entry Conditions',
        hint: 'Conditions required to enter this state'),
    Field('exitConditions', String, 'Exit Conditions',
        hint: 'Conditions required to exit this state'),
    Field('allowedOperations', String, 'Allowed Operations',
        hint: 'What operations can be performed in this state'),
    Field('restrictedOperations', String, 'Restricted Operations',
        hint: 'What operations are not allowed in this state'),
    Field('slaRequirements', String, 'SLA Requirements',
        hint: 'Any time-bound requirements for this state'),
    Field('notificationTriggers', String, 'Notification Triggers',
        hint: 'Events that trigger notifications in this state'),
  ])
  String? content;
}

/// A business rule reference entry (form).
///
/// Reference to business rules that govern this object.
@SectionId('BIRURE')
class BusinessRuleReferenceEntry {
  @Form([
    Field('ruleId', String, 'Rule ID',
        hint: 'Reference to the business rule definition'),
    Field('ruleName', String, 'Rule Name',
        required: true, hint: 'Name of the business rule'),
    Field('ruleType', String, 'Rule Type',
        hint: 'Validation | Calculation | Constraint | Authorization | Workflow'),
    Field('description', String, 'Description',
        hint: 'Brief description of the rule'),
    Field('enforcement', String, 'Enforcement',
        hint: 'Automated | Manual | Hybrid'),
    Field('triggerCondition', String, 'Trigger Condition',
        hint: 'When this rule is evaluated'),
    Field('affectedAttributes', String, 'Affected Attributes',
        hint: 'Attributes involved in this rule'),
    Field('consequenceOnViolation', String, 'Consequence On Violation',
        hint: 'What happens when rule is violated'),
  ])
  String? content;

  @Reference('ruleId')
  String? ruleRef;
}

/// A lifecycle transition entry (form).
///
/// Detailed state transition specification.
@SectionId('LFTRS')
class LifecycleTransitionEntry {
  @Form([
    Field('transitionId', String, 'Transition ID',
        hint: 'Unique identifier for this transition'),
    Field('transitionName', String, 'Transition Name',
        hint: 'Descriptive name (e.g., "Submit Order")'),
    Field('fromState', String, 'From State',
        required: true, hint: 'Source state'),
    Field('toState', String, 'To State',
        required: true, hint: 'Target state'),
  ])
  String? content;

  /// Triggering event details.
  LifecycleTransitionEntryTrigger trigger = LifecycleTransitionEntryTrigger();

  /// Transition conditions and guarantees.
  LifecycleTransitionEntryConditions conditions =
      LifecycleTransitionEntryConditions();

  /// Actions, actors, and rollback handling.
  LifecycleTransitionEntryExecution execution =
      LifecycleTransitionEntryExecution();
}

/// Triggering event details.
@SectionId('LTET')
class LifecycleTransitionEntryTrigger {
  @Form([
    Field('trigger', String, 'Trigger',
        hint: 'What initiates this transition'),
    Field('triggerType', String, 'Trigger Type',
        hint: 'UserAction | SystemEvent | Timer | ExternalEvent'),
  ])
  String? content;
}

/// Transition conditions and guarantees.
@SectionId('LTEC')
class LifecycleTransitionEntryConditions {
  @Form([
    Field('guardConditions', String, 'Guard Conditions',
        hint: 'Conditions that must be true for transition'),
    Field('preConditions', String, 'Pre-Conditions',
        hint: 'What must be true before transition'),
    Field('postConditions', String, 'Post-Conditions',
        hint: 'What is guaranteed after transition'),
  ])
  String? content;
}

/// Actions, actors, and rollback handling.
@SectionId('LTEE')
class LifecycleTransitionEntryExecution {
  @Form([
    Field('actions', String, 'Actions',
        hint: 'Actions performed during transition'),
    Field('sideEffects', String, 'Side Effects',
        hint: 'Events published, notifications sent'),
    Field('allowedActors', String, 'Allowed Actors',
        hint: 'Who can trigger this transition'),
    Field('rollbackStrategy', String, 'Rollback Strategy',
        hint: 'How to handle transition failure'),
  ])
  String? content;
}

/// An object operation entry (form).
///
/// Business operations that can be performed on the object.
@SectionId('OBOP')
class ObjectOperationEntry {
  @Form([
    Field('operationName', String, 'Operation Name',
        required: true, hint: 'Name of the operation (e.g., Submit, Approve)'),
    Field('description', String, 'Description',
        hint: 'What this operation does'),
    Field('operationType', String, 'Operation Type',
        hint: 'Command | Query | Event'),
  ])
  String? content;

  /// Execution contract for this operation.
  ObjectOperationEntryExecution execution = ObjectOperationEntryExecution();

  /// State and event lifecycle details.
  ObjectOperationEntryLifecycle lifecycle = ObjectOperationEntryLifecycle();

  /// Authorization and usage boundaries.
  ObjectOperationEntryGovernance governance =
      ObjectOperationEntryGovernance();
}

/// Execution contract for an object operation.
@SectionId('OOEE')
class ObjectOperationEntryExecution {
  @Form([
    Field('preconditions', String, 'Preconditions',
        hint: 'What must be true before operation'),
    Field('postconditions', String, 'Postconditions',
        hint: 'What is guaranteed after operation'),
    Field('inputParameters', String, 'Input Parameters',
        hint: 'Required inputs for this operation'),
    Field('outputResult', String, 'Output Result',
        hint: 'What the operation returns'),
  ])
  String? content;
}

/// State and event lifecycle details for an object operation.
@SectionId('OOEL')
class ObjectOperationEntryLifecycle {
  @Form([
    Field('businessRulesApplied', String, 'Business Rules Applied',
        hint: 'Rules evaluated during operation'),
    Field('stateTransitions', String, 'State Transitions',
        hint: 'Possible state changes'),
    Field('eventsPublished', String, 'Events Published',
        hint: 'Domain events triggered'),
  ])
  String? content;
}

/// Authorization and usage boundaries for an object operation.
@SectionId('OOEG')
class ObjectOperationEntryGovernance {
  @Form([
    Field('allowedInStates', String, 'Allowed In States',
        hint: 'States where operation is permitted'),
    Field('authorization', String, 'Authorization',
        hint: 'Who can perform this operation'),
    Field('idempotent', String, 'Idempotent',
        hint: 'Whether operation is idempotent: Yes | No'),
  ])
  String? content;
}

/// An object invariant entry (form).
///
/// Business invariants that must always hold true.
@SectionId('OBINV')
class ObjectInvariantEntry {
  @Form([
    Field('invariantName', String, 'Invariant Name',
        required: true, hint: 'Name of the invariant'),
    Field('description', String, 'Description',
        hint: 'What this invariant means'),
    Field('expression', String, 'Expression',
        hint: 'Logic or pseudo-code expressing the invariant'),
    Field('scope', String, 'Scope',
        hint: 'Single | AcrossStates | AcrossObjects'),
    Field('enforcementPoint', String, 'Enforcement Point',
        hint: 'When invariant is checked'),
    Field('violationAction', String, 'Violation Action',
        hint: 'What happens on violation: Reject | Compensate | Alert'),
    Field('businessJustification', String, 'Business Justification',
        hint: 'Why this invariant exists'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 7.3 Function Model
// ---------------------------------------------------------------------------

/// 7.3. Function Model.
///
/// Business functions, their decomposition, and relationships to data objects.
@SectionId('FUMO')
@MapsTo(D03InformationModel)
class FunctionModel {
  // ---------------------------------------------------------------------------
  // Function Decomposition Overview (4 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('decompositionApproach', String, 'Decomposition Approach',
        hint: 'How functions are decomposed: Hierarchical | ProcessBased | CapabilityBased'),
    Field('decompositionDepth', String, 'Decomposition Depth',
        hint: 'Number of levels in the hierarchy'),
    Field('topLevelFunctions', String, 'Top-Level Functions',
        hint: 'Summary of major function areas'),
    Field('decompositionBasis', String, 'Decomposition Basis',
        hint: 'Criteria for breaking down: BusinessCapability | ProcessStep | OrganizationalUnit'),
  ])
  String? decompositionOverview;

  // ---------------------------------------------------------------------------
  // Function-to-Data Matrix Overview (4 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('crudNotation', String, 'CRUD Notation',
        hint: 'Notation used: CRUD | CRUDx | Custom'),
    Field('matrixScope', String, 'Matrix Scope',
        hint: 'What\'s covered: CoreFunctions | AllFunctions | UserFacing'),
    Field('primaryAccessPatterns', String, 'Primary Access Patterns',
        hint: 'Summary of major access patterns'),
    Field('dataOwnership', String, 'Data Ownership',
        hint: 'Which functions own which data'),
  ])
  String? matrixOverview;

  /// 7.3.1. Function Decomposition — contains 0+× Function.
  @SectionId('FUNCT-FUNC-LST')
  @SectionIdPattern('FUNCT-FUNC-xxx')
  List<FunctionEntry> functions = [];

  /// 7.3.2. Function-to-Data Matrix Entries — contains 0+× MatrixEntry.
  @SectionId('FNDMX-MATR-LST')
  @SectionIdPattern('FNDMX-MATR-xxx')
  List<FunctionDataMatrixEntry> matrixEntries = [];

  /// 7.3.3. Business Rules — contains 1+× Business Rule.
  @SectionId('BIRU-BUSI-LST')
  @SectionIdPattern('BIRU-BUSI-xxx')
  @Min(1)
  List<BusinessRuleEntry> businessRules = [];
}

/// A function entry (form).
///
/// Business function specification in the functional decomposition.
@SectionId('FUNCT')
class FunctionEntry {
  @Form([
    Field('functionId', String, 'Function ID',
        hint: 'Unique function identifier'),
    Field('functionName', String, 'Function Name',
        required: true, hint: 'Verb-noun phrase (e.g., Process Order)'),
    Field('description', String, 'Description',
        hint: 'What this function accomplishes'),
    Field('parentFunction', String, 'Parent Function',
        hint: 'Parent function in hierarchy'),
  ])
  String? content;

  /// Decomposition position and classification.
  FunctionEntryClassification classification = FunctionEntryClassification();

  /// Execution profile and criticality.
  FunctionEntryOperations operations = FunctionEntryOperations();

  /// Automation and data handling summary.
  FunctionEntryImplementation implementation = FunctionEntryImplementation();

  /// Sub-functions — contains 0+× SubFunction.
  @SectionId('SUFN-SUBF-LST')
  @SectionIdPattern('SUFN-SUBF-xxx')
  List<SubFunctionEntry> subFunctions = [];
}

/// Decomposition position and classification.
@SectionId('FUENCL')
class FunctionEntryClassification {
  @Form([
    Field('level', String, 'Level',
        hint: 'Hierarchy level: 1 | 2 | 3 etc.'),
    Field('functionType', String, 'Function Type',
        hint: 'Operational | Support | Management | Information'),
    Field('owningProcess', String, 'Owning Process',
        hint: 'Business process this belongs to'),
  ])
  String? content;
}

/// Execution profile and criticality.
@SectionId('FUENOP')
class FunctionEntryOperations {
  @Form([
    Field('frequency', String, 'Frequency',
        hint: 'How often executed: Continuous | Daily | OnDemand | Periodic'),
    Field('volumeEstimate', String, 'Volume Estimate',
        hint: 'Estimated execution frequency/volume'),
    Field('criticalityLevel', String, 'Criticality Level',
        hint: 'Business criticality: Critical | High | Medium | Low'),
  ])
  String? content;
}

/// Automation and data handling summary.
@SectionId('FUENIM')
class FunctionEntryImplementation {
  @Form([
    Field('automationLevel', String, 'Automation Level',
        hint: 'Manual | SemiAutomated | FullyAutomated'),
    Field('dataAccess', String, 'Data Access',
        hint: 'Summary of data entities accessed with CRUD'),
  ])
  String? content;
}

/// A sub-function entry (form).
///
/// Lower-level function in the decomposition.
@SectionId('SUFN')
class SubFunctionEntry {
  @Form([
    Field('subFunctionName', String, 'Sub-Function Name',
        required: true, hint: 'Name of the sub-function'),
    Field('description', String, 'Description',
        hint: 'What this sub-function does'),
    Field('dataAccess', String, 'Data Access',
        hint: 'Entities accessed with CRUD notation'),
    Field('systemSupport', String, 'System Support',
        hint: 'Systems that support this function'),
  ])
  String? content;
}

/// A function-to-data matrix entry (form).
///
/// Maps a function to the data entities it accesses.
@SectionId('FNDMX')
class FunctionDataMatrixEntry {
  @Form([
    Field('functionName', String, 'Function Name',
        required: true, hint: 'Function being mapped'),
    Field('entityName', String, 'Entity Name',
        required: true, hint: 'Data entity being accessed'),
    Field('accessType', String, 'Access Type',
        hint: 'CRUD access: C | R | U | D or combinations'),
    Field('accessFrequency', String, 'Access Frequency',
        hint: 'How often function accesses this entity'),
    Field('isOwner', String, 'Is Owner',
        hint: 'Whether this function owns the entity: Yes | No'),
    Field('accessReason', String, 'Access Reason',
        hint: 'Why this function needs this access'),
  ])
  String? content;
}

/// A business rule entry (form).
///
/// Comprehensive business rule specification following SBVR-like patterns.
@SectionId('BIRU')
class BusinessRuleEntry {
  // ---------------------------------------------------------------------------
  // Rule Identity (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('ruleId', String, 'Rule ID',
        required: true, hint: 'Unique rule identifier (e.g., BR-001)'),
    Field('ruleName', String, 'Rule Name',
        required: true, hint: 'Descriptive name'),
    Field('ruleVersion', String, 'Rule Version',
        hint: 'Version number for change tracking'),
    Field('description', String, 'Description',
        hint: 'Full statement of the business rule'),
    Field('businessStatement', String, 'Business Statement',
        hint: 'Natural language statement from business perspective'),
  ])
  String? identity;

  // ---------------------------------------------------------------------------
  // Classification (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('ruleType', String, 'Rule Type',
        hint: 'Structural | Derivation | Constraint | Authorization | Workflow | Calculation'),
    Field('ruleCategory', String, 'Rule Category',
        hint: 'Validation | Computation | Inference | Action-Enabling'),
    Field('enforcementLevel', String, 'Enforcement Level',
        hint: 'Mandatory | Guideline | Advisory'),
    Field('priority', String, 'Priority',
        hint: 'When rules conflict: 1 (highest) to 5 (lowest)'),
    Field('source', String, 'Source',
        hint: 'Where rule originates: Regulation | Policy | Contract | BestPractice'),
  ])
  String? classification;

  // ---------------------------------------------------------------------------
  // Rule Logic (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('condition', String, 'Condition (IF)',
        hint: 'Trigger condition in natural language or pseudo-code'),
    Field('action', String, 'Action (THEN)',
        hint: 'What happens when condition is true'),
    Field('elseAction', String, 'Else Action (ELSE)',
        hint: 'What happens when condition is false'),
    Field('expression', String, 'Formal Expression',
        hint: 'Formalized rule logic'),
    Field('parameters', String, 'Parameters',
        hint: 'Configurable values in the rule'),
  ])
  String? ruleLogic;

  // ---------------------------------------------------------------------------
  // Implementation (5 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('enforcement', String, 'Enforcement',
        hint: 'How enforced: DatabaseConstraint | ApplicationLogic | Workflow | Manual'),
    Field('implementationPoint', String, 'Implementation Point',
        hint: 'Where implemented: UI | API | Service | Database | Integration'),
    Field('validationTiming', String, 'Validation Timing',
        hint: 'When validated: OnInput | OnSave | OnSubmit | Scheduled | RealTime'),
    Field('systemsInvolved', String, 'Systems Involved',
        hint: 'Which systems enforce this rule'),
    Field('testability', String, 'Testability',
        hint: 'How rule can be tested: UnitTestable | IntegrationRequired | ManualOnly'),
  ])
  String? implementation;

  // ---------------------------------------------------------------------------
  // Exception Handling (4 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('exceptionHandling', String, 'Exception Handling',
        hint: 'How violations are handled'),
    Field('overridePolicy', String, 'Override Policy',
        hint: 'Whether and how rule can be overridden'),
    Field('overrideApproval', String, 'Override Approval',
        hint: 'Who can approve overrides'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'How exceptions are escalated'),
  ])
  String? exceptionHandling;

  // ---------------------------------------------------------------------------
  // Governance (4 fields)
  // ---------------------------------------------------------------------------
  @Form([
    Field('ruleOwner', String, 'Rule Owner',
        hint: 'Business owner responsible for this rule'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'When rule becomes/became effective'),
    Field('expirationDate', String, 'Expiration Date',
        hint: 'When rule expires (if applicable)'),
    Field('reviewFrequency', String, 'Review Frequency',
        hint: 'How often rule is reviewed: Annually | OnChange | Never'),
  ])
  String? governance;

  /// Contains 0+× AffectedObject.
  @SectionId('AFOB-AFFE-LST')
  @SectionIdPattern('AFOB-AFFE-xxx')
  List<AffectedObjectEntry> affectedObjects = [];

  /// Contains 0+× AffectedFunction.
  @SectionId('AFFN-AFFE-LST')
  @SectionIdPattern('AFFN-AFFE-xxx')
  List<AffectedFunctionEntry> affectedFunctions = [];

  /// Contains 0+× RuleExample.
  @SectionId('RULEXM-EXAM-LST')
  @SectionIdPattern('RULEXM-EXAM-xxx')
  List<RuleExampleEntry> examples = [];
}

/// An affected object reference entry (form).
///
/// Business objects affected by this rule.
@SectionId('AFOB')
class AffectedObjectEntry {
  @Form([
    Field('objectName', String, 'Object Name',
        required: true, hint: 'Name of the affected business object'),
    Field('affectedAttributes', String, 'Affected Attributes',
        hint: 'Specific attributes affected'),
    Field('impact', String, 'Impact',
        hint: 'How the object is impacted: Validated | Constrained | Modified | Created'),
    Field('accessType', String, 'Access Type',
        hint: 'Read | Write | Both'),
  ])
  String? content;

  @Reference('objectName')
  String? objectRef;
}

/// An affected function reference entry (form).
///
/// Functions where this rule applies.
@SectionId('AFFN')
class AffectedFunctionEntry {
  @Form([
    Field('functionName', String, 'Function Name',
        required: true, hint: 'Name of the affected function'),
    Field('triggerPoint', String, 'Trigger Point',
        hint: 'When in the function rule is triggered'),
    Field('impact', String, 'Impact',
        hint: 'How the function is impacted'),
    Field('isMandatory', String, 'Is Mandatory',
        hint: 'Whether check is required in this function: Yes | No'),
  ])
  String? content;

  @Reference('functionName')
  String? functionRef;
}

/// A rule example entry (form).
///
/// Examples illustrating rule application.
@SectionId('RULEXM')
class RuleExampleEntry {
  @Form([
    Field('exampleName', String, 'Example Name',
        required: true, hint: 'Name for this example'),
    Field('scenario', String, 'Scenario',
        hint: 'Description of the example scenario'),
    Field('inputData', String, 'Input Data',
        hint: 'Example input values'),
    Field('expectedOutcome', String, 'Expected Outcome',
        hint: 'Expected result of rule evaluation'),
    Field('exampleType', String, 'Example Type',
        hint: 'Positive | Negative | EdgeCase | BoundaryCondition'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 7.1.5 Data Dictionary
// ---------------------------------------------------------------------------

/// 7.1.5. Data Dictionary.
///
/// Attribute-level dictionary that complements the entity overview
///..
@SectionId('DADI')
@DetailedIn(D03InformationModel)
@SecondLevelSectionId(D03InformationModel, 'BDM-DIC')
class DataDictionary {
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
@SectionId('VACO')
@DetailedIn(D03InformationModel)
@SecondLevelSectionId(D03InformationModel, 'BDM-VAL')
class ValidationConstraints {
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
  String? content;
}

// ---------------------------------------------------------------------------
// 7.1.7 Integrity Constraints
// ---------------------------------------------------------------------------

/// 7.1.7. Integrity Constraints.
///
/// Cross-entity integrity rules beyond simple referential integrity.
@SectionId('INCO')
@DetailedIn(D03InformationModel)
@SecondLevelSectionId(D03InformationModel, 'BDM-CON')
class IntegrityConstraints {
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
  String? content;
}

/// A single behavior rule entry.
@SectionId('BEHAV')
class BehaviorRuleEntry {
  @Form([
    Field('keyBusinessRules', String, 'Key Business Rules',
        hint: 'Primary business rules governing this object'),
    Field('invariants', String, 'Invariants',
        hint: 'Conditions that must always be true'),
    Field('keyOperations', String, 'Key Operations',
        hint: 'Main operations/behaviors (e.g., Submit, Approve, Cancel)'),
    Field('validationRules', String, 'Validation Rules',
        hint: 'Rules for validating object state'),
    Field('calculatedProperties', String, 'Calculated Properties',
        hint: 'Derived/calculated attributes (e.g., orderTotal, age)'),
  ])
  String? content;
}

/// A single integration point entry.
@SectionId('INTEG')
class IntegrationPointEntry {
  @Form([
    Field('exposedInApis', String, 'Exposed In APIs',
        hint: 'Which APIs expose this object: Internal | Public | Partner'),
    Field('eventPublished', String, 'Events Published',
        hint: 'Domain events this object publishes'),
    Field('eventSubscribed', String, 'Events Subscribed',
        hint: 'Events this object reacts to'),
    Field('externalSystemMapping', String, 'External System Mapping',
        hint: 'How this maps to external systems'),
  ])
  String? content;
}

/// A single constraint entry.
@SectionId('DATAA')
class DataAttributeConstraintEntry {
  @Form([
    Field('mandatory', String, 'Mandatory',
        hint: 'Whether attribute is required: Required | Optional | ConditionallyRequired'),
    Field('nullable', String, 'Nullable',
        hint: 'Whether database allows NULL: Yes | No'),
    Field('unique', String, 'Unique',
        hint: 'Uniqueness constraint: Unique | UniqueWithinParent | NotUnique'),
    Field('defaultValue', String, 'Default Value',
        hint: 'Default value or expression (e.g., NOW(), 0, "Draft")'),
    Field('validationRules', String, 'Validation Rules',
        hint: 'Business validation rules (e.g., must be positive, max 100)'),
    Field('constraintExpression', String, 'Constraint Expression',
        hint: 'CHECK constraint (e.g., amount > 0, status IN ("Draft","Active"))'),
    Field('allowedValues', String, 'Allowed Values',
        hint: 'Enumerated values if applicable'),
    Field('patternRegex', String, 'Pattern/Regex',
        hint: r'Regex for validation (e.g., ^[A-Z]{2}-\d{6}$ for order IDs)'),
  ])
  String? content;
}

/// A single display property entry.
@SectionId('DISPL')
class DisplayPropertyEntry {
  @Form([
    Field('displayLabel', String, 'Display Label',
        hint: 'User-friendly label for UI'),
    Field('displayOrder', String, 'Display Order',
        hint: 'Order when displaying in forms/tables'),
    Field('displayGroup', String, 'Display Group',
        hint: 'Grouping for UI layout'),
    Field('helpText', String, 'Help Text',
        hint: 'User assistance text for forms'),
  ])
  String? content;
}

/// A single volume metric entry.
@SectionId('VOLUM')
class VolumeMetricEntry {
  @Form([
    Field('estimatedRecordCount', String, 'Estimated Record Count',
        hint: 'Initial record count with source (e.g., 120,000 from migration)'),
    Field('growthRate', String, 'Growth Rate',
        hint: 'Expected growth rate (e.g., 10% annually, 5,000/month)'),
    Field('peakTransactionVolume', String, 'Peak Transaction Volume',
        hint: 'Maximum transactions per time period (e.g., 1,000 orders/hour)'),
    Field('averageRecordSize', String, 'Average Record Size',
        hint: 'Typical record size in bytes for storage planning'),
    Field('storageEstimate', String, 'Storage Estimate',
        hint: 'Projected storage requirements (e.g., 50GB initial, 10GB/year)'),
    Field('partitioningStrategy', String, 'Partitioning Strategy',
        hint: 'How data should be partitioned: ByDate | ByRange | ByHash | None'),
  ])
  String? content;
}

/// A single compliance requirement entry.
@SectionId('COMPL1')
class ComplianceRequirementEntry {
  @Form([
    Field('sensitivityLevel', String, 'Sensitivity Level',
        hint: 'Data sensitivity: Public | Internal | Confidential | Restricted'),
    Field('containsPii', String, 'Contains PII',
        hint: 'Whether entity contains personally identifiable information: Yes | No'),
    Field('containsPhi', String, 'Contains PHI',
        hint: 'Whether entity contains protected health information: Yes | No'),
    Field('complianceFrameworks', String, 'Compliance Frameworks',
        hint: 'Applicable regulations: GDPR | HIPAA | SOX | PCI-DSS | CCPA'),
    Field('encryptionRequirements', String, 'Encryption Requirements',
        hint: 'AtRest | InTransit | Both | FieldLevel | None'),
    Field('accessRestrictions', String, 'Access Restrictions',
        hint: 'Who can access: AllUsers | AuthenticatedUsers | RoleRestricted | SystemOnly'),
  ])
  String? content;
}

/// A single technical characteristic entry.
@SectionId('TECHN')
class TechnicalCharacteristicEntry {
  @Form([
    Field('indexingStrategy', String, 'Indexing Strategy',
        hint: 'Primary index and secondary indexes planned'),
    Field('cachingStrategy', String, 'Caching Strategy',
        hint: 'Cache policy: NoCache | ReadThrough | WriteThrough | CacheAside'),
    Field('consistencyRequirements', String, 'Consistency Requirements',
        hint: 'Strong | Eventual | ReadYourWrites'),
    Field('replicationStrategy', String, 'Replication Strategy',
        hint: 'How data is replicated across regions or nodes'),
    Field('backupRequirements', String, 'Backup Requirements',
        hint: 'Backup frequency and recovery point objective'),
    Field('scalingApproach', String, 'Scaling Approach',
        hint: 'How entity scales: Vertical | Horizontal | Sharding'),
  ])
  String? content;
}

/// A single participant entry.
@SectionId('PARTI')
class ParticipantEntry {
  @Form([
    Field('sourceEntityName', String, 'Source Entity',
        hint: 'Name of the source/parent entity'),
    Field('sourceRole', String, 'Source Role',
        hint: 'Role name on the source end (e.g., "placer" in Customer places Order)'),
    Field('targetEntityName', String, 'Target Entity',
        hint: 'Name of the target/child entity'),
    Field('targetRole', String, 'Target Role',
        hint: 'Role name on the target end (e.g., "placed" in Customer places Order)'),
  ])
  String? content;
}

/// A single relationship attribute entry.
@SectionId('RELAT')
class RelationshipAttributeEntry {
  @Form([
    Field('hasRelationshipAttributes', String, 'Has Relationship Attributes',
        hint: 'Whether the relationship has its own attributes: Yes | No'),
    Field('relationshipAttributes', String, 'Relationship Attributes',
        hint: 'Attributes on the relationship itself (e.g., quantity on OrderItem)'),
    Field('temporalAspects', String, 'Temporal Aspects',
        hint: 'Effective dates, versioning: None | EffectiveDates | FullHistory'),
  ])
  String? content;
}
