//! `spec_meta_diff` — structural comparison of two [`SomMetaNode`] subtrees; a
//! faithful port of `tom_som_go_runtime/spec_meta_diff.go` (itself a port of
//! `tom_som_dart_runtime/lib/src/spec_meta_diff.dart` and the TypeScript /
//! Python / JavaScript siblings).
//!
//! [`som_meta_node_diff`] is the agreement oracle: the generated
//! facades embed populated metadata trees as static code (SOM §7.2), while
//! [`crate::build_som_meta_tree`] derives the same tree from the exported
//! meta-JSON at runtime — the two must be field-for-field identical for every
//! node. Tests compare them with this function, which returns a human-readable
//! description of the **first** difference found (with the node's position),
//! or the empty string when the subtrees agree completely.
//!
//! Rust conventions (documented divergences from the Go port): optional ints
//! are `Option<i64>` instead of `*int` (still rendered as `null` when absent so
//! the message strings stay aligned with the sibling ports), and
//! annotation-argument values are the runtime's own [`Json`] enum, whose
//! numeric variants compare by numeric value across `Int`/`Float` (the JSON
//! decoder yields `Float` where generated literals may be integral).

use crate::json::{encode_str, Json};
use crate::spec_meta::{
    SomContentTypeMeta, SomDocMeta, SomFormMeta, SomMetaExtra, SomMetaNode,
};

/// Compares the `a` and `b` subtrees field by field (annotations, names,
/// kinds, form/document metadata, children and list element subtrees).
///
/// Returns `""` when the subtrees are structurally identical, else a
/// description of the first difference, prefixed with the node's position (a
/// `/`-joined member-name chain rooted at the `<root>` marker).
pub fn som_meta_node_diff(a: &SomMetaNode, b: &SomMetaNode) -> String {
    som_meta_node_diff_at(a, b, "<root>")
}

fn som_meta_node_diff_at(a: &SomMetaNode, b: &SomMetaNode, at: &str) -> String {
    if a.class_name != b.class_name {
        return str_diff(at, "className", &a.class_name, &b.class_name);
    }
    if a.member_name != b.member_name {
        return str_diff(at, "memberName", &a.member_name, &b.member_name);
    }
    if a.section_id != b.section_id {
        return str_diff(at, "sectionId", &a.section_id, &b.section_id);
    }
    if a.section_id_pattern != b.section_id_pattern {
        return str_diff(
            at,
            "sectionIdPattern",
            &a.section_id_pattern,
            &b.section_id_pattern,
        );
    }
    if a.kind != b.kind {
        return str_diff(at, "kind", &a.kind, &b.kind);
    }
    if a.type_name != b.type_name {
        return str_diff(at, "typeName", &a.type_name, &b.type_name);
    }
    if a.serialization_order != b.serialization_order {
        return str_diff(
            at,
            "serializationOrder",
            &opt_int_repr(a.serialization_order),
            &opt_int_repr(b.serialization_order),
        );
    }
    if a.min != b.min {
        return str_diff(at, "min", &opt_int_repr(a.min), &opt_int_repr(b.min));
    }
    if a.unused != b.unused {
        return str_diff(
            at,
            "unused",
            &a.unused.to_string(),
            &b.unused.to_string(),
        );
    }
    let (a_ct_type, a_ct_desc) = content_type_fields(&a.content_type);
    let (b_ct_type, b_ct_desc) = content_type_fields(&b.content_type);
    if a_ct_type != b_ct_type {
        return str_diff(at, "contentType.type", &a_ct_type, &b_ct_type);
    }
    if a_ct_desc != b_ct_desc {
        return str_diff(at, "contentType.description", &a_ct_desc, &b_ct_desc);
    }
    if a.content_help != b.content_help {
        return str_diff(at, "contentHelp", &a.content_help, &b.content_help);
    }
    if a.headline != b.headline {
        return str_diff(at, "headline", &a.headline, &b.headline);
    }
    if a.comment != b.comment {
        return str_diff(at, "comment", &a.comment, &b.comment);
    }
    if a.doc_comment != b.doc_comment {
        return str_diff(at, "docComment", &a.doc_comment, &b.doc_comment);
    }
    if a.class_doc_comment != b.class_doc_comment {
        return str_diff(
            at,
            "classDocComment",
            &a.class_doc_comment,
            &b.class_doc_comment,
        );
    }
    if a.maps_to != b.maps_to {
        return str_diff(at, "mapsTo", &a.maps_to, &b.maps_to);
    }
    if a.detailed_in != b.detailed_in {
        return str_diff(at, "detailedIn", &a.detailed_in, &b.detailed_in);
    }
    if a.recursive != b.recursive {
        return str_diff(
            at,
            "recursive",
            &a.recursive.to_string(),
            &b.recursive.to_string(),
        );
    }
    let d = meta_form_diff(at, &a.form, &b.form);
    if !d.is_empty() {
        return d;
    }
    let d = meta_document_diff(at, &a.document, &b.document);
    if !d.is_empty() {
        return d;
    }
    let d = meta_extra_diff(at, &a.extra, &b.extra);
    if !d.is_empty() {
        return d;
    }

    if a.children.len() != b.children.len() {
        return format!(
            "{}: children count differs — {} != {} ({} vs {})",
            at,
            a.children.len(),
            b.children.len(),
            json_repr_strings(&member_names(&a.children)),
            json_repr_strings(&member_names(&b.children)),
        );
    }
    for (ca, cb) in a.children.iter().zip(b.children.iter()) {
        let name = if ca.member_name.is_empty() {
            &ca.class_name
        } else {
            &ca.member_name
        };
        let d = som_meta_node_diff_at(ca, cb, &format!("{}/{}", at, name));
        if !d.is_empty() {
            return d;
        }
    }

    let a_elem = a.element_node.is_some();
    let b_elem = b.element_node.is_some();
    if a_elem != b_elem {
        return format!(
            "{}: elementNode presence differs — {} != {}",
            at, a_elem, b_elem
        );
    }
    if let (Some(ea), Some(eb)) = (&a.element_node, &b.element_node) {
        return som_meta_node_diff_at(ea, eb, &format!("{}/§element", at));
    }
    String::new()
}

