/// Section 7: Business Object and Data Model [PD00-BUS]. Seeds → BDM.
///
/// Conceptual overview of the business data the system manages.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 7. Business Object and Data Model [PD00-BUS]. Seeds → BDM.
class BusinessObjectAndDataModel {
  String? content;

  /// 7.1. Data Model [PD00-BUS-DAT].
  DataModel dataModel = DataModel();

  /// 7.2. Business Object Model [PD00-BUS-BUS].
  BusinessObjectModel businessObjectModel = BusinessObjectModel();

  /// 7.3. Function Model [PD00-BUS-FUN].
  FunctionModel functionModel = FunctionModel();
}

// ---------------------------------------------------------------------------
// 7.1 Data Model
// ---------------------------------------------------------------------------

/// 7.1. Data Model [PD00-BUS-DAT].
class DataModel {
  String? content;

  /// 7.1.1. Entity Overview [PD00-BUS-DAT-ENT] — contains 1+× Data Entity.
  List<DataEntityEntry> entities = [];

  /// 7.1.2. Entity Relationships [PD00-BUS-DAT-REL].
  EntityRelationships entityRelationships = EntityRelationships();

  /// 7.1.3. Entity-Relationship Diagram [PD00-BUS-DAT-DIA] (mermaid).
  ErDiagramSection erDiagram = ErDiagramSection();

  /// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
  DataClassification dataClassification = DataClassification();
}

/// A data entity entry [PD00-BUS-DAT-ENT-nn] (form).
class DataEntityEntry {
  @Form([
    Field('entityName', String, 'Entity Name', required: true),
    Field('description', String, 'Short description'),
    Field('category', String, 'Category'),
    Field('estimatedRecordCount', String, 'Estimated Record Count'),
    Field('growthRate', String, 'Growth Rate'),
  ])

  String? content;
  /// Contains 0+× DataAttribute.
  List<DataAttributeEntry> attributes = [];
  /// Contains 0+× KeyAttribute.
  List<KeyAttributeEntry> keyAttributes = [];
  /// Retention Policy.
  TextSection retentionPolicy = TextSection();
}

/// A data attribute entry (form) [PD00-BUS-DAT-ENT-nn-ATT-nn].
class DataAttributeEntry {
  @Form([
    Field('attributeName', String, 'Attribute Name', required: true),
    Field('dataType', String, 'Data Type'),
    Field('length', String, 'Length'),
    Field('format', String, 'Format'),
    Field('mandatory', String, 'Mandatory'),
    Field('description', String, 'Short description'),
  ])

  String? content;
}

/// A key attribute entry (form) — primary, unique, or foreign key [PD00-BUS-DAT-ENT-nn-KEY-nn].
class KeyAttributeEntry {
  @Form([
    Field('attributeName', String, 'Attribute Name', required: true),
    Field('keyType', String, 'Key Type'),
    Field('description', String, 'Short description'),
  ])

  String? content;
  @Reference('Referenced Entity')
  DataEntityEntry? referencedEntity;
}

/// 7.1.2. Entity Relationships [PD00-BUS-DAT-REL].
class EntityRelationships {
  String? content;
  /// Contains 0+× EntityRelationship.
  List<EntityRelationshipEntry> items = [];
}

/// An entity relationship entry (form) [PD00-BUS-DAT-REL-nn].
class EntityRelationshipEntry {
  @Form([
    Field('relationshipType', String, 'Relationship Type'),
    Field('cardinality', String, 'Cardinality'),
    Field('description', String, 'Short description'),
  ])

  String? content;
  @Reference('Source Entity')
  DataEntityEntry? sourceEntity;
  @Reference('Target Entity')
  DataEntityEntry? targetEntity;
}

/// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
class DataClassification {
  String? content;
  /// Contains 0+× DataClassification.
  List<DataClassificationEntry> items = [];
}

/// A data classification entry (form) [PD00-BUS-DAT-CLA-nn].
class DataClassificationEntry {
  @Form([
    Field('classification', String, 'Classification'),
    Field('description', String, 'Short description'),
  ])

  String? content;
  /// Contains 0+× HandlingRequirement.
  List<HandlingRequirementEntry> handlingRequirements = [];
  /// Retention Policy.
  TextSection retentionPolicy = TextSection();
  /// Contains 0+× AccessRestriction.
  List<AccessRestrictionEntry> accessRestrictions = [];
}

/// A data handling requirement entry (form) [PD00-BUS-DAT-CLA-nn-HAN-nn].
class HandlingRequirementEntry {
  @Form([
    Field('requirement', String, 'Requirement'),
    Field('description', String, 'Short description'),
  ])

  String? content;
}

/// An access restriction entry (form) [PD00-BUS-DAT-CLA-nn-ARE-nn].
class AccessRestrictionEntry {
  @Form([
    Field('restriction', String, 'Restriction'),
    Field('enforcement', String, 'Enforcement'),
  ])

