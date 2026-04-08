/// Section 7: Business Object and Data Model [PD00-BUS]. Seeds → BDM.
///
/// Conceptual overview of the business data the system manages.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 7. Business Object and Data Model [PD00-BUS]. Seeds → BDM.
@tomReflector
class BusinessObjectAndDataModel {
  final String? content;

  /// 7.1. Data Model [PD00-BUS-DAT].
  final DataModel dataModel;

  /// 7.2. Business Object Model [PD00-BUS-BUS].
  final BusinessObjectModel businessObjectModel;

  /// 7.3. Function Model [PD00-BUS-FUN].
  final FunctionModel functionModel;

  const BusinessObjectAndDataModel({
    this.content,
    this.dataModel = const DataModel(),
    this.businessObjectModel = const BusinessObjectModel(),
    this.functionModel = const FunctionModel(),
  });
}

// ---------------------------------------------------------------------------
// 7.1 Data Model
// ---------------------------------------------------------------------------

/// 7.1. Data Model [PD00-BUS-DAT].
@tomReflector
class DataModel {
  final String? content;

  /// 7.1.1. Entity Overview [PD00-BUS-DAT-ENT] — contains 1+× Data Entity.
  final List<DataEntityEntry> entities;

  /// 7.1.2. Entity Relationships [PD00-BUS-DAT-REL].
  final EntityRelationships entityRelationships;

  /// 7.1.3. Entity-Relationship Diagram [PD00-BUS-DAT-DIA] (mermaid).
  final String? erDiagram;

  /// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
  final DataClassification dataClassification;

  const DataModel({
    this.content,
    this.entities = const [],
    this.entityRelationships = const EntityRelationships(),
    this.erDiagram,
    this.dataClassification = const DataClassification(),
  });
}

/// A data entity entry [PD00-BUS-DAT-ENT-nn] (form).
@tomReflector
class DataEntityEntry {
  final String? content;
  final String? entityName;
  final String? description;
  final String? category;
  final List<DataAttributeEntry> keyAttributes;
  final String? estimatedRecordCount;
  final String? growthRate;
  final String? retentionPolicy;

  const DataEntityEntry({
    this.content,
    this.entityName,
    this.description,
    this.category,
    this.keyAttributes = const [],
    this.estimatedRecordCount,
    this.growthRate,
    this.retentionPolicy,
  });
}

/// A data attribute entry (form).
@tomReflector
class DataAttributeEntry {
  final String? content;
  final String? attributeName;
  final String? dataType;
  final String? description;

  const DataAttributeEntry({
    this.content,
    this.attributeName,
    this.dataType,
    this.description,
  });
}

/// 7.1.2. Entity Relationships [PD00-BUS-DAT-REL].
@tomReflector
class EntityRelationships {
  final String? content;
  final List<EntityRelationshipEntry> items;

  const EntityRelationships({this.content, this.items = const []});
}

/// An entity relationship entry (form).
@tomReflector
class EntityRelationshipEntry {
  final String? content;
  final String? sourceEntity;
  final String? targetEntity;
  final String? relationshipType;
  final String? cardinality;
  final String? description;

  const EntityRelationshipEntry({
    this.content,
    this.sourceEntity,
    this.targetEntity,
    this.relationshipType,
    this.cardinality,
    this.description,
  });
}

/// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
@tomReflector
class DataClassification {
  final String? content;
  final List<DataClassificationEntry> items;

  const DataClassification({this.content, this.items = const []});
}

/// A data classification entry (form).
@tomReflector
class DataClassificationEntry {
  final String? content;
  final String? classification;
  final String? description;
  final List<HandlingRequirementEntry> handlingRequirements;
  final String? retentionPolicy;
  final List<AccessRestrictionEntry> accessRestrictions;

  const DataClassificationEntry({
    this.content,
    this.classification,
    this.description,
    this.handlingRequirements = const [],
    this.retentionPolicy,
    this.accessRestrictions = const [],
  });
}

/// A data handling requirement entry (form).
@tomReflector
class HandlingRequirementEntry {
  final String? content;
  final String? requirement;
  final String? description;

  const HandlingRequirementEntry({
    this.content,
    this.requirement,
    this.description,
  });
}

/// An access restriction entry (form).
@tomReflector
class AccessRestrictionEntry {
  final String? content;
  final String? restriction;
  final String? enforcement;