fn str_diff(at: &str, field: &str, a: &str, b: &str) -> String {
    format!("{}: {} differs — {} != {}", at, field, a, b)
}

fn member_names(nodes: &[std::rc::Rc<SomMetaNode>]) -> Vec<String> {
    nodes.iter().map(|n| n.member_name.clone()).collect()
}

/// Renders the two comparable fields of an optional `@ContentType` the way the
/// sibling ports interpolate them (`null` for an absent annotation).
fn content_type_fields(ct: &Option<SomContentTypeMeta>) -> (String, String) {
    match ct {
        None => ("null".to_string(), "null".to_string()),
        Some(c) => (c.type_.clone(), c.description.clone()),
    }
}

fn opt_int_repr(v: Option<i64>) -> String {
    match v {
        None => "null".to_string(),
        Some(n) => n.to_string(),
    }
}

fn meta_form_diff(at: &str, a: &Option<SomFormMeta>, b: &Option<SomFormMeta>) -> String {
    let a_set = a.is_some();
    let b_set = b.is_some();
    if a_set != b_set {
        return format!("{}: form presence differs — {} != {}", at, a_set, b_set);
    }
    let (Some(fa), Some(fb)) = (a, b) else {
        return String::new();
    };
    if fa.fields.len() != fb.fields.len() {
        return format!(
            "{}: form field count differs — {} != {}",
            at,
            fa.fields.len(),
            fb.fields.len()
        );
    }
    for (x, y) in fa.fields.iter().zip(fb.fields.iter()) {
        if x.name != y.name
            || x.type_name != y.type_name
            || x.description != y.description
            || x.required != y.required
            || x.hint != y.hint
            || x.order != y.order
        {
            return format!("{}: form field {} differs", at, x.name);
        }
    }
    String::new()
}

