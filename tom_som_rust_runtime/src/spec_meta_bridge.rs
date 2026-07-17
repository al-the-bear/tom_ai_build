//! `spec_meta_bridge` — bridge from the meta-JSON class graph ([`SpecModel`])
//! to the canonical metadata tree ([`SomMetaTree`], DR1 §3.1), a faithful port
//! of the Go `spec_meta_bridge.go` (itself a port of
//! `tom_som_dart_runtime/lib/src/spec_meta_bridge.dart`).
//!
//! The generated facades (DR8) emit populated `SomMetaTree`s directly; every
//! consumer that only has the exported spec-model meta-data (the conformance
//! harness, tooling) builds its tree here. The expansion follows the same walk
//! `SpecReflection.resolve` performs — crucially, a node's
//! [`SomMetaNode::section_id`] is the **field-level** id exactly as exported
//! (`field.section_id`), so the tree's path grammar stays byte-compatible with
//! the paths a `SpecDocument` is keyed by. (DR1 §2.2's "field id, else
//! target-class id" resolution is applied at *export* time by the model
//! exporter / DR8 generator, not re-derived here.)
//!
//! Recursive class references become terminal re-entry nodes
//! ([`SomMetaNode::recursive`]), mirroring how the generated chains terminate.

use std::collections::HashSet;
use std::rc::Rc;

use crate::json::Json;
use crate::spec_meta::{
    SomContentTypeMeta, SomDocMeta, SomFormFieldMeta, SomFormMeta, SomMetaExtra, SomMetaNode,
    SomMetaTree, SomSecondLevelId, SOM_META_KIND_COMPLEX, SOM_META_KIND_SECTION,
};
use crate::spec_model::{
    SpecAnnotation, SpecClass, SpecField, SpecModel, SPEC_FIELD_KIND_COMPLEX,
    SPEC_FIELD_KIND_FORM, SPEC_FIELD_KIND_LIST, SPEC_FIELD_KIND_SECTION,
};

/// Reports whether an annotation name has a dedicated [`SomMetaNode`] slot;
/// everything else is captured losslessly into [`SomMetaNode::extra`].
fn is_slotted_annotation(name: &str) -> bool {
    matches!(
        name,
        "SectionId"
            | "SectionIdPattern"
            | "SerializationOrder"
            | "Min"
            | "Unused"
            | "ContentType"
            | "ContentHelp"
            | "Headline"
            | "Comment"
            | "Form"
            | "Document"
            | "MapsTo"
            | "DetailedIn"
            | "SecondLevelSectionId"
    )
}

/// Builds the wired [`SomMetaTree`] for one document root of `model`.
///
/// When `root_type` is `""` the model's first root is used; otherwise the root
/// is looked up via [`SpecModel::root_by_type`] (returning its error for an
/// unknown type). Children are ordered by `@SerializationOrder` (annotated
/// members first, then declaration order), which is the sibling emission order
/// of the hierarchical YAML format (DR1 §2.3).
pub fn build_som_meta_tree(model: &SpecModel, root_type: &str) -> Result<SomMetaTree, String> {
    let root = if root_type.is_empty() {
        match model.roots.first() {
            Some(r) => r,
            None => model.root_by_type("")?,
        }
    } else {
        model.root_by_type(root_type)?
    };
    let cls = model.class_named(&root.type_);

    let mut section_id = root.section_id.clone();
    let mut class_section_id = String::new();
    let mut doc_comment = root.doc.clone();
    let mut class_doc = String::new();
    let mut maps_to = String::new();
    let mut detailed_in = String::new();
    let mut root_headline = String::new();
    let mut annotations: &[SpecAnnotation] = &[];
    let mut children = Vec::new();
    if let Some(cls) = cls {
        if section_id.is_empty() {
            section_id = cls.section_id.clone();
        }
        class_section_id = cls.section_id.clone();
        if doc_comment.is_empty() {
            doc_comment = cls.doc.clone();
        }
        class_doc = cls.doc.clone();
        root_headline = cls.headline.clone();
        maps_to = cls.maps_to.clone();
        detailed_in = cls.detailed_in.clone();
        annotations = &cls.annotations;
        let mut stack = HashSet::new();
        stack.insert(root.type_.clone());
        children = bridge_child_nodes(model, cls, &mut stack);
    }
    let root_node = SomMetaNode {
        class_name: root.type_.clone(),
        section_id,
        class_section_id,
        kind: SOM_META_KIND_SECTION.to_string(),
        type_name: root.type_.clone(),
        headline: root_headline,
        doc_comment,
        class_doc_comment: class_doc,
        maps_to,
        detailed_in,
        document: Some(SomDocMeta {
            name: root.title.clone(),
            description: root.description.clone(),
            based_on: bridge_based_on(cls),
        }),
        second_level_ids: bridge_second_level_ids(annotations),
        extra: bridge_extras(annotations),
        children,
        ..SomMetaNode::default()
    };
    SomMetaTree::new(Rc::new(root_node))
}