  String? content;
}

// ---------------------------------------------------------------------------
// 7.2 Business Object Model
// ---------------------------------------------------------------------------

/// 7.2. Business Object Model [PD00-BUS-BUS].
class BusinessObjectModel {
  String? content;

  /// 7.2.1. Object Catalog [PD00-BUS-BUS-CAT] — contains 1+× Business Object.
  List<BusinessObjectEntry> objects = [];

  /// 7.2.2. Business Object Diagram [PD00-BUS-BUS-DIA] (mermaid).
  DiagramSection objectDiagram = DiagramSection();
}

/// A business object entry [PD00-BUS-BUS-CAT-nn] (form).
///
/// Includes optional lifecycle state transitions subsection.
class BusinessObjectEntry {
  @Form([
    Field('objectName', String, 'Object Name', required: true),
    Field('category', String, 'Category'),
    Field('description', String, 'Short description'),
  ])

  String? content;
  /// Contains 0+× BusinessObjectAttribute.
  List<BusinessObjectAttributeEntry> attributes = [];
  /// Contains 0+× ObjectState.
  List<ObjectStateEntry> keyStates = [];
  /// Contains 0+× BusinessRuleReference.
  List<BusinessRuleReferenceEntry> keyBusinessRules = [];

  /// Lifecycle State Transitions [PD00-BUS-BUS-CAT-nn-LIF] — contains 0+× LifecycleTransition.
  List<LifecycleTransitionEntry> lifecycleTransitions = [];
}

/// A business object attribute entry (form) [PD00-BUS-BUS-CAT-nn-BOA-nn].
class BusinessObjectAttributeEntry {
  @Form([
    Field('attributeName', String, 'Attribute Name', required: true),
    Field('type', String, 'Type'),
    Field('length', String, 'Length'),
    Field('format', String, 'Format'),
    Field('description', String, 'Short description'),
    Field('mandatory', String, 'Mandatory'),
    Field('defaultValue', String, 'Default Value'),
    Field('validationRules', String, 'Validation Rules'),
  ])

  String? content;
}

/// An object state entry (form) [PD00-BUS-BUS-CAT-nn-STA-nn].
class ObjectStateEntry {
  @Form([
    Field('stateName', String, 'State Name'),
    Field('description', String, 'Short description'),
  ])

  String? content;
}

/// A business rule reference entry (form) [PD00-BUS-BUS-CAT-nn-BRR-nn].
class BusinessRuleReferenceEntry {
  @Form([
    Field('ruleName', String, 'Rule Name', required: true),
    Field('description', String, 'Short description'),
  ])

  String? content;
}

/// A lifecycle transition entry (form) [PD00-BUS-BUS-CAT-nn-LIF-nn].
class LifecycleTransitionEntry {
  @Form([
    Field('fromState', String, 'From State'),
    Field('toState', String, 'To State'),
    Field('trigger', String, 'Trigger'),
  ])

  String? content;
}

// ---------------------------------------------------------------------------
// 7.3 Function Model
// ---------------------------------------------------------------------------

/// 7.3. Function Model [PD00-BUS-FUN].
class FunctionModel {
  @Form([
    Field('functionDecomposition', String, 'Function Decomposition'),
    Field('functionToDataMatrix', String, 'Function To Data Matrix'),
  ])

  String? content;

  /// 7.3.3. Business Rules [PD00-BUS-FUN-RUL] — contains 1+× Business Rule.
  List<BusinessRuleEntry> businessRules = [];
}

/// A business rule entry [PD00-BUS-FUN-RUL-nn] (form).
class BusinessRuleEntry {
  @Form([
    Field('ruleId', String, 'Rule Id', required: true),
    Field('ruleName', String, 'Rule Name', required: true),
    Field('description', String, 'Short description'),
    Field('enforcement', String, 'Enforcement'),
    Field('exceptionHandling', String, 'Exception Handling'),
  ])

  String? content;
  /// Contains 0+× AffectedObject.
  List<AffectedObjectEntry> affectedObjects = [];
  /// Contains 0+× AffectedFunction.
  List<AffectedFunctionEntry> affectedFunctions = [];
}

/// An affected object reference entry (form) [PD00-BUS-FUN-RUL-nn-AOB-nn].
class AffectedObjectEntry {
  @Form([
    Field('objectName', String, 'Object Name', required: true),
    Field('impact', String, 'Impact assessment'),
  ])

  String? content;
}

/// An affected function reference entry (form) [PD00-BUS-FUN-RUL-nn-AFU-nn].
class AffectedFunctionEntry {
  @Form([
    Field('functionName', String, 'Function Name'),
    Field('impact', String, 'Impact assessment'),
  ])

  String? content;
}