fn meta_document_diff(at: &str, a: &Option<SomDocMeta>, b: &Option<SomDocMeta>) -> String {
    let a_set = a.is_some();
    let b_set = b.is_some();
    if a_set != b_set {
        return format!(
            "{}: document presence differs — {} != {}",
            at, a_set, b_set
        );
    }
    let (Some(da), Some(db)) = (a, b) else {
        return String::new();
    };
    if da.name != db.name {
        return format!("{}: document.name differs — {} != {}", at, da.name, db.name);
    }
    if da.description != db.description {
        return format!("{}: document.description differs", at);
    }
    if da.based_on != db.based_on {
        return format!(
            "{}: document.basedOn differs — {} != {}",
            at,
            json_repr_strings(&da.based_on),
            json_repr_strings(&db.based_on)
        );
    }
    String::new()
}

fn meta_extra_diff(at: &str, a: &[SomMetaExtra], b: &[SomMetaExtra]) -> String {
    if a.len() != b.len() {
        let a_names: Vec<String> = a.iter().map(|e| e.annotation.clone()).collect();
        let b_names: Vec<String> = b.iter().map(|e| e.annotation.clone()).collect();
        return format!(
            "{}: extra annotation count differs — {} != {} ({} vs {})",
            at,
            a.len(),
            b.len(),
            json_repr_strings(&a_names),
            json_repr_strings(&b_names)
        );
    }
    for (x, y) in a.iter().zip(b.iter()) {
        if x.annotation != y.annotation || !args_eq(&x.args, &y.args) {
            return format!(
                "{}: extra annotation {} differs — {} != {}",
                at,
                x.annotation,
                json_repr_args(&x.args),
                json_repr_args(&y.args)
            );
        }
    }
    String::new()
}

/// Compares two annotation-argument lists as unordered string-keyed maps —
/// mirroring the Go port, whose args are `map[string]interface{}` (a nil map
/// equals an empty one; here both are just empty `Vec`s).
fn args_eq(a: &[(String, Json)], b: &[(String, Json)]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    a.iter().all(|(k, av)| {
        b.iter()
            .find(|(bk, _)| bk == k)
            .is_some_and(|(_, bv)| meta_value_eq(av, bv))
    })
}

/// Deep structural equality over JSON-shaped values (the annotation-argument
/// shapes: scalars, arrays, string-keyed objects). Numbers compare by numeric
/// value across `Int`/`Float` (see the module header); objects compare as
/// unordered maps, mirroring Go's `map[string]interface{}` semantics.
fn meta_value_eq(a: &Json, b: &Json) -> bool {
    if let (Some(an), Some(bn)) = (as_float(a), as_float(b)) {
        return an == bn;
    }
    match (a, b) {
        (Json::Array(al), Json::Array(bl)) => {
            al.len() == bl.len()
                && al.iter().zip(bl.iter()).all(|(x, y)| meta_value_eq(x, y))
        }
        (Json::Object(am), Json::Object(bm)) => args_eq(am, bm),
        _ => a == b,
    }
}

fn as_float(v: &Json) -> Option<f64> {
    match v {
        Json::Int(n) => Some(*n as f64),
        Json::Float(n) => Some(*n),
        _ => None,
    }
}

/// Renders a string list as compact JSON for diff messages (mirroring the Go
/// port's `json.Marshal` interpolations).
fn json_repr_strings(items: &[String]) -> String {
    let parts: Vec<String> = items.iter().map(|s| encode_str(s)).collect();
    format!("[{}]", parts.join(","))
}

/// Renders an annotation-argument list as a compact JSON object.
fn json_repr_args(args: &[(String, Json)]) -> String {
    let parts: Vec<String> = args
        .iter()
        .map(|(k, v)| format!("{}:{}", encode_str(k), json_repr(v)))
        .collect();
    format!("{{{}}}", parts.join(","))
}

/// Renders a [`Json`] value as compact JSON for diff messages.
fn json_repr(v: &Json) -> String {
    match v {
        Json::Null => "null".to_string(),
        Json::Bool(b) => b.to_string(),
        Json::Int(n) => n.to_string(),
        Json::Float(n) => format!("{}", n),
        Json::Str(s) => encode_str(s),
        Json::Array(items) => {
            let parts: Vec<String> = items.iter().map(json_repr).collect();
            format!("[{}]", parts.join(","))
        }
        Json::Object(pairs) => json_repr_args(pairs),
    }
}