fn bridge_based_on(cls: Option<&SpecClass>) -> Vec<String> {
    let Some(cls) = cls else {
        return Vec::new();
    };
    let Some(ann) = cls.annotation("Document") else {
        return Vec::new();
    };
    let Some(Json::Array(raw)) = ann.argument("basedOn") else {
        return Vec::new();
    };
    raw.iter().map(bridge_str).collect()
}

/// Coerces an annotation argument value to its string form (`""` for absent /
/// unrepresentable values, matching the other ports' `String(x || '')`).
fn bridge_str(v: &Json) -> String {
    match v {
        Json::Str(s) => s.clone(),
        Json::Int(i) => i.to_string(),
        Json::Float(f) => {
            if *f == (*f as i64) as f64 {
                (*f as i64).to_string()
            } else {
                String::new()
            }
        }
        Json::Bool(b) => {
            if *b {
                "true".to_string()
            } else {
                "false".to_string()
            }
        }
        _ => String::new(),
    }
}

fn bridge_child_nodes(
    model: &SpecModel,
    cls: &SpecClass,
    stack: &mut HashSet<String>,
) -> Vec<Rc<SomMetaNode>> {
    const FALLBACK: i64 = 1 << 30;
    let mut fields: Vec<(usize, &SpecField)> = cls.fields.iter().enumerate().collect();
    fields.sort_by_key(|(index, field)| (field.serialization_order.unwrap_or(FALLBACK), *index));
    fields
        .iter()
        .map(|(_, field)| Rc::new(bridge_field_node(model, cls, field, stack)))
        .collect()
}

