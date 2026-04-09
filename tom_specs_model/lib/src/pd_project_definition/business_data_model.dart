/// Section 7: Business Object and Data Model [PD00-BUS]. Seeds → BDM.
///
/// Conceptual overview of the business data the system manages.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 7. Business Object and Data Model [PD00-BUS]. Seeds → BDM.
@tomReflector
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
@tomReflector
class DataModel {
  String? content;

  /// 7.1.1. Entity Overview [PD00-BUS-DAT-ENT] — contains 1+× Data Entity.
  List<DataEntityEntry> entities = [];

  /// 7.1.2. Entity Relationships [PD00-BUS-DAT-REL].
  EntityRelationships entityRelationships = EntityRelationships();

  /// 7.1.3. Entity-Relationship Diagram [PD00-BUS-DAT-DIA] (mermaid).
  String? erDiagram;

  /// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
  DataClassification dataClassification = DataClassification();
}

/// A data entity entry [PD00-BUS-DAT-ENT-nn] (form).
@tomReflector
class DataEntityEntry {
  String? content;
  String? entityName;
  String? description;
  String? category;
  List<DataAttributeEntry> keyAttributes = [];
  String? estimatedRecordCount;
  String? growthRate;
  String? retentionPolicy;
}

/// A data attribute entry (form).
@tomReflector
class DataAttributeEntry {
  String? content;
  String? attributeName;
  String? dataType;
  String? description;
}

/// 7.1.2. Entity Relationships [PD00-BUS-DAT-REL].
@tomReflector
class EntityRelationships {
  String? content;
  List<EntityRelationshipEntry> items = [];
}

/// An entity relationship entry (form).
@tomReflector
class EntityRelationshipEntry {
  String? content;
  String? sourceEntity;
  String? targetEntity;
  String? relationshipType;
  String? cardinality;
  String? description;
}

/// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
@tomReflector
class DataClassification {
  String? content;
  List<DataClassificationEntry> items = [];
}

/// A data classification entry (form).
@tomReflector
class DataClassificationEntry {
  String? content;
  String? classification;
  String? description;
  List<HandlingRequirementEntry> handlingRequirements = [];
  String? retentionPolicy;
  List<AccessRestrictionEntry> accessRestrictions = [];
}

/// A data handling requirement entry (form).
@tomReflector
class HandlingRequirementEntry {
  String? content;
  String? requirement;
  String? description;
}

/// An access restriction entry (form).
@tomReflector
class AccessRestrictionEntry {
  String? content;
  String? restriction;
  String? enforcement;
}

// ---------------------------------------------------------------------------
// 7.2 Business Object Model
// ---------------------------------------------------------------------------

/// 7.2. Business Object Model [PD00-BUS-BUS].
@tomReflector
class BusinessObjectModel {
  String? content;

  /// 7.2.1. Object Catalog [PD00-BUS-BUS-CAT] — contains 1+× Business Object.
  List<BusinessObjectEntry> objects = [];

  /// 7.2.2. Business Object Diagram [PD00-BUS-BUS-DIA] (mermaid).
  String? objectDiagram;
}

/// A business object entry [PD00-BUS-BUS-CAT-nn] (form).
///
/// Includes optional lifecycle state transitions subsection.
@tomReflector
class BusinessObjectEntry {
  String? content;
  String? objectName;
  String? category;
  String? description;
  List<ObjectStateEntry> keyStates = [];
  List<BusinessRuleReferenceEntry> keyBusinessRules = [];

  /// Lifecycle State Transitions [PD00-BUS-BUS-CAT-nn-LIF].
  List<LifecycleTransitionEntry> lifecycleTransitions = [];
}

/// An object state entry (form).
@tomReflector
class ObjectStateEntry {
  String? content;
  String? stateName;
  String? description;
}

/// A business rule reference entry (form).
@tomReflector
class BusinessRuleReferenceEntry {
  String? content;
  String? ruleName;
  String? description;
}

/// A lifecycle transition entry (form).
@tomReflector
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
@tomReflector
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
@tomReflector
class BusinessRuleEntry {
  String? content;
  String? ruleId;
  String? ruleName;
  String? description;
  List<AffectedObjectEntry> affectedObjects = [];
  List<AffectedFunctionEntry> affectedFunctions = [];
  String? enforcement;
  String? exceptionHandling;
}

/// An affected object reference entry (form).
@tomReflector
class AffectedObjectEntry {
  String? content;
  String? objectName;
  String? impact;
}

/// An affected function reference entry (form).
@tomReflector
class AffectedFunctionEntry {
  String? content;
  String? functionName;
  String? impact;
}
