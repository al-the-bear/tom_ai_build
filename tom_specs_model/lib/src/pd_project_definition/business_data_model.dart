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
  String? content;
  String? entityName;
  String? description;
  String? category;
  /// Contains 0+× DataAttribute.
  List<DataAttributeEntry> attributes = [];
  /// Contains 0+× KeyAttribute.
  List<KeyAttributeEntry> keyAttributes = [];
  String? estimatedRecordCount;
  String? growthRate;
  String? retentionPolicy;
}

/// A data attribute entry (form) [PD00-BUS-DAT-ENT-nn-ATT-nn].
class DataAttributeEntry {
  String? content;
  String? attributeName;
  String? dataType;
  String? length;
  String? format;
  String? mandatory;
  String? description;
}

/// A key attribute entry (form) — primary, unique, or foreign key [PD00-BUS-DAT-ENT-nn-KEY-nn].
class KeyAttributeEntry {
  String? content;
  String? attributeName;
  String? keyType;
  String? referencedEntity;
  String? description;
}

/// 7.1.2. Entity Relationships [PD00-BUS-DAT-REL].
class EntityRelationships {
  String? content;
  /// Contains 0+× EntityRelationship.
  List<EntityRelationshipEntry> items = [];
}

/// An entity relationship entry (form) [PD00-BUS-DAT-REL-nn].
class EntityRelationshipEntry {
  String? content;
  String? sourceEntity;
  String? targetEntity;
  String? relationshipType;
  String? cardinality;
  String? description;
}

/// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
class DataClassification {
  String? content;
  /// Contains 0+× DataClassification.
  List<DataClassificationEntry> items = [];
}

/// A data classification entry (form) [PD00-BUS-DAT-CLA-nn].
class DataClassificationEntry {
  String? content;
  String? classification;
  String? description;
  /// Contains 0+× HandlingRequirement.
  List<HandlingRequirementEntry> handlingRequirements = [];
  String? retentionPolicy;
  /// Contains 0+× AccessRestriction.
  List<AccessRestrictionEntry> accessRestrictions = [];
}

/// A data handling requirement entry (form) [PD00-BUS-DAT-CLA-nn-HAN-nn].
class HandlingRequirementEntry {
  String? content;
  String? requirement;
  String? description;
}

/// An access restriction entry (form) [PD00-BUS-DAT-CLA-nn-ARE-nn].
class AccessRestrictionEntry {
  String? content;
  String? restriction;
  String? enforcement;
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
  String? content;
  String? objectName;
  String? category;
  String? description;
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
  String? content;
  String? attributeName;
  String? type;
  String? length;
  String? format;
  String? description;
  String? mandatory;
  String? defaultValue;
  String? validationRules;
}

/// An object state entry (form) [PD00-BUS-BUS-CAT-nn-STA-nn].
class ObjectStateEntry {
  String? content;
  String? stateName;
  String? description;
}

/// A business rule reference entry (form) [PD00-BUS-BUS-CAT-nn-BRR-nn].
class BusinessRuleReferenceEntry {
  String? content;
  String? ruleName;
  String? description;
}

/// A lifecycle transition entry (form) [PD00-BUS-BUS-CAT-nn-LIF-nn].
class LifecycleTransitionEntry {
  String? content;
  String? fromState;
  String? toState;
  String? trigger;
}

// ---------------------------------------------------------------------------
// 7.3 Function Model
// ---------------------------------------------------------------------------

/// 7.3. Function Model [PD00-BUS-FUN].
class FunctionModel {
  String? content;

  /// 7.3.1. Function Decomposition [PD00-BUS-FUN-DEC].
  String? functionDecomposition;

  /// 7.3.2. Function-to-Data Matrix [PD00-BUS-FUN-MAT].
  String? functionToDataMatrix;

  /// 7.3.3. Business Rules [PD00-BUS-FUN-RUL] — contains 1+× Business Rule.
  List<BusinessRuleEntry> businessRules = [];
}

/// A business rule entry [PD00-BUS-FUN-RUL-nn] (form).
class BusinessRuleEntry {
  String? content;
  String? ruleId;
  String? ruleName;
  String? description;
  /// Contains 0+× AffectedObject.
  List<AffectedObjectEntry> affectedObjects = [];
  /// Contains 0+× AffectedFunction.
  List<AffectedFunctionEntry> affectedFunctions = [];
  String? enforcement;
  String? exceptionHandling;
}

/// An affected object reference entry (form) [PD00-BUS-FUN-RUL-nn-AOB-nn].
class AffectedObjectEntry {
  String? content;
  String? objectName;
  String? impact;
}

/// An affected function reference entry (form) [PD00-BUS-FUN-RUL-nn-AFU-nn].
class AffectedFunctionEntry {
  String? content;
  String? functionName;
  String? impact;
}