fn bridge_field_node(
    model: &SpecModel,
    owner: &SpecClass,
    field: &SpecField,
    stack: &mut HashSet<String>,
) -> SomMetaNode {
    let kind = field.kind.clone(); // SPEC_FIELD_KIND_* values equal the SOM_META_KIND_* values.
    let mut target: Option<&SpecClass> = None;
    let mut recursive = false;
    let mut children = Vec::new();
    let mut element_node = None;

    if field.kind == SPEC_FIELD_KIND_COMPLEX || field.kind == SPEC_FIELD_KIND_SECTION {
        target = model.class_named(&field.type_);
        if let Some(t) = target {
            if stack.contains(&t.name) {
                recursive = true;
            } else {
                stack.insert(t.name.clone());
                children = bridge_child_nodes(model, t, stack);
                stack.remove(&t.name);
            }
        }
    } else if field.kind == SPEC_FIELD_KIND_LIST && field.element_is_complex {
        if let Some(element) = model.class_named(&field.element_type) {
            let mut element_children = Vec::new();
            let mut element_recursive = false;
            if stack.contains(&element.name) {
                element_recursive = true;
            } else {
                stack.insert(element.name.clone());
                element_children = bridge_child_nodes(model, element, stack);
                stack.remove(&element.name);
            }
            element_node = Some(Rc::new(SomMetaNode {
                class_name: element.name.clone(),
                class_section_id: element.section_id.clone(),
                kind: SOM_META_KIND_COMPLEX.to_string(),
                type_name: element.name.clone(),
                headline: element.headline.clone(),
                doc_comment: element.doc.clone(),
                class_doc_comment: element.doc.clone(),
                maps_to: element.maps_to.clone(),
                detailed_in: element.detailed_in.clone(),
                recursive: element_recursive,
                children: element_children,
                ..SomMetaNode::default()
            }));
        }
    }

    let content_type = if field.content_type.is_empty() {
        None
    } else {
        let description = field
            .annotation("ContentType")
            .and_then(|a| a.argument("description"))
            .map(bridge_str)
            .unwrap_or_default();
        Some(SomContentTypeMeta {
            type_: field.content_type.clone(),
            description,
        })
    };

    let comment_text = field
        .annotation("Comment")
        .and_then(|a| a.argument("text"))
        .map(bridge_str)
        .unwrap_or_default();

    let form = if field.kind == SPEC_FIELD_KIND_FORM {
        let fields = field
            .form_fields
            .iter()
            .enumerate()
            .map(|(i, ff)| SomFormFieldMeta {
                name: ff.name.clone(),
                type_name: ff.type_.clone(),
                description: ff.label.clone(),
                required: ff.required,
                hint: ff.hint.clone(),
                order: i as i64,
            })
            .collect();
        Some(SomFormMeta { fields })
    } else {
        None
    };

    let mut class_name = owner.name.clone();
    let mut class_section_id = String::new();
    let mut doc_comment = field.doc.clone();
    // YRD4: the field-level `@Headline` wins over the target class's.
    let mut headline = field.headline.clone();
    let mut class_doc = String::new();
    let mut maps_to = String::new();
    let mut detailed_in = String::new();
    if let Some(target) = target {
        class_name = target.name.clone();
        class_section_id = target.section_id.clone();
        if doc_comment.is_empty() {
            doc_comment = target.doc.clone();
        }
        if headline.is_empty() {
            headline = target.headline.clone();
        }
        class_doc = target.doc.clone();
        maps_to = target.maps_to.clone();
        detailed_in = target.detailed_in.clone();
    }
    let mut type_name = field.type_.clone();
    if type_name.is_empty() {
        type_name = field.element_type.clone();
    }
    if type_name.is_empty() {
        type_name = field.enum_type.clone();
    }
    if type_name.is_empty() {
        type_name = "String".to_string();
    }

    SomMetaNode {
        class_name,
        member_name: field.name.clone(),
        section_id: field.section_id.clone(),
        class_section_id,
        section_id_pattern: field.section_id_pattern.clone(),
        kind,
        type_name,
        serialization_order: field.serialization_order,
        min: field.min,
        unused: field.annotation("Unused").is_some(),
        content_type,
        content_help: field.help.clone(),
        headline,
        comment: comment_text,
        doc_comment,
        class_doc_comment: class_doc,
        form,
        maps_to,
        detailed_in,
        second_level_ids: bridge_second_level_ids(&field.annotations),
        extra: bridge_extras(&field.annotations),
        recursive,
        children,
        element_node,
        ..SomMetaNode::default()
    }
}

fn bridge_second_level_ids(annotations: &[SpecAnnotation]) -> Vec<SomSecondLevelId> {
    annotations
        .iter()
        .filter(|a| a.name == "SecondLevelSectionId")
        .map(|a| SomSecondLevelId {
            document_class: a.argument("documentClass").map(bridge_str).unwrap_or_default(),
            id: a.argument("id").map(bridge_str).unwrap_or_default(),
        })
        .collect()
}

fn bridge_extras(annotations: &[SpecAnnotation]) -> Vec<SomMetaExtra> {
    annotations
        .iter()
        .filter(|a| !is_slotted_annotation(&a.name))
        .map(|a| SomMetaExtra {
            annotation: a.name.clone(),
            args: a.arguments.clone(),
        })
        .collect()
}