  const AccessRestrictionEntry({
    this.content,
    this.restriction,
    this.enforcement,
  });
}

// ---------------------------------------------------------------------------
// 7.2 Business Object Model
// ---------------------------------------------------------------------------

/// 7.2. Business Object Model [PD00-BUS-BUS].
@tomReflector
class BusinessObjectModel {
  final String? content;

  /// 7.2.1. Object Catalog [PD00-BUS-BUS-CAT] — contains 1+× Business Object.
  final List<BusinessObjectEntry> objects;

  /// 7.2.2. Business Object Diagram [PD00-BUS-BUS-DIA] (mermaid).
  final String? objectDiagram;

  const BusinessObjectModel({
    this.content,
    this.objects = const [],
    this.objectDiagram,
  });
}

/// A business object entry [PD00-BUS-BUS-CAT-nn] (form).
///
/// Includes optional lifecycle state transitions subsection.
@tomReflector
class BusinessObjectEntry {
  final String? content;
  final String? objectName;
  final String? category;
  final String? description;
  final List<ObjectStateEntry> keyStates;
  final List<BusinessRuleReferenceEntry> keyBusinessRules;

  /// Lifecycle State Transitions [PD00-BUS-BUS-CAT-nn-LIF].
  final List<LifecycleTransitionEntry> lifecycleTransitions;

  const BusinessObjectEntry({
    this.content,
    this.objectName,
    this.category,
    this.description,
    this.keyStates = const [],
    this.keyBusinessRules = const [],
    this.lifecycleTransitions = const [],
  });
}

/// An object state entry (form).
@tomReflector
class ObjectStateEntry {
  final String? content;
  final String? stateName;
  final String? description;

  const ObjectStateEntry({this.content, this.stateName, this.description});
}

/// A business rule reference entry (form).
@tomReflector
class BusinessRuleReferenceEntry {
  final String? content;
  final String? ruleName;
  final String? description;

  const BusinessRuleReferenceEntry({
    this.content,
    this.ruleName,
    this.description,
  });
}

/// A lifecycle transition entry (form).
@tomReflector
class LifecycleTransitionEntry {
  final String? content;
  final String? fromState;
  final String? toState;
  final String? trigger;

  const LifecycleTransitionEntry({
    this.content,
    this.fromState,
    this.toState,
    this.trigger,
  });
}

// ---------------------------------------------------------------------------
// 7.3 Function Model
// ---------------------------------------------------------------------------

/// 7.3. Function Model [PD00-BUS-FUN].
@tomReflector
class FunctionModel {
  final String? content;

  /// 7.3.1. Function Decomposition [PD00-BUS-FUN-DEC].
  final String? functionDecomposition;

  /// 7.3.2. Function-to-Data Matrix [PD00-BUS-FUN-MAT].
  final String? functionToDataMatrix;

  /// 7.3.3. Business Rules [PD00-BUS-FUN-RUL] — contains 1+× Business Rule.
  final List<BusinessRuleEntry> businessRules;

  const FunctionModel({
    this.content,
    this.functionDecomposition,
    this.functionToDataMatrix,
    this.businessRules = const [],
  });
}

/// A business rule entry [PD00-BUS-FUN-RUL-nn] (form).
@tomReflector
class BusinessRuleEntry {
  final String? content;
  final String? ruleId;
  final String? ruleName;
  final String? description;
  final List<AffectedObjectEntry> affectedObjects;
  final List<AffectedFunctionEntry> affectedFunctions;
  final String? enforcement;
  final String? exceptionHandling;

  const BusinessRuleEntry({
    this.content,
    this.ruleId,
    this.ruleName,
    this.description,
    this.affectedObjects = const [],
    this.affectedFunctions = const [],
    this.enforcement,
    this.exceptionHandling,
  });
}

/// An affected object reference entry (form).
@tomReflector
class AffectedObjectEntry {
  final String? content;
  final String? objectName;
  final String? impact;

  const AffectedObjectEntry({this.content, this.objectName, this.impact});
}

/// An affected function reference entry (form).
@tomReflector
class AffectedFunctionEntry {
  final String? content;
  final String? functionName;
  final String? impact;

  const AffectedFunctionEntry({
    this.content,
    this.functionName,
    this.impact,
  });
}
